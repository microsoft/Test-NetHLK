<# Typical Test Cases
- Availability of Keyword
- Default value of the keyword
- Datatype of the keyword
- Ensures all possible Values for the keyword are available
- Ensures no additional values for the keyword exist
#>

#>

# This is the MSFT definition
$AdapterDefinition = [AdapterDefinition]::new()

$Adapters | ForEach-Object {
    $thisAdapter = $_.Name
    $thisAdapterAdvancedProperties = $AdapterAdvancedProperties | Where-Object Name -eq $thisAdapter

    # This is the configuration from the remote pNIC
    $AdapterConfiguration = Invoke-Command ${function:Get-AdvancedRegistryKeyInfo} -Session $PSSession -ArgumentList $thisAdapter, $thisAdapterAdvancedProperties.RegistryKeyword

    Switch ($AdapterConfiguration) {
        { $_.RegistryKeyword -eq '*NetworkDirect' } {

            # *NetworkDirect: RegistryDefaultValue
            if ($_.RegistryDefaultValue -eq $AdapterDefinition.NDKPI.NetworkDirect.RegistryDefaultValue) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *NetworkDirect RegistryDefaultValue is $($AdapterDefinition.NDKPI.NetworkDirect.RegistryDefaultValue)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue

            # *NetworkDirect: RegistryDataType
            if ($_.RegistryDataType -eq $AdapterDefinition.NDKPI.NetworkDirect.RegistryDataType) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *NetworkDirect RegistryDataType is $($AdapterDefinition.NDKPI.NetworkDirect.RegistryDataType)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue
        }

        { $_.RegistryKeyword -eq '*NetworkDirectTechnology' } {

            # *NetworkDirectTechnology: RegistryDefaultValue
            if ($_.RegistryDefaultValue -eq $AdapterDefinition.NDKPI.NetworkDirectTechnology.RegistryDefaultValue) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *NetworkDirectTechnology RegistryDefaultValue is $($AdapterDefinition.NDKPI.NetworkDirectTechnology.RegistryDefaultValue)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue

            # *NetworkDirectTechnology: RegistryDataType
            if ($_.RegistryDataType -eq $AdapterDefinition.NDKPI.NetworkDirectTechnology.RegistryDataType) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *NetworkDirectTechnology RegistryDataType is $($AdapterDefinition.NDKPI.NetworkDirectTechnology.RegistryDataType)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue
        }

        { $_.RegistryKeyword -eq '*RSCIPv4' } {

            # *RSCIPv4: RegistryDefaultValue
            if ($_.RegistryDefaultValue -eq $AdapterDefinition.RSC.RSCIPv4.RegistryDefaultValue) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *RSCIPv4 RegistryDefaultValue is $($AdapterDefinition.RSC.RSCIPv4.RegistryDefaultValue)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue

            # *RSCIPv4: RegistryDataType
            if ($_.RegistryDataType -eq $AdapterDefinition.RSC.RSCIPv4.RegistryDataType) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *RSCIPv4 RegistryDataType is $($AdapterDefinition.RSC.RSCIPv4.RegistryDataType)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue
        }

        { $_.RegistryKeyword -eq '*RSCIPv6' } {

            # *RSCIPv6: RegistryDefaultValue
            if ($_.RegistryDefaultValue -eq $AdapterDefinition.RSC.RSCIPv6.RegistryDefaultValue) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *RSCIPv6 RegistryDefaultValue is $($AdapterDefinition.RSC.RSCIPv6.RegistryDefaultValue)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue

            # *RSCIPv6: RegistryDataType
            if ($_.RegistryDataType -eq $AdapterDefinition.RSC.RSCIPv6.RegistryDataType) { $PassFail = $pass }
            Else { $PassFail = $fail; $testsFailed ++ }

            "[$PassFail] $thisAdapter *RSCIPv6 RegistryDataType is $($AdapterDefinition.RSC.RSCIPv6.RegistryDataType)" | Out-File -FilePath $Log -Append

            Remove-Variable PassFail -ErrorAction SilentlyContinue
        }
    }

<#
    Context 'INF Keywords: Receive Segment Coalescing v4 and v6' {
        It "*RSCIPv4: Should have the *RSCIPv4 keyword" {
            ($thisAdapterAdvancedProperties | Where-Object RegistryKeyword -eq `*RSCIPv4) | Should -Not -BeNullOrEmpty
        }

        It "*RSCIPv4: Should be $($AdapterDefinition.RSC.RSCIPv4.DisplayDefaultValue) by default" {
            ($AdapterConfiguration | Where-Object RegistryKeyword -eq `*RSCIPv4).RegistryDefaultValue | Should Be $($AdapterDefinition.RSC.RSCIPv4.RegistryDefaultValue)
        }

        It "*RSCIPv4: Should be of type $($AdapterDefinition.RSC.RSCIPv4.RegistryDataType)" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*RSCIPv4).RegistryDataType | Should Be $($AdapterDefinition.RSC.RSCIPv4.RegistryDataType)
        }

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

        It "*RSCIPv6: Should have the *RSCIPv6 keyword" {
            ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSCIPv6) | Should -Not -BeNullOrEmpty
        }

        It "*RSCIPv6: Should be $($AdapterDefinition.RSC.RSCIPv6.DisplayDefaultValue) by default" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*RSCIPv6).RegistryDefaultValue | Should Be $($AdapterDefinition.RSC.RSCIPv6.RegistryDefaultValue)
        }

        It "*RSCIPv6: Should be of type $($AdapterDefinition.RSC.RSCIPv6.RegistryDataType)" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*RSCIPv6).RegistryDataType | Should Be $($AdapterDefinition.RSC.RSCIPv6.RegistryDataType)
        }

        # Iterate through the list of possible values
        $($AdapterDefinition.RSC.RSCIPv6.PossibleValues) | ForEach-Object {
            $thisPossibleValue = $_

            # Ensure thisPossibleValue is in the list specified by the IHV
            It "*RSCIPv6: Should have the possible value of $thisPossibleValue" {
                $thisPossibleValue | Should -BeIn ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSCIPv6).ValidRegistryValues
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
    }

    #Add SRIOV and min number of VFs supported should change based on standard/premium
    Context 'INF Keywords: Network Direct Kernel Provider Interface' {
        # Tests for both *NetworkDirect
        It "*NetworkDirect: Should have the *NetworkDirect keyword" {
            ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*NetworkDirect) | Should -Not -BeNullOrEmpty
        }

        It "*NetworkDirect: Should be $($AdapterDefinition.NDKPI.NetworkDirect.DisplayDefaultValue) by default" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*NetworkDirect).RegistryDefaultValue | Should Be $($AdapterDefinition.NDKPI.NetworkDirect.RegistryDefaultValue)
        }

        It "*NetworkDirect: Should be of type $($AdapterDefinition.NDKPI.NetworkDirect.RegistryDataType)" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*NetworkDirect).RegistryDataType | Should Be $($AdapterDefinition.NDKPI.NetworkDirect.RegistryDataType)
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

    Context 'INF Keywords: Receive Side Scaling' {
        It "*RSS: Should have the *RSS keyword" {
            ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSS) | Should -Not -BeNullOrEmpty
        }

        It "*RSS: Should be $($AdapterDefinition.RSC.RSS.DisplayDefaultValue) by default" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*RSS).RegistryDefaultValue | Should Be $($AdapterDefinition.RSC.RSS.RegistryDefaultValue)
        }

        It "*RSS: Should be of type $($AdapterDefinition.RSC.RSS.RegistryDataType)" {
            ($AdapterConfiguration | Where RegistryKeyword -eq `*RSS).RegistryDataType | Should Be $($AdapterDefinition.RSC.RSS.RegistryDataType)
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
    }
    #>
}
