# AdvancedLogger - UsefulLogger

Currently development in progress.

### A most useful logger service written for iOS Projects.

Check out the `docs/index.html` file to explore all useful methods.

## Installation

**AdvancedLogger** uses new Swift Package Manager which is easiest way introduced for iOS projects since from the beginning. 

From Xcode simply select `File > Swift Packages > Add Package Dependency...` and paste `https://github.com/exozet/iOSUsefulLogger` to search field. You can specify rules according to your preferences and you are ready to use. 

## Usage

**AdvancedLogger** is built on top of `CoreUsefulSDK` which manages logs throughout the application, basically saves logs into the device storage in order to retrieve back, in addition with some extra cool features.

### Basic Usage

#### Starting the service

First, set `delegate` class to `AdvancedLogger`. In order to start service, then call `startListening:`. 

> Do not override `delegate` of `LoggingManager`, otherwise it'll cause logs not delivered to the service.

```swift
AdvancedLogger.delegate = self
AdvancedLogger.startListening()
```

#### Setting minimum log level

In default minimum log level for the service is set to `info`. It can be changed as in below, the logs which have lower levels will be ignored.

```swift
AdvancedLogger.minimumLogLevel = .verbose
```

#### Printing logs

Logs will be still delivered methods of `LoggingManager` from `CoreUsefulSDK`.

```swift
LoggingManager.verbose(message: "This is example verbose log", domain: .service)
LoggingManager.info(message: "This is example info log", domain: .service)
LoggingManager.warning(message: "This is example warning log", domain: .service)
LoggingManager.error(message: "This is example error log", domain: .service)
```

#### Reading logs

The class which is expected to listen logs should conform `LoggingDelegate`. All logs has bigger or equal to `minimumLogLevel`, will be delivered through. Example class code is given below.

```swift
class LogListener: LoggingDelegate {

    init() {
        AdvancedLogger.delegate = self
        AdvancedLogger.minimumLogLevel = .verbose
        AdvancedLogger.startListening()
    }
    
    public func log(message: String, level: LogLevel, domain: LogDomain, source: String) {
        let logMessage = "[\(source)]: \(level.rawValue) >> \(message)"
        os_log(level.osLogType, "%{public}@", logMessage)
    }

}
```

### Crash Logger

**AdvancedLogger** has capability to also write exceptions and signal crashes into the log file, also retrive previous crash in the next start of the application. 

Call the given method in the `application:didFinishLaunchingWithOptions:` in `AppDelegate`. This will cause `CrashLogger` to start and return crash report if application is crashed on last previous opening. Here, it could be useful to show an alert to user to encourage sending device logs to you.

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let crashLog = AdvancedLogger.CrashLogger.application(application, didFinishLaunchingWithOptions: launchOptions) {
            LoggingManager.error("Application is crashed in previous run - \(crashLog)", domain: .app)
        }
        return true
    }
    
}
```

### Handling log file

In default, logs are written into **DeviceLogs.log** file, which is saved under the `AppData/Documents` directory in the app container. The file name can be changed, retrieved programmatically or user can see in the email dialogue as attachment.

#### Changing log file name

Log file name can be changed easily as shown in below. Don't need to worry for setting file name everytime, unless file name is different, logs will stay in the storage. Otherwise, old logs will be removed from the device storage.

```swift
AdvancedLogger.fileName = "MyCoolLogs"
```

#### Showing E-mail dialogue

**AdvancedLogger** can create email dialogue with the log file as attached in below. You can add `to` recipients and more context before showing email dialogue to user. 

```swift
let emailDialogue = AdvancedLogger.createMailViewController()
emailDialogue.setToRecipients(["myaddress@company.com"])
emailDialogue.setSubject("Logs I received")
self.present(emailDialogue, animated: true, completion: nil)
```

#### Getting Log content programmatically

The logs in the device storage can be retrieved programmatically as in below in `String` format.

```swift
let myLogs = AdvancedLogger.getLogContent() ?? "No Logs found"
print(myLogs)
```

#### Clearing Logs

If application consumes too much storage, or for some reason log file needs to be cleared, call the given function in below to clear logs in the device storage.

```swift
AdvancedLogger.clearLogs()
```
