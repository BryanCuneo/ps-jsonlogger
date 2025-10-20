# Parsing and Visualization

This section is a work in progress. For now it provides documentation for the `Import-Log` and `Convert-Log` cmdlets and includes a simple exmaple PowerShell script. I'm actively working on a more extensive example written in Golang that will be added here when complete.

## PowerShell
This module provides both the `Import-Log` and `Convert-Log` cmdlets, which can be used to parse or convert a ps-jsonlogger log file.

### Built-In - Import-Log
`Import-Log` parses a ps-jsonlogger log file and returns a PowerShell object containing the log entries and the following metadata:
- startTime
- endTime
- duration
- programName
- PSVersion
- jsonLoggerVersion
- hasWarning
- hasError
- hasFatal

```
PS /ps-jsonlogger/testing> Import-Module ps-jsonlogger
PS /ps-jsonlogger/testing> Import-Log -Path "./testing/out/testing.log"

startTime         : 10/19/2025 8:45:38 PM
endTime           : 10/19/2025 8:45:39 PM
duration          : 00:00:00.129
programName       : Test Script for ps-jsonlogger
PSVersion         : 7.5.3
jsonLoggerVersion : 1.2.0
hasWarning        : True
hasError          : True
hasFatal          : False
entries           : {...}   
```

This cmdlet is intended for you to utilize in your own PS-based log visualization tools. For a simple example, see the [visualize_log_file.ps1](./PowerShell/visualize_log_file.ps1) script.

### Built-In - Convert-Log
`Convert-Log` imports a ps-jsonlogger log file (using the [`Import-Log`](#import-log) cmdlet) and exports it to a new file in the chosen format. This is a WIP and currently supports just `.csv` and `.clixml` formats as output.