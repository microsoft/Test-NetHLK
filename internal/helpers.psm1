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

Function Test-ContainsAllMSFTRequiredValidRegistryValues {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    # For keys of an enum type (DisplayParameterType = 5); tests whether all values in the MSFT definition are available in the adapter

    $($DefinitionPath.ValidRegistryValues) | ForEach-Object {
        $thisValidRegistryValue = $_

        if ($thisValidRegistryValue -in $AdvancedRegistryKey.ValidRegistryValues) {
            Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue"
            "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue"
            "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
}

Function Test-ContainsOnlyMSFTRequiredValidRegistryValues {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    # For keys of an enum type (DisplayParameterType = 5); tests that the adapter does not add additional validregistryvalues that are not in the MSFT definition

    $($AdvancedRegistryKey.ValidRegistryValues) | ForEach-Object {
        $thisValidRegistryValue = $_

        if ($thisValidRegistryValue -in $DefinitionPath.ValidRegistryValues) {
            Write-WTTLogMessage "[$PASS] $thisAdapter defines the ValidRegistryValue of $thisValidRegistryValue allowed for $($AdvancedRegistryKey.RegistryKeyword)"
            "[$PASS] $thisAdapter defines the ValidRegistryValue of $thisValidRegistryValue allowed for $($AdvancedRegistryKey.RegistryKeyword)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogMessage "[$FAIL] $thisAdapter defines the ValidRegistryValue of $thisValidRegistryValue allowed for $($AdvancedRegistryKey.RegistryKeyword)"
            "[$FAIL] $thisAdapter defines the ValidRegistryValue of $thisValidRegistryValue allowed for $($AdvancedRegistryKey.RegistryKeyword)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }


    if ($thisValidRegistryValue -in $AdvancedRegistryKey.ValidRegistryValues) {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) contains the required ValidRegistryValue of $thisValidRegistryValue" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}

Function Test-DisplayParameterType {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath,        # This is what is defined in the datatypes.ps1
        $MaxValue               # The numerical maximum value. This may not be specified but allows for ints of different sizes
    )

    if ($MaxValue) {
        if ($AdvancedRegistryKey.DisplayParameterType -le $DefinitionPath.DisplayParameterType) {
            Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"
            "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"
            "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is -le $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
    else {
        if ($AdvancedRegistryKey.DisplayParameterType -eq $DefinitionPath.DisplayParameterType) {
            Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"
            "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogError "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"
            "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DisplayParameterType is $($DefinitionPath.DisplayParameterType)"  | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
}

Function Test-NicSwitch {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    # For keys of an enum type (DisplayParameterType = 5); tests whether all values in the MSFT definition are available in the adapter

    if ($AdvancedRegistryKey.SwitchName -eq 'Default Switch') {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.SwitchName) NicSwitch Name is $($DefinitionPath.SwitchName)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.SwitchName) NicSwitch Name is $($DefinitionPath.SwitchName)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $thisAdapter $($AdvancedRegistryKey.SwitchName) NicSwitch Name is $($DefinitionPath.SwitchName)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.SwitchName) NicSwitch Name is $($DefinitionPath.SwitchName)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ($AdvancedRegistryKey.Flags -eq 0) {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.Flags) Flags is $($DefinitionPath.Flags)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.Flags) Flagse is $($DefinitionPath.Flags)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $thisAdapter $($AdvancedRegistryKey.Flags) Flags is $($DefinitionPath.Flags)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.Flags) Flags is $($DefinitionPath.Flags)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ($AdvancedRegistryKey.SwitchType -eq 1) {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.SwitchType) SwitchType is $($DefinitionPath.SwitchType)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.SwitchType) SwitchType is $($DefinitionPath.SwitchType)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $thisAdapter $($AdvancedRegistryKey.SwitchType) SwitchType is $($DefinitionPath.SwitchType)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.SwitchType) SwitchType is $($DefinitionPath.SwitchType)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ($AdvancedRegistryKey.SwitchId -eq 0) {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.SwitchId) SwitchId is $($DefinitionPath.SwitchId)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.SwitchId) SwitchId is $($DefinitionPath.SwitchId)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $thisAdapter $($AdvancedRegistryKey.SwitchId) SwitchId is $($DefinitionPath.SwitchId)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.SwitchId) SwitchId is $($DefinitionPath.SwitchId)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }

    if ($AdvancedRegistryKey.NumVFs -ge 32) {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.NumVFs) NumVFs is -ge $($DefinitionPath.NumVFs)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.NumVFs) NumVFs is -ge $($DefinitionPath.NumVFs)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogError "[$FAIL] $thisAdapter $($AdvancedRegistryKey.NumVFs) NumVFs is -ge $($DefinitionPath.NumVFs)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.NumVFs) NumVFs is -ge $($DefinitionPath.NumVFs)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}

Function Test-NumericParameterBaseValue {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath         # This is what is defined in the datatypes.ps1
    )

    if ($AdvancedRegistryKey.NumericParameterBaseValue -eq $DefinitionPath.NumericParameterBaseValue) {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterBaseValue is $($DefinitionPath.NumericParameterBaseValue)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}

Function Test-NumericParameterStepValue {
    param (
        $AdvancedRegistryKey ,  # This is what is configured on the adapter
        $DefinitionPath        # This is what is defined in the datatypes.ps1
    )

    if ($AdvancedRegistryKey.NumericParameterStepValue -eq $DefinitionPath.NumericParameterStepValue) {
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterStepValue is $($DefinitionPath.NumericParameterStepValue)" | Out-File -FilePath $Log -Append

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
            Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)"
            "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)"
            "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is -ge $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
    else {
        if ($AdvancedRegistryKey.NumericParameterMaxValue -eq $DefinitionPath.NumericParameterMaxValue) {
            Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)"
            "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)"
            "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMaxValue is $($DefinitionPath.NumericParameterMaxValue)" | Out-File -FilePath $Log -Append

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
        if ($AdvancedRegistryKey.NumericParameterMinValue -le $DefinitionPath.NumericParameterMinValue) {
            Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append

            $testsFailed ++
        }
    }
    else {
        if ($AdvancedRegistryKey.NumericParameterMinValue -eq $DefinitionPath.NumericParameterMinValue) {
            Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append
        }
        Else {
            Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is -le $($DefinitionPath.NumericParameterMinValue)"
            "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) NumericParameterMinValue is $($DefinitionPath.NumericParameterMinValue)" | Out-File -FilePath $Log -Append

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
        Write-WTTLogMessage "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)"
        "[$PASS] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)" | Out-File -FilePath $Log -Append
    }
    Else {
        Write-WTTLogMessage "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)"
        "[$FAIL] $thisAdapter $($AdvancedRegistryKey.RegistryKeyword) DefaultRegistryValue is $($DefinitionPath.DefaultRegistryValue)" | Out-File -FilePath $Log -Append

        $testsFailed ++
    }
}