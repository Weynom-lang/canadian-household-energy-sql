-- ============================================================
-- Household-Income Dataset Pipeline
-- ============================================================
-- Purpose:
-- Define the raw table structure, create an analyst-friendly
-- clean view, and validate the household-income dataset used
-- in Question 5 of the household energy analysis.
--
-- Source: Statistics Canada household energy consumption data
-- Expected raw row count: 6,270
--
-- Candidate grain:
-- ref_date + geo + household_income + energy_type
-- + energy_consumption
--
-- Important structural note:
-- The "Income not stated" category is present in 2011, 2013,
-- and 2015 but is absent from 2019 and 2021. Therefore, not
-- every statistical vector is expected to contain all five
-- study-year observations.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Raw table
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS raw.income (
    raw_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ref_date INTEGER,
    geo TEXT,
    dguid TEXT,
    household_income TEXT,
    energy_type TEXT,
    energy_consumption TEXT,
    uom TEXT,
    uom_id INTEGER,
    scalar_factor TEXT,
    scalar_id INTEGER,
    vector TEXT,
    coordinate TEXT,
    value NUMERIC,
    status TEXT,
    symbol TEXT,
    terminated TEXT,
    decimals INTEGER
);


-- ------------------------------------------------------------
-- 2. Raw row-count validation
-- ------------------------------------------------------------
-- Expected result: 6,270 rows after CSV import.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows
FROM raw.income;


-- ------------------------------------------------------------
-- 3. Candidate-grain duplicate check
-- ------------------------------------------------------------
-- Expected result: 0 rows.
-- ------------------------------------------------------------

SELECT
    ref_date,
    geo,
    household_income,
    energy_type,
    energy_consumption,
    COUNT(*) AS row_count
FROM raw.income
GROUP BY
    ref_date,
    geo,
    household_income,
    energy_type,
    energy_consumption
HAVING COUNT(*) > 1
ORDER BY row_count DESC;


-- ------------------------------------------------------------
-- 4. Vector-year coverage profile
-- ------------------------------------------------------------
-- This intentionally profiles the number of observed years
-- rather than assuming every vector must contain five rows.
--
-- Expected source structure:
-- 1,155 vectors with 5 observed years
--   165 vectors with 3 observed years
--
-- The three-year vectors correspond to "Income not stated".
-- ------------------------------------------------------------

WITH vector_coverage AS (
    SELECT
        vector,
        COUNT(DISTINCT ref_date) AS observed_years
    FROM raw.income
    GROUP BY vector
)
SELECT
    observed_years,
    COUNT(*) AS vector_count
FROM vector_coverage
GROUP BY observed_years
ORDER BY observed_years DESC;


-- ------------------------------------------------------------
-- 5. 2021 Canada analysis-slice validation
-- ------------------------------------------------------------
-- Expected result:
-- 7 published income categories with no F or E quality flags.
-- ------------------------------------------------------------

SELECT
    household_income,
    value,
    status
FROM raw.income
WHERE ref_date = 2021
  AND geo = 'Canada'
  AND energy_type = 'Total, all energy types'
  AND energy_consumption = 'Gigajoules per household'
ORDER BY value;


-- ------------------------------------------------------------
-- 6. Clean view
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW clean.income AS
SELECT
    ref_date AS year,
    geo AS geography,
    household_income,
    energy_type,
    energy_consumption AS measure,
    uom AS unit,
    value,
    status,
    vector AS statcan_vector
FROM raw.income;


-- ------------------------------------------------------------
-- 7. Raw-to-clean row-count validation
-- ------------------------------------------------------------
-- Expected:
-- raw_rows   = 6,270
-- clean_rows = 6,270
-- ------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM raw.income) AS raw_rows,
    (SELECT COUNT(*) FROM clean.income) AS clean_rows;


-- ------------------------------------------------------------
-- 8. Clean-view grain validation
-- ------------------------------------------------------------
-- Expected result: 0 rows.
-- ------------------------------------------------------------

SELECT
    year,
    geography,
    household_income,
    energy_type,
    measure,
    COUNT(*) AS row_count
FROM clean.income
GROUP BY
    year,
    geography,
    household_income,
    energy_type,
    measure
HAVING COUNT(*) > 1
ORDER BY row_count DESC;