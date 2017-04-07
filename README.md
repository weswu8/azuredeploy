Azure Resource Group 部署模板
====
Azure采用资源组的方式管理资源，在架构设计时建议一个资源组内的资源具有相同的生命周期。本模板是一套包含嵌套关系的部署模板。
本模板在Azure China测试通过. 以下是这个模板的说明：

本模板自动创建的资源：
----
	1 x Load Balancer：引用一个已经定义好的公网IP，一个LoadBalancing的规则，一个健康检查的规则。
	
	4 x Availability Set： 分别是：webAvSet，middleAvSet, cacheAvSet，dbAvSet
	
	2 x Storage Accounts: 一个Standard账号用来存放普通VM的磁盘，一个preminum用来存放数据库VM的磁盘
	
	2 x Web Server: 每台配置如下: 放置于webAvSet中，Centos, 1x OSDisk, 1x DataDisk, 客户自定义启动脚本,
                  	1xPrivate IP, 自动挂接到之前创建的LoadBalancer上
	
	2 x Mdidle Server: 每台配置如下:放置于middleAvSet中，Centos, 1x OSDisk, 1x DataDisk, 
					   客户自定义启动脚本, 1xPrivate IP
	
	2 x Cache Server: 每台配置如下:放置于cacheAvSet中，Centos, 1x OSDisk, 1x DataDisk, 
					  客户自定义启动脚本, 1xPrivate IP
	
	2 x DB Server: 每台配置如下:放置于dbAvSet中， Centos, 1x OSDisk, 1x DataDisk(可采用高级SSD存储账号), 
	               1xPrivate IP

使用方式：
----
1.在一个公用资源组内定义如下公共的资源(本模板不包括这部分内容):

	Vnet：定义public和privat 子网, web Server会放置在public子网，其它的server放置在private子网.
	
	NSG: 每种Server的NSG，如webnsg, dbnsg.
	
	public IP address: 定义保留的Public IP, 这个会用于LoadBalancer的前段.

2.在 Powershell IDE中 运行 deploy.ps1 脚本即可.
	如果db使用高级存储账号，请在deploy-master.json模板中修改如下参数:
	
		"db001VMSize": "Standard_DS1_v2"
		
		"premiumStorageAccountName": {
							"value": "[reference('storageAccountslinkedTemplate').outputs.premiumStorageAccountName.value]"
		},
		
3.删除或者清空资源，在 Powershell IDE中运行cleanup.ps1 脚本即可.

特殊说明：
----
	1.为避免运行脚本是都要登陆Portal的问题，本脚本采用了保存相关Token的方式，这个方式有安全隐患，不建议在生产环境中使用.
	
	2.部署模式,采用incremental方式可以增量部署资源，如果要删除资源用complete模式。如果只想删除特定的资源，
		 需要将部署资源的模板复制一份，然后在模板中去掉要删除的资源即可.
		 
	3.主模板文件可以在本机，但是所有的子模板必须在可通过internet访问的地方.

文件说明：
----
	------deploy.ps1   模板的启动文件，Powershell的部署脚本.
	
	------cleanup.ps1   模板的启动文件，Powershell的清空资源和删除资源的脚本.
	
	------deploy-master.json 主模板文件，deploy.ps1会调用主模板，主模板会调用
	      相应的子模板，增加或删除相应的资源从这里着手.
							  
	------cleanup.json 清空或删除指定资源的模板,减少资源从这里开始.
	
	------deploy-loadbalancer.json LoadBalancer的模板.
	
	------deploy-availabilitysets.json 可用性集的模板.
	
	------deploy-storageaccounts.json 存储账号的模板.
	
	------deploy-vm-web001.json  web001 Server的模板，如果不需要每台机器都定制，
	      可采用RM的Copy功能批量创建服务器.
								 
	------deploy-vm-db001.json  db001 Server的模板，如果不需要每台机器都定制，
	      可采用RM的Copy功能批量创建服务器.
