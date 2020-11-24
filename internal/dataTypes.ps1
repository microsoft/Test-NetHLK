#region Buffers - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/keywords-that-can-be-edited
Class ReceiveBuffers {
    [string]   $RegistryKeyword      = '*ReceiveBuffers'
    [int]      $DisplayParameterType = '4' # 4 byte unsigned integer

    # There is some variability in this right now; for example Intel has steps of 8 while mellanox steps by 1, etc.
    #[int]      $NumericParameterBaseValue = 10   # Must be this value
    #[int]      $NumericParameterMaxValue =   # Must be >= this value 9014 + EncapOverhead (160)
    #[int]      $NumericParameterMinValue =    # Must be < than this value
    #[int]      $NumericParameterStepValue = 1    # Must be this value

    ReceiveBuffers () {}
}

Class TransmitBuffers {
    [string]   $RegistryKeyword      = '*TransmitBuffers'
    [int]      $DisplayParameterType = '4' # 4 byte unsigned integer

    TransmitBuffers () {}
}

Class Buffers {
    $ReceiveBuffers = [ReceiveBuffers]::new()
    $TransmitBuffers = [TransmitBuffers]::new()

    Buffers () {}
}
#endregion

#region ChecksumOffload
#https://docs.microsoft.com/en-us/windows-hardware/drivers/network/enumeration-keywords
#endregion ChecksumOffload

#region JumboPacket - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/keywords-that-can-be-edited
Class JumboPacket {
    [string]   $RegistryKeyword      = '*JumboPacket'
    [int]      $DisplayParameterType = '4' # 4 byte unsigned integer
    [int]      $RegistryDefaultValue = 1514

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    [int]      $NumericParameterMaxValue = 9174  # Must be >= this value 9014 + EncapOverhead (160)
    [int]      $NumericParameterMinValue = 800   # Must be <= than this value
    [int]      $NumericParameterStepValue = 1    # Must be this value

    JumboPacket () {}
}
#endregion JumboPacket

