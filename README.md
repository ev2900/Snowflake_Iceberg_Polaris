# Snowflake Iceberg Polaris (Snowflake Open Catalog Account)

<img width="275" alt="map-user" src="https://img.shields.io/badge/cloudformation template deployments-34-blue"> <img width="85" alt="map-user" src="https://img.shields.io/badge/views-400-green"> <img width="125" alt="map-user" src="https://img.shields.io/badge/unique visits-017-green">

> [!CAUTION]
> This code sample is not fully functioning bc. of a limitation when creating the ```SNOWFLAKEICEBERGRESTCATALOG``` Glue connection.
>
> When creating a connection to Snowflake Open Catalog Account and/or Polaris the table depth property needs to be set to 4. Default value is 3.
>
> As of 12/21/2025 it is not possible to set this property via. the AWS CLI or console.
>

Apache Polaris is an open-source metadata catalog for Apache Iceberg. Snowflake offers a managed implementation of Polaris via. a Snowflake Open Catalog Account.

Iceberg tables that are created and registered with Horizon can be sync'd with Polaris via. a catalog integration and a database / schema sync in Horizon.

Once the sync to Polaris is set up the Lake Formation catalog federation can connect to Polaris and federate the Polaris tables to the Glue Data Catalog. This allows AWS native services to query these Iceberg tables via. a READ ONLY integration.

The architecture below depicts this

<img width="900" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/Architecture.png">

# Example

You can test this integration. Begin by deploying the CloudFormation stack below. This will create the required AWS resources.

> [!WARNING]
> The CloudFormation stack creates IAM role(s) that have ADMIN permissions. This is not appropriate for production deployments. Scope these roles down before using this CloudFormation in production.

