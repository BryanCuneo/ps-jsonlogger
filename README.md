# ps-jsonlogger
ps-jsonlogger is a small, dependency-free structured logging module for PowerShell that offers both compact JSON logs on-disk and human-readble console output. It supports log levels, context objects, full call stack inclusion, and more.

## Usage Instructions
### Basic usage
##### basic_logging.ps1
```PowerShell
Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./basic_logging.log" -ProgramName "Basic Logging"
$logger.Log("Hello, World!")
```

##### basic_logging.log
```json
{"timestamp":"2025-10-08T14:47:10.3774112-05:00","level":"START","programName":"Basic Logging","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0"}
{"timestamp":"2025-10-08T14:47:10.3780732-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\basic_logging.ps1: line 4"}
```

The first entry in a log file, which is created when you run `New-JsonLogger`, always contains the program name, the timestmap of when the log was initialized, the version of PowerShell you're running, and the version of ps-jsonlogger that created this particular log file.

### Closing the Log
If you wish to add a closing line to the log file, you can do so with `[JsonLogger]::Close()`:
##### close.ps1
```PowerShell
Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./close.log" -ProgramName "close.log"
$logger.Log("Hello, World!")
$logger.Close()
```

##### close.log
```JSON
{"timestamp":"2025-10-08T14:47:59.7832010-05:00","level":"START","programName":"close.log","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0"}
{"timestamp":"2025-10-08T14:47:59.7838817-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\close.ps1: line 4"}
{"timestamp":"2025-10-08T14:47:59.7939339-05:00","level":"END"}
```

You can also call `Close()` with a message string. E.g. `$logger.Close("Done!")` will result in a closing line like this instead:
```JSON
{"timestamp":"2025-10-06T11:26:11.8719322-05:00","level":"END","message":"Done!"}
```

_Note: This doesn't actually delete the $logger object or otherwise close your connection to the log file. PowerShell doesn't have any class destructors and there's no filestream object to actually close. Therefore the `Close()` function is just a way to add a final entry to the log file._

### Log Levels
The following log levels are available: `INFO`, `WARNING`, `ERROR`, `FATAL`, `DEBUG`, `VERBOSE`. Both `FATAL` and `VERBOSE` always includes the full call stack in the log entry. Additionally, `FATAL` will close the log and call `exit 1`, terminating the script. You can specify which log level you want to use like so:
##### log_levels.ps1
```PowerShell
Import-Module ps-jsonlogger -Force

$logger = New-JsonLogger -LogFilePath "./log_levels.log" -ProgramName "Log Levels"

$logger.Log("Hello, World!")
$logger.Log("INFO", "Info level test")
$logger.Log("WARNING", "Level test - warning")
$logger.Log("ERROR", "Level test - error")
$logger.Log("DEBUG", "Level test - debug")
$logger.Log("VERBOSE", "Level test - verbose")

$logger.Close("You can call Close() with an optional message like this")
$logger.Log("FATAL", "For terminating errors, FATAL logs will exit the script with 'exit 1'.")
$logger.Log("DEBUG", "This line will never be logged, because the preceeding line exited the program.")
```

##### log_levels.log
```JSON
{"timestamp":"2025-10-08T14:48:37.3494565-05:00","level":"START","programName":"Log Levels","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0","hasWarning":true,"hasError":true,"hasFatal":true}
{"timestamp":"2025-10-08T14:48:37.3500870-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 5"}
{"timestamp":"2025-10-08T14:48:37.3601950-05:00","level":"INFO","message":"Info level test","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 6"}
{"timestamp":"2025-10-08T14:48:37.3944020-05:00","level":"WARNING","message":"Level test - warning","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 7"}
{"timestamp":"2025-10-08T14:48:37.4332684-05:00","level":"ERROR","message":"Level test - error","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 8"}
{"timestamp":"2025-10-08T14:48:37.4457347-05:00","level":"DEBUG","message":"Level test - debug","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 9"}
{"timestamp":"2025-10-08T14:48:37.4550907-05:00","level":"VERBOSE","message":"Level test - verbose","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 10","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 67 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 185 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 143 at <ScriptBlock>, C:\\log_levels.ps1: line 10 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-08T14:48:37.4669481-05:00","level":"END","message":"You can call Close() with an optional message like this"}
{"timestamp":"2025-10-08T14:48:37.4773313-05:00","level":"FATAL","message":"For terminating errors, FATAL logs will exit the script with 'exit 1'.","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 13","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 67 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 185 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 143 at <ScriptBlock>, C:\\log_levels.ps1: line 13 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-08T14:48:37.5047285-05:00","level":"END"}
```

