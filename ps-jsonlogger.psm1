enum Levels {
    INFO
    WARN
    ERR
    DEBUG
    VERBOSE
}

class LogEntry {
    $timestamp = (Get-Date).ToString("o")

    [ValidateSet("INFO", "WARN", "ERR", "DEBUG", "VERBOSE")]
    [string]$level

    [string]$message
    [string]$calledFrom

    # PS has no constructor chaining, so we use hidden init functions instead
    hidden init([string]$level, [string]$message, [string]$calledFrom) { $this.Init($level, $message, $calledFrom, $false, $null) }
    hidden init([string]$level, [string]$message, [string]$calledFrom, [object]$contextObject) { $this.Init($level, $message, $calledFrom, $false, $contextObject) }
    hidden init([string]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack) { $this.Init($level, $message, $calledFrom, $includeCallStack, $null) }
    hidden init([string]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack, [object]$contextObject) {
        $this.level = $level
        $this.message = $message
        $this.calledFrom = $calledFrom

        if ($null -ne $contextObject) {
            $this | Add-Member -MemberType NoteProperty -Name "contextObject" -Value $contextObject
        }

        if ($this.level -like [Levels]::VERBOSE -or $includeCallStack) {
            $this | Add-Member -MemberType NoteProperty -Name "callStack" -Value ([string](Get-PSCallStack))
        }
    }

    LogEntry([string]$level, [string]$message, [string]$calledFrom) {
        $this.Init($level, $message, $calledFrom)
    }
    LogEntry([string]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack) {
        $this.Init($level, $message, $calledFrom, $includeCallStack)
    }
    LogEntry([string]$level, [string]$message, [string]$calledFrom, [object]$obj) {
        $this.Init($level, $message, $calledFrom, $obj)
    }
    LogEntry([string]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack, [object]$obj) {
        $this.Init($level, $message, $calledFrom, $includeCallStack, $obj)
    }
}

class JsonLogger {
    [ValidateSet("ascii", "bigendianunicode", "oem", "unicode", "utf7", "utf8", "utf8BOM", "utf8NoBOM", "utf32")]
    [string]$Encoding

    [switch]$Overwrite
    [string]$LogFilePath
    [string]$ProgramName

    [string]$JsonLoggerVersion = "0.0.1-alpha"

    [string]$CalledFrom

    JsonLogger([string]$logFilePath, [string]$encoding = "utf8BOM", [switch]$overwrite = $false, [string]$programName) {
        $this.Encoding = $encoding
        $this.Overwrite = $overwrite
        $this.LogFilePath = $logFilePath

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
            ProgramName       = $programName
            StartTime         = (Get-Date).ToString("o")
            JsonLoggerVersion = $this.JsonLoggerVersion
        }
        try {
            $initialEntryJson = $initialEntry | ConvertTo-Json -Compress
            Add-Content -Path $this.LogFilePath -Value $initialEntryJson -Encoding $this.Encoding
        }
        catch {
            throw "Failed to convert initial log entry to JSON: $_"
        }
    }

    [void] Log([string]$level, [string]$message, [switch]$includeCallStack, [object]$contextObject) {

        if ([string]::IsNullOrEmpty($this.CalledFrom)) {
            $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        }

        if ($null -eq $message -or $message.Trim() -eq "") {
            $this.CalledFrom = ""
            throw "Message cannot be null or empty."
        }

        if ($null -ne $contextObject) {
            $logEntry = [LogEntry]::new($level, $message, $this.CalledFrom, $includeCallStack, $contextObject)
            $jsonEntryJson = $logEntry | ConvertTo-Json -Compress -Depth 100
        }
        else {
            $logEntry = [LogEntry]::new($level, $message, $this.CalledFrom, $includeCallStack)
            $jsonEntryJson = $logEntry | ConvertTo-Json -Compress
        }

        $this.CalledFrom = ""
        Add-Content -Path $this.LogFilePath -Value $jsonEntryJson
    }

    [void] Log([string]$level, [string]$message) {
        $this.CalledFrom = (Get-PSCallStack)[1].ToString()

        $this.Log([string]$level, $message, $null)
    }

    [void] Log([string]$level, [string]$message, [object]$callStackOrContext) {
        if ([string]::IsNullOrEmpty($this.CalledFrom)) {
            $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        }

        if ($null -eq $callStackOrContext -or $callStackOrContext.GetType().Name -ne "Boolean") {
            # [object]contextObject
            $this.Log($level, $message, $false, $callStackOrContext)
        }
        elseif ($callStackOrContext.GetType().Name -eq "Boolean") {
            # [switch]$includeCallStack
            $this.Log($level, $message, $callStackOrContext, $null)
        }

    }
}

function New-JsonLogger {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("ascii", "bigendianunicode", "oem", "unicode", "utf7", "utf8", "utf8BOM", "utf8NoBOM", "utf32")]
        [string]$Encoding = "utf8BOM",

        [Parameter(Mandatory = $false)]
        [switch]$Overwrite = $false,

        [Parameter(Mandatory = $true)]
        [string]$ProgramName
    )

    return [JsonLogger]::new($LogFilePath, $Encoding, $Overwrite, $ProgramName)
}

Export-ModuleMember -Function New-JsonLogger
