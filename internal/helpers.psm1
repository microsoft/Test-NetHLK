Function Get-AdvancedRegistryKeyInfo {
    param (
        [parameter(Mandatory = $true)]
        [string] $interfaceName ,

        [parameter(Mandatory = $true)]
        [string[]] $registryKeyword
    )

    class AdvancedRegKeyInfo {
        $RegistryKeyword
        $RegistryDataType
        $DisplayParameterType

        AdvancedRegKeyInfo(
            [string]$Keyword,
            [string]$Type,
            [string]$Value
        ) {
            $this.RegistryKeyword      = $Keyword
            $this.RegistryDataType     = $Type
            $this.DisplayParameterType = $Value
        }
    }

    $NetAdapter = Get-NetAdapter -Name $interfaceName -ErrorAction SilentlyContinue
    If (-not ($NetAdapter)) { return 'Error: Adapter Does Not Exist' }

    $ReturnKeyInfo = @()
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $psPath = $_.PSPath

        if (( Get-ItemProperty -Path $PsPath ) -match ($NetAdapter).InterfaceGuid ) {
            foreach ($keyword in $registryKeyword) {
                $RegistryValue = (Get-ItemProperty -Path $PsPath).$keyword

                $AdvancedRegistryKeyDataType     = Get-ItemProperty -Path "$PSPath\NDI\Params\$keyword" -Name Type    -ErrorAction SilentlyContinue
                $AdvancedRegistryKeyDefaultValue = Get-ItemProperty -Path "$PSPath\NDI\Params\$keyword" -Name Default -ErrorAction SilentlyContinue

                $regKeyInfo = [AdvancedRegKeyInfo]::new($keyword, $AdvancedRegistryKeyDataType.Type, $AdvancedRegistryKeyDefaultValue.Default)
                Remove-Variable AdvancedRegistryKeyDataType, AdvancedRegistryKeyDefaultValue -ErrorAction SilentlyContinue

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