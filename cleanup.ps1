#******************************************************************************
# File:cleanup.ps1 资源的删除脚本，现版本下的模板会删除指定资源组内所有的资源，如果只想删除特定的资源，
#                  需要将部署资源的模板复制一份，然后在模板中去掉要删除的资源即可。
# Author:wesley wu
# Email:weswu@microsoft.com
# Version:1.0
#******************************************************************************
#******************************************************************************
# Global Parameters
# Caution: Only the resources declared in your template will exist in the resource group
# 注意: 一个资源组包含的资源都应该具有一样的生命周期，现版本下的模板会删除指定资源组内所有的资源，
#      如果只想删除特定的资源，需要将部署资源的模板复制一份，然后在模板中去掉要删除的资源即可。
#******************************************************************************
# 如何查看订阅ID, 使用powershell:
# 1.Login-AzureRmAccount –EnvironmentName AzureChinaCloud 
# 2.Get-AzureRMSubscription
$subscriptionId = "subscriptionId-here"
# 要删除的资源组，这个资源组内的所以资源会被删除
$resourceGroupName = "resourceGroupName-here"
# 资源组的Region,可选项是：China East/China North
$resourceGroupLocation = "Location-here"
# 资源定义的模板文件的位置，如果只想删除特定的资源，需要将部署资源的模板复制一份，然后在模板中去掉要删除的资源即可
$templateFilePath = "your-path-here\cleanup.json"
# deployMode --Complete: Only the resources declared in your template will exist in the resource group
# deployMode --Incremental:  Non-existing resources declared in your template will be added.
# 部署模式,采用incremental方式可以增量部署资源，如果要删除资源用complete模式
$deployMode = "Complete"


#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
Write-Host "Logging in...";
# 免除每次运行脚本都要登陆，采用如下方式获取登陆的Token,使用powershell:
# 1.Login-AzureRmAccount –EnvironmentName AzureChinaCloud
# 2.Save-AzureRmProfile -Path "C:\your-path-here\accesstoken.json"
# 保存登陆Token的路径，注意要保证这个文件的安全
$cnProfile = "C:\your-path-here\accesstoken.json"
Select-AzureRmProfile -Path $cnProfile

# 选择相应的订阅
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# 检查现有的资源组
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "The resource group '$resourceGroupName' in location '$resourceGroupLocation does not exist!'";
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# 测试部署模板
Write-Host "Testing cleanup...";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile  $templateFilePath -Verbose;


# 开始新的部署
Write-Host "Starting cleanup...";
New-AzureRmResourceGroupDeployment -Mode $deployMode -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath;

# 列出剩余的资源
Write-Host "Resources which are still remaining in the resource group...";
Get-AzureRmResource | Where {$_.ResourceGroupName –eq $resourceGroupName} | ft
