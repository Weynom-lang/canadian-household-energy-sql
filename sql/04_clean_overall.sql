-- ============================================================
-- Create clean.overall
-- Purpose: expose the analytically useful fields from
-- raw.overall using clearer, reader-friendly names.
-- ============================================================

CREATE VIEW clean.overall AS
SELECT
    ref_date AS year,
    geo AS geography,
    energy_type,
    energy_consumption AS measure,
    uom AS unit,
    value,
    status,
    vector AS statcan_vector
FROM raw.overall;



-- Design decisions:
--
-- ref_date -> year
-- clearer analytical naming.
--
-- geo -> geography
-- clearer to a reader unfamiliar with the StatsCan source.
--
-- energy_consumption -> measure
-- the field contains multiple measure types, including
-- Gigajoules, Gigajoules per household, Number of households,
-- and Proportion of total energy.
--
-- uom -> unit
-- retained because it provides useful context for interpreting
-- value, even where the measure already implies the unit.
--
-- vector -> statcan_vector
-- retained as the stable Statistics Canada series identifier
-- for source traceability across years.
--
-- Omitted from clean.overall:
-- raw_id, dguid, uom_id, scalar_factor, scalar_id, coordinate,
-- symbol, terminated, decimals.
--
-- These remain preserved in raw.overall but add limited value
-- to everyday analytical queries.
--
-- No rows are filtered from the clean view.
-- F-flagged and NULL-valued observations remain available
-- because their absence is itself analytically meaningful.