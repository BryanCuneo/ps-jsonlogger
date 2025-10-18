Import-Module ps-jsonlogger

New-Logger -Path "./log_levels_part_1.log" -ProgramName "Log Levels Example 1"

Write-Log -Level "INFO" "Info level test"
Write-Log -Level "SUCCESS" "Success level test"
Write-Log -Level "WARNING" "Level test - warning"
Write-Log -Level "ERROR" "Level test - error"
Write-Log -Level "DEBUG" "Level test - debug"
Write-Log -Level "VERBOSE" "Level test - verbose"

Write-Log -Level "FATAL" "For terminating errors, FATAL-level logs will exit the script with 'exit 1'."
Write-Log -Level "DEBUG" "This line will never be logged because the preceeding line exited the program."