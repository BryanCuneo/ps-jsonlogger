Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./log_levels.log" -ProgramName "Log Levels"

$logger.Log("Hello, World!")
$logger.Log("INFO", "Info level test")
$logger.Log("WARNING", "Level test - warning")
$logger.Log("ERROR", "Level test - error")
$logger.Log("DEBUG", "Level test - debug")
$logger.Log("VERBOSE", "Level test - verbose")

$logger.Close("You can call Close() with an optional message like this")
$logger.Log("FATAL", "For terminating errors, FATAL logs will exit the script with 'exit 1'.")
$logger.Log("DEBUG", "This line will never be logged, because the preceeding line exited the program.")