# 002-HubSpokeTopology

This repo pairs with my YouTube videos:
- Part 1 VNETs, Subnets and Peerings - https://youtu.be/n76A7vg5PsI
- Part 2 Logging and Network Security Groups - https://youtu.be/oJD2l7I4V_I
- Part 3 Bastion Service - https://youtu.be/OGxXnzKPzx0

The goal of the video was to recreate the following Hub-Spoke Network design from Microsoft.  While I realize Microsoft provides all the code at the bottom of the link, I only used it when I was stuck during the prep work.  I'm using the video and github repo to help document my own learning.  I hope this can be useful to someone else as well.

https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke?tabs=cli

<img width="815" alt="hub-spoke" src="https://user-images.githubusercontent.com/120427986/209974191-99765631-ec05-44db-8aaf-c4d1fe80775f.png">

Supporting Links:
- Download bicep tools - https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install]
- Visual Studio Code - https://code.visualstudio.com
- Bastion Service NSG Info- https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg

Links to documentation for each resource object used:
- Virtual Networks - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-bicep
- Peerings - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/virtualnetworkpeerings?pivots=deployment-language-bicep
- Network Security Groups - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups?pivots=deployment-language-bicep
- Log Analytics Workspace - https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?pivots=deployment-language-bicep
- Diagnostic Settings - https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?pivots=deployment-language-bicep
- Azure Monitor
- Public IP (Bastion) - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses?pivots=deployment-language-bicep
- Bastion Service - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/bastionhosts?pivots=deployment-language-bicep
- Firewall
- VPN Gateway
