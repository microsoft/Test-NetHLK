[![Build status](https://ci.appveyor.com/api/projects/status/28dr5irvwqc34ftf?svg=true)](https://ci.appveyor.com/project/MSFTCoreNet/test-nethlk)
[![downloads](https://img.shields.io/powershellgallery/dt/Test-NetHLK.svg?label=downloads)](https://www.powershellgallery.com/packages/Test-NetHLK)

# Overview

Test-NetHLK is a module used for testing the advanced properties for Network Adapters and determining if a network switch supports the Azure Stack HCI requirements.

**This repo is a work in progress and we are actively receiving feedback to improve.**

## Installation

This module is available on the PowerShell gallery using the following command:
```Install-Module Test-NetHLK -Force```

For a disconnected system, please use:
```Save-Module Test-NetHLK -Path <SomeFolderPath>```

Then move the module to the disconnected system in the PowerShell module path. For example:
```C:\Program Files\WindowsPowerShell\Modules\Test-NetHLK\...```

## Test-NICAdvancedProperties

This cmdlet tests the properties returned from Get-NetAdapterAdvancedProperty. For syntatical help, please use the PowerShell help with the following command ```help Test-NICAdvancedProperties```

Example Use:
```Test-NICAdvancedProperties -InterfaceName Ethernet```

## Test-SwitchCapability

This cmdlet is used to verify that a network switch supports the [documented requirements](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/physical-network-requirements) for Azure Stack HCI.

# Property Definitions

Coming Soon

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
