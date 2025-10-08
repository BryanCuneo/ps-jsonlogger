Import-Module ps-jsonlogger

class Ctx {
    [string]$Name
    [object]$NestedObj1
    [object]$NestedObj2

    Ctx([string]$name) {
        $this.Name = $name
        $this.NestedObj1 = [ordered]@{
            Id    = 1
            Value = "Nested object 1"
        }
        $this.NestedObj2 = [ordered]@{
            Id    = 2
            Value = "Nested object 2"
        }
    }
}

function main {
    $level = "DEBUG"
    $context = [Ctx]::new("Sample Context Object")

    $script:logger.Log($level, "Current object state", $context)
}

$script:logger = New-JsonLogger -LogFilePath "./context_object.log" -ProgramName "Context Object Test"
main