#region JumboPacket - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/keywords-that-can-be-edited
Class JumboPacket {
    [string]   $RegistryKeyword      = '*JumboPacket'
    [int]      $DisplayParameterType = '4' # 4 byte unsigned integer
    [int]      $RegistryDefaultValue = 1514

    [int]      $NumericParameterBaseValue = 10   # Must be this value
    [int]      $NumericParameterMaxValue = 9174  # Must be >= this value 9014 + EncapOverhead (160)
    [int]      $NumericParameterMinValue = 800   # Must be < than this value
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
        [string[]] $PossibleValues       = [System.Enum]::GetValues('LSOVal').Value__

        LSOIPv4 () {}
    }

    Class LSOIPv6 {
        [string]   $RegistryKeyword      = '*LSOIPv6'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [LSOVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [LSOVal]::Enabled
        [string[]] $PossibleValues       = [System.Enum]::GetValues('LSOVal').Value__

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
    [string[]] $PossibleValues       = [System.Enum]::GetValues('NetworkDirectVal').Value__

    NetworkDirect () {}
}

Class NetworkDirectTechnology {
    [string] $RegistryKeyword = '*NetworkDirectTechnology'
    [int]    $DisplayParameterType = 5

    # Should this have a default? Vendors will only put in what they support; probably not worth testing
    #[string] $RegistryDefaultValue = [NetworkDirectTechnologyVal]::iWARP

    [string[]] $PossibleValues = [System.Enum]::GetValues('NetworkDirectTechnologyVal').Value__

    NetworkDirectTechnology () {}
}

Class NDKPI {
    $NetworkDirect = [NetworkDirect]::new()
    $NetworkDirectTechnology = [NetworkDirectTechnology]::new()
}
#endregion NDKPI

#region LSO
enum PacketDirectVal {
    Disabled = 0
    Enabled  = 1
}

Class PacketDirect {
    [string]   $RegistryKeyword      = '*PacketDirect'
    [int]      $DisplayParameterType = 5

    [string]   $RegistryDefaultValue = [PacketDirectVal]::Disabled.Value__
    [string]   $DisplayDefaultValue  = [PacketDirectVal]::Disabled
    [string[]] $PossibleValues       = [System.Enum]::GetValues('PacketDirectVal').Value__

    PacketDirect () {}
}
#endregion PacketDirect

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
    [string[]] $PossibleValues       = [System.Enum]::GetValues('QOSVal').Value__

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
    [string[]] $PossibleValues       = [System.Enum]::GetValues('RSCVal').Value__

    RSCIPv4 () {}
}

Class RSCIPv6 {
    [string]   $RegistryKeyword      = '*RSCIPv6'
    [int]      $DisplayParameterType = 5

    [string]   $RegistryDefaultValue = [RSCVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [RSCVal]::Enabled
    [string[]] $PossibleValues       = [System.Enum]::GetValues('RSCVal').Value__

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
        [string[]] $PossibleValues       = [System.Enum]::GetValues('RSSVal').Value__

        RSS () {}
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
    [string[]] $PossibleValues       = [System.Enum]::GetValues('SRIOVVal').Value__

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
        [string[]] $PossibleValues       = [System.Enum]::GetValues('USOVal').Value__

        USOIPv4 () {}
    }

    Class USOIPv6 {
        [string]   $RegistryKeyword      = '*USOIPv6'
        [int]      $DisplayParameterType = 5

        [string]   $RegistryDefaultValue = [USOVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [USOVal]::Enabled
        [string[]] $PossibleValues       = [System.Enum]::GetValues('USOVal').Value__

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
        [string[]] $PossibleValues       = [System.Enum]::GetValues('VMQVal').Value__

        VMQ () {}
    }
#endregion VMQ

<# https://docs.microsoft.com/en-us/windows-hardware/drivers/network/keywords-that-can-be-edited
Class ReceiveBuffers {
    [string]   $RegistryKeyword      = '*ReceiveBuffers'
    [string]   $RegistryDataType     = 'enum'
    [string]   $RegistryDefaultValue = [RSCVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [RSCVal]::Enabled
    [string[]] $PossibleValues       = [System.Enum]::GetValues('ReceiveBuffers').Value__

    JumboPacket () {}
}

Class TransmitBuffers {
    [string]   $RegistryKeyword      = '*TransmitBuffers'
    [string]   $RegistryDataType     = 'enum'
    [string]   $RegistryDefaultValue = [RSCVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [RSCVal]::Enabled
    [string[]] $PossibleValues       = [System.Enum]::GetValues('TransmitBuffers').Value__

    JumboPacket () {}
}
#endregion
#>


# RSS https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rss
    # *RSS, *MaxRSSProcessors, *NumRSSQueues
# IOV Subkeys - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-sr-iov
    # *NumVFs
# A bunch of stuff - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-network-devices

# Note several Requirements (e.g. NumRSSQueues etc) outlined here https://go.microsoft.com/fwlink/?linkid=2027110

Class AdapterDefinition {
    $JumboPacket = [JumboPacket]::new()

    $LSO   = [LSO]::new()

    $NDKPI = [NDKPI]::new()

    $PacketDirect = [PacketDirect]::new()

    $QOS   = [QOS]::new()
    $RSC   = [RSC]::new()
    $RSS   = [RSS]::new()

    $SRIOV = [SRIOV]::new()

    $USO   = [USO]::new()
    $VMQ   = [VMQ]::new()
}


#region Requirements

enum Base {
    VLANID
    QOS
    PriorityVLANTag
}

enum TenGbEOrGreater {
    RSCIPv4
}

enum Standard {
    RSCIPv6
}

enum Premium {
    RSS
}

$Requirements = @()
if ($TestScope -eq 'Base')                { $Requirements = [System.Enum]::GetValues('Base') }
elseif ($TestScope -eq 'TenGbEOrGreater') { $Requirements = [System.Enum]::GetValues('Base'), [System.Enum]::GetValues('TenGbEOrGreater') }
elseif ($TestScope -eq 'Standard')        { $Requirements = [System.Enum]::GetValues('Base'), [System.Enum]::GetValues('TenGbEOrGreater'), [System.Enum]::GetValues('Standard') }
elseif ($TestScope -eq 'Premium')         { $Requirements = [System.Enum]::GetValues('Base'), [System.Enum]::GetValues('TenGbEOrGreater'), [System.Enum]::GetValues('Standard'), [System.Enum]::GetValues('Premium') }

#endregion Requirements