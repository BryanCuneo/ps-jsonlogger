# ps-jsonlogger
ps-jsonlogger is a small, dependency-free JSON logger designed to be easily embedded in automation scripts. It supports several log levels, context objects, full call stack inclusion, and writes compact, structured JSON entries to disk.

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
{"timestamp":"2025-10-06T10:29:26.5768736-05:00","level":"START","programName":"Basic Logging","PSVersion":"7.5.3","jsonLoggerVersion":"0.0.2"}
{"timestamp":"2025-10-06T10:29:26.5873021-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\basic_logging.ps1: line 4"}
```

The first entry in a log file, which is created when you run `New-JsonLogger`, always contains the program name, the timestmap of when the log was initialized, the version of PowerShell you're running, and the version of ps-jsonlogger that created this particular log file.

### Closing the Log
If you wish to add a closing line to the log file, you can do so with `[JsonLogger]::Close()`:
```PowerShell
Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./close.log" -ProgramName "close.log"
$logger.Log("Hello, World!")
$logger.Close()
```

##### close.log
```JSON
{"timestamp":"2025-10-06T11:26:11.8569805-05:00","level":"START","programName":"close.log","PSVersion":"7.5.3","jsonLoggerVersion":"0.0.2"}
{"timestamp":"2025-10-06T11:26:11.8578787-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\close.ps1: line 4"}
{"timestamp":"2025-10-06T11:26:11.8719322-05:00","level":"END"}
```

You can also call `Close()` with a message string. E.g. `$logger.Close("Done!")` will result in a closing line like this instead:
```JSON
{"timestamp":"2025-10-06T11:26:11.8719322-05:00","level":"END","message":"Done!"}
```

_Note: This doesn't actually delete the $logger object or otherwise close your connection to the log file. PowerShell doesn't have any class destructors and there's no filestream object to actually close. Therefore the `Close()` function is just a way to add a final entry to the log file._

### Log Levels
The following log levels are available: `INFO`, `WARNING`, `ERROR`, `FATAL`, `DEBUG`, `VERBOSE`. Both `FATAL` and `VERBOSE` always includes the full call stack in the log entry. In addition, `FATAL` will close the log and call `exit 1`, terminating the script.

You can specify which log level you want to use like so:
##### log_levels.ps1
```PowerShell
Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./log_levels.log" -ProgramName "Log Levels"
$logger.Log("Hello, World!")
$logger.Log("INFO", "Info level test")
$logger.Log("WARNING", "Level test - warning")
$logger.Log("ERROR", "Level test - error")
$logger.Log("DEBUG", "Level test - debug")
$logger.Log("VERBOSE", "Level test - verbose")

$logger.Close()
```

##### log_levels.log
```JSON
{"timestamp":"2025-10-06T11:18:40.9320762-05:00","level":"START","programName":"Log Levels","PSVersion":"7.5.3","jsonLoggerVersion":"0.0.2"}
{"timestamp":"2025-10-06T11:18:40.9328826-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 4"}
{"timestamp":"2025-10-06T11:18:40.9446534-05:00","level":"INFO","message":"Info level test","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 5"}
{"timestamp":"2025-10-06T11:18:40.9620318-05:00","level":"WARNING","message":"Level test - warning","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 6"}
{"timestamp":"2025-10-06T11:18:40.9830093-05:00","level":"ERROR","message":"Level test - error","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 7"}
{"timestamp":"2025-10-06T11:18:40.9989381-05:00","level":"DEBUG","message":"Level test - debug","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 8"}
{"timestamp":"2025-10-06T11:18:41.0128001-05:00","level":"VERBOSE","message":"Level test - verbose","calledFrom":"at <ScriptBlock>, C:\\log_levels.ps1: line 9","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 57 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 156 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 123 at <ScriptBlock>, C:\\log_levels.ps1: line 9 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-06T11:18:41.0267790-05:00","level":"END"}
```

### Writing Log Output to the Console
You can pass the `-WriteToHost` flag to `New-JsonLogger` and write out human-readable versions of the log entries to the console using the `Write-Host` cmdlet (this is in addition to the on-disk log file). Adding that to the above `log_levels.ps1` will look like this:

##### log_levels.ps1
```PowerShell
Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./log_levels.log" -ProgramName "Log Levels" -WriteToHost
$logger.Log("Hello, World!")
$logger.Log("INFO", "Info level test")
$logger.Log("WARNING", "Level test - warning")
$logger.Log("ERROR", "Level test - error")
$logger.Log("DEBUG", "Level test - debug")
$logger.Log("VERBOSE", "Level test - verbose")

