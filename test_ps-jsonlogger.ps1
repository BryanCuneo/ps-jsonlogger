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

Import-Module "./ps-jsonlogger" -Force

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

    Write-Log "Info test 1 - Write-Log `$message (the default level is INFO)"
    Write-Log -Level $level "Info test 2 - Write-Log -Level `$level `$message"
    "Info test 3 - `$message | Write-Log -Level `$level -WithCallStack" | Write-Log -Level $level -WithCallStack
    Write-Log -I "Info test 4 - Write-Log -I `$message -Context `$context" -Context $context
    "Info test 5 - `$message | Write-Log -Info -Context @(`$context, `$string) -WithCallStack" | Write-Log -Info -Context @($context, "additional context here") -WithCallStack
}

function Test-Warning {
    $level = "WARNING"
    $context = [Ctx]::new("Context - WARNING")

    Write-Log -Level $level "Warning test 1 - Write-Log -Level `$level `$message"
    "Warning test 2 - `$message | Write-Log -Level `$level -WithCallStack" | Write-Log -Level $level -WithCallStack
    Write-Log -W "Warning test 3 - Write-Log -W `$message -Context `$context" -Context $context
    "Warning test 4 - `$message | Write-Log -Warning -Context @(`$context, `$string) -WithCallStack" | Write-Log -Warning -Context @($context, "additional context here") -WithCallStack
}

function Test-Error {
    $level = "ERROR"
    $context = [Ctx]::new("Context - ERROR")

    Write-Log -Level $level "Error test 1 - Write-Log -Level `$level `$message"
    "Error test 2 - `$message | Write-Log -Level `$level -WithCallStack" | Write-Log -Level $level -WithCallStack
    Write-Log -E "Error test 3 - Write-Log -E `$message -Context `$context" -Context $context
    "Error test 4 - `$message | Write-Log -Error -Context @(`$context, `$string) -WithCallStack" | Write-Log -Error -Context @($context, "additional context here") -WithCallStack
}

function Test-Debug {
    $level = "DEBUG"
    $context = [Ctx]::new("Context - DEBUG")

    $global:logger.Log($level, "Debug test 1 - Log(`$level, `$message)")
    $global:logger.Log($level, "Debug test 2 - Log(`$level, `$message, `$true)", $true)
    $global:logger.Log($level, "Debug test 3 - Log(`$level, `$message, `$context)", $context)
    $global:logger.Log($level, "Debug test 4 - Log(`$level, `$message, @(`$context, `$string), `$true)", @($context, "additional context here"), $true)
}

function Test-Verbose {
    $level = "VERBOSE"
    $context = [Ctx]::new("Context - VERBOSE")

    $global:logger.Log($level, "Verbose test 1 - Log(`$level, `$message)")
    $global:logger.Log($level, "Verbose test 2 - Log(`$level, `$message, `$true)", $true)
    $global:logger.Log($level, "Verbose test 3 - Log(`$level, `$message, `$context)", $context)
    $global:logger.Log($level, "Verbose test 4 - Log(`$level, `$message, @(`$context, `$string), `$true)", @($context, "additional context here"), $true)
}

function Test-CloseFatal {
    $global:logger.Close("Testing Close() with a message.")
    $global:logger.Log("FATAL", "There was a fatal error. Exiting")
    $global:logger.Log("DEBUG", "This log entry should never be written because the above FATAL entry exits the program.")
}

function main {
    New-Logger `
        -Path "./testing.log" `
        -ProgramName "Test Script for ps-jsonlogger" `
        -Overwrite `
        -WriteToHost

    Test-Info
    Test-Warning
    Test-Error
    # Test-Debug
    # Test-Verbose
    # Test-CloseFatal
}

main