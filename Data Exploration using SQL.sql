/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Year]
      ,[province]
      ,[adm_level]
      ,[region]
      ,[Poverty_Incidence_among_Families]
      ,[Magnitude_of_Poor_Population]
      ,[Magnitude_of_Poor_Families]
      ,[Subsistence_Incidence_among_Population]
      ,[Annual_Per_Capita_Poverty_Threshold]
      ,[Magnitude_of_Subsistence_Poor_Population]
      ,[Poverty_Incidence_among_Population]
  FROM [Kimmy].[dbo].[povstat_cleaned]

/* Create a temporary table filtered to contain only regional values. Exclude the columns adm_level and province. */

DROP TABLE IF EXISTS povstat_cleaned_region
SELECT Year, region, Poverty_Incidence_among_Families, Magnitude_of_Poor_Population, Magnitude_of_Poor_Families, Subsistence_Incidence_among_Population,
	Annual_Per_Capita_Poverty_Threshold, Magnitude_of_Subsistence_Poor_Population, Poverty_Incidence_among_Population
INTO povstat_cleaned_region
FROM povstat_cleaned
WHERE adm_level = 'Region'

SELECT *
FROM povstat_cleaned_region
ORDER BY Year DESC

/* From the created new table, filter the data to include only values from 2015 and explore the data using the variables poverty incidence among population and 
magnitude of poor population. */

SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
FROM povstat_cleaned_region
WHERE Year = 2015
ORDER BY Magnitude_of_Poor_Population DESC

/* Explore the mean, standard deviation, variance, maximum, and minimum of the variables poverty incidence among population and magnitude of poor population for the 
whole country. */

SELECT ROUND(AVG(Poverty_Incidence_among_Population), 3) AS avg_incidence, ROUND(STDEVP(Poverty_Incidence_among_Population), 3) AS stdev_incidence, 
	ROUND(VAR(Poverty_Incidence_among_Population), 3) AS var_incidence, ROUND(MIN(Poverty_Incidence_among_Population), 3) AS min_incidence, 
	ROUND(MAX(Poverty_Incidence_among_Population), 3) AS max_incidence, ROUND(AVG(Magnitude_of_Poor_Population), 0) AS avg_magnitude, 
	ROUND(STDEVP(Magnitude_of_Poor_Population),0) AS stdev_magnitude, ROUND(VAR(Magnitude_of_Poor_Population), 0) AS var_magnitude, 
	ROUND(MIN(Magnitude_of_Poor_Population),0) AS min_magnitude, ROUND(MAX(Magnitude_of_Poor_Population), 0) AS max_magnitude
FROM povstat_cleaned_region

/* Rank the regions according to the poverty incidence among population and magnitude of poor population from highest to lowest. */

SELECT region, DENSE_RANK() OVER (ORDER BY Poverty_Incidence_among_Population DESC) AS incidence_rank, 
	DENSE_RANK() OVER (ORDER BY Magnitude_of_Poor_Population DESC) AS magnitude_rank
FROM povstat_cleaned_region
WHERE Year = 2015

/* Identify from the list of the regions which are included in both the top 9 list of poverty incidence among population and magnitude of poor population. */

SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
FROM 
	(SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, DENSE_RANK() OVER (ORDER BY Poverty_Incidence_among_Population DESC) 
		AS incidence_rank, DENSE_RANK() OVER (ORDER BY Magnitude_of_Poor_Population DESC) AS magnitude_rank
	FROM povstat_cleaned_region
	WHERE Year = 2015) AS ranks
WHERE incidence_rank <= 9 AND magnitude_rank <= 9
ORDER BY magnitude_rank

/* Examine the 50th percentile of all regions' values for poverty incidence among population and magnitude of poor population. */

SELECT DISTINCT(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Poverty_Incidence_among_Population) OVER ()) AS perc70_incidence,
	PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Magnitude_of_Poor_Population) OVER () AS perc70_magnitude
FROM povstat_cleaned_region
WHERE Year = 2015

/* Determine which of the regions have values that exceeded both of the 70th percentile of the collective's recorded poverty incidence among population 
and magnitude of poor population. */

WITH perc50 AS(
	SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, 
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Poverty_Incidence_among_Population) OVER ()) AS perc50_incidence,
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Magnitude_of_Poor_Population) OVER ()) AS perc50_magnitude
	FROM povstat_cleaned_region
	WHERE Year = 2015)
SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
FROM perc50
WHERE Poverty_Incidence_among_Population >= perc50_incidence AND Magnitude_of_Poor_Population >= perc50_magnitude
ORDER BY perc50_magnitude

/* See if there are regions commonly present at both the 70th percentile and the top 7 lists for the poverty incidence among population 
and magnitude of poor population metrics. */

WITH perc50 AS(
	SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, 
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Poverty_Incidence_among_Population) OVER ()) AS perc50_incidence,
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Magnitude_of_Poor_Population) OVER ()) AS perc50_magnitude
	FROM povstat_cleaned_region
	WHERE Year = 2015),
	/* Create a new CTE that references the previous CTE. */
priority_regions AS(
	SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
	FROM perc50
	WHERE Poverty_Incidence_among_Population >= perc50_incidence AND Magnitude_of_Poor_Population >= perc50_magnitude
	AND EXISTS 
	/* This subquery was derived from the previously made query for the regions present in the top 9 lists of poverty incidence among population and magnitude of 
	poor population.*/
	(SELECT * FROM 
		(SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, DENSE_RANK() OVER (ORDER BY Poverty_Incidence_among_Population DESC) 
			AS incidence_rank, DENSE_RANK() OVER (ORDER BY Magnitude_of_Poor_Population DESC) AS magnitude_rank
		FROM povstat_cleaned_region
		WHERE Year = 2015) AS ranks
	WHERE incidence_rank <= 9 AND magnitude_rank <= 9)
	)
SELECT *
FROM priority_regions
ORDER BY Magnitude_of_Poor_Population

/* Using the CTE for the priority regions for filtering, view the data for the provinces encompassed by the selected regions. Filter out also the regions listed
as provinces. */

WITH perc50 AS(
	SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, 
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Poverty_Incidence_among_Population) OVER ()) AS perc50_incidence,
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Magnitude_of_Poor_Population) OVER ()) AS perc50_magnitude
	FROM povstat_cleaned_region
	WHERE Year = 2015),
priority_regions AS(
	SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
	FROM perc50
	WHERE Poverty_Incidence_among_Population >= perc50_incidence AND Magnitude_of_Poor_Population >= perc50_magnitude
	AND EXISTS 
	(SELECT * FROM 
		(SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, DENSE_RANK() OVER (ORDER BY Poverty_Incidence_among_Population DESC) 
			AS incidence_rank, DENSE_RANK() OVER (ORDER BY Magnitude_of_Poor_Population DESC) AS magnitude_rank
		FROM povstat_cleaned_region
		WHERE Year = 2015) AS ranks
	WHERE incidence_rank <= 9 AND magnitude_rank <= 9)
	)
SELECT *
FROM povstat_cleaned
WHERE region IN
	(SELECT region FROM priority_regions)
	AND province <> region

/* Add another CTE to indicate the provinces from the priority regions. Create a temporary table to store the values of the priority provinces, excluding 
the column adm_level. */

DROP TABLE IF EXISTS povstat_cleaned_province

WITH perc50 AS(
	SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, 
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Poverty_Incidence_among_Population) OVER ()) AS perc50_incidence,
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Magnitude_of_Poor_Population) OVER ()) AS perc50_magnitude
	FROM povstat_cleaned_region
	WHERE Year = 2015),
priority_regions AS(
	SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
	FROM perc50
	WHERE Poverty_Incidence_among_Population >= perc50_incidence AND Magnitude_of_Poor_Population >= perc50_magnitude
	AND EXISTS 
	(SELECT * FROM 
		(SELECT region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, DENSE_RANK() OVER (ORDER BY Poverty_Incidence_among_Population DESC) 
			AS incidence_rank, DENSE_RANK() OVER (ORDER BY Magnitude_of_Poor_Population DESC) AS magnitude_rank
		FROM povstat_cleaned_region
		WHERE Year = 2015) AS ranks
	WHERE incidence_rank <= 9 AND magnitude_rank <= 9)
	),
priority_provinces AS(
	SELECT *
	FROM povstat_cleaned
	WHERE region IN
		(SELECT region 
		FROM priority_regions)
	AND province <> region
	)
SELECT Year, province, region, Poverty_Incidence_among_Families, Magnitude_of_Poor_Population, Magnitude_of_Poor_Families, Subsistence_Incidence_among_Population,
	Annual_Per_Capita_Poverty_Threshold, Magnitude_of_Subsistence_Poor_Population, Poverty_Incidence_among_Population
