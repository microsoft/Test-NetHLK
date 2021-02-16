$DataFile   = Import-PowerShellDataFile .\$($env:repoName).psd1 -ErrorAction SilentlyContinue
$TestModule = Test-ModuleManifest       .\$($env:repoName).psd1 -ErrorAction SilentlyContinue

Describe "$($env:APPVEYOR_BUILD_FOLDER)-Manifest" {
    Context Validation {
        It "[Import-PowerShellDataFile] - $($env:repoName).psd1 is a valid PowerShell Data File" {
            $DataFile | Should Not BeNullOrEmpty
        }

        It "[Test-ModuleManifest] - $($env:repoName).psd1 should pass the basic test" {
            $TestModule | Should Not BeNullOrEmpty
        }

        Import-Module .\$($env:repoName).psd1 -ErrorAction SilentlyContinue
        $Module = Get-Module $($env:repoName) -ErrorAction SilentlyContinue

        'Test-NICAdvancedProperties', 'Test-SwitchCapability' | ForEach-Object {
            It "Should have an available command: $_" {
                $module.ExportedCommands.ContainsKey($_) | Should be $true
            }
        }

        It "Should have an available alias: Test-NICProperties" {
            $module.ExportedAliases.ContainsKey('Test-NICProperties') | Should be $true
        }

        It "Should have an reference command: Test-NICAdvancedProperties" {
            $module.ExportedAliases.'Test-NICProperties'.ReferencedCommand.Name | Should be 'Test-NICAdvancedProperties'
        }

        It "Should have an required module of: DataCenterBridging" {
            $module.RequiredModules | Should be 'DataCenterBridging'
        }

        $requiredModule = Find-Module DataCenterBridging -ErrorAction SilentlyContinue
        It "Should list required modules (DataCenterBridging) on the PowerShell Gallery" {
            if ($requiredModule) { $true | Should be $true }
            else { $false | Should be $true }
            
        }
    }
}
