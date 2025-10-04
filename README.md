# ps-jsonlogger
ps-jsonlogger is a small, dependency-free JSON logger designed to be easily embedded in automation scripts. It supports several log levels and writes compact, structured JSON entries to disk.

## Basic Usage
##### basic_logging.ps1
```PowerShell
Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./basic_logging.log" -ProgramName "Basic Logging"
$logger.Log("INFO", "Hello, World!")
```

##### basic_logging.log
```json
{"ProgramName":"Basic Logging","StartTime":"2025-10-03T23:55:09.6120489-05:00","JsonLoggerVersion":"0.0.1"}
{"timestamp":"2025-10-03T23:55:09.6137185-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at <ScriptBlock>, C:\\basic_logging.ps1: line 4"}
```

The first entry in a log file, which is created when you run `New-JsonLogger`, always contains the program name, the timestmap of when the log was initialized, and the version of ps-jsonlogger that created this particular log file.

## Log Levels
The following log levels are available: `INFO`, `WARNING`, `ERROR`, `DEBUG`, `VERBOSE`.
The only level with special functionality is `VERBOSE`, which always includes the full call stack in the log entry.

## Advanced Usage
### This section is a WIP

##### advanced_logging.ps1
```PowerShell
Import-Module ps-jsonlogger

function Whoops {
    param(
        [switch]$Verbose
    )

    if ($Verbose) {
        $Global:logger.Log("VERBOSE", 'Note the full call stack included in this entry even though we did not pass $includeCallStack=$true')
    }

    $Global:logger.Log("WARNING", "This function does nothing!", $true)
    throw "Whoops! There was an error!"
}

function Invoke-Something {
    param(
        [switch]$Debug
    )

    if ($Debug) {
        $Global:logger.Log("DEBUG", "Calling Whoops with the -Verbose flag)")
    }
    try {
        Whoops -Verbose
    }
    catch {
        $err = $_
        $Global:logger.Log("ERROR", "There was an error", $err, $true)
    }
}

function main {
    $logger.Log("INFO", "Hello, World!")
    Invoke-Something -Debug
}

$Global:logger = New-JsonLogger -LogFilePath "./advanced_logging.log" -ProgramName "Basic Logging"

main
```

##### advanced_logging.log
```JSON
{"ProgramName":"Basic Logging","StartTime":"2025-10-04T00:17:16.0184604-05:00","JsonLoggerVersion":"0.0.1"}
{"timestamp":"2025-10-04T00:17:16.0193111-05:00","level":"INFO","message":"Hello, World!","calledFrom":"at main, C:\\advanced_logging.ps1: line 34"}
{"timestamp":"2025-10-04T00:17:16.0298655-05:00","level":"DEBUG","message":"Calling Whoops with the -Verbose flag)","calledFrom":"at Invoke-Something, C:\\advanced_logging.ps1: line 22"}
{"timestamp":"2025-10-04T00:17:16.0442560-05:00","level":"VERBOSE","message":"Note the full call stack included in this entry even though we did not pass $includeCallStack=$true","calledFrom":"at Whoops, C:\\advanced_logging.ps1: line 9","callStack":"at init, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 81 at init, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 69 at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 89 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 176 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 143 at Whoops, C:\\advanced_logging.ps1: line 9 at Invoke-Something, C:\\advanced_logging.ps1: line 25 at main, C:\\advanced_logging.ps1: line 35 at <ScriptBlock>, C:\\advanced_logging.ps1: line 39 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-04T00:17:16.0652551-05:00","level":"WARNING","message":"This function does nothing!","calledFrom":"at Whoops, C:\\advanced_logging.ps1: line 12","callStack":"at init, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 81 at init, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 69 at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 89 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 176 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 148 at Whoops, C:\\advanced_logging.ps1: line 12 at Invoke-Something, C:\\advanced_logging.ps1: line 25 at main, C:\\advanced_logging.ps1: line 35 at <ScriptBlock>, C:\\advanced_logging.ps1: line 39 at <ScriptBlock>, <No file>: line 1"}
{"timestamp":"2025-10-04T00:17:16.0879946-05:00","level":"ERROR","message":"There was an error","context":[{"Exception":{"ErrorRecord":{"Exception":{"Message":"Whoops! There was an error!","TargetSite":null,"Data":{},"InnerException":null,"HelpLink":null,"Source":null,"HResult":-2146233087,"StackTrace":null},"TargetObject":null,"CategoryInfo":{"Category":0,"Activity":"","Reason":"ParentContainsErrorRecordException","TargetName":"","TargetType":""},"FullyQualifiedErrorId":"RuntimeException","ErrorDetails":null,"InvocationInfo":null,"ScriptStackTrace":null,"PipelineIterationInfo":[]},"WasThrownFromThrowStatement":true,"TargetSite":null,"Message":"Whoops! There was an error!","Data":{},"InnerException":null,"HelpLink":null,"Source":null,"HResult":-2146233087,"StackTrace":null},"TargetObject":"Whoops! There was an error!","CategoryInfo":{"Category":14,"Activity":"","Reason":"RuntimeException","TargetName":"Whoops! There was an error!","TargetType":"String"},"FullyQualifiedErrorId":"Whoops! There was an error!","ErrorDetails":null,"InvocationInfo":{"MyCommand":null,"BoundParameters":{},"UnboundArguments":[],"ScriptLineNumber":13,"OffsetInLine":5,"HistoryId":12,"ScriptName":"C:\\advanced_logging.ps1","Line":"    throw \"Whoops! There was an error!\"\r\n","Statement":"throw \"Whoops! There was an error!\"","PositionMessage":"At C:\\advanced_logging.ps1:13 char:5\r\n+     throw \"Whoops! There was an error!\"\r\n+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~","PSScriptRoot":"C:\\Users\\Bryan Cuneo\\source\\repos\\ps-jsonlogger\\ignore","PSCommandPath":"C:\\advanced_logging.ps1","InvocationName":"","PipelineLength":0,"PipelinePosition":0,"ExpectingInput":false,"CommandOrigin":1,"DisplayScriptPosition":null},"ScriptStackTrace":"at Whoops, C:\\advanced_logging.ps1: line 13\r\nat Invoke-Something, C:\\advanced_logging.ps1: line 25\r\nat main, C:\\advanced_logging.ps1: line 35\r\nat <ScriptBlock>, C:\\advanced_logging.ps1: line 39\r\nat <ScriptBlock>, <No file>: line 1","PipelineIterationInfo":[]}],"calledFrom":"at Invoke-Something, C:\\advanced_logging.ps1: line 29","callStack":"at init, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 81 at LogEntry, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 95 at Log, C:\\PowerShell\\Modules\\ps-jsonlogger\\0.0.1\\ps-jsonlogger.psm1: line 172 at Invoke-Something, C:\\advanced_logging.ps1: line 29 at main, C:\\advanced_logging.ps1: line 35 at <ScriptBlock>, C:\\advanced_logging.ps1: line 39 at <ScriptBlock>, <No file>: line 1"}
```