_Note: You can also pass the warning levels as lowercase text, e.g. `$logger.log("warning", "be careful")`_

When a log file contains a warning, an error, and/or a fatal entry, the initial entry will include `"hasWarning":true`, `"has:error":true`, and/or `"hasFatal":true` respectively:

##### Initial entry of log_levels.log
```JSON
{"timestamp":"2025-10-08T14:48:37.3494565-05:00","level":"START","programName":"Log Levels","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0","hasWarning":true,"hasError":true,"hasFatal":true}
```

### Writing Log Output to the Console
You can pass the `-WriteToHost` flag to `New-JsonLogger` and write out human-readable versions of the log entries to the console using the `Write-Host` cmdlet (this is in addition to the on-disk log file):

##### write_to_host.ps1
```PowerShell
Import-Module ps-jsonlogger -Force

$logger = New-JsonLogger -LogFilePath "./write_to_host.log" -ProgramName "Write to Host" -WriteToHost

$logger.Log("Hello, World!")
$logger.Log("INFO", "Info level test")
$logger.Log("WARNING", "Level test - warning")
$logger.Log("ERROR", "Level test - error")
$logger.Log("DEBUG", "Level test - debug")
$logger.Log("VERBOSE", "Level test - verbose")

$logger.Log("FATAL", "For terminating errors, FATAL logs will exit the script with 'exit 1'.")
$logger.Log("DEBUG", "This line will never be logged, because the preceeding line exited the program.")
```

##### Console Output
```
PS > ./write_to_host.ps1
[START][2025-10-08 14:54:46] Write to Host
[INF] Hello, World!
[INF] Info level test
[WRN] Level test - warning
[ERR] Level test - error
[DBG] Level test - debug
[VRB] Level test - verbose
[FTL] For terminating errors, FATAL logs will exit the script with 'exit 1'.
[END][2025-10-08 14:54:46]
PS >
```

_Note: In an actual PowerShell console, warnings will have yellow text and errors will have red text. Unfortunately GitHub`s markdown does not provide a way to color text within a code block so those colors are not displayed above._

### Overwriting Existing Log Files
Normally when you try to write to an existing file, you'll receive an error:

```PowerShell
PS > $logger = New-JsonLogger -LogFilePath "./overwrite_test.log" -ProgramName "Overwrite Test"
```
```
Exception: The file './overwrite_test.log' already exists and is not empty. Use -Overwrite to overwrite it.
```

You can pass the `-Overwrite` flag to `New-JsonLogger` to overwrite the existing file:
```PowerShell
$logger = New-JsonLogger -LogFilePath "./overwrite_test.log" -ProgramName "Overwrite Test" -Overwrite
```

### The `calledFrom` Field
The `calledFrom` field in each log entries tells you from where the `Log()` function was called. If it was called from a function, you'll see the function name, script source, and what line in that script source the call to `Log()` happened:

##### called_from_function.ps1
```PowerShell
Import-Module ps-jsonlogger

function main {
    $logger = New-JsonLogger -LogFilePath "./called_from_function.log" -ProgramName "Called From Function Test"
    $logger.Log("Check out the 'calledFrom' attribute of this log entry!")
}

