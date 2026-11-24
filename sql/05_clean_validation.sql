-- ============================================================
-- clean.overall validation
-- Purpose: confirm that the clean view preserves the expected
-- row count, missingness structure, candidate grain, and
-- StatsCan time-series relationships from raw.overall.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Compare raw and clean row counts
--
-- Expected:
-- raw_rows   = 825
-- clean_rows = 825
-- ------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM raw.overall) AS raw_rows,
    (SELECT COUNT(*) FROM clean.overall) AS clean_rows;


-- ------------------------------------------------------------
-- 2. Confirm value completeness and status preservation
--
-- Expected:
-- total_rows      = 825
-- non_null_values = 679
-- null_values     = 146
-- f_rows          = 146
-- e_rows          = 34
-- no_status_rows  = 645
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(value) AS non_null_values,
    COUNT(*) FILTER (WHERE value IS NULL) AS null_values,
    COUNT(*) FILTER (WHERE status = 'F') AS f_rows,
    COUNT(*) FILTER (WHERE status = 'E') AS e_rows,
    COUNT(*) FILTER (WHERE status IS NULL) AS no_status_rows
FROM clean.overall;


-- ------------------------------------------------------------
-- 3. Re-check candidate grain
--
-- Expected grain:
-- one observation per
-- year + geography + energy_type + measure
--
-- Expected result: 0 rows.
-- ------------------------------------------------------------

SELECT
    year,
    geography,
    energy_type,
    measure,
    COUNT(*) AS row_count
FROM clean.overall
GROUP BY
    year,
    geography,
    energy_type,
    measure
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 4. Validate StatsCan series structure
--
-- Each statcan_vector should appear exactly five times,
-- once for each reference year:
-- 2011, 2013, 2015, 2019, 2021.
--
-- Expected result: 0 rows.
-- ------------------------------------------------------------

SELECT
    statcan_vector,
    COUNT(*) AS row_count,
    COUNT(DISTINCT year) AS year_count
FROM clean.overall
GROUP BY statcan_vector
HAVING
    COUNT(*) <> 5
    OR COUNT(DISTINCT year) <> 5;