INTO povstat_cleaned_province
FROM povstat_cleaned
WHERE province IN 
	(SELECT province FROM priority_provinces)

SELECT *
FROM povstat_cleaned_province

/* Add columns that indicate the 50th percentile value for both poverty incidence among population and magnitude of poor population of all listed provinces
in 2015. */

SELECT province, region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, 
	(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Poverty_Incidence_among_Population) OVER ()) AS perc50_incidence,
	(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Magnitude_of_Poor_Population) OVER ()) AS perc50_magnitude
FROM povstat_cleaned_province
WHERE Year = 2015 AND province <> region

/* Determine the provinces who are within the 50th percentile for both poverty incidence among population and magnitude of poor population in 2015. Store the values
in a temporary table. */

DROP TABLE IF EXISTS priority_provinces
SELECT province, region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
INTO priority_provinces
FROM 
	(SELECT province, region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population, 
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Poverty_Incidence_among_Population) OVER ()) AS perc50_incidence,
		(PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Magnitude_of_Poor_Population) OVER ()) AS perc50_magnitude
	FROM povstat_cleaned_province
	WHERE Year = 2015 AND province <> region) AS perc
WHERE Poverty_Incidence_among_Population >= perc50_incidence AND Magnitude_of_Poor_Population >= perc50_magnitude 

SELECT *
FROM priority_provinces

/* Filter the povstat_cleaned_province table with only the provinces included in the priority_provinces table. Order the data according to province 
and ascending years. Leave only the values for the poverty incidence among population and magnitude of poor population.  */

SELECT Year, province, region, Poverty_Incidence_among_Population, Magnitude_of_Poor_Population
FROM povstat_cleaned_province
WHERE province IN
	(SELECT province FROM priority_provinces)
ORDER BY province, Year

/* Create new columns for the difference in values for poverty incidence among population and magnitude of poor population between succeeding years per province. */

SELECT Year, province, region, Poverty_Incidence_among_Population, (Poverty_Incidence_among_Population - LAG(Poverty_Incidence_among_Population) OVER 
	(PARTITION BY province ORDER BY Year)) AS diff_incidence, Magnitude_of_Poor_Population, (Magnitude_of_Poor_Population - 
	LAG(Magnitude_of_Poor_Population) OVER (PARTITION BY province ORDER BY Year)) AS diff_magnitude
FROM povstat_cleaned_province
WHERE province IN
	(SELECT province FROM priority_provinces)

/* Add columns which indicates the latest change in poverty incidence among population and magnitude of poor population from 2012 to 2015 per province. */

