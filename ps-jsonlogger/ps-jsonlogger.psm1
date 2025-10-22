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

enum Levels {
    INFO
    SUCCESS
    WARNING
    ERROR
    FATAL
    DEBUG
    VERBOSE
}

enum ConsoleStyles {
    Simple
    TimeSpan
    Timestamp
}

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $_ValidEncodings = @("ansi", "ascii", "bigendianunicode", "bigendianutf32",
        "oem", "unicode", "utf7", "utf8", "utf8BOM", "utf8NoBOM", "utf32")
    # Before 7.4, "ansi" was not a valid encoding
    if ($PSVersionTable.PSVersion.Minor -lt 4) {
        $_ValidEncodings.Remove("ansi")
    }
}
else {
    $_ValidEncodings = @("Ascii", "BigEndianUnicode", "BigEndianUTF32",
        "Byte", "Default", "Oem", "String", "Unicode", "Unknown", "UTF7",
        "UTF8", "UTF32")
}

$_Loggers = [ordered]@{}

class Logger {
    [string]$Path
    [string]$ProgramName
    [string]$Encoding
    [bool]$Overwrite
    [string]$WriteToHost
    [datetime]$StartTime
    [bool]$hasWarning = $false
    [bool]$hasError = $false

    static [string]$JsonLoggerVersion = "1.3.0"
    static [hashtable]$ShortLevels = @{
        [Levels]::INFO    = "INF"
        [Levels]::SUCCESS = "SCS"
        [Levels]::WARNING = "WRN"
        [Levels]::ERROR   = "ERR"
        [Levels]::FATAL   = "FTL"
        [Levels]::DEBUG   = "DBG"
        [Levels]::VERBOSE = "VRB"
    }

    Logger([string]$path, [string]$programName, [string]$encoding, [bool]$overwrite = $false, [ConsoleStyles]$WriteToHost) {
        $this.StartTime = (Get-Date).ToString("o")
        $this.Path = $path
        $this.ProgramName = $programName
        $this.Encoding = $encoding
        $this.Overwrite = $overwrite
        $this.WriteToHost = $WriteToHost

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
            timestamp         = $this.StartTime
            level             = "START"
            programName       = $this.ProgramName
            PSVersion         = $global:PSVersionTable.PSVersion.ToString()
            jsonLoggerVersion = [Logger]::JsonLoggerVersion
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
        $file = Get-Content -Path $this.Path -Encoding $this.Encoding

        if ($global:PSVersionTable.PSVersion.Major -ge 6) {
            $newInitialEntry = ($file[0] | ConvertFrom-Json -AsHashtable)
        }
        else {
            # PowerShell v5 doesn't support -AsHashtable, so we have to do it manually
            $json = ($file[0] | ConvertFrom-Json)
            $newInitialEntry = [ordered]@{}
            $json.PSObject.Properties | ForEach-Object {
                $newInitialEntry[$_.Name] = $_.Value
            }
        }

        $newInitialEntry.$newFieldName = $value
        $file[0] = $newInitialEntry | ConvertTo-Json -Compress
        $file | Set-Content -Path $this.Path -Encoding $this.Encoding
    }

    hidden [timespan] GetTimeSinceStart([datetime]$time) {
        return New-TimeSpan -Start $time -End $this.StartTime
    }

