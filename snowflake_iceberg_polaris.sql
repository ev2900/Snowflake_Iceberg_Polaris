-- Optional create a new database
CREATE DATABASE ICEBERG_POLARIS

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

--
DESC EXTERNAL VOLUME EXT_VOL_POLARIS_S3;

SELECT
	parse_json("property_value"):STORAGE_AWS_IAM_USER_ARN::string AS storage_aws_iam_user_arn,
    parse_json("property_value"):STORAGE_AWS_EXTERNAL_ID::string AS storage_aws_external_id
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "property" = 'STORAGE_LOCATION_1';

--
CREATE OR REPLACE CATALOG INTEGRATION OPEN_CATALOG_EXT_POLARIS 
  CATALOG_SOURCE=POLARIS 
  TABLE_FORMAT=ICEBERG 
  REST_CONFIG = (
    CATALOG_URI = '<>' 
    CATALOG_NAME = '<>'
  )
  REST_AUTHENTICATION = (
    TYPE = OAUTH 
    OAUTH_CLIENT_ID = '<>' 
    OAUTH_CLIENT_SECRET = '<>' 
    OAUTH_ALLOWED_SCOPES = ('PRINCIPAL_ROLE:ALL') 
  ) 
  ENABLED=TRUE;

--
ALTER DATABASE ICEBERG_POLARIS SET CATALOG_SYNC = 'OPEN_CATALOG_EXT_POLARIS';

--
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

-- Optional query the table
SELECT * FROM SAMPLEDATA_ICEBERG_HORIZON LIMIT 10;

-- Trouble shooting
SELECT VALUE[0]::STRING AS tableName,
       VALUE[1]::BOOLEAN notificationStatus,
       VALUE[2]::STRING errorCode,
       VALUE[3]::STRING errorMessage
  FROM TABLE(FLATTEN(PARSE_JSON(
    SELECT SYSTEM$SEND_NOTIFICATIONS_TO_CATALOG(
      'SCHEMA',
      'PUBLIC'))));
