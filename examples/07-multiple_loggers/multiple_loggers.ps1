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