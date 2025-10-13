# Copyright (c) 2025 Bryan Cuneo

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

enum Encodings {
    ascii
    bigendianunicode
    oem
    unicode
    utf7
    utf8
    utf8BOM
    utf8NoBOM
    utf32
}

enum Levels {
    INFO
    WARNING
    ERROR
    FATAL
    DEBUG
    VERBOSE
}

[hashtable]$script:_ShortLevels = @{
    "INFO"    = "INF"
    "WARNING" = "WRN"
    "ERROR"   = "ERR"
    "FATAL"   = "FTL"
    "DEBUG"   = "DBG"
    "VERBOSE" = "VRB"
}

$script:_Loggers = [ordered]@{}

class Logger {
    [string]$Path
    [string]$ProgramName
    [string]$Encoding
    [bool]$Overwrite
    [bool]$WriteToHost

    [string]$JsonLoggerVersion = "1.0.0-alpha"
    [bool]$hasWarning = $false
    [bool]$hasError = $false

    Logger([string]$path, [string]$programName, [Encodings]$encoding = [Encodings]::utf8BOM, [bool]$overwrite = $false, [bool]$writeToHost = $false) {
        $this.Path = $path
        $this.ProgramName = $programName
        $this.Encoding = [Encodings].GetEnumName($encoding)
        $this.Overwrite = $overwrite
        $this.WriteToHost = $writeToHost

        if ($this.Overwrite -or -not (Test-Path -Path $this.Path)) {
            New-Item -Path $this.Path -ItemType File -Force | Out-Null
        }
        elseif ((Get-Item -Path $this.Path).Length -gt 0) {
            throw "The file '$path' already exists and is not empty. Use -Overwrite to overwrite it."
        }
        elseif (-not (Get-Item -Path $this.Path).PSIsContainer) {
            throw "The path '$path' is not a valid file."
        }

        $initialEntry = [ordered]@{
            timestamp         = (Get-Date).ToString("o")
            level             = "START"
            programName       = $this.ProgramName
            PSVersion         = $global:PSVersionTable.PSVersion.ToString()
            jsonLoggerVersion = $this.JsonLoggerVersion
        }
        try {
            $initialEntryJson = $initialEntry | ConvertTo-Json -Compress
            Add-Content -Path $this.Path -Value $initialEntryJson -Encoding $this.Encoding -ErrorAction Stop

            if ($this.WriteToHost) {
                Write-Host "[$($initialEntry.level)][$(Get-Date $initialEntry.timestamp -f "yyyy-MM-dd HH:mm:ss")] $($this.ProgramName)"
            }
        }
        catch {
            throw "Failed to convert initial log entry to JSON: $_"
        }
    }

    hidden [void] AddToInitialEntry([string]$newFieldName, [object]$value) {
        $file = Get-Content -Path $this.Path
        $newInitialEntry = ($file[0] | ConvertFrom-Json -AsHashtable)
        $newInitialEntry.$newFieldName = $value
        $file[0] = $newInitialEntry | ConvertTo-Json -Compress
        $file | Set-Content -Path $this.Path
    }

    [void] Log([Levels]$level, [string]$message, [string]$calledFrom, [array]$context, [bool]$includeCallStack) {
        try {
            if ($null -ne $context) {
                $logEntry = [LogEntry]::new($level, $message, $calledFrom, $context, $includeCallStack)
                $jsonEntryJson = $logEntry | ConvertTo-Json -Compress -Depth 100
            }
            else {
                $logEntry = [LogEntry]::new($level, $message, $calledFrom, $null, $includeCallStack)
                $jsonEntryJson = $logEntry | ConvertTo-Json -Compress
            }
        }
        catch {
            throw $_
        }

        Add-Content -Path $this.Path -Value $jsonEntryJson -Encoding $this.Encoding -ErrorAction Stop

        if ($this.WriteToHost) {
            switch ($level) {
                "WARNING" { Write-Host $logEntry.ToString() -ForegroundColor Yellow }
                "ERROR" { Write-Host $logEntry.ToString() -ForegroundColor Red }
                "FATAL" { Write-Host $logEntry.ToString() -ForegroundColor Red }
                default { Write-Host $logEntry.ToString() }
            }
        }

        if (-not $this.hasWarning -and $level -eq [Levels]::WARNING) {
            $this.AddToInitialEntry("hasWarning", $true)
            $this.hasWarning = $true
        }
        elseif (-not $this.HasError -and $level -eq [Levels]::ERROR) {
            $this.AddToInitialEntry("hasError", $true)
            $this.hasError = $true
        }
        elseif ($level -eq [Levels]::FATAL) {
            $this.AddToInitialEntry("hasFatal", $true)
            Close-Log
            exit 1
        }
    }

