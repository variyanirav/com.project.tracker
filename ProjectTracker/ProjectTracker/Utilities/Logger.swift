//
//  Logger.swift
//  ProjectTracker
//
//  Created by NiravVariya on 18/03/26.
//

import Foundation
import os.log

class Logger {
    static let subsystem = "com.niravvariya.ProjectTracker"
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    private static let osLog = OSLog(subsystem: subsystem, category: "general")
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    private static func log(
        level: LogLevel,
        message: String,
        file: String,
        function: String,
        line: Int
    ) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(filename):\(line)] \(function) - \(message)"
        
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }
        
        os_log("%{public}@", log: osLog, type: osLogType, logMessage)
        
        // Also print to console in debug builds
        #if DEBUG
        print(logMessage)
        #endif
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
