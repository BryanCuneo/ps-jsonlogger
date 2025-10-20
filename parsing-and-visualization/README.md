# Parsing and Visualization

This section is a work in progress. For now it provides documentation for the `Import-Log` and `Convert-Log` cmdlets and includes a simple exmaple PowerShell script. I'm actively working on a more extensive example written in Golang that will be added here when complete.

## PowerShell
The `ps-jsonlogger` module provides both the `Import-Log` and `Convert-Log` cmdlets, which can be used to parse or convert a ps-jsonlogger log file.

### Import-Log
`Import-Log` parses a log file and returns a PowerShell object containing the log entries and the following metadata:
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

This cmdlet is intended for utilization in PS-based log visualization tools. See the [visualize_log_file.ps1](./PowerShell/visualize_log_file.ps1) script for a simple example:

<img width="728" height="135" alt="image" src="https://github.com/user-attachments/assets/f1cffa96-9669-4dcc-b31b-6ccc1ee211b4" />

_Note: The script uses symbols from [Nerd Fonts](https://www.nerdfonts.com/). You'll need a Nerd Font of your own for it to work properly. Shown above with_ AtkynsonMono Nerd Font, _based on [Atkinson Hyperlegible Mono](https://www.brailleinstitute.org/freefont/)._ 


### Convert-Log
`Convert-Log` imports a ps-jsonlogger log file (using the [`Import-Log`](#import-log) cmdlet) and exports it to a new file in the chosen format. This is a WIP and currently supports just `.csv` and `.clixml` formats as output.

[Back to the main page.](../)
