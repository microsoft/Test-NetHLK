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
        $RegistryDefaultValue

        AdvancedRegKeyInfo(
            [string]$Keyword,
            [string]$Type,
            [string]$Value
        ) {
            $this.RegistryKeyword      = $Keyword
            $this.RegistryDataType     = $Type
            $this.RegistryDefaultValue = $Value
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