SELECT Year, province, region, Poverty_Incidence_among_Population, diff_incidence, LAST_VALUE(diff_incidence) OVER (PARTITION BY province ORDER BY Year 
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS incidence_2015, Magnitude_of_Poor_Population, diff_magnitude, 
	LAST_VALUE(diff_magnitude) OVER (PARTITION BY province ORDER BY Year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS magnitude_2015
FROM 
	(SELECT Year, province, region, Poverty_Incidence_among_Population, (Poverty_Incidence_among_Population - LAG(Poverty_Incidence_among_Population) OVER 
		(PARTITION BY province ORDER BY Year)) AS diff_incidence, Magnitude_of_Poor_Population, (Magnitude_of_Poor_Population - 
		LAG(Magnitude_of_Poor_Population) OVER (PARTITION BY province ORDER BY Year)) AS diff_magnitude
	FROM povstat_cleaned_province
	WHERE province IN
		(SELECT province FROM priority_provinces)) AS no_last_value

/* Determine the standard deviation of the change in poverty incidence among population and magnitude of poor population between succeeding years per province 
from the values of the newly created columns. */

WITH diff AS(
	SELECT Year, province, region, Poverty_Incidence_among_Population, diff_incidence, LAST_VALUE(diff_incidence) OVER (PARTITION BY province ORDER BY Year 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS incidence_2015, Magnitude_of_Poor_Population, diff_magnitude, 
		LAST_VALUE(diff_magnitude) OVER (PARTITION BY province ORDER BY Year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS magnitude_2015
	FROM 
		(SELECT Year, province, region, Poverty_Incidence_among_Population, (Poverty_Incidence_among_Population - LAG(Poverty_Incidence_among_Population) OVER 
			(PARTITION BY province ORDER BY Year)) AS diff_incidence, Magnitude_of_Poor_Population, (Magnitude_of_Poor_Population - 
			LAG(Magnitude_of_Poor_Population) OVER (PARTITION BY province ORDER BY Year)) AS diff_magnitude
		FROM povstat_cleaned_province
		WHERE province IN
			(SELECT province FROM priority_provinces)) AS no_last_value
)	
SELECT province, region, STDEVP(diff_incidence) AS stdev_incidence, MAX(incidence_2015) AS incidence_2015, STDEVP(diff_magnitude) AS stdev_magnitude, 
	MAX(magnitude_2015) AS magnitude_2015
FROM diff
GROUP BY province, region;

/* Arrange the data from the highest positive change to the highest negative change in magnitude of poor population during 2015. Add a column that indicates which
quartile each province belongs to. */

WITH diff AS(
	SELECT Year, province, region, Poverty_Incidence_among_Population, diff_incidence, LAST_VALUE(diff_incidence) OVER (PARTITION BY province ORDER BY Year 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS incidence_2015, Magnitude_of_Poor_Population, diff_magnitude, 
		LAST_VALUE(diff_magnitude) OVER (PARTITION BY province ORDER BY Year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS magnitude_2015
	FROM 
		(SELECT Year, province, region, Poverty_Incidence_among_Population, (Poverty_Incidence_among_Population - LAG(Poverty_Incidence_among_Population) OVER 
			(PARTITION BY province ORDER BY Year)) AS diff_incidence, Magnitude_of_Poor_Population, (Magnitude_of_Poor_Population - 
			LAG(Magnitude_of_Poor_Population) OVER (PARTITION BY province ORDER BY Year)) AS diff_magnitude
		FROM povstat_cleaned_province
		WHERE province IN
			(SELECT province FROM priority_provinces)) AS no_last_value
),	
stdev AS(
	SELECT province, region, STDEVP(diff_incidence) AS stdev_incidence, MAX(incidence_2015) AS incidence_2015, STDEVP(diff_magnitude) AS stdev_magnitude, 
		MAX(magnitude_2015) AS magnitude_2015
	FROM diff
	GROUP BY province, region
)
SELECT *, NTILE(4) OVER (ORDER BY magnitude_2015 DESC, incidence_2015 DESC, stdev_incidence DESC) AS quartile
FROM stdev;

/* Using the quartile column, create another column that labels the priority level for each province. */

WITH diff AS(
	SELECT Year, province, region, Poverty_Incidence_among_Population, diff_incidence, LAST_VALUE(diff_incidence) OVER (PARTITION BY province ORDER BY Year 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS incidence_2015, Magnitude_of_Poor_Population, diff_magnitude, 
		LAST_VALUE(diff_magnitude) OVER (PARTITION BY province ORDER BY Year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS magnitude_2015
	FROM 
		(SELECT Year, province, region, Poverty_Incidence_among_Population, (Poverty_Incidence_among_Population - LAG(Poverty_Incidence_among_Population) OVER 
			(PARTITION BY province ORDER BY Year)) AS diff_incidence, Magnitude_of_Poor_Population, (Magnitude_of_Poor_Population - 
			LAG(Magnitude_of_Poor_Population) OVER (PARTITION BY province ORDER BY Year)) AS diff_magnitude
		FROM povstat_cleaned_province
		WHERE province IN
			(SELECT province FROM priority_provinces)) AS no_last_value
),	
stdev AS(
	SELECT province, region, STDEVP(diff_incidence) AS stdev_incidence, MAX(incidence_2015) AS incidence_2015, STDEVP(diff_magnitude) AS stdev_magnitude, 
		MAX(magnitude_2015) AS magnitude_2015
	FROM diff
	GROUP BY province, region
),
quart AS(
	SELECT *, NTILE(4) OVER (ORDER BY magnitude_2015 DESC, incidence_2015 DESC, stdev_incidence DESC) AS quartile
	FROM stdev)
SELECT province, region, ROUND(stdev_incidence, 2) AS stdev_incidence_change, ROUND(incidence_2015, 2) AS incidence_change_2015, 
	ROUND(stdev_magnitude, 0) AS stdev_magnitude_change, magnitude_2015 AS magnitude_change_2015,
	CASE WHEN quartile = 1 THEN 'highest'
		WHEN quartile = 2 THEN 'high'
		WHEN quartile = 3 THEN 'medium-high'
		ELSE 'medium' 
		END AS priority_level
FROM quart