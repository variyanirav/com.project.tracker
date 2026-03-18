//
//  DatabaseManager.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var database: OpaquePointer?
    private let queue = DispatchQueue(label: "com.niravvariya.ProjectTracker.database", attributes: .concurrent)
    
    private init() {
        setupDatabase()
    }
    
    // MARK: - Database Setup
    
    private func setupDatabase() {
        queue.sync(flags: .barrier) {
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dbPath = documentsPath.appendingPathComponent("projecttracker.db").path
            
            if sqlite3_open(dbPath, &database) == SQLITE_OK {
                Logger.info("Successfully opened database at \(dbPath)")
                createTables()
            } else {
                Logger.error("Failed to open database")
            }
        }
    }
    
    private func createTables() {
        let createProjectsTable = """
        CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            client_name TEXT,
            hourly_rate REAL NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        """
        
        let createTasksTable = """
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
        );
        """
        
        let createTimeEntriesTable = """
        CREATE TABLE IF NOT EXISTS time_entries (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            task_id TEXT,
            date TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            duration INTEGER DEFAULT 0,
            status TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
            FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL
        );
        """
        
        let createIndexes = [
            "CREATE INDEX IF NOT EXISTS idx_time_entries_project ON time_entries(project_id);",
            "CREATE INDEX IF NOT EXISTS idx_time_entries_date ON time_entries(date);",
            "CREATE INDEX IF NOT EXISTS idx_time_entries_task ON time_entries(task_id);",
            "CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_id);"
        ]
        
        // Already in a barrier sync from setupDatabase(), so execute directly without nested sync
        let tables = [createProjectsTable, createTasksTable, createTimeEntriesTable]
        
        for table in tables {
            executeDirect(table)
        }
        
        for index in createIndexes {
            executeDirect(index)
        }
    }
    
    // Direct execution without queue synchronization (used when already synchronized)
    private func executeDirect(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(database, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            Logger.error("Database error: \(error)")
            sqlite3_free(errorMessage)
        }
    }
    
    // MARK: - Query Methods
    
    func execute(_ sql: String) -> Bool {
        var success = false
        queue.sync(flags: .barrier) {
            var errorMessage: UnsafeMutablePointer<CChar>?
            
            if sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK {
                success = true
            } else {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                Logger.error("Database error: \(error)")
                sqlite3_free(errorMessage)
            }
        }
        return success
    }
    
    func query<T>(_ sql: String, _ handler: (OpaquePointer?) -> T) -> [T] {
        var results: [T] = []
        
        queue.sync {
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    results.append(handler(statement))
                }
                sqlite3_finalize(statement)
            } else {
                Logger.error("Failed to prepare SQL: \(sql)")
            }
        }
        
        return results
    }
    
    func singleQuery<T>(_ sql: String, _ handler: (OpaquePointer?) -> T) -> T? {
        var result: T?
        
        queue.sync {
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = handler(statement)
                }
                sqlite3_finalize(statement)
            } else {
                Logger.error("Failed to prepare SQL: \(sql)")
            }
        }
        
        return result
    }
    
    func scalar(_ sql: String) -> Int {
        var result = 0
        queue.sync {
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = Int(sqlite3_column_int(statement, 0))
                }
                sqlite3_finalize(statement)
            } else {
                Logger.error("Failed to prepare SQL: \(sql)")
            }
        }
        return result
    }
    
    // MARK: - Cleanup
    
    deinit {
        sqlite3_close(database)
    }
}
