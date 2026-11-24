-- ============================================================
-- Question 2: 2021 Provincial Comparison
-- ============================================================
-- How did household energy consumption per household differ
-- across Canadian provinces in 2021?
--
-- Measure:
-- Gigajoules per household
--
-- Energy type:
-- Total, all energy types
--
-- Analysis includes:
-- 1. Provincial ranking from highest to lowest consumption
-- 2. Highest-to-lowest provincial spread
-- 3. Comparison with the Canada national benchmark
--
-- Canada is excluded from the provincial ranking itself
-- because Canada is not a province.
--
-- Canada is retained separately as a national benchmark for
-- comparing each province's household energy consumption.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Provincial ranking
-- ------------------------------------------------------------
-- Purpose:
-- Rank the 10 provinces from highest to lowest household
-- energy consumption per household in 2021.
--
-- Expected grain:
-- One row per province.
--
-- Expected rows:
-- 10 provinces.
-- ------------------------------------------------------------

SELECT
    year,
    geography,
    value
FROM clean.overall
WHERE year = 2021
  AND energy_type = 'Total, all energy types'
  AND measure = 'Gigajoules per household'
  AND geography <> 'Canada'
ORDER BY value DESC;


-- ------------------------------------------------------------
-- 2. Highest-to-lowest provincial spread
-- ------------------------------------------------------------
-- Purpose:
-- Measure the difference between the highest- and
-- lowest-consuming provinces in 2021.
--
-- Expected grain:
-- One summary row representing all 10 provinces.
--
-- Expected result:
-- Highest value: 121.8 GJ/household
-- Lowest value:   66.4 GJ/household
-- Provincial gap: 55.4 GJ/household
-- ------------------------------------------------------------

SELECT
    MAX(value) AS highest_value,
    MIN(value) AS lowest_value,
    MAX(value) - MIN(value) AS provincial_gap
FROM clean.overall
WHERE year = 2021
  AND energy_type = 'Total, all energy types'
  AND measure = 'Gigajoules per household'
  AND geography <> 'Canada';


-- ------------------------------------------------------------
-- 3. Comparison with Canada benchmark
-- ------------------------------------------------------------
-- Purpose:
-- Compare each province's 2021 household energy consumption
-- per household with the Canada national benchmark.
--
-- Canada benchmark:
-- 85.4 GJ/household
--
-- difference_from_canada:
--     province value - Canada value
--
-- Positive difference:
--     Province is above the national benchmark.
--
-- Negative difference:
--     Province is below the national benchmark.
--
-- percent_difference_from_canada:
--     Percentage difference relative to Canada's value.
--
-- Expected grain:
-- One row per province.
-- ------------------------------------------------------------

WITH canada_benchmark AS (
    SELECT
        value AS canada_value
    FROM clean.overall
    WHERE year = 2021
      AND energy_type = 'Total, all energy types'
      AND measure = 'Gigajoules per household'
      AND geography = 'Canada'
)

SELECT
    o.geography,
    o.value AS province_value,
    c.canada_value,

    o.value - c.canada_value
        AS difference_from_canada,

    ROUND(
        (o.value - c.canada_value)
        / c.canada_value * 100,
        2
    ) AS percent_difference_from_canada

FROM clean.overall AS o
CROSS JOIN canada_benchmark AS c

WHERE o.year = 2021
  AND o.energy_type = 'Total, all energy types'
  AND o.measure = 'Gigajoules per household'
  AND o.geography <> 'Canada'

ORDER BY percent_difference_from_canada DESC;