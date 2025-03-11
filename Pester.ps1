# MyScriptWithTests.ps1

# Function Definition
function Add-Numbers {
    param (
        [int]$a,
        [int]$b
    )
    return $a + $b
}

# Pester Tests
Describe "Add-Numbers" {
    It "Should add two numbers correctly" {
        $result = Add-Numbers -a 2 -b 3
        $result | Should -Be 5
    }
}

# Run the tests
Invoke-Pester -ScriptBlock {
    . $MyInvocation.MyCommand.Path
}