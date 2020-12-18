using module .\internal\helpers.psm1
using module .\internal\datatypes.psm1
using module .\internal\WttLog.psm1

function Test-NICProperties {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]

    param (
        [Parameter(Mandatory=$false,
                   HelpMessage="Enter one or more Network Adapter names as returned by Get-NetAdapter 'Name' Property")]
        [ValidateScript({Get-NetAdapter -Name $_})]
        [string[]] $InterfaceName = '*',

        <#
        [Parameter(Mandatory=$false)]
        [ValidateSet('Base', '10GbE', 'Standard', 'Premium')]
        [string[]] $TestScope = 'Premium',

        [Parameter(Mandatory=$false)]
        [ValidateSet('2019', '2022', 'HCIv1', 'HCIv2')]
        [string[]] $OSVersion = '2022',
        #>

        [Parameter(Mandatory=$false)]
        [string] $ReportPath,

        [Parameter(Mandatory=$false)]
        [PSCredential] $Credential
    )

    Clear-Host

    $global:pass = 'PASS'
    $global:fail = 'FAIL'
    $global:testsFailed = 0

    # Once in the Program Files path, use this:
    # $here = Split-Path -Parent (Get-Module -Name Test-NICProperties -ListAvailable | Select-Object -First 1).Path
    $here = Split-Path -Parent (Get-Module -Name Test-NICProperties | Select-Object -First 1).Path

    # Keep a separate log for easier diagnostics
    $global:Log = New-Item -Name 'Results.log' -Path "$here\Results" -ItemType File -Force
    Start-WTTLog "$here\Results\Results.wtl"
    Start-WTTTest "$here\Results\Results.wtl"

    #TODO: Check that the adapter exists
    $Adapters = Get-NetAdapter -Name $InterfaceName -Physical | Where-Object MediaType -eq '802.3'
    $AdapterAdvancedProperties = Get-NetAdapterAdvancedProperty -Name $InterfaceName -AllProperties
    $NodeOS = Get-CimInstance -ClassName 'Win32_OperatingSystem'

    ### Verify the TestHost is sufficient version
    if (($NodeOS.Caption -like '*Windows Server 2019*') -or
        ($NodeOS.Caption -like '*Windows Server 2022*') -or
        ($NodeOS.Caption -like '*Azure Stack HCI*')) {

        if ($edition.Edition -eq 'ServerAzureStackHCICor' -or $edition.Edition -like '*Server*') { $PassFail = $pass }
        Else { $PassFail = $fail; $testsFailed ++ }
    }

    <# Tests:
    - Existance of required keys per documented requirements
    - Tests the keys are the correct type
    - Tests the keys have the correct default values
    - Tests that enums contains all the right values
    - Tests that enums do not contain extra (unauthorized values)
    - Tests that ints have the correct Base
    - Tests that ints have the correct Max
    - Tests that ints have the correct Min
    - Tests that ints have the correct Step
    #>

    # This is the MSFT definition
    $AdapterDefinition = [AdapterDefinition]::new()

    $Requirements = ([Requirements]::new())
    if     (($OSVersion -eq '2019') -or ($OSVersion -eq 'HCIv1')) { $Requirements = ([Requirements]::new()).WS2019_HCIv1 }
    elseif (($OSVersion -eq '2022') -or ($OSVersion -eq 'HCIv2')) { $Requirements = ([Requirements]::new()).WS2022_HCIv2 }

    $Adapters | ForEach-Object {
        $thisAdapter = $_
        $thisAdapterAdvancedProperties = $AdapterAdvancedProperties | Where-Object Name -eq $thisAdapter.Name

        # This is the configuration from the remote pNIC
        $AdapterConfiguration   = Get-AdvancedRegistryKeyInfo -InterfaceName $thisAdapter.Name -AdapterAdvancedProperties $thisAdapterAdvancedProperties
        $NicSwitchConfiguration = Get-NicSwitchInfo -InterfaceName $thisAdapter.Name

        <#
        # Device.Network.LAN.Base.100MbOrGreater Windows Server Ethernet devices must be able to link at 1Gbps or higher speeds
        if ($thisAdapter.Speed -ge 1000000000) {
          Write-WTTLogMessage "[$Pass] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) RegistryDefaultValue is $($AdapterDefinition.RegistryDefaultValue)"
          "[$Pass] $($thisAdapter.Name) is 1Gbps or higher" | Out-File -FilePath $Log -Append
        }
        else {
          Write-WTTLogError   "[$Fail] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) RegistryDefaultValue is $($AdapterDefinition.RegistryDefaultValue)"
          "[$Fail] $($thisAdapter.Name) is 1Gbps or higher" | Out-File -FilePath $Log -Append

          $testsFailed ++
        }
        #>

        $RequirementsTested = @()
        Switch -Wildcard ($AdapterConfiguration) {

            { $_.RegistryKeyword -eq '*EncapOverhead' } {

                $thisDefinitionPath = $AdapterDefinition.EncapOverhead

                # *EncapOverhead: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapOverhead: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapOverhead: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapOverhead: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                #TODO: Fix MaxValue - Should be between 160 and 480
                # *EncapOverhead: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

                # *EncapOverhead: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrLess

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*EncapsulatedPacketTaskOffloadNvgre' } {

                $thisDefinitionPath = $AdapterDefinition.EncapsulatedPacketTaskOffloadNvgre

                # *EncapsulatedPacketTaskOffloadNvgre: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapsulatedPacketTaskOffloadNvgre: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapsulatedPacketTaskOffloadNvgre: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*EncapsulatedPacketTaskOffloadVxlan' } {

                $thisDefinitionPath = $AdapterDefinition.EncapsulatedPacketTaskOffloadVxlan

                # *EncapsulatedPacketTaskOffloadVxlan: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapsulatedPacketTaskOffloadVxlan: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapsulatedPacketTaskOffloadVxlan: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*FlowControl' } {

                $thisDefinitionPath = $AdapterDefinition.FlowControl

                # *FlowControl: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *FlowControl: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *FlowControl: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*InterruptModeration' } {

                $thisDefinitionPath = $AdapterDefinition.InterruptModeration

                # *InterruptModeration: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *InterruptModeration: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *InterruptModeration: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*JumboPacket' } {

                $thisDefinitionPath = $AdapterDefinition.JumboPacket

                # *JumboPacket: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *JumboPacket: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *JumboPacket: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *JumboPacket: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *JumboPacket: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

                # *JumboPacket: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrLess

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*LsoV2IPv4' } {

                $thisDefinitionPath = $AdapterDefinition.LSO.LSOv2IPV4

                # *LsoV2IPv4: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *LsoV2IPv4: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *LsoV2IPv4: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*LsoV2IPv6' } {

                $thisDefinitionPath = $AdapterDefinition.LSO.LsoV2IPv4

                # *LsoV2IPv6: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *LsoV2IPv6: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *LsoV2IPv6: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*MaxRSSProcessors' } {

                $thisNetAdapterRSS = Get-NetAdapterRSS -Name $thisAdapter.Name | Format-Table *MSIX*
                if ($thisNetAdapterRSS.MsiXEnabled -eq $true -and $thisNetAdapterRSS.MsiXSupported -eq $true) { $MSIXSupport = $true }
                else { $MSIXSupport = $true }

                if     ($thisAdapter.Speed -ge 10000000000) { $AdapterSpeed = '10Gbps' }
                elseif ($thisAdapter.Speed -ge 1000000000)  { $AdapterSpeed = '1Gbps' }
                elseif ($thisAdapter.Speed -ge 100000000)   { $AdapterSpeed = '100Mbps' }

                if ($MSIXSupport -and $AdapterSpeed -eq '10Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.MaxRSSProcessors.MaxRSSProcessors_MSIXSupport_10GbOrGreater
                }
                elseif ($MSIXSupport -and $AdapterSpeed -eq '1Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.MaxRSSProcessors.MaxRSSProcessors_MSIXSupport_1Gb
                }
                elseif (-not($MSIXSupport) -and $AdapterSpeed -eq '10Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.MaxRSSProcessors.MaxRSSProcessors_No_MSIXSupport_10GbOrGreater
                }
                elseif (-not($MSIXSupport) -and $AdapterSpeed -eq '1Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.MaxRSSProcessors.MaxRSSProcessors_No_MSIXSupport_1Gb
                }

                # *MaxRSSProcessors: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *MaxRSSProcessors: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *MaxRSSProcessors: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *MaxRSSProcessors: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *MaxRSSProcessors: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *MaxRSSProcessors: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*NetworkDirect' } {

                $thisDefinitionPath = $AdapterDefinition.NDKPI.NetworkDirect

                # *NetworkDirect: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NetworkDirect: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NetworkDirect: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*NetworkDirectTechnology' } {

                $thisDefinitionPath = $AdapterDefinition.NDKPI.NetworkDirectTechnology

                # *NetworkDirectTechnology: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NetworkDirectTechnology: ValidRegistryValues
                    # As the adapter can choose to support one or more of these types, we will only check that the contained values are within the MSFT defined range
                    # We will not test to ensure that all defined values are found unlike other enums (because an adapter may support both RoCE and RoCEv2 but not iWARP and visa versa)
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*NumaNodeId' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.NumaNodeId

                # *NumaNodeId: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumaNodeId: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumaNodeId: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumaNodeId: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumaNodeId: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumaNodeId: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*NumRSSQueues' } {

                $thisNetAdapterRSS = Get-NetAdapterRSS -Name $thisAdapter.Name | Format-Table *MSIX*
                if ($thisNetAdapterRSS.MsiXEnabled -eq $true -and $thisNetAdapterRSS.MsiXSupported -eq $true) { $MSIXSupport = $true }
                else { $MSIXSupport = $true }

                if     ($thisAdapter.Speed -ge 10000000000) { $AdapterSpeed = '10Gbps' }
                elseif ($thisAdapter.Speed -ge 1000000000)  { $AdapterSpeed = '1Gbps' }
                elseif ($thisAdapter.Speed -ge 100000000)   { $AdapterSpeed = '100Mbps' }

                if ($MSIXSupport -and $AdapterSpeed -eq '10Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.NumRSSQueues.NumRSSQueues_MSIXSupport_10GbOrGreater
                }
                elseif ($MSIXSupport -and $AdapterSpeed -eq '1Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.NumRSSQueues.NumRSSQueues_MSIXSupport_1Gb
                }
                elseif (-not($MSIXSupport) -and $AdapterSpeed -eq '10Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.NumRSSQueues.NumRSSQueues_No_MSIXSupport_10GbOrGreater
                }
                elseif (-not($MSIXSupport) -and $AdapterSpeed -eq '1Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.RSSClass.NumRSSQueues.NumRSSQueues_No_MSIXSupport_1Gb
                }

                # *NumRSSQueues: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumRSSQueues: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumRSSQueues: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumRSSQueues: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumRSSQueues: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumRSSQueues: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*PriorityVLANTag' } {

                $thisDefinitionPath = $AdapterDefinition.PriorityVLANTag

                # *PriorityVLANTag: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *PriorityVLANTag: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *PriorityVLANTag: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*PtpHardwareTimestamp' } {

                $thisDefinitionPath = $AdapterDefinition.PtpHardwareTimestamp

                # *PtpHardwareTimestamp: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *PtpHardwareTimestamp: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *PtpHardwareTimestamp: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*QOS' } {

                $thisDefinitionPath = $AdapterDefinition.QOS

                # *QOS: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *QOS: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *QOS: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*ReceiveBuffers' } {

                $thisDefinitionPath = $AdapterDefinition.Buffers.ReceiveBuffers

                # *ReceiveBuffers: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSCIPv4' } {

                $thisDefinitionPath = $AdapterDefinition.RSC.RSCIPv4

                # *RSCIPv4: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSCIPv4: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSCIPv4: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSCIPv6' } {

                $thisDefinitionPath = $AdapterDefinition.RSC.RSCIPv6

                # *RSCIPv6: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSCIPv6: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSCIPv6: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSS' } {

                # Device.Network.LAN.RSS.RSS - Make sure the requirements from here are checked

                $thisDefinitionPath = $AdapterDefinition.RSSClass.RSS

                # *RSS: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSS: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSS: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSSBaseProcGroup' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.RSSBaseProcGroup

                # *RSSBaseProcGroup: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSBaseProcGroup: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSBaseProcGroup: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSBaseProcGroup: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSBaseProcGroup: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSSBaseProcNumber' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.RSSBaseProcNumber

                # *RSSBaseProcNumber: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSBaseProcNumber: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MaxValue 4

                # *RSSBaseProcNumber: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSBaseProcNumber: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSBaseProcNumber: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RssMaxProcNumber' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.RssMaxProcNumber

                # *RssMaxProcNumber: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSSMaxProcGroup' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.RSSMaxProcGroup

                # *RSSMaxProcGroup: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSMaxProcGroup: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSMaxProcGroup: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSMaxProcGroup: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSMaxProcGroup: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSSOnHostVPorts' } {

                $thisDefinitionPath = $AdapterDefinition.RSSOnHostVPorts

                # *RSSOnHostVPorts: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSOnHostVPorts: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSOnHostVPorts: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RssOrVmqPreference' } {

                $thisDefinitionPath = $AdapterDefinition.VMQClass.RssOrVmqPreference

                # *RssOrVmqPreference: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssOrVmqPreference: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssOrVmqPreference: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSSProfile' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.RSSProfile

                # *RSSProfile: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSProfile: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSProfile: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*SRIOV' } {

                $thisDefinitionPath = $AdapterDefinition.SRIOV

                # *SRIOV: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *SRIOV: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *SRIOV: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # Test NICSwitch Defaults
                Test-NicSwitch -AdvancedRegistryKey $NicSwitchConfiguration -DefinitionPath $AdapterDefinition.NicSwitch

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*TransmitBuffers' } {

                $thisDefinitionPath = $AdapterDefinition.Buffers.TransmitBuffers

                # *TransmitBuffers: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*UsoIPv4' } {

                $thisDefinitionPath = $AdapterDefinition.USO.UsoIPv4

                # *UsoIPv4: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *UsoIPv4: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*UsoIPv6' } {

                $thisDefinitionPath = $AdapterDefinition.USO.UsoIPv6

                # *UsoIPv6: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *UsoIPv6: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq 'VLANID' } {
                # Device.Network.LAN.Base.PriorityVLAN - Since all WS devices must be -ge 1Gbps, they must implement
                # Ethernet devices that implement link speeds of gigabit or greater must implement Priority & VLAN tagging according to the IEEE 802.1q specification.

                $thisDefinitionPath = $AdapterDefinition.VLANID

                # VLANID: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # VLANID: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # VLANID: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # VLANID: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # VLANID: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # VLANID: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*VMQ' } {

                $thisDefinitionPath = $AdapterDefinition.VMQClass.VMQ

                # *VMQ: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VMQ: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VMQ: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*VMQVlanFiltering' } {

                $thisDefinitionPath = $AdapterDefinition.VMQClass.VMQVlanFiltering

                # *VMQVlanFiltering: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VMQVlanFiltering: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VMQVlanFiltering: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*VxlanUDPPortNumber' } {

                $thisDefinitionPath = $AdapterDefinition.VxlanUDPPortNumber

                # *VxlanUDPPortNumber: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VxlanUDPPortNumber: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VxlanUDPPortNumber: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VxlanUDPPortNumber: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VxlanUDPPortNumber: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

                # *VxlanUDPPortNumber: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrLess

                $RequirementsTested += $_.RegistryKeyword

            }
        }
    <#
        $RequirementsTested | ForEach-Object {
            $ThisTestedRequirement = $_.TrimStart('*')

            $Requirements.Base = $Requirements.Base | Where-Object { $_ -ne $ThisTestedRequirement }
            $Requirements.TenGbEOrGreater = $Requirements.TenGbEOrGreater | Where-Object { $_ -ne $ThisTestedRequirement }
            $Requirements.Standard = $Requirements.Standard | Where-Object { $_ -ne $ThisTestedRequirement }
            $Requirements.Premium  = $Requirements.Premium | Where-Object { $_ -ne $ThisTestedRequirement }
        }

        $Certification = 'Fail'

        If     (($Requirements.Premium -eq $Null) -and ($Requirements.Standard -eq $Null)  -and
                ($Requirements.TenGbEOrGreater -eq $Null) -and ($Requirements.Base -eq $Null)) { $Certification = 'Premium' }
        ElseIf (($Requirements.Standard -eq $Null) -and ($Requirements.TenGbEOrGreater -eq $Null) -and ($Requirements.Base -eq $Null)) { $Certification = 'Standard' }
        ElseIf (($Requirements.TenGbEOrGreater -eq $Null) -and ($Requirements.Base -eq $Null)) { $Certification = 'TenGbEOrGreater' }
        ElseIf  ($Requirements.Base -eq $null) { $Certification = 'Base' }
    #>
    }

    Stop-WTTTest
    Stop-WTTLog
}

#TODO: Calculate which capabilities are there and whether they have enough for Standard/Premium
#TODO: Add MSIX RSS Stuff