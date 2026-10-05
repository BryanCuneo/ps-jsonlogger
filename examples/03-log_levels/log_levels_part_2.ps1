# Copyright (c) 2026 Bryan Cuneo

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

Import-Module ps-jsonlogger

New-Logger -Path "./log_levels_part_2.log" -ProgramName "Log Levels Example 2"

Write-Log "If you don't specify a level, INFO is the default"
Write-Log -Level "SUCCESS" "The full level name is always an option"
Write-Log -Level "W" "All levels can be shortened to their first letter"
Write-Log -Level "error" "Level arguments are case-insensitive"
Write-Log -Dbg "Instead of -Level, you can use the per-level parameters"
Write-Log -V "If you want to be REALLY consice, you can also shorten the per-level parameters"

Close-Log