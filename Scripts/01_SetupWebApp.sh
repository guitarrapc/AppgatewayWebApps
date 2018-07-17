# This Script enable you to configure Docker hosted on WebApps

location=West Europ
rg=myResourceGroup
sp=myAppServicePlan
app=mydockerwebapp_test_gwapp
docker=guitarrapc/mydockerimage:v1.0.0

cd docker-django-webapp-linux
docker build --tag $docker .
docker push $docker

az login
az group create --name $rg --location $location
az appservice plan create --name $sp --resource-group $rg --sku Free --is-linux
az webapp create --resource-group $rg --plan $sp --name $app --deployment-container-image-name $docker
az webapp config appsettings set --resource-group $rg --name $app --settings WEBSITES_PORT=8000
az webapp restart --resource-group $rg --name $app