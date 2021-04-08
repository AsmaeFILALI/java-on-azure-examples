
# Upload files to static website

## Prerequisites

This example assumes you have previously completed the following examples:

1. [Create an Azure Resource Group](../../group/create/)
1. [Create an Azure Storage Account](../storage/create/)
1. [Enale static website hosting](../enable-static-website/)

<!-- workflow.cron(0 3 * * 4) -->
<!-- workflow.include(../enable-static-website/README.md) -->

## Upload files to static website

<!-- workflow.run() 

  cd storage/upload-files-to-static-website

  -->

To upload a directory containing your static website use following command line:

```shell
  az storage blob upload-batch \
    --source web \
    --destination '$web' \
    --account-name $STORAGE_ACCOUNT_NAME
```

<!-- workflow.run() 

  cd ../..

  -->

## Cleanup

<!-- workflow.directOnly() 

  export URL=$(az storage account show --name $STORAGE_ACCOUNT_NAME --query primaryEndpoints.web --output tsv)
  export RESULT=$(curl $URL)

  az group delete --name $RESOURCE_GROUP --yes || true

  if [[ "$RESULT" != *"This is served from Azure Storage"* ]]; then
    echo "Response did not contain 'This is served from Azure Storage'"
    exit 1
  fi

  -->

Do NOT forget to remove the resources once you are done running the example.

1m