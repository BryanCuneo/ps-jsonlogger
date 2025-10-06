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

    $Global:logger.Log("Info test 1 - Log(`$message)")
    $Global:logger.Log($level, "Info test 2 - Log(`$level, `$message)")
    $Global:logger.Log($level, "Info test 3 - Log(`$level, `$message, `$true)", $true)
    $Global:logger.Log($level, "Info test 4 - Log(`$level, `$message, `$context)", $context)
    $Global:logger.Log($level, "Info test 5 - Log(`$level, `$message, @(`$context, `$string), $true)", @($context, "additional context here"), $true)
}

function Test-Warning {
    $level = "WARNING"
    $context = [Ctx]::new("Context - WARNING")

    $Global:logger.Log($level, "Warning test 1 - Log(`$level, `$message)")
    $Global:logger.Log($level, "Warning test 2 - Log(`$level, `$message, `$true)", $true)
    $Global:logger.Log($level, "Warning test 3 - Log(`$level, `$message, `$context)", $context)
    $Global:logger.Log($level, "Warning test 4 - Log(`$level, `$message, @(`$context, `$string), $true)", @($context, "additional context here"), $true)
}

function Test-Error {
    $level = "ERROR"
    $context = [Ctx]::new("Context - ERROR")

    $Global:logger.Log($level, "Error test 1 - Log(`$level, `$message)")
    $Global:logger.Log($level, "Error test 2 - Log(`$level, `$message, `$true)", $true)
    $Global:logger.Log($level, "Error test 3 - Log(`$level, `$message, `$context)", $context)
    $Global:logger.Log($level, "Error test 4 - Log(`$level, `$message, @(`$context, `$string), $true)", @($context, "additional context here"), $true)
}

function Test-Debug {
    $level = "DEBUG"
    $context = [Ctx]::new("Context - DEBUG")

    $Global:logger.Log($level, "Debug test 1 - Log(`$level, `$message)")
    $Global:logger.Log($level, "Debug test 2 - Log(`$level, `$message, `$true)", $true)
    $Global:logger.Log($level, "Debug test 3 - Log(`$level, `$message, `$context)", $context)
    $Global:logger.Log($level, "Debug test 4 - Log(`$level, `$message, @(`$context, `$string), $true)", @($context, "additional context here"), $true)
}

function Test-Verbose {
    $level = "VERBOSE"
    $context = [Ctx]::new("Context - VERBOSE")

    $Global:logger.Log($level, "Verbose test 1 - Log(`$level, `$message)")
    $Global:logger.Log($level, "Verbose test 2 - Log(`$level, `$message, `$true)", $true)
    $Global:logger.Log($level, "Verbose test 3 - Log(`$level, `$message, `$context)", $context)
    $Global:logger.Log($level, "Verbose test 4 - Log(`$level, `$message, @(`$context, `$string), $true)", @($context, "additional context here"), $true)
}

function main {
    $Global:logger = New-JsonLogger `
        -LogFilePath "./testing.log" `
        -ProgramName "ps-jsonlogger testing" `
        -Overwrite `
        -WriteToHost

    Test-Info
    Test-Warning
    Test-Error
    Test-Debug
    Test-Verbose
}

main