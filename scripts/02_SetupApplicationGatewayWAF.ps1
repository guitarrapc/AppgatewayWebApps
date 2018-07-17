# This script enable you to configure WebApps behind new WAF.
# I do recommend not use Script to configure WAF but use Terraform.
# If you already setup WAF, check 03_ConfigureApplicationGatewayWAF.ps1 to configure WebApps.

# don't use custom domain, use yourapp.azurewebsites.net to set webapp behind waf.
$subscription = "mysubscriptionid"
$location = "West Europ"
$rgName = "myResourceGroup"
$app = "mydockerwebapp.azurewebsites.net"
$gw = "myAppGateway"

# Login
Login-AzureRmAccount
Select-AzureRmsubscription -SubscriptionName $subscription

$rg = Get-AzureRmResourceGroup -Name $rgName

# vnet
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name subnet01 -AddressPrefix 10.0.0.0/24
$vnet = New-AzureRmVirtualNetwork -Name appgwvnet -ResourceGroupName $rg.Name -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
$sn = $vnet.Subnets[0]

# WAF
$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $rg.Name -name publicIP01 -location $location -AllocationMethod Dynamic
$gipconfig = New-AzureRmApplicationGatewayIPConfiguration -Name gatewayIP01 -Subnet $sn
$pool = New-AzureRmApplicationGatewayBackendAddressPool -Name appGatewayBackendPool -BackendFqdns $app
$match = New-AzureRmApplicationGatewayProbeHealthResponseMatch -StatusCode 200-399
$probeconfig = New-AzureRmApplicationGatewayProbeConfig -name webappprobe -Protocol Http -Path / -Interval 30 -Timeout 120 -UnhealthyThreshold 3 -PickHostNameFromBackendHttpSettings -Match $match
$poolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name appGatewayBackendHttpSettings -Port 80 -Protocol Http -CookieBasedAffinity Disabled -RequestTimeout 120 -PickHostNameFromBackendAddress -Probe $probeconfig
$fp = New-AzureRmApplicationGatewayFrontendPort -Name frontendport01  -Port 80
$fipconfig = New-AzureRmApplicationGatewayFrontendIPConfig -Name fipconfig01 -PublicIPAddress $publicip
$listener = New-AzureRmApplicationGatewayHttpListener -Name listener01 -Protocol Http -FrontendIPConfiguration $fipconfig -FrontendPort $fp
$rule = New-AzureRmApplicationGatewayRequestRoutingRule -Name rule01 -RuleType Basic -BackendHttpSettings $poolSetting -HttpListener $listener -BackendAddressPool $pool
$sku = New-AzureRmApplicationGatewaySku -Name WAF_Medium -Tier WAF -Capacity 2
$config = New-AzureRmApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode Detection
New-AzureRmApplicationGateway -Name $gw -ResourceGroupName $rg.Name -Location $location -BackendAddressPools $pool -BackendHttpSettingsCollection $poolSetting -FrontendIpConfigurations $fipconfig  -GatewayIpConfigurations $gipconfig -FrontendPorts $fp -HttpListeners $listener -RequestRoutingRules $rule -Sku $sku -WebApplicationFirewallConfig $config

# NOTICE : You must change DNS CName with WAF DNS or Public IP -> mydockerwebapp.YOURDOMAIN.TLD