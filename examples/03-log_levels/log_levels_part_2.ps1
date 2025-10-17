Import-Module ps-jsonlogger

New-Logger -Path "./log_levels_part_2.log" -ProgramName "Log Levels Example 2"

Write-Log "If you don't specify a level, INFO is the default"
Write-Log -Level "SUCCESS" "The full level name is always an option"
Write-Log -Level "W" "All levels can be shortened to their first letter"
Write-Log -Level "error" "Level arguments are case-insensitive"
Write-Log -Dbg "Instead of -Level, you can use the per-level parameters"
Write-Log -V "If you want to be REALLY consice, you can also shorten the per-level parameters"

Close-Log