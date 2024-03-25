enum EnableDisable {
    Disabled = 0
    Enabled  = 1
}

#region Buffers - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/keywords-that-can-be-edited
Class ReceiveBuffers {
    [string]   $RegistryKeyword      = '*ReceiveBuffers'
    [int]      $DisplayParameterType = '1' # 1 byte unsigned integer

    ReceiveBuffers () {}
}

Class TransmitBuffers {
    [string]   $RegistryKeyword      = '*TransmitBuffers'
    [int]      $DisplayParameterType = '1' # 1 byte unsigned integer

    TransmitBuffers () {}
}

Class Buffers {
    $ReceiveBuffers = [ReceiveBuffers]::new()
    $TransmitBuffers = [TransmitBuffers]::new()

    Buffers () {}
}
#endregion

#region ChecksumOffload - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/enumeration-keywords
#Send and Receive TCP Checksum Offload for IPv4 and IPv6
#Send and Receive IP Checksum Offload for IPv4
#Send and Receive UDP Checksum offload for IPv4 and IPv6
#Support for TCP Checksum Standardized Keywords is mandatory.


#endregion ChecksumOffload

#region EncapOverhead
Class EncapOverhead {
    [string]   $RegistryKeyword      = '*EncapOverhead'
    [int]      $DisplayParameterType = '4' # 1 byte unsigned integer is preferred but 4 or less is acceptable
    [int]      $DefaultRegistryValue = 0

    [int]      $NumericParameterBaseValue = 10  # Must be this value
    [int]      $NumericParameterMaxValue  = 160  # Must be >= 160
    [int]      $NumericParameterMinValue  = 0    # Must be this value
    [int]      $NumericParameterStepValue = 32  # Must be this value

    EncapOverhead () {}
}
#endregion EncapOverhead

#region EncapsulatedPacketTaskOffload
#endregion EncapsulatedPacketTaskOffload

#region EncapsulatedPacketTaskOffloadNvgre
Class EncapsulatedPacketTaskOffloadNvgre {
    [string]   $RegistryKeyword      = '*EncapsulatedPacketTaskOffloadNvgre'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    EncapsulatedPacketTaskOffloadNvgre () {}
}
#endregion EncapsulatedPacketTaskOffloadNvgre

#region EncapsulatedPacketTaskOffloadVxlan
Class EncapsulatedPacketTaskOffloadVxlan {
    [string]   $RegistryKeyword      = '*EncapsulatedPacketTaskOffloadVxlan'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    EncapsulatedPacketTaskOffloadVxlan () {}
}
#endregion EncapsulatedPacketTaskOffloadVxlan

#region FlowControl - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/enumeration-keywords
enum FlowControlVal {
    TxRxDisabled    = 0 # Server Default
    TxEnabled       = 1
    RxEnabled       = 2
    RxTxEnabled     = 3 # Client Default
    AutoNegotiation = 4
}

Class FlowControl_Server {
    [string]   $RegistryKeyword      = '*FlowControl'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [FlowControlVal]::TxRxDisabled.Value__
    [string]   $DisplayDefaultValue  = [FlowControlVal]::TxRxDisabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('FlowControlVal').Value__

    FlowControl_Server () {}
}

Class FlowControl_Client {
    [string]   $RegistryKeyword      = '*FlowControl'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [FlowControlVal]::RxTxEnabled.Value__
    [string]   $DisplayDefaultValue  = [FlowControlVal]::RxTxEnabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('FlowControlVal').Value__

    FlowControl_Client () {}
}

Class FlowControl {
    $FlowControl_Server = [FlowControl_Server]::new()
    $FlowControl_Client = [FlowControl_Client]::new()

    FlowControl () {}
}
#endregion FlowControl

#region InterruptModeration - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/enumeration-keywords
Class InterruptModeration {
    [string]   $RegistryKeyword      = '*InterruptModeration'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    InterruptModeration () {}
}
#endregion InterruptModeration

