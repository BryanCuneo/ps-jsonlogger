Import-Module ps-jsonlogger

function main {
    $logger = New-JsonLogger -LogFilePath "./called_from_function.log" -ProgramName "Called From Function Test"
    $logger.Log("Check out the 'calledFrom' attribute of this log entry!")
}

main