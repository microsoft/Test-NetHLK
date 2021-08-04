using module .\internal\helpers.psm1
using module .\internal\datatypes.psm1
using assembly .\internal\Microsoft.WTT.Log.dll
using module .\internal\WttLog.psm1
using module DataCenterBridging

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

    $NodeOS = Get-CimInstance -ClassName 'Win32_OperatingSystem'
    $OSDisplayVersion = (Get-ComputerInfo -Property OSDisplayVersion).OSDisplayVersion

    if (($NodeOS.Caption -like '*Windows Server 2019*') -or
        ($NodeOS.Caption -like '*Windows Server 2022*') -or
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
    if     ($NodeOS.BuildNumber -eq '17763') { $NDISDefinition = $AdapterDefinition.NDIS.WS2019  }
    elseif ($NodeOS.BuildNumber -ge '21287') { $NDISDefinition = $AdapterDefinition.NDIS.WS2022  }
    elseif ($OSDisplayVersion -eq '20H2'   ) { $NDISDefinition = $AdapterDefinition.NDIS.HCI20H2 }
    elseif ($OSDisplayVersion -eq '21H2'   ) { $NDISDefinition = $AdapterDefinition.NDIS.HCI21H2 }

    <# Not Implemented
    $Requirements = ([Requirements]::new())
    if     (($OSVersion -eq '2019') -or ($OSVersion -eq 'HCIv1')) { $Requirements = ([Requirements]::new()).WS2019_HCIv1 }
    elseif (($OSVersion -eq '2022') -or ($OSVersion -eq 'HCIv2')) { $Requirements = ([Requirements]::new()).WS2022_HCIv2 }
    #>

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

        if     ($thisAdapter.Speed -ge 10000000000) { $AdapterSpeed = '10Gbps' }
        elseif ($thisAdapter.Speed -ge 1000000000)  { $AdapterSpeed = '1Gbps' }
        elseif ($thisAdapter.Speed -ge 100000000)   { $AdapterSpeed = '100Mbps' }

        $RequirementsTested = @()
        Switch -Wildcard ($AdapterConfiguration | Sort-Object RegistryKeyword) {

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

function Test-SwitchCapability {
    <#
    .SYNOPSIS
    This module performs strict parameter validation of advanced registry keys and switch validation for Azure Stack HCI devices.

    .DESCRIPTION
    Advanced registry keys are administrator controls for NIC properties. This module validates that those advanced properties
    follow the defined specification by Microsoft, validating that each key is of an appropriate type and accepts valid values.

    Additionally, this module performs validation of Azure Stack HCI switch requirements. These requirements are listed here:
    https://docs.microsoft.com/en-us/azure-stack/hci/concepts/physical-network-requirements

    This module is intended to be run through the automated Hardware Lab Kit (HLK) device tests for NICs or switches

    The following Switch tests are performed:
    - Tests that 802.1AB packets are sent from the switch
    - Tests that 802.1 Subtype 1 is sent, only 1 valid VLAN is sent, and cannot be 0
    - Tests that 802.1 Subtype 3 is sent, contains only valid vlans, and supports at least 10 vlans.
    - Tests that 802.1 Subtype 11 is sent and has at least one priority enabled between priority 0 - 7
    - Tests that 802.3 Subtype 4 is sent and has at least an MTU of 9200 or higher

    Switch Setup Instructions:
    - Enable Native VLAN of non-zero value
    - Ensure at least 10 VLANs are trunked on the switchport
    - Enable Jumbo Frames of 9174
    - Enable PFC on at least 1 of priority0 - priority 7
    - Enable LLDP 802.1AB on the switchport and subtypes 802.1 Subtype 1, 3, 11 and 802.3 Subtype 4

    .EXAMPLE Test Switch Capabilities using pNIC01 to detect
    Test-SwitchCapability -Switch -InterfaceName 'pNIC01'
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory=$true, HelpMessage="Enter the name of a Network Adapter as returned by Get-NetAdapter 'Name' Property")]
        [ValidateScript({Get-NetAdapter -Name $_})]
        [string] $InterfaceName ,

        [Parameter(Mandatory=$false, HelpMessage="Performs all Switch Tests regardless of HCI version")]
        [Switch] $AllTests = $false
    )

    Clear-Host

    $global:pass = 'PASS'
    $global:fail = 'FAIL'
    $global:testsFailed = 0

    $here = Split-Path -Parent (Get-Module -Name Test-NetHLK -ListAvailable | Select-Object -First 1).Path

    # Keep a separate log for easier diagnostics
    $global:Log = New-Item -Name 'Results.log' -Path "$here\Results" -ItemType File -Force
    Start-WTTLog "$here\Results\Results.wtl"
    Start-WTTTest "$here\Results\Results.wtl"

    # Since these tests only apply to Azure Stack HCI SKUs, we will check for an appropriate SKU first, then narrow down tests by version
    $NodeOS = Get-CimInstance -ClassName 'Win32_OperatingSystem'
    $OSDisplayVersion = (Get-ComputerInfo -Property OSDisplayVersion).OSDisplayVersion

    # ID the system as client or server to enable the tests to pivot expected values
    if (-not($NodeOS.Caption -like '*Azure Stack HCI*')) {
        #Write-WTTLogError "The OS SKU was incorrect or could not be determined. Ensure the machine is running the Azure Stack HCI SKU. Caption detected: $($NodeOS.Caption)"
        "The OS SKU was incorrect or could not be determined. Ensure the machine is running the Azure Stack HCI SKU. Caption detected: $($NodeOS.Caption)" | Out-File -FilePath $Log -Append

        throw
    }

    if ($InterfaceName.Count -gt 1) { <#Write-WTTLogMessage "Testing will occur only on the first adapter $($InterfaceName | Select-Object -First 1)."#> }
    $InterfaceName = ($InterfaceName | Select-Object -First 1)

    #Write-WTTLogMessage "Enabling LLDP on interfaces: $InterfaceName."
    Enable-FabricInfo -InterfaceNames $InterfaceName

    #Write-WTTLogMessage "Sleep for 35 seconds to ensure an LLDP packet is captured"
    Start-Sleep -Seconds 35

    Remove-Variable FabricInfo -ErrorAction SilentlyContinue
    $FabricInfo = Get-FabricInfo -InterfaceNames $InterfaceName

    if (-not ($FabricInfo)) {
        #Write-WTTLogError "The switch did not send an LLDP frame to the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
        "[$FAIL] The switch did not send an LLDP frame to the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again." | Out-File -FilePath $Log -Append
    }
    else {
        #Write-WTTLogMessage "[$PASS] The switch sent an LLDP frame to the interface named: $InterfaceName"
        "[$PASS] The switch sent an LLDP frame to the interface named: $InterfaceName" | Out-File -FilePath $Log -Append

        #TODO: ChassisID - Validate that a valid MAC address is set

        Switch ($OSDisplayVersion.Substring(0,$OSDisplayVersion.Length-2)) {
            {$_ -ge '20' -or $AllTests} {
                #region VLAN Name 802.1 Subtype 3
                if ($FabricInfo.$InterfaceName.Fabric.VLANID -ne 'Information Not Provided By Switch') {
                    if ($FabricInfo.$InterfaceName.Fabric.VLANID.Count -lt 10) {
                        #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                        "[$Pass] [Test: 802.1AB - 802.1 Subtype 3] The switch must send at least 10 VLANs" | Out-File -FilePath $Log -Append

                        $FabricInfo.$InterfaceName.Fabric.VLANID | Foreach-Object {
                            $thisVLAN = $_

                            if ($thisVLAN -gt 0 -and $thisVLAN -lt 4096) {
                                #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                                "[$Pass] [Test: 802.1AB - 802.1 Subtype 3] The switch sent a valid Named VLAN: $thisVLAN" | Out-File -FilePath $Log -Append
                            }
                            Else {
                                #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                                "[$FAIL] [Test: 802.1AB - 802.1 Subtype 3] The switch sent a valid Named VLAN: $thisVLAN" | Out-File -FilePath $Log -Append
                            }
                        }
                    }
                    Else {
                        #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                        "[$Fail] [Test: 802.1AB - 802.1 Subtype 3] The switch must send at least 10 VLANs" | Out-File -FilePath $Log -Append
                    }
                }
                Else {
                    #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                    "[$Fail] [Test: 802.1AB - 802.1 Subtype 3] The switch must indicate the named VLANs" | Out-File -FilePath $Log -Append
                }
                #endregion VLAN Name 802.1 Subtype 3

                #region VLAN Name 802.3 Subtype 4
                if ($FabricInfo.$InterfaceName.Fabric.FrameSize -ne 'Information Not Provided By Switch') {
                    if ($FabricInfo.$InterfaceName.Fabric.FrameSize -gt 9200) {
                        #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                        "[$Pass] [Test: 802.1AB - 802.3 Subtype 4] The switch must support a frame size of at least 9200" | Out-File -FilePath $Log -Append
                    }
                }
                Else {
                    #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                    "[$Fail] [Test: 802.1AB - 802.3 Subtype 4] The switch must indicate the MTU" | Out-File -FilePath $Log -Append
                }
                #endregion VLAN Name 802.3 Subtype 4
            }

            {$_ -ge '21' -or $AllTests} {
                #region VLAN Name 802.1 Subtype 1
                if ($FabricInfo.$InterfaceName.Fabric.NativeVLAN -ne 'Information Not Provided By Switch') {
                    if ($FabricInfo.$InterfaceName.Fabric.NativeVLAN.Count -eq 1) {
                        #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                        "[$Pass] [Test: 802.1AB - 802.1 Subtype 1] The switch must send exactly 1 VLAN" | Out-File -FilePath $Log -Append

                        if ($thisVLAN -gt 0 -and $thisVLAN -lt 4096) {
                            #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                            "[$Pass] [Test: 802.1AB - 802.1 Subtype 1] The switch sent a valid Native VLAN" | Out-File -FilePath $Log -Append
                        }
                        Else {
                            #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                            "[$FAIL] [Test: 802.1AB - 802.1 Subtype 1] The switch sent an invalid VLANID of $($FabricInfo.$InterfaceName.Fabric.NativeVLAN)" | Out-File -FilePath $Log -Append
                        }
                    }
                    Else {
                        #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                        "[$Fail] [Test: 802.1AB - 802.1 Subtype 1] The switch must send exactly 1 VLAN" | Out-File -FilePath $Log -Append
                    }
                }
                Else {
                    #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                    "[$Fail] [Test: 802.1AB - 802.1 Subtype 1] The switch must indicate the Native VLAN" | Out-File -FilePath $Log -Append
                }
                #endregion VLAN Name 802.1 Subtype 1

                #region VLAN Name 802.1 Subtype 11
                if ($FabricInfo.$InterfaceName.Fabric.PFC -ne 'Information Not Provided By Switch') {
                    $FabricInfo.$InterfaceName.Fabric.PFC | ForEach-Object {
                        $thisPriority = $_

                        if ($thisPriority -ne 'Priority0' -or $thisPriority -ne 'Priority1' -or $thisPriority -ne 'Priority2' -or $thisPriority -ne 'Priority3' -or
                            $thisPriority -ne 'Priority4' -or $thisPriority -ne 'Priority5' -or $thisPriority -ne 'Priority6' -or $thisPriority -ne 'Priority7') {
                            #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                            "[$Pass] [Test: 802.1AB - 802.1 Subtype 11] The switch must support valid PFC: $thisPriority" | Out-File -FilePath $Log -Append
                        }
                        else {
                            #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                            "[$Fail] [Test: 802.1AB - 802.1 Subtype 11] The switch supports an invalid PFC class: $thisPriority" | Out-File -FilePath $Log -Append
                        }
                    }
                }
                Else {
                    #Write-WTTLogError "No LLDP packets were captured on the interface named: $InterfaceName. Ensure that LLDP is enabled on the switchport connected to this interface and try again."
                    "[$Fail] [Test: 802.1AB - 802.1 Subtype 11] The switch must have at least 1 priority enable with PFC" | Out-File -FilePath $Log -Append
                }
                #endregion VLAN Name 802.1 Subtype 11
            }

            default {
                #Write-WTTLogError "The OSDisplayVersion was not properly detected by the test. Detected version: $OSDisplayVersion"
                "[$FAIL] The OSDisplayVersion was not properly detected by the test. Detected version: $OSDisplayVersion" | Out-File -FilePath $Log -Append
            }
        }
    }

    Stop-WTTTest
    Stop-WTTLog
}

New-Alias -Name 'Test-NICProperties' -Value 'Test-NICAdvancedProperties'

#TODO: Calculate which capabilities are there and whether they have enough for Standard/Premium