#region JumboPacket - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/keywords-that-can-be-edited
Class JumboPacket {
    [string]   $RegistryKeyword      = '*JumboPacket'
    [int]      $DisplayParameterType = '2' # 2 byte unsigned integer
    [int]      $DefaultRegistryValue = 1514

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    [int]      $NumericParameterMaxValue = 9014  # Must be >= this value 9014 + EncapOverhead (160)
    [int]      $NumericParameterMinValue = 1514   # Must be <= than this value
    [int]      $NumericParameterStepValue = 1    # Must be this value

    JumboPacket () {}
}
#endregion JumboPacket

#region LSO - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/using-registry-values-to-enable-and-disable-task-offloading
Class LSOv2IPV4 {
    [string]   $RegistryKeyword      = '*LSOv2IPV4'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    LSOv2IPV4 () {}
}

Class LSOv2IPV6 {
    [string]   $RegistryKeyword      = '*LSOv2IPV6'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    LSOv2IPV6 () {}
}

Class LSO {
    $LSOv2IPV4 = [LSOv2IPV4]::new()
    $LSOv2IPV6 = [LSOv2IPV6]::new()

    LSO () {}
}
#endregion LSO

#region NDKPI - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/inf-requirements-for-ndkpi
enum NetworkDirectTechnologyVal {
    iWARP      = 1
    Infiniband = 2
    RoCE       = 3
    RoCEv2     = 4
}

enum NetworkDirectRoCEFrameSizeVal {
    Small   = 256
    Medium  = 512
    Default = 1024
    Large   = 2048
    XLarge  = 4096
}

Class NetworkDirect {
    [string] $RegistryKeyword      = '*NetworkDirect'
    [int]    $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    NetworkDirect () {}
}

Class NetworkDirectTechnology {
    [string] $RegistryKeyword = '*NetworkDirectTechnology'
    [int]    $DisplayParameterType = 5

    [string[]] $ValidRegistryValues = [System.Enum]::GetValues('NetworkDirectTechnologyVal').Value__

    NetworkDirectTechnology () {}
}

Class NetworkDirectRoCEFrameSize {
    [string]   $RegistryKeyword      = '*NetworkDirectRoCEFrameSize'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [NetworkDirectRoCEFrameSizeVal]::Default.Value__
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('NetworkDirectRoCEFrameSizeVal').Value__

    NetworkDirectRoCEFrameSize () {}
}

Class NDKPI {
    $NetworkDirect              = [NetworkDirect]::new()
    $NetworkDirectTechnology    = [NetworkDirectTechnology]::new()
    $NetworkDirectRoCEFrameSize = [NetworkDirectRoCEFrameSize]::new()
}
#endregion NDKPI

#region NDIS
Class NDIS {
    [string] $WS2016  = '6.60'
    [string] $WS2019  = '6.82'
    [string] $WS2022  = '6.85'
    [string] $WS2025  = '6.89'

    NDIS () {}
}
#endregion NDIS

#region NicSwitch
Class NicSwitch_1GbOrGreater {
    $SwitchName = 'Default Switch'  # Must be this value
    $Flags      = 0  # Must be this value
    $SwitchType = 1  # Must be this value
    $SwitchId   = 0  # Must be this value
    $NumVFs     = 4  # For 1GbE or Higher

    NicSwitch_1GbOrGreater () {}
}

Class NicSwitch_10GbOrGreater {
    $SwitchName = 'Default Switch'  # Must be this value
    $Flags      = 0  # Must be this value
    $SwitchType = 1  # Must be this value
    $SwitchId   = 0  # Must be this value
    $NumVFs     = 32 # For 10GbE or higher

    NicSwitch_10GbOrGreater () {}
}

Class NicSwitch {
    $NicSwitch_1GbOrGreater  = [NicSwitch_1GbOrGreater]::new()
    $NicSwitch_10GbOrGreater = [NicSwitch_10GbOrGreater]::new()

    NicSwitch () {}
}
#endregion NicSwitch

#region PriorityVLANTag - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/enumeration-keywords
enum PriorityVLANTagVal {
    PriorityVLANDisabled = 0
    PriorityEnabled      = 1
    VLANEnabled          = 2
    PriorityVLANEnabled  = 3
}