[![Launch CloudFormation Stack](https://sharkech-public.s3.amazonaws.com/misc-public/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=snowflake-iceberg-polaris&templateURL=https://sharkech-public.s3.amazonaws.com/misc-public/snowflake_iceberg_polaris.yaml)

## Snowflake / Snowflake Open Catalaog Account (Polaris) Set Up

### Create a sample Iceberg table in AWS via. Glue

Navigate to the Glue console ETL jobs page, select the Create Iceberg Table and select the Run button

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/run_glue_job.png">

### Create a catalog integration in Snowflake

Update and run the following SQL in Snowflake.

The values of any of the <...> place holders can be found in the output section of the CloudFormation stack

**<img width="700" alt="quick_setup" src="**

Update the run the following SQL in Snowflake.

```
--  Step 1 | Create external volume to link S3 bucket with Snowflake
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

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/stack_update.png">

Then select Replace existing tempalte and copy paste the following S3 URL

```https://sharkech-public.s3.amazonaws.com/misc-public/snowflake_iceberg_polaris_iam_update.yaml```

On the next page you will be asked for several inputs. Run the following SQL in Snowflake to get each input paramater

STORAGE_AWS_EXTERNAL_ID and STORAGE_AWS_IAM_USER_ARN

```
-- Step 2 | Get STORAGE_AWS_EXTERNAL_ID and STORAGE_AWS_IAM_USER_ARN to update IAM role
DESC EXTERNAL VOLUME EXT_VOL_POLARIS_S3;

SELECT
   parse_json("property_value"):STORAGE_AWS_EXTERNAL_ID::string AS storage_aws_external_id,
	parse_json("property_value"):STORAGE_AWS_IAM_USER_ARN::string AS storage_aws_iam_user_arn
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "property" = 'STORAGE_LOCATION_1';
```

PolarisCatalogExternalId and PolarisCatalogIAMRole

Via. the Snowflake Open Catalog account web page select the database you created.

On this screen you will see the External ID and IAM user ARN

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/polaris_info.png">

The parameters page on the CloudFormation stack update should look like this

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/stack_update_2.png">

### Create a Polaris connection

Select Connections, +Connection

Name the catalog ```CATALOG_CONNECTION```, select Create new principal role, Name the new principal ```CATALOG_PRINCIPAL```

<img width="400" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/create_catalog.png">

The next screen will show you the client id and secrete. Copy and paste those as the values of the OAUTH_CLIENT_ID and OAUTH_CLIENT_SECRET in the SQL statement below

### Create a catalog integration for Polaris

Update and run the following SQL in Snowflake.

```
-- Step 3 | Create catatalog intergration
CREATE OR REPLACE CATALOG INTEGRATION OPEN_CATALOG_EXT_POLARIS
  CATALOG_SOURCE=POLARIS
  TABLE_FORMAT=ICEBERG
  REST_CONFIG = (
    CATALOG_URI = 'https://<first-part-of-catalog-url>/polaris/api/catalog' -- https://uwtkikf-iceberg_open_catalog.snowflakecomputing.com/polaris/api/catalog
    CATALOG_NAME = 'POLARIS_CATALOG'
  )
  REST_AUTHENTICATION = (
    TYPE = OAUTH
    OAUTH_CLIENT_ID = '<>'
    OAUTH_CLIENT_SECRET = '<>'
    OAUTH_ALLOWED_SCOPES = ('PRINCIPAL_ROLE:ALL')
  )
  ENABLED=TRUE;
```

### Create Snowflake Open Catalog Role and Grant to Principle

Select Catalogs, + Catalog Role

Name the role ```ADMIN```. For testing purposes you can assign the role all privileges

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/catalog_role.png">

Next you need to grant the ADMIN role to the CATALOG_PRINCIPLE you created earlier

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/grant_catalog_role.png">

### Set the database and/or schema sync to Polaris

Run the following SQL in Snowflake. Modify the database and shema name is necessary

```
-- Step 4 | Set database and schema sync
ALTER DATABASE ICEBERG_POLARIS SET CATALOG_SYNC = 'OPEN_CATALOG_EXT_POLARIS';
ALTER SCHEMA PUBLIC SET CATALOG_SYNC = 'OPEN_CATALOG_EXT_POLARIS';
```

### Create an Iceberg table and insert sample data

Run the following SQL in Snowflake to create the table

```
-- Step 5 | Create an Iceberg table
CREATE OR REPLACE ICEBERG TABLE SAMPLEDATA_ICEBERG_HORIZON
  CATALOG='SNOWFLAKE'
  EXTERNAL_VOLUME='EXT_VOL_POLARIS_S3'
(
    quote_id        VARCHAR,
    customer_id     VARCHAR,
    premium_amount  DOUBLE,
    status          STRING,
    created_at      TIMESTAMP
);

```

Run the following SQL in Snowflake to insert sample data

```
-- Step 6 | Insert sample data into the table
INSERT INTO SAMPLEDATA_ICEBERG_HORIZON (
    quote_id,
    customer_id,
    premium_amount,
    status,
    created_at
)
VALUES
    ('Q-1001', 'CUST-001', 125.50, 'PENDING',     '2025-01-10 14:23:00'),
    ('Q-1002', 'CUST-002', 210.75, 'APPROVED',   '2025-01-11 09:15:22'),
    ('Q-1003', 'CUST-003', 340.00, 'REJECTED',   '2025-01-12 16:42:10'),
    ('Q-1004', 'CUST-001', 180.25, 'PENDING',    '2025-01-13 11:05:47'),
    ('Q-1005', 'CUST-004', 295.99, 'APPROVED',   '2025-01-14 08:33:19');
```

This will create an Iceberg table that is registerd with Horizon but also is represented in the Snowflake Open Catalog Account

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_Polaris/blob/main/README/polaris_table.png">

## Lake Formation / Glue Data Catalog Federation Set Up

### Create secrets manager secret

To federate to the Snowflake Open Catalog Account, you need to store the client secret in AWS secret manager. For testing purposes you can use the same client secret value you used to create the catalog intergration in Snowflake.

Replace the <> sections and run the following via. AWS CLI.

*If you do not have an AWS CLI enviorment set up Cloudshell via. AWS console can be an easy to run these*

```
aws secretsmanager create-secret \
--name SnowflakeClientSecret \
--description "Snowflake secret" \
--secret-string '{"USER_MANAGED_CLIENT_APPLICATION_CLIENT_SECRET": "<client-secret>"}' \
--region '<region ex. us-west-2>'
```

The aws CLI will return the ARN of the secret. Copy this down, you will need it in the next step.

### Create Lake Formation catalog federation connection

To create a Lake Formation catalog federation connection we need to create the connection.

Replace the <> sections and run the following via. AWS CLI.

The ```<lake-formation-IAM-role-ARN>``` can be found in the CloudFormation stack outputs.

The other values that need to be replaced can be reused from previous steps.

**Note** while you could also create this connection via. the AWS console UI, this method of deployment does not allow you to set the ```TABLE_DEPTH``` property to 4 (default is 3). A ```TABLE_DEPTH``` of 4 is requires when federating a connection via. a Snowflake Open Catalog Account.

```
aws glue create-connection --region us-west-2 --connection-input '{
	"Name": "SnowflakeConnection",
	"ConnectionType": "SNOWFLAKEICEBERGRESTCATALOG",
	"ConnectionProperties": {
 		"ROLE_ARN": "<lake-formation-IAM-role-ARN>",
 		"CATALOG_CASING_FILTER": "UPPERCASE_ONLY",
 		"TABLE_DEPTH": "4",
 		"INSTANCE_URL": "https://<first-part-of-catalog-url>.snowflakecomputing.com/polaris/api/catalog"
 	},
 	"AuthenticationConfiguration": {
 		"AuthenticationType": "OAUTH2",
 		"SecretArn": "<secret-manager-arn-from-previous-step>",
 		"OAuth2Properties": {
 			"OAuth2GrantType": "CLIENT_CREDENTIALS",
 			"OAuth2ClientApplication": {
 				"UserManagedClientApplicationClientId": "<client-id>"
 			},
 			"TokenUrl": "https://<first-part-of-catalog-url>.snowflakecomputing.com/polaris/api/catalog/v1/oauth/tokens",
 			"TokenUrlParametersMap": {
 				"scope": "PRINCIPAL_ROLE:ALL"
 			}
 		}
 	}
}'
```
