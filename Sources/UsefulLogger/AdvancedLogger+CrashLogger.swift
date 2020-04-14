// AdvancedLogger+CrashLogger.swift
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


import UIKit

public extension AdvancedLogger {
    
    /// Holds basic structure for the crash logs.
    struct CrashLog {
        
        /// Name of the crash.
        var name: String
        /// Reason for the crash.
        var reason: String
        /// Callstack of the crash.
        var callStack: [String]
        
        fileprivate init(name: String, reason: String, callStack: [String]) {
            self.name = name
            self.reason = reason
            self.callStack = callStack
        }
        
        fileprivate init?(dict: [String:Any]) {
            guard let name = dict["name"] as? String,
                let reason = dict["reason"] as? String,
                let callStack = dict["callStack"] as? [String] else { return nil }
            
            self.name = name
            self.reason = reason
            self.callStack = callStack
        }
        
        fileprivate var dictionary: [String:Any] {
            return ["name": self.name,
                    "reason": self.reason,
                    "callStack": callStack]
        }
    }
    
    /// Advanced Crash Logger to listen crash logs from the application and act.
    class CrashLogger {
        
        /// Starts `CrashLogger` to listen, and returns old log if there is any.
        /// - returns: Old crash log if it is present.
        @discardableResult
        public class func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> CrashLog? {
            CrashLogger.start()
            return CrashLogger.checkCrashLogs()
        }
        
        /// Starts Crash Logger to listen crash logs.
        ///
        /// If `application:didFinishLaunchingWithOptions:` is called already, it's not needed to call that method too.
        public class func start() {
            guard !CrashLogger.isStarted else { return }
            
            CrashLogger.appExceptionHandler = NSGetUncaughtExceptionHandler()
            NSSetUncaughtExceptionHandler(CrashLogger.ExceptionReceiver)
            CrashLogger.addSignals()
            CrashLogger.isStarted = true
        }
        
        /// Saves crash logs into the log file if it's `true`.
        ///
        /// Default value is `true`.
        public static var saveToLogFile = true
                
        /// Holds state of the `CrashLogger`.
        private static var isStarted = false
        
        /// Keeps App's old exception handler.
        private static var appExceptionHandler: (@convention(c) (NSException) -> Swift.Void)? = nil
        
        fileprivate static let kUserDefault = "AdvancedLogger.CrashLog.UserDefaults"
        
        private class func saveCrashLog(_ log: CrashLog) {
            if UserDefaults.standard.value(forKey: CrashLogger.kUserDefault) != nil {
                UserDefaults.standard.removeObject(forKey: CrashLogger.kUserDefault)
            }
            
            UserDefaults.standard.set(log.dictionary, forKey: CrashLogger.kUserDefault)
        }
        
        private static func checkCrashLogs() -> CrashLog? {
            defer {
                UserDefaults.standard.removeObject(forKey: CrashLogger.kUserDefault)
            }
            
            guard let dict = UserDefaults.standard.value(forKey: CrashLogger.kUserDefault) as? [String:Any],
                let crashLog = CrashLog(dict: dict) else { return nil }
            
            return crashLog
        }
        
        private class func addSignals() {
            signal(SIGABRT, CrashLogger.SignalReceiver)
            signal(SIGILL, CrashLogger.SignalReceiver)
            signal(SIGSEGV, CrashLogger.SignalReceiver)
            signal(SIGFPE, CrashLogger.SignalReceiver)
            signal(SIGBUS, CrashLogger.SignalReceiver)
            signal(SIGPIPE, CrashLogger.SignalReceiver)
            signal(SIGTRAP, CrashLogger.SignalReceiver)
        }
        
        private static let ExceptionReceiver: @convention(c) (NSException) -> Swift.Void = {
            (exception) -> Void in
            if let appExceptionHandler = CrashLogger.appExceptionHandler {
                appExceptionHandler(exception)
            }
            
            guard CrashLogger.isStarted else {
                return
            }
            
            let log = AdvancedLogger.CrashLog(name: exception.name.rawValue,
                                              reason: exception.reason ?? "",
                                              callStack: exception.callStackSymbols)
            
            let queueName = OperationQueue.current?.name ?? "Unknown"
            let msg = "\(log.name) - Reason: \(exception.reason ?? "Unknown reason")"
            let source = "AL.CrashLog.Exception"
            
            if CrashLogger.saveToLogFile {
                AdvancedLogger.shared.writeLogToFile(source: source,
                                                     level: "CRASH!",
                                                     domain: "Logger",
                                                     queue: queueName,
                                                     message: "\(msg) \n STACK: \n \(exception.callStackSymbols.joined(separator: " \n"))")
            }
            AdvancedLogger.shared.logDelegate?.log(message: "CRASH!! - \(msg)", level: .error,
                                                   domain: .app, source: source)
            
            CrashLogger.saveCrashLog(log)
        }
        
        private static let SignalReceiver : @convention(c) (Int32) -> Void = {
            (signal) -> Void in
            
            guard CrashLogger.isStarted else {
                return
            }
            
            var stack = Thread.callStackSymbols
            stack.removeFirst(2)
            let reason = "Signal \(CrashLogger.name(of: signal))(\(signal)) was raised.\n"
            
            let log = AdvancedLogger.CrashLog(name: CrashLogger.name(of: signal),
                                              reason: reason,
                                              callStack: stack)
            
            let queueName = OperationQueue.current?.name ?? "Unknown"
            let msg = "\(log.name) - Reason: \(reason)"
            let source = "AL.CrashLog.Signal"
            
            if CrashLogger.saveToLogFile {
                AdvancedLogger.shared.writeLogToFile(source: source,
                                                     level: "CRASH!",
                                                     domain: "Logger",
                                                     queue: queueName,
                                                     message: "\(msg) \n STACK: \n \(stack.joined(separator: " \n"))")
            }
            AdvancedLogger.shared.logDelegate?.log(message: "CRASH!! - \(msg)", level: .error,
                                                   domain: .app, source: source)
            
            CrashLogger.saveCrashLog(log)
            CrashLogger.terminateApp()
        }
        
        private class func terminateApp() {
            NSSetUncaughtExceptionHandler(nil)
            
            signal(SIGABRT, SIG_DFL)
            signal(SIGILL, SIG_DFL)
            signal(SIGSEGV, SIG_DFL)
            signal(SIGFPE, SIG_DFL)
            signal(SIGBUS, SIG_DFL)
            signal(SIGPIPE, SIG_DFL)
            
            kill(getpid(), SIGKILL)
        }
        
        private class func name(of signal:Int32) -> String {
            switch (signal) {
            case SIGABRT:
                return "SIGABRT"
            case SIGILL:
                return "SIGILL"
            case SIGSEGV:
                return "SIGSEGV"
            case SIGFPE:
                return "SIGFPE"
            case SIGBUS:
                return "SIGBUS"
            case SIGPIPE:
                return "SIGPIPE"
            default:
                return "OTHER"
            }
        }
    }
}
