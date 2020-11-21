<# Typical Test Cases
- Availability of Keyword
- Default value of the keyword
- Datatype of the keyword
- Ensures all possible Values for the keyword are available
- Ensures no additional values for the keyword exist
#>

# This is the MSFT definition
$AdapterDefinition = [AdapterDefinition]::new()

$Adapters | ForEach-Object {
    $thisAdapter = $_.Name
    $thisAdapterAdvancedProperties = $AdapterAdvancedProperties | Where-Object Name -eq $thisAdapter

    # This is the configuration from the remote pNIC
    $AdapterConfiguration = Invoke-Command ${function:Get-AdvancedRegistryKeyInfo} -Session $PSSession -ArgumentList $thisAdapter, $thisAdapterAdvancedProperties.RegistryKeyword

    Switch ($AdapterConfiguration) {

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
            Test-NumericParameterMaxValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket

            # *JumboPacket: NumericParameterMinValue
            Test-NumericParameterMinValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.JumboPacket

        }

        { $_.RegistryKeyword -eq '*LsoV2IPv4' } {

            # *LsoV2IPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

            # *LsoV2IPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv4

        }

        { $_.RegistryKeyword -eq '*LsoV2IPv6' } {

            # *LsoV2IPv6: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv6

            # *LsoV2IPv6: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.LSO.LsoV2IPv6

        }

        { $_.RegistryKeyword -eq '*NetworkDirect' } {

            # *NetworkDirect: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirect

            # *NetworkDirect: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirect

        }

        { $_.RegistryKeyword -eq '*NetworkDirectTechnology' } {

            # *NetworkDirect: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirectTechnology

            # *NetworkDirectTechnology: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.NDKPI.NetworkDirectTechnology

        }

        { $_.RegistryKeyword -eq '*PacketDirect' } {

            # *PacketDirect: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.PacketDirect

            # *PacketDirect: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.PacketDirect

        }

        { $_.RegistryKeyword -eq '*QOS' } {

            # *QOS: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.QOS

            # *QOS: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.QOS

        }

        { $_.RegistryKeyword -eq '*RSCIPv4' } {

            # *RSCIPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv4

            # *RSCIPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv4

        }

        { $_.RegistryKeyword -eq '*RSCIPv6' } {

            # *RSCIPv6: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv6

            # *RSCIPv6: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSC.RSCIPv6

        }

        { $_.RegistryKeyword -eq '*RSS' } {

            # *RSS: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSS

            # *RSS: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.RSS

        }

        { $_.RegistryKeyword -eq '*SRIOV' } {

            # *SRIOV: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.SRIOV

            # *SRIOV: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.SRIOV

        }

        { $_.RegistryKeyword -eq '*UsoIPv4' } {

            # *UsoIPv4: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv4

            # *UsoIPv4: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv4

        }

        { $_.RegistryKeyword -eq '*UsoIPv6' } {

            # *UsoIPv6: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv6

            # *UsoIPv6: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.USO.UsoIPv6

        }

        { $_.RegistryKeyword -eq '*VMQ' } {

            # *VMQ: RegistryDefaultValue
            Test-RegistryDefaultValue -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQ

            # *VMQ: DisplayParameterType
            Test-DisplayParameterType -AdvancedRegistryKey $_ -DefinitionPath $AdapterDefinition.VMQ

        }
    }

