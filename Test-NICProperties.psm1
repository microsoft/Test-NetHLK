function Test-NICProperties {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]

    param (
        [Parameter(Mandatory=$false)]
        [string[]] $DUT = '*',

        [Parameter(Mandatory=$false)]
        [ValidateSet('Base', '10GbE', 'Standard', 'Premium')]
        [string[]] $TestScope = 'Premium',

        [Parameter(Mandatory=$false)]
        [string] $ReportPath
    )

    Clear-Host
    $startTime = Get-Date -format:'yyyyMMdd-HHmmss'

    $global:pass = '+'
    $global:fail = 'X'
    $global:testsFailed = 0

    # Once in the Program Files path, use this:
    # $here = Split-Path -Parent (Get-Module -Name Test-NICProperties -ListAvailable | Select-Object -First 1).Path
    $here = Split-Path -Parent (Get-Module -Name Test-NICProperties | Select-Object -First 1).Path
    Import-Module $here\internal\helpers.psm1 -force

    # Classes cannot be imported using Import-Module so this must be a ps1
    . $here\internal\datatypes.ps1

    $global:Log = New-Item -Name 'Results.txt' -Path "$here\Results" -ItemType File -Force

    #TODO: Remove this before going live.
    $Credential = . ..\wolfpack.ps1
    $PSSession = New-PSSession -Credential $Credential -ComputerName 'TK5-3WP07R0511'

    if (-not($PSSession)) {
        "[Fatal Error] Could not establish a remote session to the target node" | Out-File -FilePath $Log -Append
        throw '"[Fatal Error] Could not establish a remote session to the target node"'
    }

    # Get the details from the remote adapter
    #TODO: Check that the adapter exists
    $Adapters, $AdapterAdvancedProperties, $NodeOS = Invoke-Command -Session $PSSession -ScriptBlock {
        $Adapters = Get-NetAdapter -Name $using:DUT -Physical | Where-Object MediaType -eq '802.3'
        $AdapterAdvancedProperties = Get-NetAdapterAdvancedProperty -Name $using:DUT -AllProperties
        $NodeOS = Get-CimInstance -ClassName 'Win32_OperatingSystem'

        Return $Adapters, $AdapterAdvancedProperties, $NodeOS
    }



    ### Verify the TestHost is sufficient version
        $caption =  ($NodeOS.Caption -like '*Windows Server 2022*') -or
                    ($NodeOS.Caption -like '*Azure Stack HCI*')

        $caption | Should be $true

    if ($edition.Edition -eq 'ServerAzureStackHCICor' -or $edition.Edition -like '*Server*') { $PassFail = $pass }
    Else { $PassFail = $fail; $testsFailed ++ }

    $testFile = . "$here\tests\unit\unit.tests.ps1"

    if ($testsFailed -eq 0) {
        Write-Host 'Successfully passed all tests' -ForegroundColor Green
    }
    else { Write-Host "Failed $testsFailed tests. Please review the output before continuing" -ForegroundColor Red }
}

#TODO: Calculate which capabilities are there and whether they have enough for Standard/Premium