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

Import-Module "../ps-jsonlogger/ps-jsonlogger.psm1" -Force

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
    $level_short = "I"
    $context = [Ctx]::new("Context - INFO")

    Write-Log "Info test 1 - Write-Log `$message (the default level is INFO)"
    Write-Log -Level $level "Info test 2 - Write-Log -Level `"$level`" `$message"
    Write-Log -Inf "Info test 3 - Write-Log -Inf `$message -Context `$context" -Context $context
    "Info test 4 - `$message | Write-Log -Level `"$level_short`" -WithCallStack" | Write-Log -Level $level_short -WithCallStack
    "Info test 5 - `$message | Write-Log -I -Context @(`$context, `$string) -WithCallStack" | Write-Log -I -Context @($context, "additional context here") -WithCallStack
}

function Test-Success {
    $level = "SUCCESS"
    $level_short = "S"
    $context = [Ctx]::new("Context - SUCCESS")

    Write-Log -Level $level "Success test 1 - Write-Log -Level `"$level`" `$message"
    Write-Log -Scs "Success test 2 - Write-Log -Scs `$message -Context `$context" -Context $context
    "Success test 3 - `$message | Write-Log -Level `"$level_short`" -WithCallStack" | Write-Log -Level $level_short -WithCallStack
    "Success test 4 - `$message | Write-Log -S -Context @(`$context, `$string) -WithCallStack" | Write-Log -S -Context @($context, "additional context here") -WithCallStack
}

function Test-Warning {
    $level = "WARNING"
    $level_short = "W"
    $context = [Ctx]::new("Context - WARNING")

    Write-Log -Level $level "Warning test 1 - Write-Log -Level `"$level`" `$message"
    Write-Log -Wrn "Warning test 2 - Write-Log -Wrn `$message -Context `$context" -Context $context
    "Warning test 3 - `$message | Write-Log -Level `"$level_short`" -WithCallStack" | Write-Log -Level $level_short -WithCallStack
    "Warning test 4 - `$message | Write-Log -W -Context @(`$context, `$string) -WithCallStack" | Write-Log -W -Context @($context, "additional context here") -WithCallStack

    $log = @{
        Level   = "W"
        Message = "Warning test 5 - splatting works too"
    }
    Write-Log @log
}

function Test-Error {
    $level = "ERROR"
    $level_short = "E"
    $context = [Ctx]::new("Context - ERROR")

    Write-Log -Level $level "Error test 1 - Write-Log -Level `"$level`" `$message"
    Write-Log -Err "Error test 2 - Write-Log -Err `$message -Context `$context" -Context $context
    "Error test 3 - `$message | Write-Log -Level `"$level_short`" -WithCallStack" | Write-Log -Level $level_short -WithCallStack
    "Error test 4 - `$message | Write-Log -E -Context @(`$context, `$string) -WithCallStack" | Write-Log -E -Context @($context, "additional context here") -WithCallStack
}

function Test-Debug {
    $level = "DEBUG"
    $level_short = "D"
    $context = [Ctx]::new("Context - DEBUG")

    Write-Log -Level $level "Debug test 1 - Write-Log -Level `"$level`" `$message"
    Write-Log -Dbg "Debug test 2 - Write-Log -Dbg `$message -Context `$context" -Context $context
    "Debug test 3 - `$message | Write-Log -Level `"$level_short`" -WithCallStack" | Write-Log -Level $level_short -WithCallStack
    "Debug test 4 - `$message | Write-Log -D -Context @(`$context, `$string) -WithCallStack" | Write-Log -D -Context @($context, "additional context here") -WithCallStack
}

function Test-Verbose {
    $level = "VERBOSE"
    $level_short = "V"
    $context = [Ctx]::new("Context - VERBOSE")

    Write-Log -Level $level "Verbose test 1 - Write-Log -Level `"$level`" `$message"
    Write-Log -Vrb "Verbose test 2 - Write-Log -Vrb `$message -Context `$context" -Context $context
    "Verbose test 3 - `$message | Write-Log -Level `"$level_short`" -WithCallStack" | Write-Log -Level $level_short -WithCallStack
    "Verbose test 4 - `$message | Write-Log -V -Context @(`$context, `$string) -WithCallStack" | Write-Log -V -Context @($context, "additional context here") -WithCallStack
}

function Test-Fatal {
    Write-Log -Level "FATAL" "Fatal test 1 - Write-Log -Level `"FATAL`" `$message"
    Write-Log -Dbg "This log entry should never be written because the above FATAL entry exits the program."
}

function main {
    New-Logger -Path "./out/testing.log" -ProgramName "Test Script for ps-jsonlogger" -Overwrite -WriteToHost
    Test-Info
    Test-Success
    Test-Warning
    Test-Error
    Test-Debug
    Test-Verbose
    # Test-Fatal

    Close-Log

    Write-Host "`nImporting log..." -NoNewline
    $log = Import-Log -Path "./out/testing.log"
    Write-Host " Done" -ForegroundColor Green
    Write-Host $log

    Write-Host "`nConverting log"
    Write-Host " * CSV..." -NoNewline
    Convert-Log -Path "./out/testing.log" -Destination "./out/testing.csv" -ConvertTo "CSV" -Overwrite
    Write-Host " Done" -ForegroundColor Green
    Write-Host " * CLIXML..." -NoNewline
    Convert-Log -Path "./out/testing.log" -Destination "./out/testing.clixml" -ConvertTo "CLIXML" -Overwrite -Encoding "utf8"
    Write-Host " Done" -ForegroundColor Green

}

main