$logger.Close()
```

##### Console Output
```
PS > ./log_levels.ps1
[START][2025-10-06 11:18:40]Log Levels
[INFO]Hello, World!
[INFO]Info level test
[WARNING]Level test - warning
[ERROR]Level test - error
[DEBUG]Level test - debug
[VERBOSE]Level test - verbose
[END][2025-10-06 11:18:41]
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

function Main {
    $logger = New-JsonLogger -LogFilePath "./called_from_function.log" -ProgramName "Called From Function Test"
    $logger.Log("Check out the 'calledFrom' attribute of this log entry!")
}

Main
```
##### Relevant line from called_from_function.log
```JSON
{"timestamp":"2025-10-06T13:15:03.0548222-05:00","level":"INFO","message":"Check out the 'calledFrom' attribute of this log entry!","calledFrom":"at Main, C:\\called_from_function.ps1: line 5"}
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
{"timestamp":"2025-10-06T13:16:44.9848207-05:00","level":"INFO","message":"Check out the 'calledFrom' attribute of this log entry!","calledFrom":"at <ScriptBlock>, C:\\called_outside_function.ps1: line 4"}
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

function Main {
    $level = "DEBUG"
    $context = [Ctx]::new("Sample Context Object")

    $global:logger.Log($level, "Current object state", $context)
}

$global:logger = New-JsonLogger -LogFilePath "./context_object.log" -ProgramName "Context Object Test"
Main
```

##### context_object.log
```JSON
{"timestamp":"2025-10-06T13:27:27.9372329-05:00","level":"START","programName":"Context Object Test","PSVersion":"7.5.3","jsonLoggerVersion":"0.0.2"}
{"timestamp":"2025-10-06T13:27:27.9428886-05:00","level":"DEBUG","message":"Current object state","context":[{"Name":"Sample Context Object","NestedObj1":{"Id":1,"Value":"Nested object 1"},"NestedObj2":{"Id":2,"Value":"Nested object 2"}}],"calledFrom":"at Main, C:\\context_object.ps1: line 25"}
```

#### Include the full call stack
If you wish to include the full call stack (taken from PowerShell's `Get-PSCallStack`), you can do that like this:

##### call_stack.ps1
```PowerShell
Import-Module ps-jsonlogger

function Second-Function {
    $global:logger.Log("DEBUG", "Full call stack, second function", $true)
}

function Main {
    $global:logger.Log("DEBUG", "Full call stack, first function", $true)
    Second-Function
}

$global:logger = New-JsonLogger -LogFilePath "./call_stack.log" -ProgramName "Including the full call stack."
Main
```

##### call_stack.log
```JSON
{"timestamp":"2025-10-06T13:32:14.1891135-05:00","level":"START","programName":"Including the full call stack.","PSVersion":"7.5.3","jsonLoggerVersion":"0.0.2"}
{"timestamp":"2025-10-06T13:32:14.1898008-05:00","level":"DEBUG","message":"Full call stack, first function","calledFrom":"at Main, C:\\call_stack.ps1: line 8","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 57 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 156 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 128 at Main, C:\\call_stack.ps1: line 8 at <ScriptBlock>, C:\\call_stack.ps1: line 13 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-06T13:32:14.2137141-05:00","level":"DEBUG","message":"Full call stack, second function","calledFrom":"at Second-Function, C:\\call_stack.ps1: line 4","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 57 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 156 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.2\\ps-jsonlogger.psm1: line 128 at Second-Function, C:\\call_stack.ps1: line 4 at Main, C:\\call_stack.ps1: line 9 at <ScriptBlock>, C:\\call_stack.ps1: line 13 at <ScriptBlock>, <No file>: line 1"}
```
