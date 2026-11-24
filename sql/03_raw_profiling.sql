-- ============================================================
-- raw.overall profiling
-- Purpose: investigate data quality, categorical structure,
-- measurement relationships, and source metadata before
-- designing the clean analytical layer.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Overall status distribution
--
-- Finding:
-- F-flagged observations are substantial enough to investigate
-- further rather than treating missingness as random.
-- ------------------------------------------------------------

SELECT
    status,
    COUNT(*) AS row_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM raw.overall),
        2
    ) AS percentage_row_count
FROM raw.overall
GROUP BY status
ORDER BY status;


-- ------------------------------------------------------------
-- 2. Status distribution by geography
--
-- Question:
-- Is missingness / quality flagging evenly distributed across
-- provinces, or concentrated geographically?
--
-- Finding:
-- Quality flags vary substantially by geography.
-- ------------------------------------------------------------

SELECT
    geo,
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE status IS NULL) AS no_flag_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status IS NULL) * 100.0 / COUNT(*),
        2
    ) AS no_flag_pct,

    COUNT(*) FILTER (WHERE status = 'E') AS e_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'E') * 100.0 / COUNT(*),
        2
    ) AS e_pct,

    COUNT(*) FILTER (WHERE status = 'F') AS f_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'F') * 100.0 / COUNT(*),
        2
    ) AS f_pct

FROM raw.overall
GROUP BY geo
ORDER BY f_pct DESC, e_pct DESC;


-- ------------------------------------------------------------
-- 3. Status distribution by year
--
-- Question:
-- Is the quality problem mainly temporal?
--
-- Finding:
-- F rates are relatively stable across years, with only modest
-- variation. Year does not appear to be the primary driver.
-- ------------------------------------------------------------

SELECT
    ref_date,
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE status IS NULL) AS no_flag_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status IS NULL) * 100.0 / COUNT(*),
        2
    ) AS no_flag_pct,

    COUNT(*) FILTER (WHERE status = 'E') AS e_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'E') * 100.0 / COUNT(*),
        2
    ) AS e_pct,

    COUNT(*) FILTER (WHERE status = 'F') AS f_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'F') * 100.0 / COUNT(*),
        2
    ) AS f_pct

FROM raw.overall
GROUP BY ref_date
ORDER BY ref_date;


-- ------------------------------------------------------------
-- 4. Status distribution by energy type
--
-- Finding:
-- F-flagged observations are concentrated in natural gas and
-- heating oil. Electricity and total-energy observations are
-- unflagged in this dataset.
-- ------------------------------------------------------------

SELECT
    energy_type,
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE status IS NULL) AS no_flag_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status IS NULL) * 100.0 / COUNT(*),
        2
    ) AS no_flag_pct,

    COUNT(*) FILTER (WHERE status = 'E') AS e_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'E') * 100.0 / COUNT(*),
        2
    ) AS e_pct,

    COUNT(*) FILTER (WHERE status = 'F') AS f_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'F') * 100.0 / COUNT(*),
        2
    ) AS f_pct

FROM raw.overall
GROUP BY energy_type
ORDER BY f_pct DESC, e_pct DESC;


-- ------------------------------------------------------------
-- 5. Geography x energy type interaction
--
-- Question:
-- Is the quality issue really a province problem, a fuel
-- problem, or an interaction between both?
--
-- Finding:
-- Missingness is concentrated in specific geography x fuel
-- combinations rather than entire provinces being broadly poor.
-- ------------------------------------------------------------

SELECT
    geo,
    energy_type,
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE status = 'F') AS f_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'F') * 100.0 / COUNT(*),
        2
    ) AS f_pct,

    COUNT(*) FILTER (WHERE status = 'E') AS e_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'E') * 100.0 / COUNT(*),
        2
    ) AS e_pct

FROM raw.overall
GROUP BY
    geo,
    energy_type
