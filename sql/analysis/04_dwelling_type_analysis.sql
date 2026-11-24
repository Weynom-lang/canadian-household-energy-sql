-- ============================================================
-- Question 4: 2021 Dwelling-Type Comparison
-- ============================================================
-- How did household energy consumption per household differ
-- across dwelling types in Canada in 2021?
--
-- Geography: Canada
-- Year: 2021
-- Energy type: Total, all energy types
-- Measure: Gigajoules per household
--
-- Analysis:
-- 1. Order dwelling types from highest to lowest consumption
-- 2. Quantify the gap between the highest and lowest values
-- ============================================================

-- 1. Order dwelling types from highest to lowest consumption
SELECT
    dwelling_type,
    value AS gj_per_household
FROM clean.dwelling
WHERE year = 2021
  AND geography = 'Canada'
  AND energy_type = 'Total, all energy types'
  AND measure = 'Gigajoules per household'
ORDER BY value DESC;

-- 2. Quantify the absolute and percentage gap between
--    the highest and lowest dwelling-type values
SELECT
    MAX(value) AS highest_value,
    MIN(value) AS lowest_value,
    MAX(value) - MIN(value) AS dwelling_gap,
    ROUND(
        (MAX(value) - MIN(value))
        / MIN(value) * 100,
        2
    ) AS percent_above_lowest
FROM clean.dwelling
WHERE year = 2021
  AND geography = 'Canada'
  AND energy_type = 'Total, all energy types'
  AND measure = 'Gigajoules per household';