Class PriorityVLANTag {
    [string]   $RegistryKeyword      = '*PriorityVLANTag'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [PriorityVLANTagVal]::PriorityVLANEnabled.Value__
    [string]   $DisplayDefaultValue  = [PriorityVLANTagVal]::PriorityVLANEnabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('PriorityVLANTagVal').Value__

    PriorityVLANTag () {}
}
#endregion PriorityVLANTag

#region PtpHardwareTimestamp
Class PtpHardwareTimestamp {
    [string]   $RegistryKeyword      = '*PtpHardwareTimestamp'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Disabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Disabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    PtpHardwareTimestamp () {}
}
#endregion

#region QOS - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-ndis-qos
Class QOS {
    [string]   $RegistryKeyword      = '*QOS'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    QOS () {}
}
#endregion QOS

#region HWQOS - or QoSOffload
Class QOSOffload {
    [string]   $RegistryKeyword      = '*QOSOffload'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    QoSOffload () {}
}
#endregion QOS

#region RSC - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rsc
Class RSCIPv4 {
    [string]   $RegistryKeyword      = '*RSCIPv4'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    RSCIPv4 () {}
}

Class RSCIPv6 {
    [string]   $RegistryKeyword      = '*RSCIPv6'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    RSCIPv6 () {}
}

Class RSC {
    $RSCIPv4 = [RSCIPv4]::new()
    $RSCIPv6 = [RSCIPv6]::new()

    RSC () {}
}
#endregion

#region RSS - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rss
enum RSSProfileVal {
    ClosestProcessor       = 1
    ClosestProcessorStatic = 2
    NUMAScaling            = 3
    NUMAScalingStatic      = 4
    ConservativeScaling    = 5
}

Class RSS {
    [string]   $RegistryKeyword      = '*RSS'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    RSS () {}
}

Class MaxRSSProcessors_MSIXSupport_1Gb {
    [string]   $RegistryKeyword      = '*MaxRssProcessors'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 4

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 4  # Must be >= than this value
    [int]      $NumericParameterMinValue  = 1  # Must be this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    MaxRSSProcessors_MSIXSupport_1Gb () {}
}

Class MaxRSSProcessors_MSIXSupport_10GbOrGreater {
    [string]   $RegistryKeyword      = '*MaxRssProcessors'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 8

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 8 # Must be >= than this value
    [int]      $NumericParameterMinValue = 1   # Must be this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    MaxRSSProcessors_MSIXSupport_10GbOrGreater () {}
}

Class MaxRSSProcessors_No_MSIXSupport_1Gb {
    [string]   $RegistryKeyword      = '*MaxRssProcessors'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 2

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 2  # Must be >= than this value
    [int]      $NumericParameterMinValue  = 1  # Must be this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    MaxRSSProcessors_No_MSIXSupport_1Gb () {}
}

Class MaxRSSProcessors_No_MSIXSupport_10GbOrGreater {
    [string]   $RegistryKeyword      = '*MaxRssProcessors'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 4

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 4  # Must be >= than this value
    [int]      $NumericParameterMinValue  = 1  # Must be < than this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    MaxRSSProcessors_No_MSIXSupport_10GbOrGreater () {}
}

Class MaxRSSProcessors {
    $MaxRSSProcessors_MSIXSupport_1Gb              = [MaxRSSProcessors_MSIXSupport_1Gb]::new()
    $MaxRSSProcessors_MSIXSupport_10GbOrGreater    = [MaxRSSProcessors_MSIXSupport_10GbOrGreater]::new()
    $MaxRSSProcessors_No_MSIXSupport_1Gb           = [MaxRSSProcessors_No_MSIXSupport_1Gb]::new()
    $MaxRSSProcessors_No_MSIXSupport_10GbOrGreater = [MaxRSSProcessors_No_MSIXSupport_10GbOrGreater]::new()

    MaxRSSProcessors () {}
}

Class NumRSSQueues_MSIXSupport_1Gb {
    [string]   $RegistryKeyword      = '*NumRSSQueues'
    [int]      $DisplayParameterType = 1  # 4 byte unsigned integer

    [int]      $DefaultRegistryValue = 4

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 4  # Must be >= than this value
    [int]      $NumericParameterMinValue  = 1  # Must be this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    NumRSSQueues_MSIXSupport_1Gb () {}
}

