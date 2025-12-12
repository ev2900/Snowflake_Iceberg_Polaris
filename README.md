# Snowflake Iceberg Polaris (Snowflake Open Catalog Account)

<img width="275" alt="map-user" src="https://img.shields.io/badge/cloudformation template deployments-6-blue"> <img width="85" alt="map-user" src="https://img.shields.io/badge/views-122-green"> <img width="125" alt="map-user" src="https://img.shields.io/badge/unique visits-002-green">

Apache Polaris is an open-source metadata catalog for Apache Iceberg. Snowflake offers a managed implementation of Polaris via. a Snowflake Open Catalog Account. 

Iceberg tables that are created and registered with Horizon can be sync'd with Polaris via. a catalog integration and a database / schema sync in Horizon.

Once the sync to Polaris is set up the Lake Formation catalog federation can connect to Polaris and federate the Polaris tables to the Glue Data Catalog. This allows AWS native services to query these Iceberg tables via. a READ ONLY integration.

The architecture below depicts this

<img width="900" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/Architecture.png">

## Example

You can test this integration. Begin by deploying the CloudFormation stack below. This will create the required AWS resources.

> [!WARNING]
> The CloudFormation stack creates IAM role(s) that have ADMIN permissions. This is not appropriate for production deployments. Scope these roles down before using this CloudFormation in production.

[![Launch CloudFormation Stack](https://sharkech-public.s3.amazonaws.com/misc-public/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=snowflake-iceberg-polaris&templateURL=https://sharkech-public.s3.amazonaws.com/misc-public/snowflake_iceberg_polaris.yaml)

### Create a sample Iceberg table in AWS via. Glue

Navigate to the Glue console ETL jobs page, select the Create Iceberg Table and select the Run button

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/run_glue_job.png">

### Create a catalog integration in Snowflake

Update and run the following SQL in Snowflake.

The values of any of the <...> place holders can be found in the output section of the CloudFormation stack

**<img width="700" alt="quick_setup" src="**

Update the run the following SQL in Snowflake.

```
CREATE OR REPLACE EXTERNAL VOLUME EXT_VOL_POLARIS_S3
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'S3-ICEBERG-EXTERNAL-VOLUME'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = '<>' 
            STORAGE_AWS_ROLE_ARN = '<>'
         )
      );

SHOW EXTERNAL VOLUMES;
```

### Create a Snowflake Open Catalog Account

Select, Admin, Accounts, + Account and Create Snowflake Open Catalog Account

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/open_catalog.png">

Follow the prompts to create the Snowflake Open Catalog Account, Admin User etc.

### Create a Catalog in Polaris / Snowflake Open Catalog Account

Select Catalogs, Create Catalog

In the input field that appears enter the following values

| Field Name            | Value                                                      |
| --------------------- | ---------------------------------------------------------- |
| Name                  | POLARIS_CATALOG                                            |
| External              | TRUE                                                       |
| Default base location | StorageBaseUri from Cloudformation Outputs                 |
| S3 role ARN           | SnowflakePolarisCatalogIAMRole from Cloudformation Outputs |

The input form should look something like this 

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/polaris_catalog.png">

### Update IAM roles tp allow Snowflake and Polaris to assume them

Before you can use the external volume and polaris can connect to Snowflake to Polaris, you need to update the IAM role Snowflake and Polaris will use.

To updae the IAM role you will deploy a stack update to the CloudFormation tempalte.

Begin by selecting the CloudFormation stack and then Update stack, Make a direct update



```https://sharkech-public.s3.amazonaws.com/misc-public/snowflake_iceberg_polaris_iam_update.yaml```

