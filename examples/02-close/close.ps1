Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./close.log" -ProgramName "close.log"
$logger.Log("Hello, World!")
$logger.Close()