    [void] Log([Levels]$level, [string]$message, [string]$calledFrom, [array]$context, [bool]$includeCallStack) {
        try {
            if ($null -ne $context) {
                $logEntry = [LogEntry]::new($level, $message, $calledFrom, $context, $includeCallStack)
                try {
                    $logEntryJson = $logEntry | ConvertTo-Json -Compress -Depth 100
                }
                catch {
                    Write-Warning "Failed to fully convert full context object to JSON. Falling back simplifed JSON."
                    $logEntryJson = $logEntry | ConvertTo-Json -Compress
                }
            }
            else {
                $logEntry = [LogEntry]::new($level, $message, $calledFrom, $null, $includeCallStack)
                $logEntryJson = $logEntry | ConvertTo-Json -Compress
            }
        }
        catch {
            throw $_
        }

        Add-Content -Path $this.Path -Value $logEntryJson -Encoding $this.Encoding -ErrorAction Stop
        
        if ($this.WriteToHost) {
            $console_message = "[$([Logger]::ShortLevels[$level])] $message"
            $color = "White"
            
            switch ($level) {
                "SUCCESS" { $color = "Green" }
                "WARNING" { $color = "Yellow" }
                "ERROR" { $color = "Red" }
                "FATAL" { $color = "Red" }
            }

            switch ($this.WriteToHost) {
                "TIMESTAMP" {
                    $console_message = "[$([Logger]::ShortLevels[$level]) $((Get-Date $logEntry.timestamp).ToString("hh:mm:ss.ff"))] $message"
                }
                "TIMESPAN" {
                    $console_message = "[$([Logger]::ShortLevels[$level]) $($this.GetTimeSinceStart($logEntry.timestamp).ToString("mm\:ss\.ff"))] $message"
                }
            }

            Write-Host $console_message -ForegroundColor $color
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
            $this.Close()
            Cleanup
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
The file path where the log file will be written. Required and cannot be null or empty.

.PARAMETER ProgramName
Friendly name for the program that is logging. Required and cannot be null or empty.

.PARAMETER Encoding
Text encoding used for the log file.

PowerShell v7 encodings:
"ascii", "bigendianunicode", "bigendianutf32", "oem", "unicode", "utf7",
"utf8", "utf8BOM", "utf8NoBOM", "utf32"

Additionally, 7.4+ supports "ansi" as an option.
Default: utf8BOM

PowerShell v5 encodings:
"Ascii", "BigEndianUnicode", "BigEndianUTF32", "Byte", "Default", "Oem",
"String", "Unicode", "Unknown", "UTF7", "UTF8", "UTF32"
Default: utf8

.PARAMETER LoggerName
An optional parameter to use if you want to create multiple loggers. By
default, it is set to "default" and you can safely ignore it.

.PARAMETER Overwrite
A switch that, when set, allows overwriting existing log files.
Default: off

.PARAMETER WriteToHost
Enables log messages to be written to the console via the Write-Host cmdlet.
Supports the following output styles:
-WriteToHost Simple
    [LVL] message
-WriteToHost TimeSpan
    [LVL mm:ss.ff] message     # Time passed since the logger started
-WriteToHost Timestamp
    [LVL hh:mm:ss.ff] message  # Time the log entry was written

.PARAMETER Force
A switch that, when set, allows the creation of a logger that has the
same name as an existing logger. Default: off

.INPUTS
None.

.OUTPUTS
A new Logger instance.

.EXAMPLE
# Creates a new logger that writes to "C:\logs\app.log" for
# "My Application" with default parameters.
New-Logger -Path "C:\logs\app.log" -ProgramName "My Application"


.EXAMPLE
# Creates a logger named "MyLogger" that overwrites any existing log
# file at "C:\logs\app.log".
New-Logger `
        -Path "C:\logs\app.log" `
        -ProgramName "My Application" `
        -LoggerName "MyLogger" `
        -Overwrite `
        -Force

.LINK
Write-Log

.LINK
Close-Log

.LINK
Import-Log

.LINK
Convert-Log

.LINK
https://github.com/BryanCuneo/ps-jsonlogger
#>
function New-Logger {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateNotNullOrEmpty()]
        [string]$ProgramName,

        [ValidateScript({
                if ($_ -in $_ValidEncodings) { $true }
                else { throw "'$_' is not a valid encoding. Please try again: $($_ValidEncodings -join ", ")" }
            })]
        [string]$Encoding,

        [ValidateNotNullOrEmpty()]
        [string]$LoggerName = "default",

        [ValidateScript({
                if ($_ -in [ConsoleStyles].GetEnumNames()) { $true }
                else { throw "'$_' is not a valid style. Please try again: $([ConsoleStyles].GetEnumNames() -join ", ")" }
            })]
        [ConsoleStyles]$WriteToHost,

        [switch]$Overwrite,
        [switch]$Force
    )

    if (-not $Encoding -and $PSVersionTable.PSVersion.Major -ge 7) {
        $Encoding = "utf8BOM"
    }
    elseif (-not $Encoding) {
        $Encoding = "utf8"
    }

    if ($_Loggers.Contains($LoggerName) -and -not $Force) {
        throw "Unable to create logger '$LoggerName'. Use -LoggerName <name> to create a new logger with a different name or -Force to override this."
    }

    if ($PSCmdlet.ShouldProcess($Path, "Create logger '$LoggerName'")) {
        Write-Host "Calling logger with WriteToHost '$WriteToHost'"
        $_Loggers[$LoggerName] = [Logger]::new($Path, $ProgramName, $Encoding, $Overwrite, $WriteToHost)
    }
}

Register-ArgumentCompleter -CommandName New-Logger -ParameterName Encoding -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $_ValidEncodings | Where-Object { $_ -like "$wordToComplete*" }
}

Register-ArgumentCompleter -CommandName New-Logger -ParameterName WriteToHost -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    [ConsoleStyles].GetEnumNames() | Where-Object { $_ -like "$wordToComplete*" }
}

<#
.SYNOPSIS
Writes structured JSON log entries using a Logger instance from New-Logger.

.DESCRIPTION
The Write-Log function allows you to log messages with different severity
levels: INFO, WARNING, ERROR, DEBUG, VERBOSE, and FATAL. You can also include
contextual information and/or call stack details.

.PARAMETER Message
The log message to be recorded. Required and cannot be null or empty. It can be
piped to the function, given as as positional parameter, or given explicitly as
-Message.

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
The severity level of the log message. Valid options are INFO, I, SUCCESS, S
WARNING, W, ERROR, E, DEBUG, D, VERBOSE, V, FATAL, and F. Default: INFO

.PARAMETER Inf
A switch that can be used to specify the log level as INFO.

.PARAMETER Scs
A switch that can be used to specify the log level as SUCCESS.

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
The Message parameter accepts pipeline input.

.OUTPUTS
None (writes output to disk).

.EXAMPLE
# Logs an message with the default level of INFO.
Write-Log "Hello, World!"

.EXAMPLE
# Logs a warning message.
Write-Log -Level "W" -Message "This is a warning message."

.EXAMPLE
# Logs an error message along with additional context information.
$context = [Ordered]@{
    Name = "John Doe"
    Age  = 42
}
"This is an error message with context." | Write-Log -Err -Context $context


.EXAMPLE
# Logs a FATAL error that will close the log cause the script to exit.
Write-Log -F "An unrecoverable error has occurred. Exiting."

.LINK
New-Logger

.LINK
Close-Log

.LINK
Import-Log

.LINK
Convert-Log

.LINK
https://github.com/BryanCuneo/ps-jsonlogger
#>
function Write-Log {
    [CmdletBinding(DefaultParameterSetName = "LevelParam")]
    param(
        [Parameter(ParameterSetName = "LevelParam")]
        [Parameter(ParameterSetName = "Info")]
        [Parameter(ParameterSetName = "Success")]
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
        [Parameter(ParameterSetName = "Success")]
        [Parameter(ParameterSetName = "Warning")]
        [Parameter(ParameterSetName = "Error")]
        [Parameter(ParameterSetName = "Debug")]
        [Parameter(ParameterSetName = "Verbose")]
        [Parameter(ParameterSetName = "Fatal")]
        [array]$Context = $null,

        [Parameter(ParameterSetName = "LevelParam")]
        [Parameter(ParameterSetName = "Info")]
        [Parameter(ParameterSetName = "Success")]
        [Parameter(ParameterSetName = "Warning")]
        [Parameter(ParameterSetName = "Error")]
        [Parameter(ParameterSetName = "Debug")]
        [Parameter(ParameterSetName = "Verbose")]
        [Parameter(ParameterSetName = "Fatal")]
        [switch]$WithCallStack,

        [Parameter(ParameterSetName = "LevelParam")]
        [Parameter(ParameterSetName = "Info")]
        [Parameter(ParameterSetName = "Success")]
        [Parameter(ParameterSetName = "Warning")]
        [Parameter(ParameterSetName = "Error")]
        [Parameter(ParameterSetName = "Debug")]
        [Parameter(ParameterSetName = "Verbose")]
        [Parameter(ParameterSetName = "Fatal")]
        [ValidateNotNullOrEmpty()]
        [string]$Logger = "default",

        [Parameter(ParameterSetName = "LevelParam")]
        [ValidateSet("INFO", "I", "SUCCESS", "S", "WARNING", "W", "ERROR", "E", "DEBUG", "D", "VERBOSE", "V", "FATAL", "F")]
        [string]$Level = "INFO",

        [Parameter(Mandatory, ParameterSetName = "Info")]
        [Alias("I")]
        [switch]$Inf,

        [Parameter(Mandatory, ParameterSetName = "Success")]
        [Alias("S")]
        [switch]$Scs,

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
        elseif ($Scs) { $Level = [Levels]::SUCCESS }
        elseif ($Wrn) { $Level = [Levels]::WARNING }
        elseif ($Err) { $Level = [Levels]::ERROR }
        elseif ($Dbg) { $Level = [Levels]::DEBUG }
        elseif ($Vrb) { $Level = [Levels]::VERBOSE }
        elseif ($Ftl) { $Level = [Levels]::FATAL }
    }
    elseif ($Level -in @("I", "W", "E", "D", "V", "F")) {
        switch ($Level) {
            "I" { $Level = [Levels]::INFO }
            "S" { $Level = [Levels]::SUCCESS }
            "W" { $Level = [Levels]::WARNING }
            "E" { $Level = [Levels]::ERROR }
            "D" { $Level = [Levels]::DEBUG }
            "V" { $Level = [Levels]::VERBOSE }
            "F" { $Level = [Levels]::FATAL }
        }
    }

    if ($_Loggers.Count -eq 0) {
        throw "No existing loggers. Use 'New-Logger' to create one."
    }

    if (-not $_Loggers.Contains($Logger)) {
        Write-Warning "'$Logger' does not match any existing loggers ('$($_Loggers.Keys -join ", '")'). Falling back to '$($_Loggers.Keys[0])'."
        $Logger = $_Loggers.Keys[0]
    }

    $_Loggers[$Logger].Log($Level, $Message, (Get-PSCallStack)[1].ToString(), $Context, $WithCallStack)
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

.PARAMETER All
A switch that, when set, closes all loggers. This parameter cannot be used with
other parameters.

.INPUTS
A string message.

.OUTPUTS
None (writes output to disk).

.EXAMPLE
# Closes the default logger with the message, "All Done!".
Close-Log "All Done!"

.LINK
New-Logger

.LINK
Write-Log

.LINK
Convert-Log

.LINK
Import-Log

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
        [string]$Logger = "default",

        [Parameter(Mandatory, ParameterSetName = "CloseAll")]
        [switch]$All
    )

    if ($_Loggers.Count -eq 0) {
        return
    }

    if ($All) {
        Cleanup
    }

    if (-not $_Loggers.Contains($Logger)) {
        throw "'$Logger' does not match any existing loggers ('$($_Loggers.Keys -join ", '")')."
    }

    $_Loggers[$Logger].Close($Message)
    $_Loggers.Remove($Logger)
}

<#
.SYNOPSIS
Imports a log file created by ps-jsonlogger.

.DESCRIPTION
Imports a log file created by ps-jsonlogger and returns an object containing
the log entries and the following metadata:
- startTime
- endTime
- duration
- programName
- PSVersion
- jsonLoggerVersion
- hasWarning
- hasError
- hasFatal

.PARAMETER Path
The path to the log file. Required and cannot be null or empty.

.PARAMETER Encoding
Text encoding used for the log file.

PowerShell v7 encodings:
"ascii", "bigendianunicode", "bigendianutf32", "oem", "unicode", "utf7",
"utf8", "utf8BOM", "utf8NoBOM", "utf32"

Additionally, 7.4+ supports "ansi" as an option.
Default: utf8BOM

PowerShell v5 encodings:
"Ascii", "BigEndianUnicode", "BigEndianUTF32", "Byte", "Default", "Oem",
"String", "Unicode", "Unknown", "UTF7", "UTF8", "UTF32"
Default: utf8

.INPUTS
The Path parameter accepts pipeline input.

.OUTPUTS
System.Management.Automation.PSCustomObject
- Contains the properties described in DESCRIPTION.

.EXAMPLE
# Basic import
$log = Import-Log -Path "C:\logs\session.log"

.EXAMPLE
# From pipeline
$log = "C:\logs\session.log" | Import-Log

.EXAMPLE
# Specify encoding
$log = Import-Log -Path "C:\logs\session.log" -Encoding utf8

.LINK
New-Logger

.LINK
Write-Log

.LINK
Close-Log

.LINK
Convert-Log

.LINK
https://github.com/BryanCuneo/ps-jsonlogger
#>
function Import-Log {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateScript({
                if ($_ -in $_ValidEncodings) { $true }
                else { throw "'$_' is not a valid encoding. Please try again with a supported encoding: $($_ValidEncodings -join ", ")" }
            })]
        [string]$Encoding
    )

    if (-not $Encoding -and $PSVersionTable.PSVersion.Major -ge 7) {
        $Encoding = "utf8BOM"
    }
    elseif (-not $Encoding) {
        $Encoding = "utf8"
    }

    $content = Get-Content -Path $Path -Encoding $Encoding -ErrorAction Stop
    $end_time = ($content[-1] | ConvertFrom-Json).timestamp

    $log = $content[0] `
    | ConvertFrom-Json `
    | Select-Object `
    @{Name = "startTime"; Expression = { $_.timestamp } },
    @{Name = "endTime"; Expression = { $end_time } },
    @{Name = "duration"; Expression = { (New-TimeSpan -Start $_.timestamp -End $end_time).ToString("hh\:mm\:ss\.fff") } },
    programName, PSVersion, jsonLoggerVersion,
    @{Name = "hasWarning"; Expression = { $_.hasWarning -eq $true } },
    @{Name = "hasError"; Expression = { $_.hasError -eq $true } },
    @{Name = "hasFatal"; Expression = { $_.hasFatal -eq $true } }

    $entries = @()
    $content | Select-Object -Skip 1 -First $($content.Count - 2) | ForEach-Object { $entries += $_ | ConvertFrom-Json }
    $log | Add-Member -MemberType NoteProperty -Name "entries" -Value $entries


    return $log
}

Register-ArgumentCompleter -CommandName Import-Log -ParameterName Encoding -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $_ValidEncodings | Where-Object { $_ -like "$wordToComplete*" }
}

<#
.SYNOPSIS
Converts a ps-jsonlogger log file. Currently supports CSV and CLIXML.

.DESCRIPTION
Parses a ps-jsonlogger using Import-Log and writes it to a new file in the
chosen format.

Supported conversions:
- CSV
- CLIXML

.PARAMETER Path
The path to the log file. Required and cannot be null or empty.

.PARAMETER Destination
Path to the output file. Required and cannot be null or empty.

.PARAMETER Encoding
Text encoding used for the log file and the output file.

PowerShell v7 encodings:
"ascii", "bigendianunicode", "bigendianutf32", "oem", "unicode", "utf7",
"utf8", "utf8BOM", "utf8NoBOM", "utf32"

Additionally, 7.4+ supports "ansi" as an option.
Default: utf8BOM

PowerShell v5 encodings:
"Ascii", "BigEndianUnicode", "BigEndianUTF32", "Byte", "Default", "Oem",
"String", "Unicode", "Unknown", "UTF7", "UTF8", "UTF32"
Default: utf8

.PARAMETER ConvertTo
Specifies the target format. Acceptable values: "CSV", "CLIXML".
Alias: To

.PARAMETER Overwrite
Switch. If present, existing Destination file will be overwritten.

.INPUTS
The Path parameter accepts pipeline input.

.OUTPUTS
None (writes output to disk).

.EXAMPLE
# Converts a log file to CSV.
Convert-Log -Path "C:\logs\session.log" -Destination "C:\logs\session.csv" -ConvertTo "CSV"

.EXAMPLE
# Converts a log file to CLIXML.
"C:\logs\session.log" | Convert-Log -Destination "C:\logs\session.clixml" -ConvertTo "CLIXML"

.LINK
New-Logger

.LINK
Write-Log

.LINK
Close-Log

.LINK
Import-Log

.LINK
Import-Clixml

.LINK
https://github.com/BryanCuneo/ps-jsonlogger
#>
function Convert-Log {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [ValidateScript({
                if ($_ -in $_ValidEncodings) { $true }
                else { throw "'$_' is not a valid encoding. Please try again with a supported encoding: $($_ValidEncodings -join ", ")" }
            })]
        [string]$Encoding,

        [Parameter(Mandatory)]
        [Alias("To")]
        [ValidateSet("CSV", "CLIXML")]
        [string]$ConvertTo,

        [switch]$Overwrite
    )

    if (-not $Encoding -and $PSVersionTable.PSVersion.Major -ge 7) {
        $Encoding = "utf8BOM"
    }
    elseif (-not $Encoding) {
        $Encoding = "utf8"
    }

    $log = Import-Log -Path $Path -Encoding $Encoding

    switch ($ConvertTo) {
        "csv" {
            $log.entries `
            | Select-Object "timestamp", "level", "message", "calledFrom", "context", "callStack" `
            | Export-Csv -Path $Destination -NoTypeInformation -Encoding $Encoding -Force:$Overwrite
        }
        "clixml" {
            $log | Export-Clixml -Path $Destination -Force:$Overwrite
        }
    }
}

Register-ArgumentCompleter -CommandName Import-Log -ParameterName Encoding -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $_ValidEncodings | Where-Object { $_ -like "$wordToComplete*" }
}

function Cleanup {
    $_Loggers.Clear()
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

Export-ModuleMember -Function New-Logger, Write-Log, Close-Log, Import-Log, Convert-Log
