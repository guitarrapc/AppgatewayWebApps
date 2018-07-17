# This script enable you to configure WebApps behind existing WAF.
# WebApps behind WAS only enabled by PowerShell Script because these 2 key parameter is only enabled by AzureRM PowerShell.
# key point1 : Add-AzureRmApplicationGatewayProbeConfig -PickHostNameFromBackendHttpSettings
# key point2 : Set-AzureRmApplicationGatewayBackendHttpSettings -PickHostNameFromBackendAddress
# key point3 : App service name must not custom domain, but use yourapp.azurewebsites.net to set webapp behind waf.
# refer : https://blogs.msdn.microsoft.com/waws/2017/11/21/setting-up-application-gateway-with-an-app-service-that-uses-azure-active-directory-authentication/
# refer : https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-web-app-powershell#configure-a-web-app-behind-an-existing-application-gateway

$rgName = "myResourceGroup"
$app = "mydockerwebapp.azurewebsites.net"
$probeName = "webappprobe2"
$gwName = "myAppGateway"

$rg = Get-AzureRmResourceGroup -Name $rgName
$gw = Get-AzureRmApplicationGateway -Name $gwName -ResourceGroupName $rg
$match = New-AzureRmApplicationGatewayProbeHealthResponseMatch -StatusCode 200-399
Add-AzureRmApplicationGatewayProbeConfig -name $probeName -ApplicationGateway $gw -Protocol Http -Path / -Interval 30 -Timeout 120 -UnhealthyThreshold 3 -PickHostNameFromBackendHttpSettings -Match $match
$probe = Get-AzureRmApplicationGatewayProbeConfig -name $probeName -ApplicationGateway $gw
Set-AzureRmApplicationGatewayBackendHttpSettings -Name appGatewayBackendHttpSettings -ApplicationGateway $gw -PickHostNameFromBackendAddress -Port 80 -Protocol http -CookieBasedAffinity Disabled -RequestTimeout 30 -Probe $probe
Set-AzureRmApplicationGatewayBackendAddressPool -Name appGatewayBackendPool -ApplicationGateway $gw -BackendFqdns $app
Set-AzureRmApplicationGateway -ApplicationGateway $gw

# NOTICE : You must change DNS CName with WAF DNS or Public IP -> mydockerwebapp.YOURDOMAIN.TLD