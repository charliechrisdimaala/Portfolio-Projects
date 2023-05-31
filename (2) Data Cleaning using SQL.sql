/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [column1]
      ,[Variable]
      ,[Year]
      ,[province]
      ,[value]
      ,[adm_level]
      ,[region]
      ,[unit]
  FROM [Kimmy].[dbo].[povstat]

/* Determine the unique variables, year, province, adm_level, region, and unit in the table. */

SELECT DISTINCT Variable
FROM povstat

SELECT DISTINCT Year
FROM povstat

SELECT DISTINCT province
FROM povstat

SELECT DISTINCT adm_level
FROM povstat

SELECT DISTINCT region
FROM povstat

SELECT DISTINCT unit
FROM povstat

/* Check for null values per column. */

SELECT *
FROM povstat
WHERE Variable IS NULL

SELECT *
FROM povstat
WHERE Year IS NULL

SELECT *
FROM povstat
WHERE province IS NULL

SELECT *
FROM povstat
WHERE value IS NULL

SELECT *
FROM povstat
WHERE adm_level IS NULL

SELECT *
FROM povstat
WHERE region IS NULL

SELECT *
FROM povstat
WHERE unit IS NULL

/* Remove records from year 1991 since it contains mostly null values and 1991 is too distant from the data of other years. */

DELETE
FROM povstat
WHERE Year = 1991

SELECT *
FROM povstat
WHERE Year = 1991

/* Replace remaining null values from the value column with 0. */

UPDATE povstat
SET value = COALESCE(value, 0)

SELECT *
FROM povstat
ORDER BY value

/* Replace remaining null values from the adm_level column with corresponding correct values. */

UPDATE povstat
SET adm_level = COALESCE(adm_level, 'Province')
WHERE province IN 
	(SELECT DISTINCT province
	FROM povstat
	WHERE adm_level IS NULL)

SELECT *
FROM povstat
ORDER BY adm_level

/* Replace remaining null values from the region column with corresponding correct values. */

UPDATE povstat
SET region = 'Region III'
WHERE province = 'Aurora'

UPDATE povstat
SET region = 'Region II'
WHERE province = 'Batanes'

UPDATE povstat
SET region = 'Region X'
WHERE province = 'Camiguin'

UPDATE povstat
SET region = 'Region XII'
WHERE province = 'Cotabato City,'

UPDATE povstat
SET region = 'Region VI'
WHERE province = 'Guimaras,'

UPDATE povstat
SET region = 'Region IX'
WHERE province = 'Isabela City,'

UPDATE povstat
SET region = 'Region VII'
WHERE province = 'Siquijor,'

SELECT *
FROM povstat
WHERE region IS NULL

/* Trim the values from the province column to remove the comma. */

UPDATE povstat
SET province = TRIM(',' FROM province)

/* Check for incorrect values from the province, adm_level, and region columns and replace them. */

SELECT province, adm_level, region
FROM povstat

UPDATE povstat
SET region = 'Region IV-A'
WHERE region = 'Region VI-A'

UPDATE povstat
SET province = UPPER(province)
WHERE adm_level = 'Region' AND region = 'CARAGA'

UPDATE povstat
SET province = 'Philippines'
WHERE adm_level = 'Country'

UPDATE povstat
SET adm_level = 'Region'
WHERE province = 'Region II'

/* Check for duplicates and remove them. */

WITH rn AS(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY Variable, Year, province, adm_level, region ORDER BY column1) AS copy
	FROM povstat)
SELECT copy
FROM rn
WHERE copy > 1

/* Change the values to percentages, if necessary. */

SELECT *, ROUND((value / 100), 3) AS pctg 
FROM povstat
WHERE unit = '%'
ORDER BY value DESC

UPDATE povstat
SET value = ROUND((value / 100), 3)
WHERE unit = '%'

/* Drop the column1 and unit columns. */

ALTER TABLE povstat
DROP COLUMN column1, unit

/* Pivot the table using the unique variables. */

SELECT *
FROM povstat

SELECT * FROM povstat AS source_table
PIVOT(
	SUM(value)
	FOR Variable IN ([Poverty Incidence among Families (%)], [Magnitude of Poor Population], [Magnitude of Poor Families], 
	[Subsistence Incidence among Population (%)], [Annual Per Capita Poverty Threshold (in Pesos)], [Magnitude of Subsistence Poor Population],
	[Poverty Incidence among Population (%)])
	) AS pivot_table
ORDER BY adm_level, region, province, Year

/* Crate new table for the cleaned data. */

CREATE TABLE dbo.povstat_cleaned(
	Year INT,
	province VARCHAR(255),
	adm_level VARCHAR(255),
	region VARCHAR(255),
	Poverty_Incidence_among_Families FLOAT,
	Magnitude_of_Poor_Population INT,
	Magnitude_of_Poor_Families INT,
	Subsistence_Incidence_among_Population FLOAT,
	Annual_Per_Capita_Poverty_Threshold INT,
	Magnitude_of_Subsistence_Poor_Population INT,
	Poverty_Incidence_among_Population FLOAT)

/* Insert values from pivot table to new table. */

INSERT INTO dbo.povstat_cleaned
	SELECT * FROM povstat AS source_table
	PIVOT(
	SUM(value)
	FOR Variable IN ([Poverty Incidence among Families (%)], [Magnitude of Poor Population], [Magnitude of Poor Families], 
	[Subsistence Incidence among Population (%)], [Annual Per Capita Poverty Threshold (in Pesos)], [Magnitude of Subsistence Poor Population],
	[Poverty Incidence among Population (%)])
	) AS pivot_table
	ORDER BY adm_level, region, province, Year

SELECT *
FROM povstat_cleaned
