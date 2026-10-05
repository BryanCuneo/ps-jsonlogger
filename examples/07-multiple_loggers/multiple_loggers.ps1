# Copyright (c) 2026 Bryan Cuneo

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

Import-Module ps-jsonlogger

function DoSomething {
    Write-Log -Level "INFO" -Message "This will go to the default logger."
}

function DoSomethingDangerous {
    throw "Be careful!"
}

function DoSomethingREALLYDangerous {
    throw "Now you've done it..."
}

function main {
    New-Logger -Path "./multiple_loggers_default.log" -ProgramName "Multiple Loggers Example"
    New-Logger -Path "./multiple_loggers_errors.log" -ProgramName "Multiple Loggers Example" -LoggerName "errors"

    DoSomething

    try {
        DoSomethingDangerous
    }
    catch {
        Write-Log -Logger "errors"-Level "ERROR" -Message "This will go to the errors logger."
    }

    try {
        DoSomethingREALLYDangerous
    }
    catch {
        # If you don't specify -Logger, the default logger will be closed.
        Close-Log -Message "Error encountered. Closing."

        # FATAL errors will both close the associated logger and exit the script.
        Write-Log -Logger "errors" -Level "FATAL" -Message "Whoops..."
    }
}

main