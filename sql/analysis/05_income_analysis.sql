-- ============================================================
-- Question 5: 2021 Household-Income Comparison
-- ============================================================
-- How did household energy consumption per household differ
-- across household-income groups in Canada in 2021?
--
-- Geography: Canada
-- Year: 2021
-- Energy type: Total, all energy types
-- Measure: Gigajoules per household
--
-- Analysis:
-- 1. Order income groups from lowest to highest income
-- 2. Compare energy consumption across successive brackets
-- 3. Quantify the gap between the highest- and lowest-income
--    categories
--
-- Note:
-- The results describe an association between household income
-- and energy consumption. They do not establish that income
-- itself causes the observed differences.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Household energy consumption by income group
-- ------------------------------------------------------------
-- Purpose:
-- Compare total household energy consumption per household
-- across the seven published 2021 income categories.
--
-- Household income is stored as text, so CASE is used to impose
-- the correct analytical order from lowest to highest income.
-- ------------------------------------------------------------

SELECT
    household_income,
    value AS gj_per_household
FROM clean.income
WHERE year = 2021
  AND geography = 'Canada'
  AND energy_type = 'Total, all energy types'
  AND measure = 'Gigajoules per household'
ORDER BY
    CASE household_income
        WHEN 'Under $20,000 (includes income loss)' THEN 1
        WHEN '$20,000 to $39,999' THEN 2
        WHEN '$40,000 to $59,999' THEN 3
        WHEN '$60,000 to $79,999' THEN 4
        WHEN '$80,000 to $99,999' THEN 5
        WHEN '$100,000 to $149,999' THEN 6
        WHEN '$150,000 and more' THEN 7
    END;


-- ------------------------------------------------------------
-- 2. Difference between highest- and lowest-income categories
-- ------------------------------------------------------------
-- Purpose:
-- Quantify the absolute and percentage difference between the
-- highest and lowest observed household-energy-consumption
-- values across the 2021 income categories.
--
-- percent_above_lowest measures how much larger the highest
-- value is relative to the lowest value.
-- ------------------------------------------------------------

SELECT
    MAX(value) AS highest_value,
    MIN(value) AS lowest_value,
    MAX(value) - MIN(value) AS income_gap,

    ROUND(
        (MAX(value) - MIN(value))
        / MIN(value) * 100,
        2
    ) AS percent_above_lowest

FROM clean.income

WHERE year = 2021
  AND geography = 'Canada'
  AND energy_type = 'Total, all energy types'
  AND measure = 'Gigajoules per household';