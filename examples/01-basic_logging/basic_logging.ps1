Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./basic_logging.log" -ProgramName "Basic Logging"
$logger.Log("Hello, World!")