#region LSO - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/using-registry-values-to-enable-and-disable-task-offloading
    enum LSOVal {
        Disabled = 0
        Enabled  = 1
    }

    Class LSOIPv4 {
        [string]   $RegistryKeyword      = '*LSOIPv4'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [LSOVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [LSOVal]::Enabled
        [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('LSOVal').Value__

        LSOIPv4 () {}
    }

    Class LSOIPv6 {
        [string]   $RegistryKeyword      = '*LSOIPv6'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [LSOVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [LSOVal]::Enabled
        [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('LSOVal').Value__

        LSOIPv6 () {}
    }

    Class LSO {
        $LSOIPv4 = [LSOIPv4]::new()
        $LSOIPv6 = [LSOIPv6]::new()

        LSO () {}
    }
#endregion LSO

#region NDKPI - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/inf-requirements-for-ndkpi
enum NetworkDirectVal {
    Disabled = 0
    Enabled  = 1
}

enum NetworkDirectTechnologyVal {
    iWARP      = 1
    Infiniband = 2
    RoCE       = 3
    RoCEv2     = 4
}

Class NetworkDirect {
    [string] $RegistryKeyword      = '*NetworkDirect'
    [int]    $DisplayParameterType = 5

    [string]   $RegistryDefaultValue = [NetworkDirectVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [NetworkDirectVal]::Enabled
    [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('NetworkDirectVal').Value__

    NetworkDirect () {}
}

Class NetworkDirectTechnology {
    [string] $RegistryKeyword = '*NetworkDirectTechnology'
    [int]    $DisplayParameterType = 5

    # Should this have a default? Vendors will only put in what they support; probably not worth testing
    #[string] $RegistryDefaultValue = [NetworkDirectTechnologyVal]::iWARP

    [string[]] $ValidRegistryValues = [System.Enum]::GetValues('NetworkDirectTechnologyVal').Value__

    NetworkDirectTechnology () {}
}

Class NDKPI {
    $NetworkDirect = [NetworkDirect]::new()
    $NetworkDirectTechnology = [NetworkDirectTechnology]::new()
}
#endregion NDKPI

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

    [string]   $RegistryDefaultValue = [PriorityVLANTagVal]::PriorityVLANEnabled.Value__
    [string]   $DisplayDefaultValue  = [PriorityVLANTagVal]::PriorityVLANEnabled
    [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('PriorityVLANTagVal').Value__

    PriorityVLANTag () {}
}
#endregion PriorityVLANTag

#region QOS - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-ndis-qos
enum QOSVal {
    Disabled = 0
    Enabled  = 1
}

Class QOS {
    [string]   $RegistryKeyword      = '*QOS'
    [int]      $DisplayParameterType = 5

    [string]   $RegistryDefaultValue = [QOSVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [QOSVal]::Enabled
    [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('QOSVal').Value__

    QOS () {}
}
#endregion QOS

#region RSC - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rsc
enum RSCVal {
    Disabled = 0
    Enabled  = 1
}

Class RSCIPv4 {
    [string]   $RegistryKeyword      = '*RSCIPv4'
    [int]      $DisplayParameterType = 5

    [string]   $RegistryDefaultValue = [RSCVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [RSCVal]::Enabled
    [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('RSCVal').Value__

    RSCIPv4 () {}
}

Class RSCIPv6 {
    [string]   $RegistryKeyword      = '*RSCIPv6'
    [int]      $DisplayParameterType = 5

    [string]   $RegistryDefaultValue = [RSCVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [RSCVal]::Enabled
    [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('RSCVal').Value__

    RSCIPv6 () {}
}

Class RSC {
    $RSCIPv4 = [RSCIPv4]::new()
    $RSCIPv6 = [RSCIPv6]::new()

    RSC () {}
}
#endregion

#region RSS - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rss#:~:text=The%20RSS%20interface%20supports%20standardized%20INF%20keywords%20that,shows%20the%20enumeration%20standardized%20INF%20keywords%20for%20RSS%3A
    enum RSSVal {
        Disabled = 0
        Enabled  = 1
    }

    Class RSS {
        [string]   $RegistryKeyword      = '*RSS'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [RSSVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [RSSVal]::Enabled
        [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('RSSVal').Value__

        RSS () {}
    }

    enum RSSProfileVal {
        ClosestProcessor       = 1
        ClosestProcessorStatic = 2
        NUMAScaling            = 3
        NUMAScalingStatic      = 4
        ConservativeScaling    = 5
    }

    Class RSSProfile {
        [string]   $RegistryKeyword      = '*RSSProfile'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [RSSProfileVal]::NUMAScalingStatic.Value__
        [string]   $DisplayDefaultValue  = [RSSProfileVal]::NUMAScalingStatic
        [string[]] $ValidRegistryValues  = [System.Enum]::GetValues('RSSProfileVal').Value__

        RSSProfile () {}
    }

    Class RssBaseProcGroup {
        [string]   $RegistryKeyword      = '*RssBaseProcGroup'
        [int]      $DisplayParameterType = 4  # 4 byte unsigned integer

        [int]      $RegistryDefaultValue = 0

        [int]      $NumericParameterBaseValue = 10   # Must be this value
        #[int]      $NumericParameterMaxValue =      # System specific
        [int]      $NumericParameterMinValue = 0   # Must be < than this value
        [int]      $NumericParameterStepValue = 1    # Must be this value

        RssBaseProcGroup () {}
    }

    Class NumaNodeId {
        [string]   $RegistryKeyword      = '*NumaNodeId'
        [int]      $DisplayParameterType = 4  # 4 byte unsigned integer

        [int]      $RegistryDefaultValue = 65535

        [int]      $NumericParameterBaseValue = 10   # Must be this value
        [int]      $NumericParameterMaxValue = 65535 # Must be this value
        [int]      $NumericParameterMinValue = 0   # Must be < than this value
        [int]      $NumericParameterStepValue = 1    # Must be this value

        NumaNodeId () {}
    }

    Class RSSClass {
        $RSS              = [RSS]::new()
        $RSSProfile       = [RSSProfile]::new()
        $RssBaseProcGroup = [RssBaseProcGroup]::new()
        $NumaNodeId       = [NumaNodeId]::new()

        RSSClass () {}
    }
#endregion RSS

#region SRIOV - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-sr-iov
enum SRIOVVal {
    Disabled = 0
    Enabled  = 1
}

Class SRIOV {
    [string]   $RegistryKeyword      = '*SRIOV'
    [int]      $DisplayParameterType = 5

    [string]   $RegistryDefaultValue = [SRIOVVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [SRIOVVal]::Enabled
    [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('SRIOVVal').Value__

    SRIOV () {}
}
#endregion SRIOV

#region USO - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/udp-segmentation-offload-uso-
    enum USOVal {
        Disabled = 0
        Enabled  = 1
    }

    Class USOIPv4 {
        [string]   $RegistryKeyword      = '*USOIPv4'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [USOVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [USOVal]::Enabled
        [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('USOVal').Value__

        USOIPv4 () {}
    }

    Class USOIPv6 {
        [string]   $RegistryKeyword      = '*USOIPv6'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [USOVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [USOVal]::Enabled
        [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('USOVal').Value__

        USOIPv6 () {}
    }

    Class USO {
        $USOIPv4 = [USOIPv4]::new()
        $USOIPv6 = [USOIPv6]::new()

        USO () {}
    }
#endregion USO

#region VMQ - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-vmq#vmq-rss
    enum VMQVal {
        Disabled = 0
        Enabled  = 1
    }

    Class VMQ {
        [string]   $RegistryKeyword      = '*VMQ'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [VMQVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [VMQVal]::Enabled
        [string[]] $ValidRegistryValues       = [System.Enum]::GetValues('VMQVal').Value__

        VMQ () {}
    }
#endregion VMQ

#region VLANID
enum VLANIDVal {
    Disabled = 0
    Enabled  = 1
}

Class VLANID {
    [string] $RegistryKeyword      = 'VLANID'
    [int]    $DisplayParameterType = 4 # 4 byte unsigned integer

    [string] $RegistryDefaultValue = 0
    [int]    $NumericParameterBaseValue = 10  # Must be this value
    [int]    $NumericParameterMaxValue = 4095 # Must be >= this value 9014 + EncapOverhead (160)
    [int]    $NumericParameterMinValue = 0    # Must be < than this value
    [int]    $NumericParameterStepValue = 1   # Must be this value

    VLANID () {}
}
#endregion VLANID
#>


# RSS https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rss
    # *RSS, *MaxRSSProcessors, *NumRSSQueues
# IOV Subkeys - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-sr-iov
    # *NumVFs
# A bunch of stuff - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-network-devices

# Note several Requirements (e.g. NumRSSQueues etc) outlined here https://go.microsoft.com/fwlink/?linkid=2027110

Class AdapterDefinition {
    $Buffers     = [Buffers]::new()
    $JumboPacket = [JumboPacket]::new()

    $LSO   = [LSO]::new()
    $NDKPI = [NDKPI]::new()

    $PriorityVLANTag = [PriorityVLANTag]::new()

    $QOS   = [QOS]::new()
    $RSC   = [RSC]::new()

    $RSSClass = [RSSClass]::new()

    $SRIOV = [SRIOV]::new()

    $USO   = [USO]::new()
    $VMQ   = [VMQ]::new()

    $VLANID = [VLANID]::new()
}


#region Requirements

enum Base {
    PriorityVLANTag # Done
    QOS             # Done - Must be since the PriorityVLANTag requires this
}

enum TenGbEOrGreater {
    RSCIPv4         # Done
    RSCIPv6         # Done
    VLANID          # Done - We should move this to BASE
    LSOIPv4         # Done
    LSOIPv6         # Done
    JumboPacket
    RSS
    RSSProfile
    RSSBaseProcGroup
    NumaNodeId
}

enum Standard {
    RSSOnHostVPorts
    TransmitBuffers
    ReceiveBuffers
    SRIOV
    VMQ
    ChecksumOffload # https://docs.microsoft.com/en-us/windows-hardware/drivers/network/enumeration-keywords
}

enum Premium {
    RSSv2
    USO
    Timestamping
}

$Requirements = @()
if     ($TestScope -eq 'Base')            { $Requirements = [System.Enum]::GetValues('Base') }
elseif ($TestScope -eq 'TenGbEOrGreater') { $Requirements = [System.Enum]::GetValues('Base'), [System.Enum]::GetValues('TenGbEOrGreater') }
elseif ($TestScope -eq 'Standard')        { $Requirements = [System.Enum]::GetValues('Base'), [System.Enum]::GetValues('TenGbEOrGreater'), [System.Enum]::GetValues('Standard') }
elseif ($TestScope -eq 'Premium')         { $Requirements = [System.Enum]::GetValues('Base'), [System.Enum]::GetValues('TenGbEOrGreater'), [System.Enum]::GetValues('Standard'), [System.Enum]::GetValues('Premium') }

#endregion Requirements