main
```
##### Relevant line from called_from_function.log
```JSON
{"timestamp":"2025-10-08T14:58:23.1087301-05:00","level":"INFO","message":"Check out the 'calledFrom' attribute of this log entry!","calledFrom":"at main, C:\\called_from_function.ps1: line 5"}
```

If instead you call `Log()` outside a function, you will see the text `at <ScriptBlock>` instead of `at FunctionName`:
##### called_outside_function.ps1
```PowerShell
Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./called_outside_function.log" -ProgramName "Called Outside Function Test"
$logger.Log("Check out the 'calledFrom' attribute of this log entry!")
```
##### Relevant line from called_outside_function.log
```JSON
{"timestamp":"2025-10-08T15:00:39.9936532-05:00","level":"INFO","message":"Check out the 'calledFrom' attribute of this log entry!","calledFrom":"at <ScriptBlock>, C:\\called_outside_function.ps1: line 4"}
```

### Additional Log Entry Options
`[Logger]::Log()` provides two additional options:
 * Context Object(s)
 * Include the full call stack

You can use one of the additional options or both at the same time:
```PowerShell
# One context object
$logger.Log($level, $message, $obj)

# An array of multiple objects
$logger.Log($level, $message, @($obj1, $obj2, $obj3))

# Include the full call stack
$logger.Log($level, $message, $true)

# Do both
$logger.Log($level, $message, $obj, $true)
```

#### Context Object(s)
You can pass any PowerShell object, or an array of multiple objects, to `[JsonLogger]::Log()` to have them appear in the log entry. Here's an example:

##### context_object.ps1
```PowerShell
Import-Module ps-jsonlogger

class Ctx {
    [string]$Name
    [object]$NestedObj1
    [object]$NestedObj2

    Ctx([string]$name) {
        $this.Name = $name
        $this.NestedObj1 = [ordered]@{
            Id    = 1
            Value = "Nested object 1"
        }
        $this.NestedObj2 = [ordered]@{
            Id    = 2
            Value = "Nested object 2"
        }
    }
}

function main {
    $level = "DEBUG"
    $context = [Ctx]::new("Sample Context Object")

    $script:logger.Log($level, "Current object state", $context)
}

$script:logger = New-JsonLogger -LogFilePath "./context_object.log" -ProgramName "Context Object Test"
main
```

##### Relevant line from context_object.log
```JSON
{"timestamp":"2025-10-08T15:02:21.3247075-05:00","level":"DEBUG","message":"Current object state","context":[{"Name":"Sample Context Object","NestedObj1":{"Id":1,"Value":"Nested object 1"},"NestedObj2":{"Id":2,"Value":"Nested object 2"}}],"calledFrom":"at main, C:\\context_object.ps1: line 25"}

```

#### Include the full call stack
If you wish to include the full call stack (taken from PowerShell's `Get-PSCallStack`), you can do that like this:

##### call_stack.ps1
```PowerShell
Import-Module ps-jsonlogger

function Second-Function {
    $script:logger.Log("DEBUG", "Full call stack, second function", $true)
}

function main {
    $script:logger.Log("DEBUG", "Full call stack, first function", $true)
    Second-Function
}

$script:logger = New-JsonLogger -LogFilePath "./call_stack.log" -ProgramName "Including the full call stack."
main
```

##### call_stack.log
```JSON
{"timestamp":"2025-10-08T15:02:25.2362373-05:00","level":"START","programName":"Including the full call stack.","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0"}
{"timestamp":"2025-10-08T15:02:25.2419280-05:00","level":"DEBUG","message":"Full call stack, first function","calledFrom":"at main, C:\\call_stack.ps1: line 8","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 67 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 185 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 148 at main, C:\\call_stack.ps1: line 8 at <ScriptBlock>, C:\\call_stack.ps1: line 13 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-08T15:02:25.2516890-05:00","level":"DEBUG","message":"Full call stack, second function","calledFrom":"at Second-Function, C:\\call_stack.ps1: line 4","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 67 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 185 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 148 at Second-Function, C:\\call_stack.ps1: line 4 at main, C:\\call_stack.ps1: line 9 at <ScriptBlock>, C:\\call_stack.ps1: line 13 at <ScriptBlock>, <No file>: line 1"}

```