<#
        # Each value in the adapter definition must be a possible value for the feature
        # Iterate through the list of possible values
        $($AdapterDefinition.RSC.RSCIPv4.PossibleValues) | ForEach-Object {
            $thisPossibleValue = $_

            # Ensure thisPossibleValue is in the list specified by the IHV
            It "*RSCIPv4: Should have the possible value of $thisPossibleValue" {
                $thisPossibleValue | Should -BeIn ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSCIPv4).ValidRegistryValues
            }
        }

        # The opposite case. The adapter cannot support extra options beyond that specified in the spec.
        # Iterate through the list of possible values
        ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSCIPv4).ValidRegistryValues | ForEach-Object {
            $thisPossibleValue = $_

            # To reduce redundancy we'll pretest the value from the adapter to ensure its not in the MSFT Definition
            # If it is not in the MSFT definition, then that is a failure.
            if ($thisPossibleValue -notin $($AdapterDefinition.RSC.RSCIPv4.PossibleValues)) {
                # Ensure thisPossibleValue is in the list specified by MSFT
                It "*RSCIPv4: Should only the possible value of $thisPossibleValue" {
                    $thisPossibleValue | Should -BeIn $($AdapterDefinition.RSC.RSCIPv4.PossibleValues)
                }
            }
        }

        # The opposite case. The adapter cannot support extra options beyond that specified in the spec.
        # Iterate through the list of possible values
        ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSCIPv6).ValidRegistryValues | ForEach-Object {
            $thisPossibleValue = $_

            # To reduce redundancy we'll pretest the value from the adapter to ensure its not in the MSFT Definition
            # If it is not in the MSFT definition, then that is a failure.
            if ($thisPossibleValue -notin $($AdapterDefinition.RSC.RSCIPv6.PossibleValues)) {
                # Ensure thisPossibleValue is in the list specified by MSFT
                It "*RSCIPv4: Should only the possible value of $thisPossibleValue" {
                    $thisPossibleValue | Should -BeIn $($AdapterDefinition.RSC.RSCIPv6.PossibleValues)
                }
            }
        }

        $($AdapterDefinition.NDKPI.NetworkDirect.PossibleValues) | ForEach-Object {
            $thisPossibleValue = $_

            # Ensure thisPossibleValue is in the list specified by the IHV
            It "*NetworkDirect: Should have the possible value of $thisPossibleValue" {
                $thisPossibleValue | Should -BeIn ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*NetworkDirect).ValidRegistryValues
            }
        }

        # The opposite case. The adapter cannot support extra options beyond that specified in the spec.
        # Iterate through the list of possible values
        ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*NetworkDirect).ValidRegistryValues | ForEach-Object {
            $thisPossibleValue = $_

            # To reduce redundancy we'll pretest the value from the adapter to ensure its not in the MSFT Definition
            # If it is not in the MSFT definition, then that is a failure.
            if ($thisPossibleValue -notin $($AdapterDefinition.NDKPI.NetworkDirect.PossibleValues)) {
                # Ensure thisPossibleValue is in the list specified by MSFT
                It "*RSCIPv4: Should only the possible value of $thisPossibleValue" {
                    $thisPossibleValue | Should -BeIn $($AdapterDefinition.RSC.RSCIPv6.PossibleValues)
                }
            }
        }

        # Tests for both *NetworkDirectTechnology - We will not test for adapter default as it is dependent on the adapter
        It "*NetworkDirectTechnology: Should have the *NetworkDirectTechnology keyword" {
            ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*NetworkDirectTechnology) | Should -Not -BeNullOrEmpty
        }

        It "*NetworkDirectTechnology: Should be of type $($AdapterDefinition.NDKPI.NetworkDirectTechnology.RegistryDataType)" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*NetworkDirectTechnology).RegistryDataType | Should Be $($AdapterDefinition.NDKPI.NetworkDirectTechnology.RegistryDataType)
        }

        #  Since the adapter can choose to support one or more of the possible values, we will only test to ensure
        #    that the values specified by the IHV are in the list of possible values. This will specifically catch
        #    the mistake in this key which first allowed for *NetworkDirectTechnology = 0 (Device Default) which was later removed


        ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*NetworkDirect).ValidRegistryValues | ForEach-Object {
            $thisPossibleValue = $_

            # Ensure thisPossibleValue is in the list specified by MSFT
            It "*NetworkDirecTechnology: Specifies the value $thisPossibleValue which should also exist in the MSFT defined list of values" {
                $thisPossibleValue | Should -BeIn $($AdapterDefinition.NDKPI.NetworkDirectTechnology.PossibleValues)
            }
        }
    }

        # Each value in the adapter definition must be a possible value for the feature
        # Iterate through the list of possible values
        $($AdapterDefinition.RSC.RSS.PossibleValues) | ForEach-Object {
            $thisPossibleValue = $_

            # Ensure thisPossibleValue is in the list specified by the IHV
            It "*RSS: Should have the possible value of $thisPossibleValue" {
                $thisPossibleValue | Should -BeIn ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSS).ValidRegistryValues
            }
        }

        # The opposite case. The adapter cannot support extra options beyond that specified in the spec.
        # Iterate through the list of possible values
        ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSS).ValidRegistryValues | ForEach-Object {
            $thisPossibleValue = $_

            # To reduce redundancy we'll pretest the value from the adapter to ensure its not in the MSFT Definition
            # If it is not in the MSFT definition, then that is a failure.
            if ($thisPossibleValue -notin $($AdapterDefinition.RSC.RSS.PossibleValues)) {
                # Ensure thisPossibleValue is in the list specified by MSFT
                It "*RSS: Should only the possible value of $thisPossibleValue" {
                    $thisPossibleValue | Should -BeIn $($AdapterDefinition.RSC.RSS.PossibleValues)
                }
            }
        }
    #>
}
