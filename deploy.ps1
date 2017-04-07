#******************************************************************************
# File:deploy.ps1 资源的部署脚本
# Author:wesley wu
# Email:weswu@microsoft.com
# Version:1.0
#******************************************************************************
#******************************************************************************
# Global Parameters
# Caution: the lifecycle of resources in the same resource group shoulb be the same
# 注意: 一个资源组包含的资源都应该具有一样的生命周期
#******************************************************************************
# 如何查看订阅ID, 使用powershell:
# 1.Login-AzureRmAccount –EnvironmentName AzureChinaCloud 
# 2.Get-AzureRMSubscription
$subscriptionId = "subscriptionId-here"
# 要部署的资源组，这个资源组是脚本动态创建的
$resourceGroupName = "resourceGroupName-here"
# 资源组的Region,可选项是：China East/China North
$resourceGroupLocation = "Location-here"
# Master脚本的存放位置
$templateFilePath = "your-path-here\cleanup.json\deploy-master.json"
# deployMode --Complete: Only the resources declared in your template will exist in the resource group
# deployMode --Incremental:  Non-existing resources declared in your template will be added.
# 部署模式,采用incremental方式可以增量部署资源，如果要删除资源用complete模式
$deployMode = "Incremental"
# 这次部署的名字
$deployName = "produciton"


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

# 创建或检查现有的资源组
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# 测试部署模板
Write-Host "Testing deployment...";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -location $resourceGroupLocation -TemplateFile  $templateFilePath -Verbose;

# 停止活跃的部署
#if ($activeDeployment = Get-AzureRmResourceGroupDeployment -ResourceGroupName "epay" | Where {$_.ProvisioningState -eq 'Running'}){
if (Get-AzureRmResourceGroupDeployment -ResourceGroupName "epay" | Where {$_.ProvisioningState -eq 'Running'}){
    Write-Host "Clear previous active deployment...";
#    ForEach ($activeDeployment in $activeDeployments){
#    Stop-AzureRMResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deployName
#    }
}

# 开始新的部署
Write-Host "Starting deployment...";
New-AzureRmResourceGroupDeployment -Mode $deployMode -Name $deployName -ResourceGroupName $resourceGroupName -location $resourceGroupLocation -TemplateFile $templateFilePath;

# 列出创建好的资源
Write-Host "Resources which are created...";
Get-AzureRmResource | Where {$_.ResourceGroupName –eq $resourceGroupName} | ft