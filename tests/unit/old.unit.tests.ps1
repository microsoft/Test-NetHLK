# This file is deprecated because of WTT logging issues with the script:scope

<# Tests:
- Existance of required keys per documented requirements
- Tests the correct type
- Tests the correct default values
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

    # Device.Network.LAN.Base.100MbOrGreater Windows Server Ethernet devices must be able to link at 1Gbps or higher speeds
    if ($thisAdapter.Speed -ge 1000000000) { $PassFail = $pass }
    else { $PassFail = $fail; $testsFailed ++ }

    "[$PassFail] $($thisAdapter.Name) is 1Gbps or higher" | Out-File -FilePath $Log -Append
    Remove-Variable -Name PassFail -ErrorAction SilentlyContinue

    $RequirementsTested = @()
    Switch -Wildcard ($AdapterConfiguration) {

        { $_.RegistryKeyword -eq '*EncapOverhead' } {

            # *EncapOverhead: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapOverhead

            # *EncapOverhead: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapOverhead

            # *EncapOverhead: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapOverhead

            # *EncapOverhead: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapOverhead

            # *EncapOverhead: NumericParameterMaxValue
            Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapOverhead -OrGreater

            # *EncapOverhead: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapOverhead -OrLess

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*EncapsulatedPacketTaskOffloadNvgre' } {

            # *LsoV2IPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapsulatedPacketTaskOffloadNvgre

            # *LsoV2IPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapsulatedPacketTaskOffloadNvgre

            # *LsoV2IPv4: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapsulatedPacketTaskOffloadNvgre
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.EncapsulatedPacketTaskOffloadNvgre

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*EncapsulatedPacketTaskOffloadVxlan' } {

            # *LsoV2IPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

            # *LsoV2IPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

            # *LsoV2IPv4: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*FlowControl' } {

            # *LsoV2IPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.FlowControl

            # *LsoV2IPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.FlowControl

            # *LsoV2IPv4: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.FlowControl
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.FlowControl

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*InterruptModeration' } {

            # *LsoV2IPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.InterruptModeration

            # *LsoV2IPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.InterruptModeration

            # *LsoV2IPv4: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.InterruptModeration
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.InterruptModeration

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*JumboPacket' } {

            # *JumboPacket: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket

            # *JumboPacket: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket

            # *JumboPacket: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket

            # *JumboPacket: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket

            # *JumboPacket: NumericParameterMaxValue
            Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket -OrGreater

            # *JumboPacket: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket -OrLess

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*LsoV2IPv4' } {

            # *LsoV2IPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

            # *LsoV2IPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

            # *LsoV2IPv4: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*LsoV2IPv6' } {

            # *LsoV2IPv6: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv6

            # *LsoV2IPv6: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv6

            # *LsoV2IPv6: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv6
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv6

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*NetworkDirect' } {

            # *NetworkDirect: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirect

            # *NetworkDirect: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirect

            # *NetworkDirect: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirect
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirect

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*NetworkDirectTechnology' } {

            # *NetworkDirectTechnology: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirectTechnology

            # *NetworkDirectTechnology: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirectTechnology

            # *NetworkDirectTechnology: ValidRegistryValues
                # As the adapter can choose to support one or more of these types, we will only check that the contained values are within the MSFT defined range
                # We will not test to ensure that all defined values are found unlike other enums (because an adapter may support both RoCE and RoCEv2 but not iWARP and visa versa)
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirectTechnology

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*NumaNodeId' } {

            # *NumaNodeId: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.NumaNodeId

            # *NumaNodeId: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.NumaNodeId

            # *NumaNodeId: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.NumaNodeId

            # *NumaNodeId: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.NumaNodeId

            # *NumaNodeId: NumericParameterMaxValue
            Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.NumaNodeId

            # *NumaNodeId: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.NumaNodeId

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*PriorityVLANTag' } {

            # *PriorityVLANTag: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.PriorityVLANTag

            # *PriorityVLANTag: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.PriorityVLANTag

            # *PriorityVLANTag: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.PriorityVLANTag
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.PriorityVLANTag

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*QOS' } {

            # *QOS: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.QOS

            # *QOS: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.QOS

            # *QOS: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.QOS
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.QOS

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*ReceiveBuffers' } {

            # *ReceiveBuffers: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.Buffers.ReceiveBuffers

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSCIPv4' } {

            # *RSCIPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv4

            # *RSCIPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv4

            # *RSCIPv4: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv4
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv4

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSCIPv6' } {

            # *RSCIPv6: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv6

            # *RSCIPv6: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv6

            # *RSCIPv6: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv6
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv6

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSS' } {

            # *RSS: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSS

            # *RSS: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSS

            # *RSS: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSS
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSS

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSSBaseProcGroup' } {

            # *RSSBaseProcGroup: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcGroup

            # *RSSBaseProcGroup: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcGroup

            # *RSSBaseProcGroup: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcGroup

            # *RSSBaseProcGroup: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcGroup

            # *RSSBaseProcGroup: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcGroup

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSSBaseProcNumber' } {

            # *RSSBaseProcNumber: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcNumber

            # *RSSBaseProcNumber: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcNumber -MaxValue 4

            # *RSSBaseProcNumber: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcNumber

            # *RSSBaseProcNumber: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcNumber

            # *RSSBaseProcNumber: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSBaseProcNumber

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RssMaxProcNumber' } {

            # *RssMaxProcNumber: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RssMaxProcNumber

            # *RssMaxProcNumber: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RssMaxProcNumber

            # *RssMaxProcNumber: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RssMaxProcNumber

            # *RssMaxProcNumber: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RssMaxProcNumber

            # *RssMaxProcNumber: NumericParameterMaxValue
            Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RssMaxProcNumber

            # *RssMaxProcNumber: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RssMaxProcNumber

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSSMaxProcGroup' } {

            # *RSSMaxProcGroup: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSMaxProcGroup

            # *RSSMaxProcGroup: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSMaxProcGroup

            # *RSSMaxProcGroup: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSMaxProcGroup

            # *RSSMaxProcGroup: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSMaxProcGroup

            # *RSSMaxProcGroup: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSMaxProcGroup

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSSOnHostVPorts' } {

            # *RSS: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSOnHostVPorts

            # *RSS: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSOnHostVPorts

            # *RSS: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSOnHostVPorts
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSOnHostVPorts

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RssOrVmqPreference' } {

            # *VMQVlanFiltering: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.RssOrVmqPreference

            # *VMQVlanFiltering: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.RssOrVmqPreference

            # *VMQVlanFiltering: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.RssOrVmqPreference
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.RssOrVmqPreference

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*RSSProfile' } {

            # *RSSProfile: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSProfile

            # *RSSProfile: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSProfile

            # *RSSProfile: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSProfile
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSSClass.RSSProfile

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*SRIOV' } {

            # *SRIOV: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.SRIOV

            # *SRIOV: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.SRIOV

            # *SRIOV: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.SRIOV
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.SRIOV

            # Test NICSwitch Defaults
            $NicSwitchConfiguration

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*TransmitBuffers' } {

            # *TransmitBuffers: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.Buffers.TransmitBuffers

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*UsoIPv4' } {

            # *UsoIPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv4

            # *UsoIPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv4

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*UsoIPv6' } {

            # *UsoIPv6: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv6

            # *UsoIPv6: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv6

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq 'VLANID' } {
            # Device.Network.LAN.Base.PriorityVLAN - Since all WS devices must be -ge 1Gbps, they must implement
            # Ethernet devices that implement link speeds of gigabit or greater must implement Priority & VLAN tagging according to the IEEE 802.1q specification.

            # VLANID: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VLANID

            # VLANID: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VLANID

            # VLANID: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VLANID

            # VLANID: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VLANID

            # VLANID: NumericParameterMaxValue
            Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VLANID

            # VLANID: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VLANID

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*VMQ' } {

            # *VMQ: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQ

            # *VMQ: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQ

            # *VMQ: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQ
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQ

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*VMQVlanFiltering' } {

            # *VMQVlanFiltering: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQVlanFiltering

            # *VMQVlanFiltering: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQVlanFiltering

            # *VMQVlanFiltering: ValidRegistryValues
            Test-ContainsAllMSFTRequiredValidRegistryValues  -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQVlanFiltering
            Test-ContainsOnlyMSFTRequiredValidRegistryValues -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQClass.VMQVlanFiltering

            $RequirementsTested += $_.RegistryKeyword

        }

        { $_.RegistryKeyword -eq '*VxlanUDPPortNumber' } {

            # *VxlanUDPPortNumber: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VxlanUDPPortNumber

            # *VxlanUDPPortNumber: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VxlanUDPPortNumber

            # *VxlanUDPPortNumber: NumericParameterBaseValue
            Test-NumericParameterBaseValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VxlanUDPPortNumber

            # *VxlanUDPPortNumber: NumericParameterStepValue
            Test-NumericParameterStepValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VxlanUDPPortNumber

            # *VxlanUDPPortNumber: NumericParameterMaxValue
            Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VxlanUDPPortNumber -OrGreater

            # *VxlanUDPPortNumber: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VxlanUDPPortNumber -OrLess

            $RequirementsTested += $_.RegistryKeyword

        }
    }

    $RequirementsTested | ForEach-Object {
        $ThisTestedRequirement = $_.TrimStart('*')

        $Requirements.Base = $Requirements.Base | Where-Object { $_ -ne $ThisTestedRequirement }
        $Requirements.TenGbEOrGreater = $Requirements.TenGbEOrGreater | Where-Object { $_ -ne $ThisTestedRequirement }
        $Requirements.Standard = $Requirements.Standard | Where-Object { $_ -ne $ThisTestedRequirement }
        $Requirements.Premium  = $Requirements.Premium | Where-Object { $_ -ne $ThisTestedRequirement }
    }

    $Certification = 'Fail'

    If     ($Requirements.Premium -eq $Null -and $Requirements.Standard -and
            $Requirements.TenGbEOrGreater -and $Requirements.Base) { $Certification = 'Premium' }
    ElseIf ($Requirements.Standard -and $Requirements.TenGbEOrGreater -and $Requirements.Base) { $Certification = 'Standard' }
    ElseIf ($Requirements.TenGbEOrGreater -and $Requirements.Base) { $Certification = 'TenGbEOrGreater' }
    ElseIf ($Requirements.Base) { $Certification = 'Base' }
}