    [void] Close() {
        $this.Close("")
    }

    [void] Close($message) {
        $finalEntry = [ordered]@{
            timestamp = (Get-Date).ToString("o")
            level     = "END"
        }

        if (-not [string]::IsNullOrEmpty($message)) {
            $finalEntry | Add-Member -MemberType NoteProperty -Name "message" -Value $message
        }

        if ($this.WriteToHost) {
            $friendlyString = "[$($finalEntry.level)][$(Get-Date $finalEntry.timestamp -f "yyyy-MM-dd HH:mm:ss")]"
            if (-not [string]::IsNullOrEmpty($message)) {
                $friendlyString += " $message"
            }
            Write-Host $friendlyString
        }

        $finalEntryJson = $finalEntry | ConvertTo-Json -Compress
        Add-Content -Path $this.Path -Value $finalEntryJson -Encoding $this.Encoding -ErrorAction Stop
    }
}

class LogEntry {
    [string]$timestamp = (Get-Date).ToString("o")
    [string]$level
    [string]$message

    LogEntry([Levels]$level, [string]$message, [string]$calledFrom, [array]$context, [bool]$includeCallStack) {
        $this.level = [Levels].GetEnumName($level)
        $this.message = $message

        if ($null -ne $context) {
            $this | Add-Member -MemberType NoteProperty -Name "context" -Value $context
        }

        $this | Add-Member -MemberType NoteProperty -Name "calledFrom" -Value $calledFrom

        if ($this.level -eq [Levels]::VERBOSE -or $this.level -eq [Levels]::FATAL -or $includeCallStack) {
            $this | Add-Member -MemberType NoteProperty -Name "callStack" -Value ([string](Get-PSCallStack))
        }
    }

    [string] ToString() {
        return "[$($script:_ShortLevels[$this.level])] $($this.message)"
    }
}

<#
.SYNOPSIS
Creates a new Logger instance.

.DESCRIPTION
The New-Logger function initializes a Logger that writes JSON entries to a
sepcified file. You can have multiple loggers in the same script by utilizing
the -LoggerName parameter, and you can use any of PowerShell's supported
encoding options with the -Encoding parameter (default: utf8).

.PARAMETER Path
The file path where the log file will be written. It is mandatory and cannot be
null or empty.

.PARAMETER ProgramName
Friendly name for the program that is logging. It is mandatory and cannot be
null or empty.

.PARAMETER Encoding
Text encoding used for the log file. Available options:
ascii, bigendianunicode, oem, unicode, utf7, utf8, utf8BOM, utf8NoBOM, utf32
Default: utf8

.PARAMETER LoggerName
An optional parameter to use if you want to create multiple loggers. By
default, it is set to "default" and you can safely ignore it.

.PARAMETER Overwrite
A switch that, when set, allows overwriting existing log files.
Default: off

.PARAMETER WriteToHost
A switch that, when set, allows log messages to be output to the host via the
Write-Host cmdlet (this is in addition to being written to disk). Default: off

.PARAMETER Force
A switch that, when set, allows the creation of a logger that has the
same name as an existing logger. Default: off

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
New-Logger -Path "C:\logs\app.log" -ProgramName "MyApplication"

Creates a new logger that writes to "C:\logs\app.log" for
"MyApplication" with default parameters.

