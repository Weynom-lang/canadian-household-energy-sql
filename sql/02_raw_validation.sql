-- ============================================================
-- raw.overall validation
-- Purpose: confirm that the imported dataset matches the
-- expected source structure and observation grain.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Row count, value completeness, and status preservation
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
FROM raw.overall;


-- ------------------------------------------------------------
-- 2. Validate candidate grain
--
-- Expected grain:
-- one observation per
-- ref_date + geo + energy_type + energy_consumption
--
-- Expected result: 0 rows.
-- Any returned row would indicate that the proposed grain is
-- not unique and would require further investigation.
-- ------------------------------------------------------------

SELECT
    ref_date,
    geo,
    energy_type,
    energy_consumption,
    COUNT(*) AS row_count
FROM raw.overall
GROUP BY
    ref_date,
    geo,
    energy_type,
    energy_consumption
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 3. Spot check a normal published observation
--
-- Expected:
-- value  = 92.1
-- status = NULL
-- ------------------------------------------------------------

SELECT
    ref_date,
    geo,
    energy_type,
    energy_consumption,
    value,
    status
FROM raw.overall
WHERE ref_date = 2011
  AND geo = 'Canada'
  AND energy_type = 'Natural gas'
  AND energy_consumption = 'Gigajoules per household';


-- ------------------------------------------------------------
-- 4. Spot check a suppressed/unavailable observation
--
-- Expected:
-- value  = NULL
-- status = 'F'
-- ------------------------------------------------------------

SELECT
    ref_date,
    geo,
    energy_type,
    energy_consumption,
    value,
    status
FROM raw.overall
WHERE ref_date = 2011
  AND geo = 'Newfoundland and Labrador'
  AND energy_type = 'Natural gas'
  AND energy_consumption = 'Gigajoules';