enum Levels {
    INFO
    WARNING
    ERROR
    DEBUG
    VERBOSE
}

class LogEntry {
    [string]$timestamp = (Get-Date).ToString("o")
    [string]$level
    [string]$message

    # PS has no constructor chaining, so we use hidden init functions instead
    hidden init([Levels]$level, [string]$message, [string]$calledFrom) { $this.Init($level, $message, $calledFrom, $false, $null) }
    hidden init([Levels]$level, [string]$message, [string]$calledFrom, [object]$context) { $this.Init($level, $message, $calledFrom, $false, $context) }
    hidden init([Levels]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack) { $this.Init($level, $message, $calledFrom, $includeCallStack, $null) }
    hidden init([Levels]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack, [object]$context) {
        $this.level = [Levels].GetEnumName($level)
        $this.message = $message

        if ($null -ne $context) {
            $this | Add-Member -MemberType NoteProperty -Name "context" -Value $context
        }

        $this | Add-Member -MemberType NoteProperty -Name "calledFrom" -Value $calledFrom

        if ($this.level -eq [Levels]::VERBOSE -or $includeCallStack) {
            $this | Add-Member -MemberType NoteProperty -Name "callStack" -Value ([string](Get-PSCallStack))
        }
    }

    LogEntry([Levels]$level, [string]$message, [string]$calledFrom) {
        $this.Init($level, $message, $calledFrom)
    }
    LogEntry([Levels]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack) {
        $this.Init($level, $message, $calledFrom, $includeCallStack)
    }
    LogEntry([Levels]$level, [string]$message, [string]$calledFrom, [object]$obj) {
        $this.Init($level, $message, $calledFrom, $obj)
    }
    LogEntry([Levels]$level, [string]$message, [string]$calledFrom, [switch]$includeCallStack, [object]$obj) {
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

    # Because we use "constructor chaining" and chained calls to Log(), we
    # have to keep track of the function that called Log() in a variable here
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

    [void] Log([Levels]$level, [string]$message) {
        $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        $this.Log([Levels]$level, $message, $null)
    }

    [void] Log([Levels]$level, [string]$message, [object]$callStackOrContext) {
        if ([string]::IsNullOrEmpty($this.CalledFrom)) {
            $this.CalledFrom = (Get-PSCallStack)[1].ToString()
        }

        if ($null -eq $callStackOrContext -or $callStackOrContext.GetType().Name -ne "Boolean") {
            # Context object found
            $this.Log($level, $message, $false, $callStackOrContext)
        }
        else {
            # includeCallStack boolean found
            $this.Log($level, $message, $callStackOrContext, $null)
        }
    }

    [void] Log([Levels]$level, [string]$message, [switch]$includeCallStack, [object]$context) {

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

        if ($null -ne $context) {
            $logEntry = [LogEntry]::new($level, $message, $this.CalledFrom, $includeCallStack, $context)
            $jsonEntryJson = $logEntry | ConvertTo-Json -Compress -Depth 100
        }
        else {
            $logEntry = [LogEntry]::new($level, $message, $this.CalledFrom, $includeCallStack)
            $jsonEntryJson = $logEntry | ConvertTo-Json -Compress
        }

        $this.CalledFrom = ""
        Add-Content -Path $this.LogFilePath -Value $jsonEntryJson -ErrorAction Stop
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
