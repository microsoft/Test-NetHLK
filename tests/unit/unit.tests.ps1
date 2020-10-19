#$Credential = Get-Credential
#$PSSession = New-PSSession -Credential $Credential -ComputerName '172.29.163.125'

<# Typical Test Cases
- Availability of Keyword
- Default value of the keyword
- Datatype of the keyword
- Ensures all possible Values for the keyword are available
- Ensures no additional values for the keyword exist
#>

# Get the details from the remote adapter
$Adapters, $AdapterAdvancedProperties = Invoke-Command -Session $PSSession -ScriptBlock {

    # Update to take input
    $Adapters = Get-NetAdapter -Name pNIC01
    $AdapterAdvancedProperties = Get-NetAdapterAdvancedProperty -Name pNIC01 -AllProperties

    Return $Adapters, $AdapterAdvancedProperties
}

# Imports [AdapterDefinition] class and Get-AdvancedRegistryKeyInfo for later use
. 'C:\Users\dacuo\OneDrive - Microsoft\Documents\dev\Validate-NIC\internal\dataTypes.ps1'
. 'C:\Users\dacuo\OneDrive - Microsoft\Documents\dev\Validate-NIC\internal\helpers.ps1'

Describe "[NIC Unit Tests]" {
    $Adapters | ForEach-Object {
        $thisAdapter = $_.Name
        $thisAdapterAdvancedProperties = $AdapterAdvancedProperties | Where Name -eq $thisAdapter

        # This is the configuration from the remote pNIC
        $AdapterConfiguration = Invoke-Command ${function:Get-AdvancedRegistryKeyInfo} -Session $PSSession -ArgumentList $thisAdapter, $thisAdapterAdvancedProperties.RegistryKeyword

        # This is the MSFT definition
        $AdapterDefinition = [AdapterDefinition]::new()

        Context 'INF Keywords: Receive Segment Coalescing v4 and v6' {
            It "*RSCIPv4: Should have the *RSCIPv4 keyword" {
                ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*RSCIPv4) | Should -Not -BeNullOrEmpty
            }

            It "*RSCIPv4: Should be $($AdapterDefinition.RSC.RSCIPv4.DisplayDefaultValue) by default" {
                ($AdapterConfiguration | Where RegistryKeyword -eq `*RSCIPv4).RegistryDefaultValue | Should Be $($AdapterDefinition.RSC.RSCIPv4.RegistryDefaultValue)
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

            <#  Since the adapter can choose to support one or more of the possible values, we will only test to ensure
                that the values specified by the IHV are in the list of possible values. This will specifically catch 
                the mistake in this key which first allowed for *NetworkDirectTechnology = 0 (Device Default) which was later removed
            #>

            ($thisAdapterAdvancedProperties | Where RegistryKeyword -eq `*NetworkDirect).ValidRegistryValues | ForEach-Object {
                $thisPossibleValue = $_

                # Ensure thisPossibleValue is in the list specified by MSFT
                It "*NetworkDirecTechnology: Specifies the value $thisPossibleAdapter which should also exist in the MSFT defined list of values" {
                    $thisPossibleValue | Should -BeIn $($AdapterDefinition.NDKPI.NetworkDirectTechnology.PossibleValues)
                }
            }
        }

        #Add SRIOV and min number of VFs supported should change based on standard/premium
        Context 'INF Keywords: SR-IOV' {

        }
    }
}
