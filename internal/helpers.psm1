Function Get-AdvancedRegistryKeyInfo {
    param (
        [parameter(Mandatory = $true)]
        [string] $interfaceName ,

        [parameter(Mandatory = $true)]
        $AdapterAdvancedProperties
    )

    class AdvancedRegKeyInfo {
        $RegistryKeyword
        $DisplayParameterType
        $DefaultRegistryValue
        $ValidRegistryValues
        $NumericParameterBaseValue
        $NumericParameterMaxValue
        $NumericParameterMinValue
        $NumericParameterStepValue

        AdvancedRegKeyInfo (
            [string]   $Keyword,
            [string]   $DisplayParameterType,
            [string]   $DefaultRegistryValue,
            [string[]] $ValidRegistryValues
        ) {
            $this.RegistryKeyword      = $Keyword
            $this.DisplayParameterType = $DisplayParameterType
            $this.DefaultRegistryValue = $DefaultRegistryValue
            $this.ValidRegistryValues  = $ValidRegistryValues
        }

        AdvancedRegKeyInfo (
            [string]$Keyword,
            [string]$DisplayParameterType,
            [string]$DefaultRegistryValue,
            [string]$NumericParameterBaseValue,
            [string]$NumericParameterMaxValue,
            [string]$NumericParameterMinValue,
            [string]$NumericParameterStepValue
        ) {
            $this.RegistryKeyword      = $Keyword
            $this.DisplayParameterType = $DisplayParameterType
            $this.DefaultRegistryValue = $DefaultRegistryValue
            $this.NumericParameterBaseValue = $NumericParameterBaseValue
            $this.NumericParameterMaxValue  = $NumericParameterMaxValue
            $this.NumericParameterMinValue  = $NumericParameterMinValue
            $this.NumericParameterStepValue = $NumericParameterStepValue
        }
    }

    $NetAdapter = Get-NetAdapter -Name $interfaceName -ErrorAction SilentlyContinue
    If (-not ($NetAdapter)) { return 'Error: Adapter Does Not Exist' }

    $ReturnKeyInfo = @()
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $psPath = $_.PSPath

        if (( Get-ItemProperty -Path $PsPath ) -match ($NetAdapter).InterfaceGuid ) {
            foreach ($keyword in $AdapterAdvancedProperties) {
                $thisKeyword = $keyword.RegistryKeyword
                $RegistryValue = (Get-ItemProperty -Path $PsPath).$thisKeyword

                $DisplayParameterType = $keyword.DisplayParameterType
                $DefaultRegistryValue = $keyword.DefaultRegistryValue

                if ($DisplayParameterType -eq 5) {
                    $ValidRegistryValues = $keyword.ValidRegistryValues
                    $regKeyInfo = [AdvancedRegKeyInfo]::new($thisKeyword, $DisplayParameterType, $DefaultRegistryValue, $ValidRegistryValues)
                }
                ElseIf ($DisplayParameterType -le 4) {
                    $NumericParameterBaseValue = $keyword.NumericParameterBaseValue
                    $NumericParameterMaxValue  = $keyword.NumericParameterMaxValue
                    $NumericParameterMinValue  = $keyword.NumericParameterMinValue
                    $NumericParameterStepValue = $keyword.NumericParameterStepValue

                    $regKeyInfo = [AdvancedRegKeyInfo]::new($thisKeyword, $DisplayParameterType, $DefaultRegistryValue, $NumericParameterBaseValue, $NumericParameterMaxValue, $NumericParameterMinValue, $NumericParameterStepValue)
                }

                Remove-Variable DisplayParameterType, DefaultRegistryValue, ValidRegistryValues, NumericParameterBaseValue, `
                                NumericParameterMaxValue, NumericParameterMinValue, NumericParameterStepValue -ErrorAction SilentlyContinue

                $ReturnKeyInfo += $regKeyInfo
            }
        }
    }

    return $ReturnKeyInfo
}

Function Test-RegistryDefaultValue {
    param (
        $AdvancedRegistryKey ,
        $DefinitionPath
    )

    # *NetworkDirect: RegistryDefaultValue
    if ($AdvancedRegistryKey.RegistryDefaultValue -eq $DefinitionPath.RegistryDefaultValue) { $PassFail = $pass }
    Else { $PassFail = $fail; $testsFailed ++ }

    "[$PassFail] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) RegistryDefaultValue is $($DefinitionPath.RegistryDefaultValue)" | Out-File -FilePath $Log -Append
}

Function Test-DisplayParameterType {
    param (
        $AdvancedRegistryKey ,
        $DefinitionPath
    )

    if ($AdvancedRegistryKey.DisplayParameterType -eq $DefinitionPath.DisplayParameterType) { $PassFail = $pass }
    Else { $PassFail = $fail; $testsFailed ++ }

    "[$PassFail] $thisAdapter *NetworkDirect DisplayParameterType is $($DefinitionPath.DisplayParameterType)" | Out-File -FilePath $Log -Append
}

Function Test-NumericParameterBaseValue {
    param (
        $AdvancedRegistryKey ,
        $DefinitionPath
    )

    if ($AdvancedRegistryKey.NumericParameterBaseValue -eq $DefinitionPath.NumericParameterBaseValue) { $PassFail = $pass }
    Else { $PassFail = $fail; $testsFailed ++ }

    "[$PassFail] $thisAdapter *NetworkDirect NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)" | Out-File -FilePath $Log -Append
}

Function Test-NumericParameterStepValue {
    param (
        $AdvancedRegistryKey ,
        $DefinitionPath
    )

    if ($AdvancedRegistryKey.NumericParameterStepValue -eq $DefinitionPath.NumericParameterStepValue) { $PassFail = $pass }
    Else { $PassFail = $fail; $testsFailed ++ }

    "[$PassFail] $thisAdapter *NetworkDirect NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)" | Out-File -FilePath $Log -Append
}

Function Test-NumericParameterMaxValue {
    param (
        $AdvancedRegistryKey ,
        $DefinitionPath
    )

    if ($AdvancedRegistryKey.NumericParameterMaxValue -ge $DefinitionPath.NumericParameterMaxValue) { $PassFail = $pass }
    Else { $PassFail = $fail; $testsFailed ++ }

    "[$PassFail] $thisAdapter *NetworkDirect NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append
}

Function Test-NumericParameterMinValue {
    param (
        $AdvancedRegistryKey ,
        $DefinitionPath
    )

    if ($AdvancedRegistryKey.NumericParameterMinValue -le $DefinitionPath.NumericParameterMinValue) { $PassFail = $pass }
    Else { $PassFail = $fail; $testsFailed ++ }

    "[$PassFail] $thisAdapter *NetworkDirect NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append
}