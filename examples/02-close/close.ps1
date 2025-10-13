Import-Module ps-jsonlogger

New-Logger -Path "./close.log" -ProgramName "Close-Log Example"
Write-Log "Hello, World!"
Close-Log "Goodbye, Cruel World!"