ORDER BY
    f_pct DESC,
    e_pct DESC,
    geo,
    energy_type;


-- ------------------------------------------------------------
-- 6. Energy type x measurement
--
-- Question:
-- Are specific measurements disproportionately affected, or
-- does suppression tend to affect several related measurements
-- within the same fuel?
--
-- Finding:
-- Natural gas and heating oil show similar F rates across
-- several measures, suggesting the issue is broader than one
-- specific measurement such as GJ per household.
-- ------------------------------------------------------------

SELECT
    energy_type,
    energy_consumption,
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE status = 'F') AS f_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'F') * 100.0 / COUNT(*),
        2
    ) AS f_pct,

    COUNT(*) FILTER (WHERE status = 'E') AS e_rows,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'E') * 100.0 / COUNT(*),
        2
    ) AS e_pct

FROM raw.overall
GROUP BY
    energy_type,
    energy_consumption
ORDER BY
    f_pct DESC,
    e_pct DESC,
    energy_type,
    energy_consumption;


-- ------------------------------------------------------------
-- 7. Measurement / unit relationships
--
-- Purpose:
-- Determine which fields add analytical meaning versus coded or
-- presentation metadata.
--
-- Clean-layer decision:
-- keep energy_consumption and uom;
-- omit uom_id and decimals from clean.
-- ------------------------------------------------------------

SELECT DISTINCT
    energy_consumption,
    uom,
    uom_id,
    decimals
FROM raw.overall
ORDER BY
    energy_consumption,
    uom;


-- ------------------------------------------------------------
-- 8. Constant and empty metadata fields
--
-- Finding:
-- scalar_factor and scalar_id are constant;
-- symbol and terminated contain no populated values.
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT scalar_factor) AS scalar_factor_distinct,
    COUNT(DISTINCT scalar_id) AS scalar_id_distinct,

    COUNT(symbol) AS symbol_non_null,
    COUNT(DISTINCT symbol) AS symbol_distinct,

    COUNT(terminated) AS terminated_non_null,
    COUNT(DISTINCT terminated) AS terminated_distinct
FROM raw.overall;


SELECT DISTINCT
    scalar_factor,
    scalar_id
FROM raw.overall;


-- ------------------------------------------------------------
-- 9. Geography identifier relationship
--
-- Finding:
-- 11 geographies map to 11 DGUID values.
-- DGUID provides source-system geography traceability but adds
-- little everyday analytical value once geography is retained.
-- ------------------------------------------------------------

SELECT DISTINCT
    geo,
    dguid
FROM raw.overall
ORDER BY geo;


-- ------------------------------------------------------------
-- 10. StatsCan vector structure
--
-- Finding:
-- Each vector identifies one statistical series:
-- one geography + one energy type + one measurement,
-- repeated across the five reference years.
-- ------------------------------------------------------------

SELECT
    vector,
    COUNT(*) AS row_count,
    COUNT(DISTINCT ref_date) AS year_count,
    COUNT(DISTINCT geo) AS geo_count,
    COUNT(DISTINCT energy_type) AS energy_type_count,
    COUNT(DISTINCT energy_consumption) AS measure_count
FROM raw.overall
GROUP BY vector
ORDER BY vector;


-- ------------------------------------------------------------
-- 11. Coordinate structure
--
-- Purpose:
-- Decode the source coordinate field.
--
-- Finding:
-- coordinate is a positional encoding of:
-- geography.energy_type.energy_consumption
-- ------------------------------------------------------------

SELECT DISTINCT
    coordinate,
    geo,
    energy_type,
    energy_consumption,
    SPLIT_PART(coordinate, '.', 1)::INTEGER AS coord_1,
    SPLIT_PART(coordinate, '.', 2)::INTEGER AS coord_2,
    SPLIT_PART(coordinate, '.', 3)::INTEGER AS coord_3
FROM raw.overall
ORDER BY
    coord_1,
    coord_2,
    coord_3;