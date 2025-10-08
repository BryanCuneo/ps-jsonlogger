Import-Module ps-jsonlogger

$logger = New-JsonLogger -LogFilePath "./called_outside_function.log" -ProgramName "Called Outside Function Test"
$logger.Log("Check out the 'calledFrom' attribute of this log entry!")