.EXAMPLE
New-Logger `
        -Path "C:\logs\app.log" `
        -ProgramName "MyApplication" `
        -LoggerName "MyLogger" `
        -Overwrite `
        -Force

Creates a logger named "MyLogger" that overwrites any existing log
file at "C:\logs\app.log".

.LINK
Write-Log

.LINK
Close-Log

.LINK
https://github.com/BryanCuneo/ps-jsonlogger
#>
function New-Logger {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProgramName,

        [ValidateNotNullOrEmpty()]
        [Encodings]$Encoding = [Encodings]::utf8,

        [ValidateNotNullOrEmpty()]
        [string]$LoggerName = "default",

        [switch]$Overwrite,
        [switch]$WriteToHost,
        [switch]$Force
    )

    if ($script:_Loggers.Contains($LoggerName) -and -not $Force) {
        throw "Unable to create logger '$LoggerName'. Use -LoggerName <name> to create a new logger with a different name or -Force to override this."
    }

    $script:_Loggers[$LoggerName] = [Logger]::new($Path, $ProgramName, $Encoding, $Overwrite, $WriteToHost)
}

<#
.SYNOPSIS
Writes structured JSON log entries using a Logger instance from New-Logger.

.DESCRIPTION
The Write-Log function allows you to log messages with different severity
levels: INFO, WARNING, ERROR, DEBUG, VERBOSE, and FATAL. You can also include
contextual information and/or call stack details.

.PARAMETER Message
The log message to be recorded. This parameter is mandatory and cannot be null
or empty. It can be piped to the function, given as as positional parameter, or
given explicitly as -Message.

.PARAMETER Context
An optional array of PowerShell objects to provide additional contextual info
about to the log entry.

.PARAMETER WithCallStack
A switch that, when set, includes the full call stack from Get-PSCallStack in
the log entry.

.PARAMETER Logger
If you have more than one logger instance, this parameter allows you to specify
which one to write to. If not specified, the default logger will be used.

.PARAMETER Level
The severity level of the log message. Valid options are INFO, I, WARNING, W,
ERROR, E, DEBUG, D, VERBOSE, V, FATAL, and F. Default: INFO

.PARAMETER Inf
A switch that can be used to specify the log level as INFO.

.PARAMETER Wrn
A switch that can be used to specify the log level as WARNING.

.PARAMETER Err
A switch that can be used to specify the log level as ERROR.

.PARAMETER Dbg
A switch that can be used to specify the log level as DEBUG.

.PARAMETER Vrb
A switch that can be used to specify the log level as VERBOSE.

.PARAMETER Ftl
A switch that can be used to specify the log level as FATAL.

.INPUTS
A string message.

.OUTPUTS
None.

.EXAMPLE
Write-Log "Hello, World!"

Logs an message with the default level of INFO.

.EXAMPLE
Write-Log -Level "W" -Message "This is a warning message."

Logs a warning message.

.EXAMPLE
    $context = [Ordered]@{
        Name = "John Doe"
        Age  = 42
    }
    "This is an error message with context." | Write-Log -Err -Context $context

Logs an error message along with additional context information.

.EXAMPLE
Write-Log -F "An unrecoverable error has occurred. Exiting."

Logs a FATAL error that will close the log cause the script to exit.

.LINK
New-Logger

.LINK
Close-Log

.LINK
https://github.com/BryanCuneo/ps-jsonlogger
#>
function Write-Log {
    [CmdletBinding(DefaultParameterSetName = "LevelParam")]
    param(
        [Parameter(ParameterSetName = "LevelParam")]
        [Parameter(ParameterSetName = "Info")]
        [Parameter(ParameterSetName = "Warning")]
        [Parameter(ParameterSetName = "Error")]
        [Parameter(ParameterSetName = "Debug")]
        [Parameter(ParameterSetName = "Verbose")]
        [Parameter(ParameterSetName = "Fatal")]
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(ParameterSetName = "LevelParam")]
        [Parameter(ParameterSetName = "Info")]
        [Parameter(ParameterSetName = "Warning")]
        [Parameter(ParameterSetName = "Error")]
        [Parameter(ParameterSetName = "Debug")]
        [Parameter(ParameterSetName = "Verbose")]
        [Parameter(ParameterSetName = "Fatal")]
        [array]$Context = $null,

        [Parameter(ParameterSetName = "LevelParam")]
        [Parameter(ParameterSetName = "Info")]
        [Parameter(ParameterSetName = "Warning")]
        [Parameter(ParameterSetName = "Error")]
        [Parameter(ParameterSetName = "Debug")]
        [Parameter(ParameterSetName = "Verbose")]
        [Parameter(ParameterSetName = "Fatal")]
        [switch]$WithCallStack,

        [Parameter(ParameterSetName = "LevelParam")]
        [Parameter(ParameterSetName = "Info")]
        [Parameter(ParameterSetName = "Warning")]
        [Parameter(ParameterSetName = "Error")]
        [Parameter(ParameterSetName = "Debug")]
        [Parameter(ParameterSetName = "Verbose")]
        [Parameter(ParameterSetName = "Fatal")]
        [ValidateNotNullOrEmpty()]
        [string]$Logger = "default",

        [Parameter(ParameterSetName = "LevelParam")]
        [ValidateSet("INFO", "I", "WARNING", "W", "ERROR", "E", "DEBUG", "D", "VERBOSE", "V", "FATAL", "F")]
        [string]$Level = "INFO",

        [Parameter(Mandatory, ParameterSetName = "Info")]
        [Alias("I")]
        [switch]$Inf,

        [Parameter(Mandatory, ParameterSetName = "Warning")]
        [Alias("W")]
        [switch]$Wrn,

        [Parameter(Mandatory, ParameterSetName = "Error")]
        [Alias("E")]
        [switch]$Err,

        [Parameter(Mandatory, ParameterSetName = "Debug")]
        [Alias("D")]
        [switch]$Dbg,

        [Parameter(Mandatory, ParameterSetName = "Verbose")]
        [Alias("V")]
        [switch]$Vrb,

        [Parameter(Mandatory, ParameterSetName = "Fatal")]
        [Alias("F")]
        [switch]$Ftl
    )

    if ($($PSCmdlet.ParameterSetName) -ne "LevelParam") {
        if ($Inf) { $Level = [Levels]::INFO }
        elseif ($Wrn) { $Level = [Levels]::WARNING }
        elseif ($Err) { $Level = [Levels]::ERROR }
        elseif ($Dbg) { $Level = [Levels]::DEBUG }
        elseif ($Vrb) { $Level = [Levels]::VERBOSE }
        elseif ($Ftl) { $Level = [Levels]::FATAL }
    }
    elseif ($Level -in @("I", "W", "E", "D", "V", "F")) {
        switch ($Level) {
            "I" { $Level = [Levels]::INFO }
            "W" { $Level = [Levels]::WARNING }
            "E" { $Level = [Levels]::ERROR }
            "D" { $Level = [Levels]::DEBUG }
            "V" { $Level = [Levels]::VERBOSE }
            "F" { $Level = [Levels]::FATAL }
        }
    }

    if ($script:_Loggers.Count -eq 0) {
        throw "No existing loggers. Use 'New-Logger' to create one."
    }

    if (-not $script:_Loggers.Contains($Logger)) {
        Write-Warning "'$Logger' does not match any existing loggers ('$($script:_Loggers.Keys -join ", '")'). Falling back to '$($script:_Loggers.Keys[0])'."
        $Logger = $script:_Loggers.Keys[0]
    }

    $script:_Loggers[$Logger].Log($Level, $Message, (Get-PSCallStack)[1].ToString(), $Context, $WithCallStack)
}

<#
.SYNOPSIS
Closes a logger instance with an optional message.

.DESCRIPTION
The Close-Log function is used to close an existing logger instance. It will
write a closing entry (with an optional message) to the file and then remove
the logger from the active logger pool.

.PARAMETER Message
An optional message to log when closing the logger. It can be piped to the
function, given as as positional parameter, or given explicitly as -Message.

.PARAMETER Logger
If you have more than one logger instance, this parameter allows you to specify
which one to close. If not specified, the default logger will be closed.

.INPUTS
A string message.

.OUTPUTS
None.

.EXAMPLE
Close-Log "All Done!"

Closes the default logger with thes message, "All Done!".

.LINK
New-Logger

.LINK
Write-Log

.LINK
https://github.com/BryanCuneo/ps-jsonlogger
#>
function Close-Log {
    param(
        [Parameter(Mandatory, ParameterSetName = "WithMessage", Position = 0, ValueFromPipeline = $true)]
        [string]$Message,

        [Parameter(ParameterSetName = "WithMessage")]
        [Parameter(ParameterSetName = "WithoutMessage")]
        [ValidateNotNullOrEmpty()]
        [string]$Logger = "default"
    )

    if ($script:_Loggers.Count -eq 0) {
        Write-Warning "There are no loggers to close."
        return
    }

    if (-not $script:_Loggers.Contains($Logger)) {
        throw "'$Logger' does not match any existing loggers ('$($script:_Loggers.Keys -join ", '")')."
    }

    $script:_Loggers[$Logger].Close($Message)
    $script:_Loggers.Remove($Logger)
}

function Cleanup {
    $script:_Loggers.Values | ForEach-Object {
        $_.Close()
    }
}

# PS module lifecycle management kind of sucks. The PowerShell.Exiting and
# OnRemove events are unreliable and don't fire in most scenarious you would
# assume they do. However, they're the best options we have to attempt to clean
# up the loggers if the user doesn't call Close-Log.
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
    Cleanup
}

$OnRemoveScript = {
    Cleanup
}
$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript

Export-ModuleMember -Function New-Logger, Write-Log, Close-Log
