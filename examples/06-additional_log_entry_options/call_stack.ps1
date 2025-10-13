Import-Module ps-jsonlogger

function Another-Function {
    Write-Log -Dbg "Full call stack, second function" -WithCallStack
}

function main {
    New-Logger -Path "./call_stack.log" -ProgramName "Including the full call stack."
    Write-Log -Dbg "Full call stack, first function" -WithCallStack

    Another-Function

    Close-Log
}

main