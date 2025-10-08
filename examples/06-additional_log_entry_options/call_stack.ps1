Import-Module ps-jsonlogger

function Second-Function {
    $script:logger.Log("DEBUG", "Full call stack, second function", $true)
}

function main {
    $script:logger.Log("DEBUG", "Full call stack, first function", $true)
    Second-Function
}

$script:logger = New-JsonLogger -LogFilePath "./call_stack.log" -ProgramName "Including the full call stack."
main