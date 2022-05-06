#!/bin/bash
cd ..


if [[ -z $RESOURCE_GROUP ]]; then
export RESOURCE_GROUP=java-on-azure-$RANDOM
export REGION=westus2
fi

az group create --name $RESOURCE_GROUP --location $REGION
if [[ -z $APPSERVICE_PLAN ]]; then
export APPSERVICE_PLAN=appservice-plan-$RANDOM
fi
az appservice plan create \
--resource-group $RESOURCE_GROUP \
--location $REGION \
--name $APPSERVICE_PLAN \
--is-linux \
--sku P1v3

cd compute/appservice/tomcat-helloworld

mvn clean install
export APPSERVICE_TOMCAT_HELLOWORLD=appservice-tomcat-helloworld-$RANDOM
mvn azure-webapp:deploy \
-DappName=$APPSERVICE_TOMCAT_HELLOWORLD \
-DappServicePlan=$APPSERVICE_PLAN \
-DresourceGroup=$RESOURCE_GROUP

sleep 60
cd ../../..

az webapp deployment slot create \
--resource-group $RESOURCE_GROUP \
--name $APPSERVICE_TOMCAT_HELLOWORLD \
--slot staging
az webapp show --name $APPSERVICE_TOMCAT_HELLOWORLD \
--resource-group $RESOURCE_GROUP \
--query=defaultHostName
az webapp deployment slot list --name $APPSERVICE_TOMCAT_HELLOWORLD \
--resource-group $RESOURCE_GROUP \
--query='[].defaultHostName'

cd compute/appservice/deploy-to-deployment-slot

mvn clean install
mvn azure-webapp:deploy \
-DappName=$APPSERVICE_TOMCAT_HELLOWORLD \
-DappServicePlan=$APPSERVICE_PLAN \
-DresourceGroup=$RESOURCE_GROUP \
-DdeploymentSlotName=staging

cd ../../..

az webapp deployment slot swap \
--resource-group $RESOURCE_GROUP \
--name $APPSERVICE_TOMCAT_HELLOWORLD \
--slot staging

export RESULT=$(az webapp show --resource-group $RESOURCE_GROUP --name $APPSERVICE_TOMCAT_HELLOWORLD --output tsv --query state)
if [[ "$RESULT" != Running ]]; then
echo 'Web application is NOT running'
az group delete --name $RESOURCE_GROUP --yes || true
exit 1
fi

export URL=https://$(az webapp show --resource-group $RESOURCE_GROUP --name $APPSERVICE_TOMCAT_HELLOWORLD --output tsv --query defaultHostName)
export RESULT=$(curl $URL)

az group delete --name $RESOURCE_GROUP --yes || true

if [[ "$RESULT" != *"Hello Staging"* ]]; then
echo "Response did not contain 'Hello Staging'"
exit 1
fi