Import-Module ps-jsonlogger

New-Logger -Path "./called_outside_function.log" -ProgramName "Called Outside Function Example"
Write-Log "Check out the 'calledFrom' attribute of this log entry!"
Close-Log