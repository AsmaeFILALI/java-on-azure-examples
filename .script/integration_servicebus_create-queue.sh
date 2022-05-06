#!/bin/bash
cd ..


if [[ -z $RESOURCE_GROUP ]]; then
export RESOURCE_GROUP=java-on-azure-$RANDOM
export REGION=westus2
fi

az group create --name $RESOURCE_GROUP --location $REGION
export SERVICE_BUS=service-bus-$RANDOM
az servicebus namespace create \
--resource-group $RESOURCE_GROUP \
--name $SERVICE_BUS \
--sku Premium \
--location $REGION
if [[ -z $SERVICE_BUS_QUEUE ]]; then
export SERVICE_BUS_QUEUE=service-bus-queue-$RANDOM
fi
az servicebus queue create \
--resource-group $RESOURCE_GROUP \
--namespace-name $SERVICE_BUS \
--name $SERVICE_BUS_QUEUE
export RESULT=$(az servicebus queue show --resource-group $RESOURCE_GROUP --namespace $SERVICE_BUS --name $SERVICE_BUS_QUEUE --query status --output tsv)
az group delete --name $RESOURCE_GROUP --yes || true
if [[ "$RESULT" != Active ]]; then
exit 1
fi