Import-Module "../ps-jsonlogger.psm1" -Force

class Ctx {
    [string]$Name
    [object]$Obj

    Ctx([string]$name) {
        $this.Name = $name
        $this.Obj = [ordered]@{
            Id    = (Get-Random -Maximum 10)
            Value = (Get-Random -Maximum 1000).ToString()
        }
    }
}

function Test-Info {
    $level = "INFO"
    $context = [Ctx]::new("Context - INFO")

    $Global:logger.Log($level, "Test 1 - INFO")
    $Global:logger.Log($level, "Test 2 - INFO", $true)
    $Global:logger.Log($level, "Test 3 - INFO", $context)
    $Global:logger.Log($level, "Test 4 - INFO", $true, $context)
}

function Test-Warning {
    $level = "WARNING"
    $context = [Ctx]::new("Context - WARNING")

    $Global:logger.Log($level, "Test 1 - WARNING")
    $Global:logger.Log($level, "Test 2 - WARNING", $true)
    $Global:logger.Log($level, "Test 3 - WARNING", $context)
    $Global:logger.Log($level, "Test 4 - WARNING", $true, $context)
}

function Test-Error {
    $level = "ERROR"
    $context = [Ctx]::new("Context - ERROR")

    $Global:logger.Log($level, "Test 1 - ERROR")
    $Global:logger.Log($level, "Test 2 - ERROR", $true)
    $Global:logger.Log($level, "Test 3 - ERROR", $context)
    $Global:logger.Log($level, "Test 4 - ERROR", $true, $context)
}

function Test-Debug {
    $level = "DEBUG"
    $context = [Ctx]::new("Context - DEBUG")

    $Global:logger.Log($level, "Test 1 - DEBUG")
    $Global:logger.Log($level, "Test 2 - DEBUG", $true)
    $Global:logger.Log($level, "Test 3 - DEBUG", $context)
    $Global:logger.Log($level, "Test 4 - DEBUG", $true, $context)
}

function Test-Verbose {
    $level = "VERBOSE"
    $context = [Ctx]::new("Context - VERBOSE")

    $Global:logger.Log($level, "Test 1 - VERBOSE")
    $Global:logger.Log($level, "Test 2 - VERBOSE", $true)
    $Global:logger.Log($level, "Test 3 - VERBOSE", $context)
    $Global:logger.Log($level, "Test 4 - VERBOSE", $true, $context)
}

function main {
    $Global:logger = New-JsonLogger `
        -LogFilePath "./testing.log" `
        -Overwrite `
        -ProgramName "ps-jsonlogger testing"

    Test-Info
    Test-Warning
    Test-Error
    Test-Debug
    Test-Verbose
}

main