function Assert-NICValidation {
    <#
    .SYNOPSIS
        Validate-NIC is an add-on module to Validate-DCB that helps to verify the proper configuration of a Network ATC deployed configuration.

    .DESCRIPTION
        Validate-NIC is an add-on module to Validate-DCB that helps to verify the proper configuration of a Network ATC deployed configuration.

        Requirements can be found here:
        https://docs.microsoft.com/en-us/windows-hardware/design/compatibility/whcp-specifications-policies

    .PARAMETER Tests
        The intents on the node to specify

    .PARAMETER ReportPath
        The string path of where to place the reports.  This should point to a folder; not a specific file.

    .EXAMPLE
        Validate-NIC -ConfigFilePath $($PWD.Path)\config\compute.ps1
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]

    param (
        [Parameter(Mandatory=$false)]
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('Rsc', 'NDKPI')]
        [string[]] $Tests = 'All',

        [Parameter(Mandatory=$false)]
        [Parameter(ParameterSetName = 'AQ')]
        [ValidateSet('Base', '10Gb+', 'Standard', 'Premium')]
        [string[]] $Qualification = 'Premium' ,

        [Parameter(Mandatory=$false)]
        [switch] $ResetAdapterDefaults = $false ,

        [Parameter(Mandatory=$false)]
        [string] $ReportPath
    )
    (Get-NetAdapter | Where-Object MediaType -eq '802.3').Name

    Clear-Host

    $here = Split-Path -Parent (Get-Module -Name Validate-NIC -ListAvailable | Select-Object -First 1).Path
    $startTime = Get-Date -format:'yyyyMMdd-HHmmss'

    New-Item -Name 'Results' -Path $here -ItemType Directory -Force

    $cred = & ..\wolfpack.ps1

    write-host "Tests: $Tests"
}

New-Alias -Name 'Validate-NIC' -Value 'Assert-NICValidation' -Force