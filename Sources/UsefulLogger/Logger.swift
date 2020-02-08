// Logger.swift
//
// Copyright (c) 2020 Burak Uzunboy
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import iOSCoreUsefulSDK

/// Useful Logger class with advanced logging features.
public class Logger: LoggingDelegate {
    
    // MARK: - Public Properties
    
    /// Name of the log file which will be stored in the device storage.
    public class var fileName: String {
        get { return Logger.shared.logFileName }
        set { Logger.shared.logFileName = newValue }
    }
    
    /// Minimum level to write logs into file.
    public static var minimumLogLevel: LogLevel = .info
    
    /// Set listener to get logs received to this service.
    public class var delegate: LoggingDelegate? {
        get { return Logger.shared.logDelegate }
        set { return Logger.shared.logDelegate = newValue }
    }
    
    /// Starts listening logs from `LoggingManager`.
    ///
    /// Do not change `delegate` property of `LoggingManager` in order to interrupt this service.
    /// To listen logs received to this service, set `delegate` property of this class.
    ///
    /// Otherwise, call this method again to give service a chance to listen again the logs.
    public class func startListening() {
        LoggingManager.delegate = Logger.shared
    }
    
    // MARK: - Private
    
    /// File handler.
    private var handler: FileHandle?
    
    /// Instance file name member.
    private var logFileName: String = "DeviceLogs" {
        didSet {
            self.deleteLogFile(oldValue)
            self.initLogFile()
        }}
    
    /// Private shared instance.
    private static let shared = Logger()
    
    private weak var logDelegate: LoggingDelegate?
    
    /// Private initializer.
    private init() {
        initLogFile()
    }
    
    /// Initializes log file.
    private func initLogFile() {
        let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fullDestPath = NSURL(fileURLWithPath: destPath).appendingPathComponent("\(self.logFileName).log")
        let fullDestPathString = fullDestPath!.path
        if !FileManager.default.fileExists(atPath: fullDestPathString) {
            do {
                try "".write(toFile: fullDestPathString, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                NSLog("Can't write to file to device directory - Error: \(error.localizedDescription)")
            }
        }
        handler = FileHandle.init(forUpdatingAtPath: fullDestPathString)
    }
    
    /// Writes given log into log file.
    private func writeLogToFile(source: String,
                                level: Character,
                                domain: String,
                                queue: String,
                                message: String) {
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let logStr = String(format: "[\(dateStr)] \(level) >> \(source): \(message) [QUEUE: \(queue)] \n")
        handler?.seekToEndOfFile()
        if let logData = logStr.data(using: String.Encoding.utf8) {
            handler?.write(logData)
        }
//
//        var willLogged = String(format: format, args)
//        let maxCount = 1000
//        let div:Int = willLogged.count/maxCount
//        if div > 0 {
//            for i in 0..<div {
//                var newStr = willLogged
//                newStr.removeLast(willLogged.count-((div-i)*maxCount))
//
//                if i > 0 {
//                    newStr = "... Continues - \(newStr)"
//                }
//
//                NSLog(newStr)
//                willLogged.removeFirst(maxCount)
//            }
//
//            willLogged = "... Continues - \(willLogged) - END"
//            NSLog(willLogged)
//        } else {
//            NSLog(willLogged)
//        }
    }
    
    /// Deletes log file with the given name.
    /// - parameter fileName: Name of the log file.
    private func deleteLogFile(_ fileName: String) {
        let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fullDestPath = NSURL(fileURLWithPath: destPath).appendingPathComponent("\(fileName).log")
        let fullDestPathString = fullDestPath!.path
        if !FileManager.default.fileExists(atPath: fullDestPathString) {
            do {
                try FileManager.default.removeItem(atPath: fullDestPathString)
            } catch {
                NSLog("Couldn't delete log file: \(fileName).log - Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Log Delegate
    public func log(message: String, level: LogLevel, domain: LogDomain, source: String) {
        var minimumLevel = 0
        switch Logger.minimumLogLevel {
        case .verbose:
            minimumLevel = 0
        case .info:
            minimumLevel = 1
        case .warning:
            minimumLevel = 2
        case .error:
            minimumLevel = 3
        }
        var givenLogLevel = 0
        switch level {
        case .verbose:
            givenLogLevel = 1
        case .info:
            givenLogLevel = 2
        case .warning:
            givenLogLevel = 3
        case .error:
            givenLogLevel = 4
        }
        
        if givenLogLevel >= minimumLevel {
            let queueName = OperationQueue.current?.name ?? "Unknown"
            var domainName = ""
            switch domain {
            case .app:
                domainName = "App"
            case .cache:
                domainName = "Cache"
            case .controller:
                domainName = "Controller"
            case .db:
                domainName = "Database"
            case .io:
                domainName = "IO"
            case .layout:
                domainName = "Layout"
            case .model:
                domainName = "Model"
            case .network:
                domainName = "Network"
            case .routing:
                domainName = "Routing"
            case .service:
                domainName = "Service"
            case .view:
                domainName = "View"
            }
            Logger.shared.writeLogToFile(source: source,
                                         level: level.rawValue.uppercased().first!,
                                         domain: domainName,
                                         queue: queueName,
                                         message: message)
            Logger.shared.logDelegate?.log(message: message, level: level, domain: domain, source: source)
        }
    }
    
}
