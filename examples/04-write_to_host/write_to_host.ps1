Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./write_to_host.log" -ProgramName "Write to Host" -WriteToHost

$logger.Log("Hello, World!")
$logger.Log("INFO", "Info level test")
$logger.Log("WARNING", "Level test - warning")
$logger.Log("ERROR", "Level test - error")
$logger.Log("DEBUG", "Level test - debug")
$logger.Log("VERBOSE", "Level test - verbose")

$logger.Log("FATAL", "For terminating errors, FATAL logs will exit the script with 'exit 1'.")
$logger.Log("DEBUG", "This line will never be logged, because the preceeding line exited the program.")