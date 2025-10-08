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

[hashtable]$script:shortLevels = @{
    "INFO"    = "INF"
    "WARNING" = "WRN"
    "ERROR"   = "ERR"
    "FATAL"   = "FTL"
    "DEBUG"   = "DBG"
    "VERBOSE" = "VRB"
}

class LogEntry {
    [string]$timestamp = (Get-Date).ToString("o")
    [string]$level
    [string]$message

    LogEntry([Levels]$level, [string]$message, [string]$calledFrom, [array]$context, [boolean]$includeCallStack) {
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
        return "[$($script:shortLevels[$this.level])] $($this.message)"
    }
}

class JsonLogger {
    [string]$LogFilePath
    [string]$ProgramName
    [string]$Encoding
    [boolean]$Overwrite
    [boolean]$WriteToHost

    [string]$JsonLoggerVersion = "1.0.0-alpha"
    [boolean]$hasWarning = $false
    [boolean]$hasError = $false

    # Because we use "constructor chaining" and chained calls to Log(), we
    # have to keep track of the function that called Log() in a variable here
    [string]$CalledFrom

    JsonLogger([string]$logFilePath, [string]$programName, [Encodings]$encoding = [Encodings]::utf8BOM, [boolean]$overwrite = $false, [boolean]$writeToHost) {
        $this.LogFilePath = $logFilePath
        $this.ProgramName = $programName
        $this.Encoding = [Encodings].GetEnumName($encoding)
        $this.Overwrite = $overwrite
        $this.WriteToHost = $writeToHost

        if ($this.Overwrite -or -not (Test-Path -Path $this.LogFilePath)) {
            New-Item -Path $this.LogFilePath -ItemType File -Force | Out-Null
        }
        elseif ((Get-Item -Path $this.LogFilePath).Length -gt 0) {
            throw "The file '$logFilePath' already exists and is not empty. Use -Overwrite to overwrite it."
        }
        elseif (-not (Get-Item -Path $this.LogFilePath).PSIsContainer) {
            throw "The path '$logFilePath' is not a valid file."
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
            Add-Content -Path $this.LogFilePath -Value $initialEntryJson -Encoding $this.Encoding -ErrorAction Stop

            if ($this.WriteToHost) {
                Write-Host "[$($initialEntry.level)][$(Get-Date $initialEntry.timestamp -f "yyyy-MM-dd HH:mm:ss")] $($this.ProgramName)"
            }
        }
        catch {
            throw "Failed to convert initial log entry to JSON: $_"
        }
    }

    hidden [void] AddToInitialEntry([string]$newFieldName, [object]$value) {
        $file = Get-Content -Path $this.LogFilePath
        $newInitialEntry = $file[0] | ConvertFrom-Json -AsHashtable
        $newInitialEntry.$newFieldName = $value
        $file[0] = $newInitialEntry | ConvertTo-Json -Compress
        $file | Set-Content -Path $this.LogFilePath
    }

    [void] Log([string]$message) {
        $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        $this.Log([Levels]::INFO, $message, $null, $false)
    }

    [void] Log([Levels]$level, [string]$message) {
        $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        $this.Log($level, $message, $null, $false)
    }

    [void] Log([Levels]$level, [string]$message, [boolean]$includeCallStack) {
        $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        $this.Log($level, $message, $null, $includeCallStack)
    }

    [void] Log([Levels]$level, [string]$message, [array]$context) {
        $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        $this.Log($level, $message, $context, $false)
    }

    [void] Log([Levels]$level, [string]$message, [array]$context, [boolean]$includeCallStack) {
        if ($null -eq $level) {
            $this.CalledFrom = ""
            throw "Level cannot be null."
        }
        if ([string]::IsNullOrEmpty($message)) {
            $this.CalledFrom = ""
            throw "Message cannot be null or empty."
        }

        if ([string]::IsNullOrEmpty($this.CalledFrom)) {
            $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        }

        if (-not $this.hasWarning -and $level -eq [Levels]::WARNING) {
            $this.AddToInitialEntry("hasWarning", $true)
            $this.hasWarning = $true
        }
        elseif (-not $this.HasError -and $level -eq [Levels]::ERROR) {
            $this.AddToInitialEntry("hasError", $true)
            $this.hasError = $true
        }

        try {
            if ($null -ne $context) {
                $logEntry = [LogEntry]::new($level, $message, $this.CalledFrom, $context, $includeCallStack)
                $jsonEntryJson = $logEntry | ConvertTo-Json -Compress -Depth 100
            }
            else {
                $logEntry = [LogEntry]::new($level, $message, $this.CalledFrom, $null, $includeCallStack)
                $jsonEntryJson = $logEntry | ConvertTo-Json -Compress
            }
        }
        catch {
            $this.CalledFrom = ""
            throw $_
        }

        $this.CalledFrom = ""
        Add-Content -Path $this.LogFilePath -Value $jsonEntryJson -Encoding $this.Encoding -ErrorAction Stop

        if ($this.WriteToHost) {
            switch ($level) {
                "WARNING" { Write-Host $logEntry.ToString() -ForegroundColor Yellow }
                "ERROR" { Write-Host $logEntry.ToString() -ForegroundColor Red }
                "FATAL" { Write-Host $logEntry.ToString() -ForegroundColor Red }
                default { Write-Host $logEntry.ToString() }
            }
        }

        if ($level -eq [Levels]::FATAL) {
            $this.AddToInitialEntry("hasFatal", $true)
            $this.Close()
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
        Add-Content -Path $this.LogFilePath -Value $finalEntryJson -Encoding $this.Encoding -ErrorAction Stop
    }
}

function New-JsonLogger {

    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogFilePath,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$ProgramName,

        [Encodings]$Encoding = [Encodings]::utf8BOM,
        [switch]$Overwrite,
        [switch]$WriteToHost
    )

    <#
    .SYNOPSIS
        Create a new JsonLogger instance and initialize the log file.

    .DESCRIPTION
        Creates and returns an instance of the `JsonLogger` class. If the
        target log file does not exist it will be created. If the file exists
        and is non-empty, you can use `-Overwrite` to force initialization.

    .PARAMETER LogFilePath
        Path to the file to write log entries to.

    .PARAMETER ProgramName
        Friendly program name included in the initial log entry written to
        the first entry of the log.

    .PARAMETER Encoding
        File encoding to use when writing log entries.
        Available:
            ascii, bigendianunicode, oem, unicode, utf7, utf8, utf8BOM, utf8NoBOM, utf32
        Default:
            utf8BOM

    .PARAMETER Overwrite
        If specified, existing log files will be truncated/overwritten.

    .PARAMETER WriteToHost
        If specified, write a human-readable log line to the console using Write-Host.

    .EXAMPLE
        $logger = New-JsonLogger -LogFilePath './testing.log' -ProgramName 'ps-jsonlogger testing'

    .NOTES
        This function is exported by the module.
    #>

    return [JsonLogger]::new($LogFilePath, $ProgramName, $Encoding, $Overwrite, $WriteToHost)
}

Export-ModuleMember -Function New-JsonLogger
