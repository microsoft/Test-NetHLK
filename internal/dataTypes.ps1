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
        [string] $RegistryDataType     = 'Enum'
        [string] $RegistryDefaultValue = [NetworkDirectVal]::Enabled.Value__
        [string] $DisplayDefaultValue  = [NetworkDirectVal]::Enabled
        [string[]] $PossibleValues     = [System.Enum]::GetValues('NetworkDirectVal').Value__

        NetworkDirect () {}
    }

    Class NetworkDirectTechnology {
        [string] $RegistryKeyword = '*NetworkDirectTechnology'
        [string] $RegistryDataType = 'Enum'

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

#region RSC - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rsc
    enum RSCVal {
        Disabled = 0
        Enabled  = 1
    }

    Class RSCIPv4 {
        [string]   $RegistryKeyword      = '*RSCIPv4'
        [string]   $RegistryDataType     = 'Enum'
        [string]   $RegistryDefaultValue = [RSCVal]::Enabled.Value__
        [string]   $DisplayDefaultValue  = [RSCVal]::Enabled
        [string[]] $PossibleValues       = [System.Enum]::GetValues('RSCVal').Value__

        RSCIPv4 () {}
    }

    Class RSCIPv6 {
        [string]   $RegistryKeyword      = '*RSCIPv6'
        [string]   $RegistryDataType     = 'Enum'
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

<#
#region RSS - https://docs.microsoft.com/en-us/windows-hardware/drivers/network/standardized-inf-keywords-for-rsc
enum RSSVal {
    Disabled = 0
    Enabled  = 1
}

Class RSS {
    [string]   $RegistryKeyword      = '*RSCIPv6'
    [string]   $RegistryDataType     = 'enum'
    [string]   $RegistryDefaultValue = [RSCVal]::Enabled.Value__
    [string]   $DisplayDefaultValue  = [RSCVal]::Enabled
    [string[]] $PossibleValues       = [System.Enum]::GetValues('RSCVal').Value__

    RSCIPv6 () {}
}

Class RcvSideScaling {
    $RSS = [RSS]::new()

    RSS () {}
}
#endregion
#>
#region Generic
# https://docs.microsoft.com/en-us/windows-hardware/drivers/network/keywords-that-can-be-edited
Class JumboPacket {
    [string]   $RegistryKeyword      = '*JumboPacket'
    [string]   $RegistryDataType     = '4' #4 byte unsigned integer
    [int]      $RegistryDefaultValue = 1514
    [int]      $DisplayDefaultValue  = 1514
    [int]      $NumericParameterBaseValue = 10
    [int]      $NumericParameterMaxValue = 9014
    [int]      $NumericParameterMinValue = 614
    [int]      $NumericParameterStepValue = 1

    [string[]] $PossibleValues       = [System.Enum]::GetValues('JumboPacket').Value__

    JumboPacket () {}
}
<#
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
Class AdapterDefinition {
    $RSC   = [RSC]::new()
    $NDKPI = [NDKPI]::new()
}
