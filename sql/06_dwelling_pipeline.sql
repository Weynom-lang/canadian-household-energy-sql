-- ============================================================
-- Dwelling-Type Dataset Pipeline
-- ============================================================
-- Purpose:
-- Define the raw table structure, create an analyst-friendly
-- clean view, and validate the dwelling-type dataset used in
-- Question 4 of the household energy analysis.
--
-- Source: Statistics Canada household energy consumption data
-- Expected raw row count: 5,715
--
-- Candidate grain:
-- ref_date + geo + dwelling_type + energy_type
-- + energy_consumption
-- ============================================================


-- ------------------------------------------------------------
-- 1. Raw table
-- ------------------------------------------------------------
-- The raw layer preserves source fields as closely as possible.
-- raw_id is a database-generated surrogate key and is not part
-- of the Statistics Canada source data.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS raw.dwelling (
    raw_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ref_date INTEGER,
    geo TEXT,
    dguid TEXT,
    dwelling_type TEXT,
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
-- Expected result: 5,715 rows after CSV import.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows
FROM raw.dwelling;


-- ------------------------------------------------------------
-- 3. Candidate-grain duplicate check
-- ------------------------------------------------------------
-- Expected result: 0 rows.
-- Each returned row would indicate more than one source
-- observation at the proposed analytical grain.
-- ------------------------------------------------------------

SELECT
    ref_date,
    geo,
    dwelling_type,
    energy_type,
    energy_consumption,
    COUNT(*) AS row_count
FROM raw.dwelling
GROUP BY
    ref_date,
    geo,
    dwelling_type,
    energy_type,
    energy_consumption
HAVING COUNT(*) > 1
ORDER BY row_count DESC;


-- ------------------------------------------------------------
-- 4. 2021 Canada analysis-slice validation
-- ------------------------------------------------------------
-- Confirms that the dwelling categories used in Question 4
-- contain published total-energy GJ/household values.
--
-- Expected result: 7 dwelling categories.
-- ------------------------------------------------------------

SELECT
    dwelling_type,
    value,
    status
FROM raw.dwelling
WHERE ref_date = 2021
  AND geo = 'Canada'
  AND energy_type = 'Total, all energy types'
  AND energy_consumption = 'Gigajoules per household'
ORDER BY value DESC;


-- ------------------------------------------------------------
-- 5. Clean view
-- ------------------------------------------------------------
-- Retains analyst-relevant dimensions and the Statistics Canada
-- vector for source-series traceability.
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW clean.dwelling AS
SELECT
    ref_date AS year,
    geo AS geography,
    dwelling_type,
    energy_type,
    energy_consumption AS measure,
    uom AS unit,
    value,
    status,
    vector AS statcan_vector
FROM raw.dwelling;


-- ------------------------------------------------------------
-- 6. Raw-to-clean row-count validation
-- ------------------------------------------------------------
-- Expected:
-- raw_rows   = 5,715
-- clean_rows = 5,715
-- ------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM raw.dwelling) AS raw_rows,
    (SELECT COUNT(*) FROM clean.dwelling) AS clean_rows;


-- ------------------------------------------------------------
-- 7. Clean-view grain validation
-- ------------------------------------------------------------
-- Expected result: 0 rows.
-- ------------------------------------------------------------

SELECT
    year,
    geography,
    dwelling_type,
    energy_type,
    measure,
    COUNT(*) AS row_count
FROM clean.dwelling
GROUP BY
    year,
    geography,
    dwelling_type,
    energy_type,
    measure
HAVING COUNT(*) > 1
ORDER BY row_count DESC;