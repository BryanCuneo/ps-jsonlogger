# ps-jsonlogger
ps-jsonlogger is a small, dependency-free structured logging module for PowerShell that offers both compact JSON logs on-disk and human-readble console output. It supports log levels, context objects, full call stack inclusion, and more. I designed this module with my current corporate environment in mind:

- **No additional dependencies** - All 3rd party libraries need to go through a security review, which can take a while. To reduce the time required for review this module exclusively uses the PS standard library and is itself quite small.

- **No modifications to existing PS constructs** -  We have a lot of existing scripts that we want to integrate this logging with, not just utilize it for new development. To avoid steppng on toes in existing code, this library doesn't repurpose or modify the behaviour any existing cmdlets/functions (e.g. `Write-Warning`, `Write-Verbose`, etc.).

- **Windows Powershell v5.1 backwards compatibility** - Of those existing scripts, some require PSv5 so backwards compatibility is a must.

- **File output and human-readable console output** - File output for production use and console output for development.

- **Simple output format** - To make it easy and fast to write parsers/visualizrs for these logs, a simple output format is prioritized.

If these features match your needs, ps-jsonlogger is for you! You can get started by checking out the [usage instructions](#usage-instructions---table-of-contents) below.


## Usage Instructions - Table of Contents

- [Installation](#installation)

- [Basic Usage](#basic-usage)

- [Closing Logs](#closing-logs)

- [Log Levels](#log-levels)

- [Writing Log Output to the Console](#writing-log-output-to-the-console)

- [Overwriting Existing Log Files](#overwriting-existing-log-files)

- [The `calledFrom` Field](#the-calledfrom-field)

- [Additional Log Entry Options](#additional-log-entry-options)

- [Creating Multiple Loggers](#creating-multiple-loggers)

- [Notes on PowerShell Core 7 vs Windows PowerShell 5.1](#notes-on-powershell-core-7-vs-windows-powershell-51)

## Installation
ps-jsonlogger will be avialable from the PowerShell Gallery as soon as the [PSGallery login issues](https://github.com/PowerShell/PowerShellGallery/issues/330) are resolved. In the meantime, you can download it directly from the [releases page](https://github.com/BryanCuneo/ps-jsonlogger/releases).

[Back to the table of contents](#usage-instructions---table-of-contents)
## Basic Usage
#### basic_logging.ps1
```PowerShell
Import-Module ps-jsonlogger

New-Logger -Path "./basic_logging.log" -ProgramName "Basic Logging Example"
Write-Log "Hello, World!"
```

#### basic_logging.log
```json
{"timestamp":"2025-10-12T21:10:25.6091212-05:00","level":"START","programName":"Basic Logging Example","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0"}
{"timestamp":"2025-10-12T21:10:25.6163049-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\basic_logging.ps1: line 4"}
```

The first entry in a log file, which is created when you run `New-Logger`, always contains the program name, the timestmap of when the log was initialized, your PowerShell version and your ps-jsonlogger version.

[Back to the table of contents](#usage-instructions---table-of-contents)
## Closing Logs
It is recommended that you call `Close-Log` at the end of your script so that a final entry is written to the log file. This will also remove it from the pool of loggers and it can no longer be written to.
#### close.ps1
```PowerShell
Import-Module ps-jsonlogger

New-Logger -Path "./close.log" -ProgramName "Close-Log Example"
Write-Log "Hello, World!"
Close-Log
```

#### close.log
```JSON
{"timestamp":"2025-10-12T21:14:02.3854661-05:00","level":"START","programName":"Close-Log Example","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0"}
{"timestamp":"2025-10-12T21:14:02.3860781-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\close.ps1: line 4"}
{"timestamp":"2025-10-12T21:14:02.3998504-05:00","level":"END"}
```

You can also call `Close-Log` with a message string. E.g. `Close-Log "Done!"` will result in a closing line like this instead:
```JSON
{"timestamp":"2025-10-12T21:16:20.8704909-05:00","level":"END","message":"Goodbye, Cruel World!"}
```

If you have multiple loggers open, you can close all of them at once by calling `Close-Log -All`.

[Back to the table of contents](#usage-instructions---table-of-contents)
## Log Levels
The following log levels are available: `INFO`, `WARNING`, `ERROR`, `FATAL`, `DEBUG`, `VERBOSE`. Both `FATAL` and `VERBOSE` always includes the full call stack in the log entry. Additionally, `FATAL` will close the log and call `exit 1`, terminating the script. You can specify which log level you want to use like so:
#### log_levels_part_1.ps1
```PowerShell
Import-Module ps-jsonlogger

New-Logger -Path "./log_levels.log" -ProgramName "Log Levels Example 1" -Overwrite

Write-Log -Level "INFO" "Info level test"
Write-Log -Level "WARNING" "Level test - warning"
Write-Log -Level "ERROR" "Level test - error"
Write-Log -Level "DEBUG" "Level test - debug"
Write-Log -Level "VERBOSE" "Level test - verbose"

Write-Log -Level "FATAL" "For terminating errors, FATAL-level logs will exit the script with 'exit 1'."
Write-Log -Level "DEBUG" "This line will never be logged because the preceeding line exited the program."
```

#### log_levels_part_1.log
```JSON
{"timestamp":"2025-10-12T21:35:29.4843863-05:00","level":"START","programName":"Log Levels Example 1","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0","hasWarning":true,"hasError":true,"hasFatal":true}
{"timestamp":"2025-10-12T21:35:29.4856272-05:00","level":"INFO","message":"Info level test","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 5"}
{"timestamp":"2025-10-12T21:35:29.4988232-05:00","level":"WARNING","message":"Level test - warning","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 6"}
{"timestamp":"2025-10-12T21:35:29.5336026-05:00","level":"ERROR","message":"Level test - error","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 7"}
{"timestamp":"2025-10-12T21:35:29.5566512-05:00","level":"DEBUG","message":"Level test - debug","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 8"}
{"timestamp":"2025-10-12T21:35:29.5664182-05:00","level":"VERBOSE","message":"Level test - verbose","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 9","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 193 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 116 at Write-Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 329 at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 9 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-12T21:35:29.5772189-05:00","level":"FATAL","message":"For terminating errors, FATAL-level logs will exit the script with 'exit 1'.","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 11","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 193 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 116 at Write-Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 329 at <ScriptBlock>, C:\\log_levels_part_1.ps1: line 11 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-12T21:35:29.6073653-05:00","level":"END"}
```

There are a couple ways to specify the log level, all are case-insensitive, and they are functionally equivalent, so you can use whichever you prefer:
* The `-Level` parameter (e.g. `-Level "ERROR"` or `-Level "E"`)
* Per-level parameters (e.g. `-Err`, `-E`)
* If no level is set, the default is `INFO`

_Note: All per-level parameters are shortened versions of the full level names. This is because Error, Verbose, and Debug are all reserved words of one kind or another in PowerShell. The full list is `-Inf`, `-Wrn`, `-Err`, `-Dbg`, `-Vrb`, and `-Ftl`._

#### log_levels_part_2.ps1
```PowerShell
Import-Module ps-jsonlogger

New-Logger -Path "./log_levels_part_2.log" -ProgramName "Log Levels Example 2"

Write-Log "If you don't specify a level, INFO is the default"
Write-Log -Level "W" "All levels can be shortened to their first letter"
Write-Log -Level "error" "Level arguments are case-insensitive"
Write-Log -Dbg "Instead of -Level, you can use the per-level parameters"
Write-Log -V "If you want to be REALLY consice, you can also shorten the per-level parameters"

Close-Log
```

#### log_levels_part_2.log
```JSON
{"timestamp":"2025-10-12T21:51:34.9483648-05:00","level":"START","programName":"Log Levels Example 2","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0","hasWarning":true,"hasError":true}
{"timestamp":"2025-10-12T21:51:34.9493238-05:00","level":"INFO","message":"If you don't specify a level, INFO is the default","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_2.ps1: line 5"}
{"timestamp":"2025-10-12T21:51:34.9585447-05:00","level":"WARNING","message":"All levels can be shortened to their first letter","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_2.ps1: line 6"}
{"timestamp":"2025-10-12T21:51:34.9898127-05:00","level":"ERROR","message":"Level arguments are case-insensitive","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_2.ps1: line 7"}
{"timestamp":"2025-10-12T21:51:35.0202367-05:00","level":"DEBUG","message":"Instead of -Level, you can use the per-level parameters","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_2.ps1: line 8"}
{"timestamp":"2025-10-12T21:51:35.0349826-05:00","level":"VERBOSE","message":"If you want to be REALLY consice, you can also shorten the per-level parameters","calledFrom":"at <ScriptBlock>, C:\\log_levels_part_2.ps1: line 9","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 193 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 116 at Write-Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 329 at <ScriptBlock>, C:\\log_levels_part_2.ps1: line 9 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-12T21:51:35.0459026-05:00","level":"END"}
```

When a log file contains a warning, an error, and/or a fatal entry, the initial entry will be updated to include `"hasWarning":true`, `"has:error":true`, and/or `"hasFatal":true` respectively:

#### Initial entry of log_levels_part_1.log
```JSON
{"timestamp":"2025-10-12T21:35:29.4843863-05:00","level":"START","programName":"Log Levels Example 1","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0","hasWarning":true,"hasError":true,"hasFatal":true}
```

[Back to the table of contents](#usage-instructions---table-of-contents)
## Writing Log Output to the Console
You can pass the `-WriteToHost` flag to `New-Logger` and write out human-readable versions of the log entries to the console using the `Write-Host` cmdlet (this is in addition to the on-disk log file):

#### write_to_host.ps1
```PowerShell
Import-Module ps-jsonlogger

New-Logger -Path "./write_to_host.log" -ProgramName "Write to Host Example" -WriteToHost

Write-Log -Level "INFO" "Info level test"
Write-Log -Level "WARNING" "Level test - warning"
Write-Log -Level "ERROR" "Level test - error"
Write-Log -Level "DEBUG" "Level test - debug"
Write-Log -Level "VERBOSE" "Level test - verbose"

Write-Log -Level "FATAL" "For terminating errors, FATAL-level logs will exit the script with 'exit 1'."
Write-Log -Level "DEBUG" "This line will never be logged because the preceeding line exited the program."
```

#### Console Output
```
PS > ./write_to_host.ps1
[START][2025-10-12 21:57:46] Write to Host Example
[INF] Info level test
[WRN] Level test - warning
[ERR] Level test - error
[DBG] Level test - debug
[VRB] Level test - verbose
[FTL] For terminating errors, FATAL-level logs will exit the script with 'exit 1'.
[END][2025-10-12 21:57:46]
PS >
```

_Note: In an actual PowerShell console, warnings will have yellow text and errors and fatal errors will have red text. Due to a limitation of GitHub`s markdown, those colors are not displayed above._

[Back to the table of contents](#usage-instructions---table-of-contents)
## Overwriting Existing Log Files
Normally when you try to write to an existing file, you'll receive an error:

```PowerShell
PS > New-Logger -Path "./overwrite_test.log" -ProgramName "Overwrite Example"
```
```
Exception: The file './overwrite_test.log' already exists and is not empty. Use -Overwrite to overwrite it.
```

You can pass the `-Overwrite` flag to `New-Logger` to overwrite the existing file:
```PowerShell
PS > New-Logger -Path "./overwrite_test.log" -ProgramName "Overwrite Example" -Overwrite
```

[Back to the table of contents](#usage-instructions---table-of-contents)
## The `calledFrom` Field
The `calledFrom` field in each log entries tells you from where the `Write-Log` function was called. If it was called from a function, you'll see the function name, script source, and what line in that script source the call to `Write-Log` happened:

#### called_within_function.ps1
```PowerShell
Import-Module ps-jsonlogger

function main {
    New-Logger -Path "./called_from_function.log" -ProgramName "Called From Function Example"
    Write-Log "Check out the 'calledFrom' attribute of this log entry!"
    Close-Log
}

main
```
#### Relevant line from called_within_function.log
```JSON
{"timestamp":"2025-10-12T22:08:53.1801031-05:00","level":"INFO","message":"Check out the 'calledFrom' attribute of this log entry!","calledFrom":"at main, C:\\called_within_function.ps1: line 5"}
```

If instead you call `Write-Log` outside a function, you will see the text `at <ScriptBlock>` instead of `at FunctionName`:
#### called_outside_function.ps1
```PowerShell
Import-Module ps-jsonlogger

New-Logger -Path "./called_outside_function.log" -ProgramName "Called Outside Function Example"
Write-Log "Check out the 'calledFrom' attribute of this log entry!"
Close-Log
```
#### Relevant line from called_outside_function.log
```JSON
{"timestamp":"2025-10-12T22:06:06.4923488-05:00","level":"INFO","message":"Check out the 'calledFrom' attribute of this log entry!","calledFrom":"at <ScriptBlock>, C:\\called_outside_function.ps1: line 4"}
```

[Back to the table of contents](#usage-instructions---table-of-contents)
## Additional Log Entry Options
`Write-Log` provides two additional options:
 * Include one or more additional objects for context
 * Include the full call stack

You can use one of the additional options or both at the same time:
```PowerShell
# One context object
Write-Log -Level $info -Message $message -Context $obj

# An array of multiple objects
Write-Log -Level $level -Message $message -Context @($obj1, $obj2, $obj3)

# Include the full call stack
Write-Log -Level $level -Message $message -WithCallStack

# Do both
Write-Log -Level $level -Message $message -Context $obj -WithCallStack
```

#### Context Object(s)
You can pass any PowerShell object, or an array of multiple objects, to `New-Logger -Context` to have them appear in the log entry. Here's an example:

#### context_object.ps1
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

    New-Logger -Path "./context_object.log" -ProgramName "Context Object Example"
    Write-Log -Level $level "Current object state" -Context $context
    Close-Log
}

main
```

#### Relevant line from context_object.log
```JSON
{"timestamp":"2025-10-12T22:15:32.1680644-05:00","level":"DEBUG","message":"Current object state","context":[{"Name":"Sample Context Object","NestedObj1":{"Id":1,"Value":"Nested object 1"},"NestedObj2":{"Id":2,"Value":"Nested object 2"}}],"calledFrom":"at main, C:\\context_object.ps1: line 26"}
```

#### Include the full call stack
If you wish to include the full call stack (taken from PowerShell's `Get-PSCallStack`), you can do that like this:

#### call_stack.ps1
```PowerShell
Import-Module ps-jsonlogger

function Another-Function {
    Write-Log -Dbg "Full call stack, second function" -WithCallStack
}

function main {
    New-Logger -Path "./call_stack.log" -ProgramName "Including the full call stack."
    Write-Log -Dbg "Full call stack, first function" -WithCallStack

    Another-Function

    Close-Log
}

main
```

#### call_stack.log
```JSON
{"timestamp":"2025-10-12T22:17:44.2150565-05:00","level":"START","programName":"Including the full call stack.","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0"}
{"timestamp":"2025-10-12T22:17:44.2157187-05:00","level":"DEBUG","message":"Full call stack, first function","calledFrom":"at main, C:\\call_stack.ps1: line 9","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 193 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 116 at Write-Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 329 at main, C:\\call_stack.ps1: line 9 at <ScriptBlock>, C:\\call_stack.ps1: line 16 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-12T22:17:44.2263534-05:00","level":"DEBUG","message":"Full call stack, second function","calledFrom":"at Another-Function, C:\\call_stack.ps1: line 4","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 193 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 116 at Write-Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 329 at Another-Function, C:\\call_stack.ps1: line 4 at main, C:\\call_stack.ps1: line 11 at <ScriptBlock>, C:\\call_stack.ps1: line 16 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-12T22:17:44.2421852-05:00","level":"END"}
```

[Back to the table of contents](#usage-instructions---table-of-contents)
## Creating Multiple Loggers
You can create multiple loggers in the same script by calling `New-Logger`  with the `-LoggerName` parameter. This will create a new logger with a different name, and you can use it in `Write-Log` and `Close-Log` by specifying the logger name as the `-Logger` parameter. Under the hood, the default logger is always named "default" and you can safely omit the -LoggerName parameter if you don't need multiple loggers.

#### multiple_loggers.ps1
```PowerShell
Import-Module ps-jsonlogger

function DoSomething {
    Write-Log -Level "INFO" -Message "This will go to the default logger."
}

function DoSomethingDangerous {
    throw "Be careful!"
}

function DoSomethingREALLYDangerous {
    throw "Now you've done it..."
}

function main {
    New-Logger -Path "./multiple_loggers_default.log" -ProgramName "Multiple Loggers Example"
    New-Logger -Path "./multiple_loggers_errors.log" -ProgramName "Multiple Loggers Example" -LoggerName "errors"

    DoSomething

    try {
        DoSomethingDangerous
    }
    catch {
        Write-Log -Logger "errors"-Level "ERROR" -Message "This will go to the errors logger."
    }

    try {
        DoSomethingREALLYDangerous
    }
    catch {
        # If you don't specify -Logger, the default logger will be closed.
        Close-Log -Message "Error encountered. Closing."

        # FATAL errors will both close the associated logger and exit the script.
        Write-Log -Logger "errors" -Level "FATAL" -Message "Whoops..."
    }
}

main
```

#### multiple_loggers_default.log
```JSON
{"timestamp":"2025-10-13T11:03:34.6137242-05:00","level":"START","programName":"Multiple Loggers Example","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0"}
{"timestamp":"2025-10-13T11:03:34.6219973-05:00","level":"INFO","message":"This will go to the default logger.","calledFrom":"at DoSomething, C:\\multiple_loggers.ps1: line 4"}
{"timestamp":"2025-10-13T11:03:34.6571757-05:00","level":"END","message":"Error encountered. Closing."}
```

#### multiple_loggers_errors.log
```JSON
{"timestamp":"2025-10-13T11:03:34.6179096-05:00","level":"START","programName":"Multiple Loggers Example","PSVersion":"7.5.3","jsonLoggerVersion":"1.0.0","hasError":true,"hasFatal":true}
{"timestamp":"2025-10-13T11:03:34.6391387-05:00","level":"ERROR","message":"This will go to the errors logger.","calledFrom":"at main, C:\\multiple_loggers.ps1: line 25"}
{"timestamp":"2025-10-13T11:03:34.6646649-05:00","level":"FATAL","message":"Whoops...","calledFrom":"at main, C:\\multiple_loggers.ps1: line 36","callStack":"at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 193 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 116 at Write-Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\1.0.0\\ps-jsonlogger.psm1: line 487 at main, C:\\multiple_loggers.ps1: line 36 at <ScriptBlock>, C:\\multiple_loggers.ps1: line 40 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-13T11:03:34.6908570-05:00","level":"END"}
```

[Back to the table of contents](#usage-instructions---table-of-contents)

## Notes on PowerShell Core 7 vs Windows PowerShell 5.1
While ps-jsonlogger is compatible with Windows PowerShell v5, it does have some inherent limitations.

### Encodings
PowerShelll 7 supports a couple additional encoding options compared to v5.

v7: `ascii`, `bigendianunicode`, `oem`, `unicode`, `utf7`, `utf8`, `utf8BOM`, `utf8NoBOM`, `utf32`
Default: `utf8BOM`

v5: `ascii`, `bigendianunicode`, `oem`, `unicode`, `utf7`, `utf8`, `utf32`
Default: `utf8`

If you're using v5, you can still use the `Encoding` parameter to specify the encoding you want to use but you will get an error if you try to use an unsupported encoding.


### Spercial Characters in JSON
Powershell v5 does not convert all special characters in JSON strings the same way as PowerShell v7. This means that you may see some characters like `\u003c` in your log files in v5 instead of `<` in v7 or `\u0027` instead of `'`. PowerShell v5 will still import these files just fine and the initial log entry include the `powerShellVersion` property that can be utilized in any parsers to ensure proper JSON deserialization.

[Back to the table of contents](#usage-instructions---table-of-contents)