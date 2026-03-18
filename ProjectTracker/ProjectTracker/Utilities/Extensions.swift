//
//  Extensions.swift
//  ProjectTracker
//
//  Created by NiravVariya on 17/03/26.
//

import Foundation

// MARK: - Date Extensions

extension Date {
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    var dateOnly: Date {
        Calendar.current.startOfDay(for: self)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }

    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    func parseISO8601() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}

// MARK: - TimeFormatter

struct TimeFormatter {
    static func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    static func formatReadable(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static func formatForCSV(_ seconds: Int) -> String {
        let hours = Double(seconds) / 3600.0
        return String(format: "%.2f", hours)
    }
}

// MARK: - Constants

struct AppConstants {
    static let databaseName = "projecttracker.db"
    static let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
        .appendingPathComponent("ProjectTracker")

    static let timerDisplayInterval: TimeInterval = 1.0
    static let timerHeartbeatInterval: TimeInterval = 5.0
    static let heartbeatTimeout: TimeInterval = 30.0

    struct ValidationRules {
        static let minProjectNameLength = 1
        static let maxProjectNameLength = 255
        static let minTaskNameLength = 1
        static let maxTaskNameLength = 255
    }
}

// MARK: - FileManager Extensions

extension FileManager {
    func ensureAppSupportDirectory() throws -> URL {
        guard let appSupportDir = AppConstants.appSupportDirectory else {
            throw NSError(domain: "FileManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to get app support directory"])
        }

        if !fileExists(atPath: appSupportDir.path) {
            try createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        }

        return appSupportDir
    }

    func databaseFileExists() -> Bool {
        guard let appSupportDir = AppConstants.appSupportDirectory else { return false }
        return fileExists(atPath: appSupportDir.appendingPathComponent(AppConstants.databaseName).path)
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    func dateIntervalOfWeek(for date: Date) -> DateInterval? {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let startOfWeek = self.date(from: components) else { return nil }
        
        guard let endOfWeek = self.date(byAdding: .day, value: 6, to: startOfWeek) else { return nil }
        
        return DateInterval(start: startOfWeek, end: endOfWeek)
    }
}
