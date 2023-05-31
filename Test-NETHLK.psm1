using module .\internal\helpers.psm1
using module .\internal\datatypes.psm1
using assembly .\internal\Microsoft.WTT.Log.dll
using module .\internal\WttLog.psm1
# using module DataCenterBridging

# Updated as of 2305
function Test-NICAdvancedProperties {
    <#
    .SYNOPSIS
    This module performs strict parameter validation of advanced registry keys and switch validation for Azure Stack HCI devices.

    .DESCRIPTION
    Advanced registry keys are administrator controls for NIC properties. This module validates that those advanced properties
    follow the defined specification by Microsoft, validating that each key is of an appropriate type and accepts valid values.

    Additionally, this module performs validation of Azure Stack HCI switch requirements. These requirements are listed here:
    https://docs.microsoft.com/en-us/azure-stack/hci/concepts/physical-network-requirements

    This module is intended to be run through the automated Hardware Lab Kit (HLK) device tests for NICs or switches

    The following NIC tests are performed:
    - Tests the keys are the correct type (enum or int of 1-byte, 2-bytes, 3-bytes, or 4-bytes)
    - Tests the keys have the correct default values
    - Tests that enums contains all the right values
    - Tests that enums do not contain unauthorized values
    - Tests that ints have the correct Base
    - Tests that ints have the correct Max
    - Tests that ints have the correct Min
    - Tests that ints have the correct Step
    - Not Implemented Yet: Existance of required keys per documented requirements

    The following NicSwitch tests are performed
    - Tests the Name, Flags, SwitchType, SwitchId
    - Tests the min number of VFs

    The following NDIS tests are performed:
    - Tests that the minimum NDIS version is used for that OS and adapter

    .EXAMPLE Test NIC Advanced Properties on pNIC01
    Test-NICAdvancedProperties -InterfaceName 'pNIC01'

    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='Default', HelpMessage="Enter one or more Network Adapter names as returned by Get-NetAdapter 'Name' Property")]
        [ValidateScript({Get-NetAdapter -Name $_})]
        [string[]] $InterfaceName = '*',

        # This is required for HLK Integration
        [Parameter(Mandatory=$false, ParameterSetName='HLK')]
        [string[]] $HLKNetworkAdapterName
    )

    Clear-Host

    $global:pass = 'PASS'
    $global:fail = 'FAIL'
    $global:testsFailed = 0

    # Once in the Program Files path, use this:
    # $here = Split-Path -Parent (Get-Module -Name Test-NETHLK -ListAvailable | Select-Object -First 1).Path
    $here = Split-Path -Parent (Get-Module -Name Test-NETHLK | Select-Object -First 1).Path

    # Keep a separate log for easier diagnostics
    $global:Log = New-Item -Name 'Results.log' -Path "$here\Results" -ItemType File -Force
    Start-WTTLog  "$here\Results\Results.wtl"
    Start-WTTTest "$here\Results\Results.wtl"

    # Certain key defaults are dependent on client vs server.
    $NodeOS = Get-CimInstance -ClassName 'Win32_OperatingSystem'
    if (($NodeOS.Caption -like '*Windows Server 2019*') -or
        ($NodeOS.Caption -like '*Windows Server 202*') -or
        ($NodeOS.Caption -like '*Azure Stack HCI*')) { $SUTType = 'Server' }
    elseif ($NodeOS.Caption -like '*Windows 10*') {$SUTType = 'Client'}
    else {
        # Test version of the system being tested. Fail and do not move on if this could not be determined.
        Write-WTTLogError "The system type (Client or Server) could not be determined. Ensure the machine is either WS2019, WS2022, Azure Stack HCI, or Windows 10. Caption detected: $($NodeOS.Caption)"
        "The system type (Client or Server) could not be determined. Ensure the machine is either WS2019, WS2022, Azure Stack HCI, or Windows 10. Caption detected: $($NodeOS.Caption)" | Out-File -FilePath $Log -Append

        Stop-WTTTest
        Stop-WTTLog

        throw
    }

    # This is required for HLK integration
    if ($HLKNetworkAdapterName) {
        $Adapters = Get-NetAdapter -Physical | Where-Object { $_.MediaType -eq '802.3' -and $_.DeviceID -like "*$HLKNetworkAdapterName*" }

        if (-not($Adapters)) {
            Write-WTTLogError "The system could not find the adapter with DeviceID: $HLKNetworkAdapterName"
            "The system could not find the adapter with DeviceID: $HLKNetworkAdapterName" | Out-File -FilePath $Log -Append

            Stop-WTTTest
            Stop-WTTLog

            throw
        }
    }
    else {
        $Adapters = Get-NetAdapter -Name $InterfaceName -Physical | Where-Object MediaType -eq '802.3'

        if (-not($Adapters)) {
            Write-WTTLogError "The system could not find the adapter named: $InterfaceName"
            "The system could not find the adapter named: $InterfaceName" | Out-File -FilePath $Log -Append

            Stop-WTTTest
            Stop-WTTLog

            throw
        }
    }

    $AdapterAdvancedProperties = Get-NetAdapterAdvancedProperty -Name $InterfaceName -AllProperties

    # This is the MSFT definition
    $AdapterDefinition = [AdapterDefinition]::new()

    # Test NDIS Version to ensure it meets the minumum required
    if     ( $NodeOS.BuildNumber -ge '20350' ) { $NDISDefinition = $AdapterDefinition.NDIS.WS2025  }
    elseif ( $NodeOS.BuildNumber -eq '20348' -or $NodeOS.BuildNumber -eq '20349' ) { $NDISDefinition = $AdapterDefinition.NDIS.WS2022  }
    elseif ( $NodeOS.BuildNumber -eq '17763' -or $NodeOS.BuildNumber -eq '17784' ) { $NDISDefinition = $AdapterDefinition.NDIS.WS2019  }
    else   {
        Write-WTTLogError "[$FAIL] Fatal Exception. Build Number could not be identified. Build Number detected: $($NodeOS.BuildNumber)"
        "[$FAIL] Fatal Exception. Build Number could not be identified. Build Number detected: $($NodeOS.BuildNumber)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    $Adapters | ForEach-Object {
        $thisAdapter = $_
        $thisAdapterAdvancedProperties = $AdapterAdvancedProperties | Where-Object Name -eq $thisAdapter.Name

        # This is the configuration from the remote pNIC
        $AdapterConfiguration   = Get-AdvancedRegistryKeyInfo -InterfaceName $thisAdapter.Name -AdapterAdvancedProperties $thisAdapterAdvancedProperties
        $NicSwitchConfiguration = Get-NicSwitchInfo -InterfaceName $thisAdapter.Name -ErrorAction SilentlyContinue

        # Test Minimum Required NDIS Version
        $NDISInfo = (Get-NetAdapter -Name $thisAdapter.Name).NDISVersion
        [Bool] $TestedOSVersion = Test-OSVersion -DefinitionPath $NDISDefinition -ConfigurationData $NDISInfo -OrGreater

        if ($TestedOSVersion) {
            Write-WTTLogMessage "[$PASS] The in use NDIS version for adapter $($thisAdapter.Name) was greater than or equal to the version required for this OS (Required Version: $NDISDefinition)"
            "[$PASS] The in use NDIS version for adapter $($thisAdapter.Name) was greater than or equal to the version required for this OS (Required Version: $NDISDefinition)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
        else {
            Write-WTTLogError "[$FAIL] The in use NDIS version for adapter $($thisAdapter.Name) was below the required versionfor this OS (Required: $NDISDefinition; Actual: $NDISInfo)"
            "[$FAIL] The in use NDIS version for adapter $($thisAdapter.Name) was below the required versionfor this OS (Required: $NDISDefinition; Actual: $NDISInfo)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }

        Remove-Variable NDISDefinition -ErrorAction SilentlyContinue

        # This is required for determination of MSIX Queues for RSS Settings.
        if     ($thisAdapter.Speed -ge 10000000000) { $AdapterSpeed = '10Gbps' }
        elseif ($thisAdapter.Speed -ge 1000000000)  { $AdapterSpeed = '1Gbps' }
        elseif ($thisAdapter.Speed -ge 100000000)   { $AdapterSpeed = '100Mbps' }
        else {
            Write-WTTLogError "[$FAIL] The link speed for adapter $InterfaceName is invalid($($thisAdapter.Speed) bps)"
            "[$FAIL] The link speed for adapter $InterfaceName is invalid($($thisAdapter.Speed) bps)" | Out-File -FilePath $Log -Append
        }

        $RequiredKeys       = @()
        $RequirementsTested = @()

        Switch -Wildcard ($AdapterConfiguration | Sort-Object RegistryKeyword) {

            {$_.RegistryKeyword} { $thisDefinitionPath = @() }

            { $_.RegistryKeyword -eq '*EncapOverhead' } {

                $thisDefinitionPath = $AdapterDefinition.EncapOverhead

                # *EncapOverhead: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapOverhead: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MaxValue

                # *EncapOverhead: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapOverhead: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *EncapOverhead: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

                # *EncapOverhead: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

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

                if     ($SUTType -eq 'Server') { $thisDefinitionPath = $AdapterDefinition.FlowControl.FlowControl_Server }
                elseif ($SUTType -eq 'Client') { $thisDefinitionPath = $AdapterDefinition.FlowControl.FlowControl_Client }

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
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

                # *MaxRSSProcessors: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

                # *MaxRSSProcessors: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *MaxRSSProcessors: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *MaxRSSProcessors: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

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

                if     ( $NodeOS.BuildNumber -ge '20350' ) { $RequiredKeys += '*NetworkDirectTechnology', '*NetworkDirectRoCEFrameSize'  }
                elseif ( $NodeOS.BuildNumber -ge '20348' ) { $RequiredKeys += '*NetworkDirectTechnology'  }

            }

            { $_.RegistryKeyword -eq '*NetworkDirectTechnology' } {

                $thisDefinitionPath = $AdapterDefinition.NDKPI.NetworkDirectTechnology

                # *NetworkDirectTechnology: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NetworkDirectTechnology: ValidRegistryValues
                    # As the adapter can choose to support one or more of these types, we will only check that the contained values are within the MSFT defined range
                    # We will not test to ensure that all defined values are found unlike other enums (because an adapter may support both RoCE and RoCEv2 but not iWARP and visa versa)
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NetworkDirectTechnology: RegistryDefaultValue - This test must go after the others to ensure the ValidRegistryValues exist and have been tested
                # Establish adapter defaults based on the supported adapter values.
                if     ([int] 1 -in $_.ValidRegistryValues) { $thisDefinitionPath | Add-Member -NotePropertyName DefaultRegistryValue -NotePropertyValue 1 }
                elseif ([int] 4 -in $_.ValidRegistryValues) { $thisDefinitionPath | Add-Member -NotePropertyName DefaultRegistryValue -NotePropertyValue 4 }
                elseif ([int] 3 -in $_.ValidRegistryValues) { $thisDefinitionPath | Add-Member -NotePropertyName DefaultRegistryValue -NotePropertyValue 3 }
                elseif ([int] 2 -in $_.ValidRegistryValues) { $thisDefinitionPath | Add-Member -NotePropertyName DefaultRegistryValue -NotePropertyValue 2 }

                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*NetworkDirectRoCEFrameSize' } {

                $thisDefinitionPath = $AdapterDefinition.NDKPI.NetworkDirectRoCEFrameSize

                # *NetworkDirectRoCEFrameSize: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NetworkDirectRoCEFrameSize: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NetworkDirectRoCEFrameSize: ValidRegistryValues
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*NumaNodeId' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.NumaNodeId

                # *NumaNodeId: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumaNodeId: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

                # *NumRSSQueues: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

                # *NumRSSQueues: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumRSSQueues: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *NumRSSQueues: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrGreater

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

            { $_.RegistryKeyword -eq '*QosOffload' } {

                $thisDefinitionPath = $AdapterDefinition.QosOffload

                # *QosOffload: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *QosOffload: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *QosOffload: ValidRegistryValues
                Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath
                Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*ReceiveBuffers' } {

                $thisDefinitionPath = $AdapterDefinition.Buffers.ReceiveBuffers

                # *ReceiveBuffers: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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
                # Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

                # *RssMaxProcNumber: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: NumericParameterMaxValue
                # Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RssMaxProcNumber: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*RSSMaxProcGroup' } {

                $thisDefinitionPath = $AdapterDefinition.RSSClass.RSSMaxProcGroup

                # *RSSMaxProcGroup: RegistryDefaultValue
                Test-DefaultRegistryValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *RSSMaxProcGroup: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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

            { $_.RegistryKeyword -eq '*SpeedDuplex' } {

                $thisDefinitionPath = $AdapterDefinition.SpeedDuplex

                # *SpeedDuplex: RegistryDefaultValue
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

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

                if ($AdapterSpeed -eq '1Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.NicSwitch.NicSwitch_1GbOrGreater
                }
                elseif ($AdapterSpeed -eq '10Gbps') {
                    $thisDefinitionPath = $AdapterDefinition.NicSwitch.NicSwitch_10GbOrGreater
                }

                # Test NICSwitch Defaults
                Test-NicSwitch -AdvancedRegistryKey $NicSwitchConfiguration -DefinitionPath $thisDefinitionPath

                $RequirementsTested += $_.RegistryKeyword

            }

            { $_.RegistryKeyword -eq '*TransmitBuffers' } {

                $thisDefinitionPath = $AdapterDefinition.Buffers.TransmitBuffers

                # *TransmitBuffers: DisplayParameterType
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

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
                Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -MinValue

                # *VxlanUDPPortNumber: NumericParameterBaseValue
                Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VxlanUDPPortNumber: NumericParameterStepValue
                Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VxlanUDPPortNumber: NumericParameterMaxValue
                Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath

                # *VxlanUDPPortNumber: NumericParameterMinValue
                Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $thisDefinitionPath -OrLess

                $RequirementsTested += $_.RegistryKeyword

            }
        }

        $RequiredKeys | Foreach-Object {
            $thisRequiredKey = $_

            if ($thisRequiredKey -notin $RequirementsTested) {
                Write-WTTLogError "[$FAIL] The required key $thisRequiredKey was not found"
                "[$FAIL] The required key $thisRequiredKey was not found" | Out-File -FilePath $Log -Append
                $testsFailed ++
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

New-Alias -Name 'Test-NICProperties' -Value 'Test-NICAdvancedProperties'
