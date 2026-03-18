//
//  TimerManager.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import Foundation
import Combine

class TimerManager: NSObject, ObservableObject {
    static let shared = TimerManager()

    @Published var elapsedSeconds = 0
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentEntry: TimeEntry?
    @Published var currentSession: TimerSession?

    private var displayTimer: DispatchSourceTimer?
    private var heartbeatTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.projecttracker.timer")

    override private init() {
        super.init()
        checkForInterruptedSession()
    }

    // MARK: - Timer Control

    func startTimer(taskId: UUID, projectId: UUID) {
        timerQueue.async { [weak self] in
            guard let self = self else { return }

            let startTime = Date()
            let entry = TimeEntry(
                id: UUID(),
                taskId: taskId,
                projectId: projectId,
                startTime: startTime,
                endTime: nil,
                duration: 0,
                date: startTime.dateOnly,
                status: .running,
                wasInterrupted: false
            )

            let session = TimerSession(
                id: UUID(),
                taskId: taskId,
                projectId: projectId,
                timerStartedAt: startTime,
                lastHeartbeat: startTime
            )

            DispatchQueue.main.async {
                self.currentEntry = entry
                self.currentSession = session
                self.isRunning = true
                self.isPaused = false
                self.elapsedSeconds = 0
            }

            self.saveSession(session)
            self.startDisplayTimer()
            self.startHeartbeatTimer()

            Logger.info("Timer started for task: \(taskId)")
        }
    }

    func pauseTimer() {
        timerQueue.async { [weak self] in
            guard let self = self else { return }

            self.displayTimer?.cancel()
            self.heartbeatTimer?.cancel()

            DispatchQueue.main.async {
                self.isRunning = false
                self.isPaused = true
            }

            if let session = self.currentSession {
                self.updateSession(session)
            }

            Logger.info("Timer paused")
        }
    }

    func resumeTimer() {
        timerQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isRunning = true
                self.isPaused = false
            }

            self.startDisplayTimer()
            self.startHeartbeatTimer()

            Logger.info("Timer resumed")
        }
    }

    func stopTimer() {
        timerQueue.async { [weak self] in
            guard let self = self else { return }

            self.displayTimer?.cancel()
            self.heartbeatTimer?.cancel()

            if var entry = self.currentEntry, let endTime = Date() as Date? {
                entry.endTime = endTime
                entry.duration = Int(endTime.timeIntervalSince(entry.startTime))
                entry.status = .completed

                self.saveTimeEntry(entry)
            }

            if let session = self.currentSession {
                self.deleteSession(session)
            }

            DispatchQueue.main.async {
                self.isRunning = false
                self.isPaused = false
                self.currentEntry = nil
                self.currentSession = nil
                self.elapsedSeconds = 0
            }

            Logger.info("Timer stopped")
        }
    }

    // MARK: - Private Timer Helpers

    private func startDisplayTimer() {
        displayTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        displayTimer?.schedule(deadline: .now(), repeating: AppConstants.timerDisplayInterval)
        displayTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }

            if let startTime = self.currentEntry?.startTime {
                let elapsed = Int(Date().timeIntervalSince(startTime))
                DispatchQueue.main.async {
                    self.elapsedSeconds = elapsed
                }
            }
        }
        displayTimer?.resume()
    }

    private func startHeartbeatTimer() {
        heartbeatTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        heartbeatTimer?.schedule(deadline: .now(), repeating: AppConstants.timerHeartbeatInterval)
        heartbeatTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }

            if var session = self.currentSession {
                session.lastHeartbeat = Date()
                self.updateSession(session)
            }
        }
        heartbeatTimer?.resume()
    }

    // MARK: - Crash Recovery

    func checkForInterruptedSession() {
        timerQueue.async { [weak self] in
            guard let self = self else { return }
            // Implementation: Query for interrupted sessions and prompt user
            Logger.info("Checking for interrupted sessions...")
        }
    }

    func recoverInterruptedSession(_ keep: Bool) {
        if keep {
            Logger.info("Session recovered")
        } else {
            Logger.info("Session discarded")
        }
    }

    // MARK: - Database Operations

    private func saveSession(_ session: TimerSession) {
        let db = DatabaseManager.shared
        let query = """
        INSERT INTO session_state (id, task_id, project_id, timer_started_at, last_heartbeat)
        VALUES ('\(session.id.uuidString)', '\(session.taskId.uuidString)', '\(session.projectId.uuidString)', datetime('now'), datetime('now'))
        """
        
        if db.execute(query) {
            Logger.debug("Session saved: \(session.id)")
        } else {
            Logger.error("Failed to save session")
        }
    }

    private func updateSession(_ session: TimerSession) {
        let db = DatabaseManager.shared
        let query = """
        UPDATE session_state SET last_heartbeat = datetime('now') WHERE id = '\(session.id.uuidString)'
        """
        
        if db.execute(query) {
            Logger.debug("Session updated: \(session.id)")
        } else {
            Logger.error("Failed to update session")
        }
    }

    private func deleteSession(_ session: TimerSession) {
        let db = DatabaseManager.shared
        let query = "DELETE FROM session_state WHERE id = '\(session.id.uuidString)'"
        
        if db.execute(query) {
            Logger.debug("Session deleted: \(session.id)")
        } else {
            Logger.error("Failed to delete session")
        }
    }

    private func saveTimeEntry(_ entry: TimeEntry) {
        let db = DatabaseManager.shared
        let dateStr = entry.date.ISO8601Format().split(separator: "T")[0]
        let duration = entry.duration
        
        let query = """
        INSERT INTO time_entries (id, task_id, project_id, start_time, end_time, duration, date, status, was_interrupted)
        VALUES ('\(entry.id.uuidString)', '\(entry.taskId.uuidString)', '\(entry.projectId.uuidString)', '\(entry.startTime.ISO8601Format())', '\(entry.endTime?.ISO8601Format() ?? "")', \(duration), '\(dateStr)', 'completed', 0)
        """
        
        if db.execute(query) {
            Logger.info("Time entry saved: \(TimeFormatter.formatReadable(entry.duration)) (\(entry.duration)s)")
        } else {
            Logger.error("Failed to save time entry")
        }
    }
}
