CREATE DATABASE IF NOT EXISTS PATRICKDB;

CREATE SCHEMA IF NOT EXISTS PATRICKDB.STARWARS;

CREATE STAGE PATRICKDB.STARWARS.AZUREBLOBSTORAGE
URL = 'azure://patricksdata.blob.core.windows.net/starwars/';
 
SHOW STAGES;
 
LIST @AZUREBLOBSTORAGE;

CREATE OR REPLACE FILE FORMAT PATRICKDB.STARWARS.JSON_FILE_FORMAT
TYPE = 'JSON' 
COMPRESSION = 'AUTO' 
ENABLE_OCTAL = FALSE
ALLOW_DUPLICATE = FALSE 
STRIP_OUTER_ARRAY = TRUE
STRIP_NULL_VALUES = FALSE 
IGNORE_UTF8_ERRORS = FALSE;

SHOW FILE FORMATS;

//Create a table in the new database
CREATE OR REPLACE TABLE PATRICKDB.STARWARS.CHARACTERS
("RAW" VARIANT);

SELECT * FROM PATRICKDB.STARWARS.CHARACTERS;

COPY INTO PATRICKDB.STARWARS.CHARACTERS 
FROM @PATRICKDB.STARWARS.AZUREBLOBSTORAGE
files = ('AllSWCharacters.json')
file_format = (FORMAT_NAME = 'JSON_FILE_FORMAT');

-- All ordering will become alphabetical
SELECT * FROM PATRICKDB.STARWARS.CHARACTERS;

SELECT 
raw:id::NUMBER AS ID,
raw:name::STRING AS NAME,
raw:height::FLOAT AS HEIGHT,
raw:homeworld::STRING AS HOMEWORLD
FROM PATRICKDB.STARWARS.CHARACTERS;

SELECT value::VARCHAR AS AFFILIATIONS
FROM PATRICKDB.STARWARS.CHARACTERS
,LATERAL FLATTEN
(input => raw:affiliations)
GROUP BY value::VARCHAR;

SELECT 
raw:id::NUMBER AS ID,
raw:name::STRING AS NAME,
raw:height::FLOAT AS HEIGHT,
raw:homeworld::STRING AS HOMEWORLD,
value::VARCHAR AS AFFILIATIONS
FROM PATRICKDB.STARWARS.CHARACTERS
,LATERAL FLATTEN
(input => raw:affiliations);

-- With the query from before, ids without affiliation gets lost (id 47-50). So we need a way with a left join
WITH flatten_data AS (
   SELECT 
      raw:id::NUMBER AS ID,
      value::VARCHAR AS AFFILIATIONS
   FROM PATRICKDB.STARWARS.CHARACTERS
   ,LATERAL FLATTEN(input => raw:affiliations)
)
SELECT 
   characters.raw:id::NUMBER AS ID,
   characters.raw:name::STRING AS NAME,
   characters.raw:height::FLOAT AS HEIGHT,
   characters.raw:homeworld::STRING AS HOMEWORLD,
   COALESCE(flatten_data.affiliations, NULL) AS AFFILIATIONS
FROM PATRICKDB.STARWARS.CHARACTERS characters
LEFT JOIN flatten_data ON characters.raw:id = flatten_data.ID
ORDER BY ID;

CREATE OR REPLACE VIEW PATRICKDB.STARWARS.CHARACTERS_NORMALIZED AS
(WITH flatten_data AS (
   SELECT 
      raw:id::NUMBER AS ID,
      value::VARCHAR AS AFFILIATIONS
   FROM PATRICKDB.STARWARS.CHARACTERS
   ,LATERAL FLATTEN(input => raw:affiliations)
)
SELECT 
   characters.raw:id::NUMBER AS ID,
   characters.raw:name::STRING AS NAME,
   characters.raw:height::FLOAT AS HEIGHT,
   characters.raw:homeworld::STRING AS HOMEWORLD,
   COALESCE(flatten_data.affiliations, NULL) AS AFFILIATIONS
FROM PATRICKDB.STARWARS.CHARACTERS characters
LEFT JOIN flatten_data ON characters.raw:id = flatten_data.ID
ORDER BY ID
);

SELECT COUNT(DISTINCT ID) AS ID_COUNT FROM PATRICKDB.STARWARS.CHARACTERS_NORMALIZED;

SELECT * FROM PATRICKDB.STARWARS.CHARACTERS_NORMALIZED;
