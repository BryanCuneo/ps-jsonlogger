Import-Module ps-jsonlogger

function main {
    New-Logger -Path "./called_within_function.log" -ProgramName "Called Within Function Example"
    Write-Log "Check out the 'calledFrom' attribute of this log entry!"
    Close-Log
}

main