Class NumRSSQueues_MSIXSupport_10GbOrGreater {
    [string]   $RegistryKeyword      = '*NumRSSQueues'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 8

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 8 # Must be >= than this value
    [int]      $NumericParameterMinValue = 1   # Must be this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    NumRSSQueues_MSIXSupport_10GbOrGreater () {}
}

Class NumRSSQueues_No_MSIXSupport_1Gb {
    [string]   $RegistryKeyword      = '*NumRSSQueues'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 2

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 2  # Must be >= than this value
    [int]      $NumericParameterMinValue  = 1  # Must be this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    NumRSSQueues_No_MSIXSupport_1Gb () {}
}

Class NumRSSQueues_No_MSIXSupport_10GbOrGreater {
    [string]   $RegistryKeyword      = '*NumRSSQueues'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 4

    [int]      $NumericParameterBaseValue = 10 # Must be this value
    [int]      $NumericParameterMaxValue  = 4  # Must be >= than this value
    [int]      $NumericParameterMinValue  = 1  # Must be < than this value
    [int]      $NumericParameterStepValue = 1  # Must be this value

    NumRSSQueues_No_MSIXSupport_10GbOrGreater () {}
}

Class NumRSSQueues {
    # NumRSSQueues must support the same values as MaxRSSProcessors
    $NumRSSQueues_MSIXSupport_1Gb              = [NumRSSQueues_MSIXSupport_1Gb]::new()
    $NumRSSQueues_MSIXSupport_10GbOrGreater    = [NumRSSQueues_MSIXSupport_10GbOrGreater]::new()
    $NumRSSQueues_No_MSIXSupport_1Gb           = [NumRSSQueues_No_MSIXSupport_1Gb]::new()
    $NumRSSQueues_No_MSIXSupport_10GbOrGreater = [NumRSSQueues_No_MSIXSupport_10GbOrGreater]::new()

    NumRSSQueues () {}
}

Class RSSProfile {
    [string]   $RegistryKeyword      = '*RSSProfile'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [RSSProfileVal]::NUMAScalingStatic.Value__
    [string]   $DisplayDefaultValue  = [RSSProfileVal]::NUMAScalingStatic
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('RSSProfileVal').Value__

    RSSProfile () {}
}

Class NumaNodeId {
    [string]   $RegistryKeyword      = '*NumaNodeId'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 65535

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    [int]      $NumericParameterMaxValue = 65535 # Must be this value
    [int]      $NumericParameterMinValue = 0   # Must be < than this value
    [int]      $NumericParameterStepValue = 1    # Must be this value

    NumaNodeId () {}
}

Class RssBaseProcGroup {
    [string]   $RegistryKeyword      = '*RssBaseProcGroup'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 0

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    #[int]      $NumericParameterMaxValue =      # System specific
    [int]      $NumericParameterMinValue = 0   # Must be < than this value
    [int]      $NumericParameterStepValue = 1    # Must be this value

    RssBaseProcGroup () {}
}

Class RSSMaxProcGroup {
    [string]   $RegistryKeyword      = '*RSSMaxProcGroup'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 0

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    #[int]      $NumericParameterMaxValue =      # System specific
    [int]      $NumericParameterMinValue = 0   # Must be < than this value
    [int]      $NumericParameterStepValue = 1    # Must be this value

    RSSMaxProcGroup () {}
}

Class RssBaseProcNumber {
    [string]   $RegistryKeyword      = '*RssBaseProcNumber'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 0

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    #[int]      $NumericParameterMaxValue =      # System specific
    [int]      $NumericParameterMinValue = 0   # Must be < than this value
    [int]      $NumericParameterStepValue = 1    # Must be this value

    RssBaseProcNumber () {}
}

