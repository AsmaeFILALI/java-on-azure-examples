#!/bin/bash
cd ..


if [[ -z $RESOURCE_GROUP ]]; then
export RESOURCE_GROUP=java-on-azure-$RANDOM
export REGION=westus2
fi

az group create --name $RESOURCE_GROUP --location $REGION
if [[ -z $ACR_NAME ]]; then
export ACR_NAME=acreg$RANDOM
fi
az acr create \
--name $ACR_NAME \
--resource-group $RESOURCE_GROUP \
--sku Basic \
--admin-enabled true

cd containers/acr/payara

mvn package
export ACR_PAYARA_IMAGE=payara:latest

az acr build --registry $ACR_NAME --image $ACR_PAYARA_IMAGE .

cd ../../..


if [[ -z $RESOURCE_GROUP ]]; then
export RESOURCE_GROUP=java-on-azure-$RANDOM
export REGION=westus2
fi

az group create --name $RESOURCE_GROUP --location $REGION
if [[ -z $ACR_NAME ]]; then
export ACR_NAME=acreg$RANDOM
fi
az acr create \
--name $ACR_NAME \
--resource-group $RESOURCE_GROUP \
--sku Basic \
--admin-enabled true

cd containers/acr/create-settings-xml

export ACR_USERNAME=`az acr credential show --name $ACR_NAME \
--resource-group $RESOURCE_GROUP --query username --output tsv`
export ACR_PASSWORD=`az acr credential show --name $ACR_NAME \
--resource-group $RESOURCE_GROUP --query 'passwords[0].value' --output tsv`
export SETTINGS_XML=$PWD/settings.xml

cd ../../..


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

cd compute/appservice/docker-payara

export APPSERVICE_DOCKER_PAYARA=appservice-docker-payara-$RANDOM

mvn azure-webapp:deploy \
--settings=$SETTINGS_XML \
-DappName=$APPSERVICE_DOCKER_PAYARA \
-DimageName=$ACR_PAYARA_IMAGE \
-DappServicePlan=$APPSERVICE_PLAN \
-DresourceGroup=$RESOURCE_GROUP \
-DserverId=$ACR_NAME

az webapp show \
--resource-group $RESOURCE_GROUP \
--name $APPSERVICE_DOCKER_PAYARA \
--query hostNames[0] \
--output tsv

sleep 180
cd ../../..


export RESULT=$(az webapp show --resource-group $RESOURCE_GROUP --name $APPSERVICE_DOCKER_PAYARA --output tsv --query state)
if [[ "$RESULT" != Running ]]; then
echo 'Web application is NOT running'
az group delete --name $RESOURCE_GROUP --yes || true
exit 1
fi

export URL=https://$(az webapp show --resource-group $RESOURCE_GROUP --name $APPSERVICE_DOCKER_PAYARA --output tsv --query defaultHostName)
export RESULT=$(curl $URL)

sleep 180

export RESULT=$(curl $URL)

az group delete --name $RESOURCE_GROUP --yes || true

if [[ "$RESULT" != *"custom Payara"* ]]; then
echo "Response did not contain 'custom Payara'"
exit 1
fi