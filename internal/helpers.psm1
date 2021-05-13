using module .\wttlog.psm1

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

        #region Enum Constructor
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
        #endregion Enum Constructor

        #region Int Constructor
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
        #endregion Int Constructor
    }

    $NetAdapter = Get-NetAdapter -Name $interfaceName -ErrorAction SilentlyContinue
    If (-not ($NetAdapter)) { Write-Error 'Error: Adapter Does Not Exist' }

    $ReturnKeyInfo = @()
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $psPath = $_.PSPath

        if (( Get-ItemProperty -Path $PsPath ) -match ($NetAdapter).InterfaceGuid ) {
            foreach ($keyword in $AdapterAdvancedProperties) {
                $thisKeyword = $keyword.RegistryKeyword

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

Function Get-NicSwitchInfo {
    param (
        [parameter(Mandatory = $true)]
        [string] $interfaceName
    )

    class NicSwitchInfo {
        $SwitchName
        $Flags
        $SwitchType
        $SwitchId
        $NumVFs

        #region NicSwitch Constructor
        NicSwitchInfo (
            [string]$SwitchName,
            [string]$Flags,
            [string]$SwitchType,
            [string]$SwitchId,
            [string]$NumVFs
        ) {
            $this.SwitchName = $SwitchName
            $this.Flags      = $Flags
            $this.SwitchType = $SwitchType
            $this.SwitchId   = $SwitchId
            $this.NumVFs     = $NumVFs
        }
        #endregion NicSwitch Constructor
    }

    $NetAdapter = Get-NetAdapter -Name $interfaceName -ErrorAction SilentlyContinue
    If (-not ($NetAdapter)) { Write-Error 'Error: Adapter Does Not Exist' }

    $ReturnKeyInfo = @()
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $psPath = $_.PSPath

        if (( Get-ItemProperty -Path $PsPath ) -match ($NetAdapter).InterfaceGuid ) {
            Remove-Variable NicSwitchInfo, thisNicSwitch -ErrorAction SilentlyContinue

            $thisNicSwitch = Get-ItemProperty -Path "$PsPath\NicSwitches\0"

            $SwitchName = $thisNicSwitch.'*SwitchName'
            $Flags      = $thisNicSwitch.'*Flags'
            $SwitchType = $thisNicSwitch.'*SwitchType'
            $SwitchId   = $thisNicSwitch.'*SwitchId'
            $NumVFs     = $thisNicSwitch.'*NumVFs'

            $NicSwitchInfo = [NicSwitchInfo]::new($SwitchName, $Flags, $SwitchType, $SwitchId, $NumVFs)

            Remove-Variable SwitchName, Flags, SwitchType, SwitchId, NumVFs -ErrorAction SilentlyContinue

            $ReturnKeyInfo += $NicSwitchInfo
            return $ReturnKeyInfo
        }
    }
}

Function Test-NicSwitch {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    if ($AdvancedRegistryKey.SwitchName -eq $($DefinitionPath.SwitchName)) {
        Write-WTTLogMessage "[$PASS] NicSwitch on name is $($DefinitionPath.SwitchName)"
        "[$PASS] NicSwitch on name is $($DefinitionPath.SwitchName)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] NicSwitch on name is $($DefinitionPath.SwitchName)"
        "[$FAIL] NicSwitch on name is $($DefinitionPath.SwitchName)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ($AdvancedRegistryKey.Flags -eq $($DefinitionPath.Flags)) {
        Write-WTTLogMessage "[$PASS] NicSwitch flags name is $($DefinitionPath.Flags)"
        "[$PASS] NicSwitch flags on name is $($DefinitionPath.Flags)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] NicSwitch flags name is $($DefinitionPath.Flags)"
        "[$FAIL] NicSwitch flags on name is $($DefinitionPath.Flags)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ($AdvancedRegistryKey.SwitchType -eq $($DefinitionPath.SwitchType)) {
        Write-WTTLogMessage "[$PASS] NicSwitch SwitchType is $($DefinitionPath.SwitchType)"
        "[$PASS] NicSwitch SwitchType on is $($DefinitionPath.SwitchType)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] NicSwitch SwitchType is $($DefinitionPath.SwitchType)"
        "[$FAIL] NicSwitch SwitchType on is $($DefinitionPath.SwitchType)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ($AdvancedRegistryKey.SwitchId -eq $($DefinitionPath.SwitchId)) {
        Write-WTTLogMessage "[$PASS] NicSwitch SwitchID is $($DefinitionPath.SwitchId)"
        "[$PASS] NicSwitch SwitchID on is $($DefinitionPath.SwitchId)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] NicSwitch SwitchID is $($DefinitionPath.SwitchId)"
        "[$FAIL] NicSwitch SwitchID on is $($DefinitionPath.SwitchId)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ([int] $AdvancedRegistryKey.NumVFs -ge [int] $DefinitionPath.NumVFs) {
        Write-WTTLogMessage "[$PASS] The NicSwitch NumVFs is -ge $($DefinitionPath.NumVFs)"
        "[$PASS] The NicSwitch NumVFs on is -ge $($DefinitionPath.NumVFs)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] The NicSwitch NumVFs is -ge $($DefinitionPath.NumVFs)"
        "[$FAIL] The NicSwitch NumVFs on is -ge $($DefinitionPath.NumVFs)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}

Function Test-OSVersion {
        <#
    .SYNOPSIS
    This is a generic function that compares the input value from the DefinitionPath to the Value from Configuration Data.

    This function accepts only single entries. To call multiple times, loop from the caller and make multiple calls

    .EXAMPLE Compare version data with the defined version
    Test-OSVersion -DefinitionPath $thisDefinition -ConfigurationData $thisConfiguration

    .EXAMPLE Compare version data greater than or equal to the defined version
    Test-OSVersion -DefinitionPath $thisDefinition -ConfigurationData $thisConfiguration -OrGreater

    .EXAMPLE Compare version data less than or equal to the defined version
    Test-OSVersion -DefinitionPath $thisDefinition -ConfigurationData $thisConfiguration -OrLess

    #>
    param (
        $ConfigurationData ,  # This is what is configured on the adapter
        $DefinitionPath    ,  # This is what is defined in the datatypes.ps1
        [Switch] $OrGreater,  # Greater or Equal too the defined value
        [Switch] $OrLess      # Less than or Equal too the defined value
    )
    
    if ( $OrGreater ) {
        if   ( $DefinitionPath -ge $ConfigurationData ) { return $true }
        else { return $false }
    }
    elseif   ( $OrLess ) {
        if   ( $DefinitionPath -le $ConfigurationData ) { return $true }
        else { return $false }
    }
    else {
        if   ( $DefinitionPath -eq $ConfigurationData ) { return $true }
        else { return $false }
    }
}

Function Test-ContainsAllMSFTRequiredValidRegistryValues {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    if ($Null -eq $AdvancedRegistryKey.ValidRegistryValues) {
        Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) defines none of the required ValidRegistryValue values"
        "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) defines none of the required ValidRegistryValue values" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
    else {
        $($DefinitionPath.ValidRegistryValues) | ForEach-Object {
            $thisValidRegistryValue = $_

            if ($thisValidRegistryValue -in $AdvancedRegistryKey.ValidRegistryValues) {
                Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue"
                "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append
            }
            Else {
                Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue"
                "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append

                $testsFailed ++
            }
        }
    }
}

Function Test-ContainsOnlyMSFTRequiredValidRegistryValues {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    if ($Null -eq $AdvancedRegistryKey.ValidRegistryValues) {
        Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) defines no ValidRegistryValues"
        "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) defines none of the required ValidRegistryValue" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
    else {
        $($AdvancedRegistryKey.ValidRegistryValues) | ForEach-Object {
            $thisValidRegistryValue = $_

            if ($thisValidRegistryValue -in $DefinitionPath.ValidRegistryValues) {
                Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) defines a ValidRegistryValue of $thisValidRegistryValue"
                "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) defines a ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append
            }
            Else {
                Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) defines a ValidRegistryValue of $thisValidRegistryValue"
                "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) defines a ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append

                $testsFailed ++
            }
        }
    }
}

Function Test-DisplayParameterType {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath,        # This is what is defined in the datatypes.ps1
        [Switch] $MaxValue,     # The numerical maximum value. This is optional, but allows for ints of lower sizes
        [Switch] $MinValue      # The numerical minimum value. This is optional, but allows for ints of greater sizes
    )

    if ($MaxValue) {
        if ($AdvancedRegistryKey.DisplayParameterType -le $DefinitionPath.DisplayParameterType) {
            Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"
            "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"
            "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
    if ($MinValue) {
        if ($AdvancedRegistryKey.DisplayParameterType -ge $DefinitionPath.DisplayParameterType -and $AdvancedRegistryKey.DisplayParameterType -ne 5) {
            Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -ge $($DefinitionPath.DisplayParameterType)"
            "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -ge $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -ge $($DefinitionPath.DisplayParameterType) and -lt 5"
            "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -ge $($DefinitionPath.DisplayParameterType) and -lt 5"  | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }    
    else {
        if ($AdvancedRegistryKey.DisplayParameterType -eq $DefinitionPath.DisplayParameterType) {
            Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"
            "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"
            "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
}

Function Test-NumericParameterBaseValue {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    if ($AdvancedRegistryKey.NumericParameterBaseValue -eq $DefinitionPath.NumericParameterBaseValue) {
        Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)"
        "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)"
        "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}

Function Test-NumericParameterStepValue {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath        # This is what is defined in the datatypes.ps1
    )

    if ($AdvancedRegistryKey.NumericParameterStepValue -eq $DefinitionPath.NumericParameterStepValue) {
        Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)"
        "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)"
        "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}

Function Test-NumericParameterMaxValue {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath,        # This is what is defined in the datatypes.ps1
        [Switch] $OrGreater     # Greater or Equal too the defined value
    )

    if ($OrGreater) {
        if ($AdvancedRegistryKey.NumericParameterMaxValue -ge $DefinitionPath.NumericParameterMaxValue) {
            Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)"
            "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)"
            "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
    else {
        if ($AdvancedRegistryKey.NumericParameterMaxValue -eq $DefinitionPath.NumericParameterMaxValue) {
            Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)"
            "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)"
            "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
}

Function Test-NumericParameterMinValue {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath,        # This is what is defined in the datatypes.ps1
        [Switch] $OrLess        # Less than or Equal too the defined value
    )

    if ($OrLess) {
        if ([int] $AdvancedRegistryKey.NumericParameterMinValue -le [int] $DefinitionPath.NumericParameterMinValue) {
            Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
    else {
        if ([int] $AdvancedRegistryKey.NumericParameterMinValue -eq [int] $DefinitionPath.NumericParameterMinValue) {
            Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
}

Function Test-DefaultRegistryValue {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    if ($AdvancedRegistryKey.DefaultRegistryValue -eq $DefinitionPath.DefaultRegistryValue) {
        Write-WTTLogMessage "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)"
        "[$PASS] $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)"
        "[$FAIL] $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}