Class RssMaxProcNumber {
    [string]   $RegistryKeyword      = '*RssMaxProcNumber'
    [int]      $DisplayParameterType = 1  # 1 byte unsigned integer

    [int]      $DefaultRegistryValue = 63

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    #[int]      $NumericParameterMaxValue =      # System specific
    [int]      $NumericParameterMinValue = 0   # Must be < than this value
    [int]      $NumericParameterStepValue = 1    # Must be this value

    RssMaxProcNumber () {}
}

Class RSSClass {
    $RSS = [RSS]::new()

    $MaxRSSProcessors = [MaxRSSProcessors]::new()
    $NumRSSQueues     = [NumRSSQueues]::new()

    $NumaNodeId       = [NumaNodeId]::new()

    $RssBaseProcGroup = [RssBaseProcGroup]::new()
    $RSSMaxProcGroup  = [RSSMaxProcGroup]::new()
    $RssBaseProcNumber = [RssBaseProcNumber]::new()
    $RssMaxProcNumber  = [RssMaxProcNumber]::new()

    $RSSProfile = [RSSProfile]::new()

    RSSClass () {}
}
#endregion RSS

#region RSSOnHostVPorts
Class RSSOnHostVPorts {
    [string]   $RegistryKeyword      = '*RSSOnHostVPorts'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    RSSOnHostVPorts () {}
}
#endregion RSSOnHostVPorts

#region SpeedDuplex - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/enumeration-keywords
Class SpeedDuplex {
    [string]   $RegistryKeyword      = '*SpeedDuplex'
    [int]      $DisplayParameterType = 5

    SpeedDuplex () {}
}
#endregion SRIOV

#region SRIOV - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-sr-iov
Class SRIOV {
    [string]   $RegistryKeyword      = '*SRIOV'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    SRIOV () {}
}
#endregion SRIOV

