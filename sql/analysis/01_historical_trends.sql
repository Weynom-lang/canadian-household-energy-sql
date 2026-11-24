-- ============================================================
-- Question 1: Historical Provincial Trends
-- ============================================================
-- How has household energy consumption per household changed
-- across Canadian provinces from 2011 to 2021?
--
-- Observed years: 2011, 2013, 2015, 2019, 2021
-- Measure: Gigajoules per household
-- Canada is excluded from the provincial trend comparison.
-- ============================================================

WITH 
lagged AS(
SELECT
    geography,
    year,
    value,
    LAG(year) OVER (
        PARTITION BY geography
        ORDER BY year
    ) AS previous_year,
    LAG(value) OVER (
        PARTITION BY geography
        ORDER BY year
    ) AS previous_value
FROM clean.overall
WHERE energy_type = 'Total, all energy types'
  AND measure = 'Gigajoules per household'
  AND geography <> 'Canada'
),
changes AS(
SELECT 
	geography,
	year,
	value,
	previous_year,
	previous_value,
	(year - previous_year) AS year_gap,
	(value - previous_value) AS absolute_change
FROM lagged
	),
summary AS(
SELECT
    geography,
    COUNT(*) FILTER (WHERE absolute_change > 0) AS increase_intervals,
    COUNT(*) FILTER (WHERE absolute_change < 0) AS decrease_intervals,
    COUNT(*) FILTER (WHERE absolute_change = 0) AS no_change_intervals,
    MAX(absolute_change)
    	FILTER(WHERE absolute_change > 0) 
    	AS largest_interval_increase,
	MIN(absolute_change) 
		FILTER(WHERE absolute_change < 0) 
		AS largest_interval_decrease,
	MAX(value) FILTER (WHERE year = 2011) AS value_2011,
	MAX(value) FILTER (WHERE year = 2021) AS value_2021
FROM changes
GROUP BY geography
ORDER BY geography)
SELECT
    geography,
    increase_intervals,
    decrease_intervals,
    no_change_intervals,
    largest_interval_increase,
    largest_interval_decrease,
    value_2011,
    value_2021,
    value_2021 - value_2011 AS overall_change,
    ROUND(
        (value_2021 - value_2011)
        / value_2011 * 100,
        2
    ) AS overall_percent_change
FROM summary
ORDER BY overall_percent_change;



