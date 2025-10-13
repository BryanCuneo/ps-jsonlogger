Import-Module ps-jsonlogger

New-Logger -Path "./basic_logging.log" -ProgramName "Basic Logging Example"
Write-Log "Hello, World!"