#region USO - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/udp-segmentation-offload-uso-
    Class USOIPv4 {
        [string]   $RegistryKeyword      = '*USOIPv4'
        [int]      $DisplayParameterType = 5

        [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
        [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

        USOIPv4 () {}
    }

    Class USOIPv6 {
        [string]   $RegistryKeyword      = '*USOIPv6'
        [int]      $DisplayParameterType = 5

        [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
        [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

        USOIPv6 () {}
    }

    Class USO {
        $USOIPv4 = [USOIPv4]::new()
        $USOIPv6 = [USOIPv6]::new()

        USO () {}
    }
#endregion USO

#region VLANID
Class VLANID {
    [string] $RegistryKeyword      = 'VLANID'
    [int]    $DisplayParameterType = 2 # 2 byte unsigned integer

    [string] $DefaultRegistryValue = 0
    [int]    $NumericParameterBaseValue = 10  # Must be this value
    [int]    $NumericParameterMaxValue = 4094 # Must be this value
    [int]    $NumericParameterMinValue = 0    # Must be this value
    [int]    $NumericParameterStepValue = 1   # Must be this value

    VLANID () {}
}
#endregion VLANID

#region VMQ - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-vmq#vmq-rss
Class VMQVlanFiltering {
    [string]   $RegistryKeyword      = '*VMQVlanFiltering'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    VMQVlanFiltering () {}
}

Class RssOrVmqPreference {
    [string]   $RegistryKeyword      = '*RssOrVmqPreference'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Disabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Disabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    RssOrVmqPreference () {}
}

Class VMQ {
    [string]   $RegistryKeyword      = '*VMQ'
    [int]      $DisplayParameterType = 5

    [string]   $DefaultRegistryValue = [EnableDisable]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [EnableDisable]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('EnableDisable').Value__

    #Device.Network.LAN.VMQ.VirtualMachineQueues

    VMQ () {}
}

Class VMQClass {
    $VMQ = [VMQ]::new()

    $VMQVlanFiltering   = [VMQVlanFiltering]::new()
    $RssOrVmqPreference = [RssOrVmqPreference]::new()

    VMQClass () {}
}
#endregion VMQ

#region VxlanUDPPortNumber
Class VxlanUDPPortNumber {
    [string]   $RegistryKeyword      = '*VxlanUDPPortNumber'
    [int]      $DisplayParameterType = '2' # 2 byte unsigned integer or greater
    [int]      $DefaultRegistryValue = 4789

    [int]      $NumericParameterBaseValue = 10    # Must be this value
    [int]      $NumericParameterMaxValue  = 65535 # Must be < this value
    [int]      $NumericParameterMinValue  = 1024  # Must be this value
    [int]      $NumericParameterStepValue = 1     # Must be this value

    VxlanUDPPortNumber () {}
}
#endregion VxlanUDPPortNumber

Class AdapterDefinition {
    $Buffers = [Buffers]::new()
    # $ChecksumOffload  - Not yet implemented

    $EncapOverhead = [EncapOverhead]::new()
    # $EncapsulatedPacketTaskOffload = [EncapsulatedPacketTaskOffload]::new() - Is this needed?
    $EncapsulatedPacketTaskOffloadNVGRE = [EncapsulatedPacketTaskOffloadNVGRE]::new()
    $EncapsulatedPacketTaskOffloadVxlan = [EncapsulatedPacketTaskOffloadVxlan]::new()

    $FlowControl         = [FlowControl]::new()
    $InterruptModeration = [InterruptModeration]::new()
    $JumboPacket         = [JumboPacket]::new()

    $LSO   = [LSO]::new()
    $NDKPI = [NDKPI]::new()

    $NDIS  = [NDIS]::new()

    $NicSwitch = [NicSwitch]::new()

    $PriorityVLANTag      = [PriorityVLANTag]::new()
    $PtpHardwareTimestamp = [PtpHardwareTimestamp]::new()

    $QOS        = [QOS]::new()
    $QOSOffload = [QOSOffload]::new()

    $RSC = [RSC]::new()

    $RSSClass = [RSSClass]::new()

    $RSSOnHostVPorts = [RSSOnHostVPorts]::new()
    $SpeedDuplex     = [SpeedDuplex]::new()

    $SRIOV    = [SRIOV]::new()
    $USO      = [USO]::new()
    $VLANID   = [VLANID]::new()
    $VMQClass = [VMQClass]::new()

    $VxlanUDPPortNumber = [VxlanUDPPortNumber]::new()
}


#region Requirements

enum Base_WS2019_HCIv1 {
    PriorityVLANTag # Done
    FlowControl
    InterruptModeration
    JumboPacket
}

enum TenGbEOrGreater_WS2019_HCIv1 {
    RSCIPv4         # Done
    RSCIPv6         # Done
    VLANID          # Done - We should move this to BASE for Server
    LSOv2IPV4         # Done
    LSOv2IPV6         # Done

    RSS
    MaxRSSProcessors
    NumRSSQueues
    RSSProfile
    NumaNodeId
    RssBaseProcGroup
    RSSMaxProcGroup
    RssBaseProcNumber
    RssMaxProcNumber

    QOS             # Done
    VMQ
    VMQVlanFiltering
    RssOrVmqPreference

    # ChecksumOffload - Not yet implemented
    TransmitBuffers
    ReceiveBuffers
}

enum Standard_WS2019_HCIv1 {
    RSSOnHostVPorts
    SRIOV
    #NicSwitch - Not a keyword but should be verified

    VxlanUDPPortNumber
    EncapOverhead

    # EncapsulatedPacketTaskOffload - Not Implemented yet
    EncapsulatedPacketTaskOffloadNVGRE
    EncapsulatedPacketTaskOffloadVXLAN

    NetworkDirect
    NetworkDirectTechnology
}

enum Premium_WS2019_HCIv1 {
    RSSv2
    #NDKm3
}

enum Base_WS2022_HCIv2 {
    PriorityVLANTag # Done
    FlowControl
    InterruptModeration
    JumboPacket
}

enum TenGbEOrGreater_WS2022_HCIv2 {
    RSCIPv4         # Done
    RSCIPv6         # Done
    VLANID          # Done - We should move this to BASE for Server
    LSOv2IPV4         # Done
    LSOv2IPV6         # Done

    RSS
    MaxRSSProcessors
    NumRSSQueues
    RSSProfile
    NumaNodeId
    RssBaseProcGroup
    RSSMaxProcGroup
    RssBaseProcNumber
    RssMaxProcNumber

    QOS             # Done
    VMQ
    VMQVlanFiltering
    RssOrVmqPreference

    # ChecksumOffload - Not yet implemented
    TransmitBuffers
    ReceiveBuffers
}

enum Standard_WS2022_HCIv2 {
    RSSOnHostVPorts
    SRIOV
    #NicSwitch - Not a keyword but should be verified

    VxlanUDPPortNumber
    EncapOverhead

    # EncapsulatedPacketTaskOffload - Not Implemented yet
    EncapsulatedPacketTaskOffloadNVGRE
    EncapsulatedPacketTaskOffloadVXLAN

    NetworkDirect
    NetworkDirectTechnology

    #RSSv2
    #NDKm3
}

enum Premium_WS2022_HCIv2 {
    PtpHardwareTimestamp

    USOIPv4
    USOIPv6

    QosOffload
}

$Base = [System.Enum]::GetValues('Base_WS2019_HCIv1') | Foreach-Object { $_ }
$TenGbEOrGreater = [System.Enum]::GetValues('Base_WS2019_HCIv1'), [System.Enum]::GetValues('TenGbEOrGreater_WS2019_HCIv1') | Foreach-Object { $_ }
$Standard = [System.Enum]::GetValues('Base_WS2019_HCIv1'), [System.Enum]::GetValues('TenGbEOrGreater_WS2019_HCIv1'), [System.Enum]::GetValues('Standard_WS2019_HCIv1') | Foreach-Object { $_ }
$Premium  = [System.Enum]::GetValues('Base_WS2019_HCIv1'), [System.Enum]::GetValues('TenGbEOrGreater_WS2019_HCIv1'), [System.Enum]::GetValues('Standard_WS2019_HCIv1'), [System.Enum]::GetValues('Premium_WS2019_HCIv1') | Foreach-Object { $_ }


Class WS2019_HCIv1 {
    $Base            = [System.Enum]::GetValues('Base_WS2019_HCIv1')
    $TenGbEOrGreater = [System.Enum]::GetValues('Base_WS2019_HCIv1'), [System.Enum]::GetValues('TenGbEOrGreater_WS2019_HCIv1')

    $Standard = [System.Enum]::GetValues('Base_WS2019_HCIv1'), [System.Enum]::GetValues('TenGbEOrGreater_WS2019_HCIv1'), [System.Enum]::GetValues('Standard_WS2019_HCIv1')
    $Premium  = [System.Enum]::GetValues('Base_WS2019_HCIv1'), [System.Enum]::GetValues('TenGbEOrGreater_WS2019_HCIv1'), [System.Enum]::GetValues('Standard_WS2019_HCIv1'), [System.Enum]::GetValues('Premium_WS2019_HCIv1')
}

$Base = [System.Enum]::GetValues('Base_WS2022_HCIv2') | Foreach-Object { $_ }
$TenGbEOrGreater = [System.Enum]::GetValues('Base_WS2022_HCIv2'), [System.Enum]::GetValues('TenGbEOrGreater_WS2022_HCIv2') | Foreach-Object { $_ }
$Standard = [System.Enum]::GetValues('Base_WS2022_HCIv2'), [System.Enum]::GetValues('TenGbEOrGreater_WS2022_HCIv2'), [System.Enum]::GetValues('Standard_WS2022_HCIv2') | Foreach-Object { $_ }
$Premium  = [System.Enum]::GetValues('Base_WS2022_HCIv2'), [System.Enum]::GetValues('TenGbEOrGreater_WS2022_HCIv2'), [System.Enum]::GetValues('Standard_WS2022_HCIv2'), [System.Enum]::GetValues('Premium_WS2022_HCIv2') | Foreach-Object { $_ }

Class WS2022_HCIv2 {
    $Base            = $Base
    $TenGbEOrGreater = $TenGbEOrGreater
    $Standard = $Standard
    $Premium  = $Premium
}

Class Requirements {
    $WS2019_HCIv1 = [WS2019_HCIv1]::new()
    $WS2022_HCIv2 = [WS2022_HCIv2]::new()
}
#endregion Requirements
