-- ============================================================
-- Question 3: 2021 Energy-Source Patterns
-- ============================================================
-- How do household energy-source patterns differ across
-- Canadian provinces in 2021?
--
-- Energy types:
-- - Electricity
-- - Natural gas
-- - Heating oil
--
-- Analysis uses two complementary measures:
--
-- 1. Gigajoules per household
--    Used to compare consumption intensity for each fuel
--    across provinces with published observations.
--
-- 2. Proportion of total energy
--    Used to examine each province's household fuel mix and
--    identify the dominant household energy source.
--
-- Important data-quality rules:
--
-- F = value unavailable / suppressed
--     These observations are not used quantitatively.
--
-- E = published estimate that should be used with caution
--     These values remain available but are explicitly flagged.
--
-- Fuel-specific GJ/household values should be interpreted
-- within each fuel rather than summed across fuels.
-- ============================================================



-- ------------------------------------------------------------
-- 1. 2021 fuel-data quality summary
-- ------------------------------------------------------------
-- Purpose:
-- Measure data availability for the three fuel types across
-- both GJ/household and proportion-of-total-energy measures.
--
-- Expected grain:
-- One row per energy_type + measure combination.
--
-- Expected rows:
-- 3 fuels × 2 measures = 6 rows.
-- ------------------------------------------------------------

SELECT
    energy_type,
    measure,

    COUNT(*) AS total_rows,

    COUNT(value) AS available_values,

    COUNT(*) FILTER (
        WHERE status = 'F'
    ) AS suppressed_rows,

    COUNT(*) FILTER (
        WHERE status = 'E'
    ) AS caution_rows

FROM clean.overall

WHERE year = 2021

  AND energy_type IN (
      'Electricity',
      'Natural gas',
      'Heating oil'
  )

  AND measure IN (
      'Gigajoules per household',
      'Proportion of total energy'
  )

GROUP BY
    energy_type,
    measure

ORDER BY
    measure,
    energy_type;



-- ------------------------------------------------------------
-- 2. Identify flagged 2021 fuel observations
-- ------------------------------------------------------------
-- Purpose:
-- Identify exactly where F and E quality flags occur.
--
-- This allows suppressed observations to be distinguished from
-- genuinely low or zero fuel consumption.
-- ------------------------------------------------------------

SELECT
    geography,
    energy_type,
    measure,
    value,
    status

FROM clean.overall

WHERE year = 2021

  AND energy_type IN (
      'Electricity',
      'Natural gas',
      'Heating oil'
  )

  AND measure IN (
      'Gigajoules per household',
      'Proportion of total energy'
  )

  AND status IS NOT NULL

ORDER BY
    measure,
    energy_type,
    geography;



-- ============================================================
-- 3A. Fuel Consumption Intensity
-- ============================================================


-- ------------------------------------------------------------
-- 3. Published GJ/household observations by fuel
-- ------------------------------------------------------------
-- Purpose:
-- Compare consumption intensity across provinces separately
-- for electricity, natural gas, and heating oil.
--
-- F observations are automatically excluded because they have
-- NULL values.
--
-- New Brunswick's natural-gas value remains included because
-- it is published, but carries an E caution flag.
-- ------------------------------------------------------------

SELECT
    geography,
    energy_type,
    value,
    status

FROM clean.overall

WHERE year = 2021

  AND energy_type IN (
      'Electricity',
      'Natural gas',
      'Heating oil'
  )

  AND measure = 'Gigajoules per household'

  AND geography <> 'Canada'

  AND value IS NOT NULL

ORDER BY
    energy_type,
    value DESC;



-- ------------------------------------------------------------
-- 4. Highest and lowest published consumption intensity
--    within each fuel
-- ------------------------------------------------------------
-- Purpose:
-- Identify the highest- and lowest-consuming province among
-- published observations for each individual fuel.
--
-- PARTITION BY energy_type creates a separate ranking window
-- for electricity, natural gas, and heating oil.
--
-- RANK() is calculated twice:
--
-- DESC → highest value receives rank 1
-- ASC  → lowest value receives rank 1
-- ------------------------------------------------------------

WITH ranked_fuels AS (

    SELECT
        geography,
        energy_type,
        value,
        status,

        RANK() OVER (
            PARTITION BY energy_type
            ORDER BY value DESC
        ) AS rank_high_to_low,

        RANK() OVER (
            PARTITION BY energy_type
            ORDER BY value ASC
        ) AS rank_low_to_high

    FROM clean.overall

    WHERE year = 2021

      AND energy_type IN (
          'Electricity',
          'Natural gas',
          'Heating oil'
      )

      AND measure = 'Gigajoules per household'

      AND geography <> 'Canada'

      AND value IS NOT NULL
)

SELECT
    geography,
    energy_type,
    value,
    status,
    rank_high_to_low,
    rank_low_to_high

FROM ranked_fuels

WHERE rank_high_to_low = 1
   OR rank_low_to_high = 1

ORDER BY
    energy_type,
    value DESC;



-- ============================================================
-- 3B. Provincial Fuel Mix
-- ============================================================


-- ------------------------------------------------------------
-- 5. Pivot 2021 fuel shares into one row per province
-- ------------------------------------------------------------
-- Purpose:
-- Place electricity, natural-gas, and heating-oil shares
-- beside each other for easier province-level comparison.
--
-- suppressed_fuels records how many of the three fuel-share
-- observations are unavailable because of an F flag.
--
-- Expected grain:
-- One row per province.
--
-- Expected rows:
-- 10 provinces.
-- ------------------------------------------------------------

SELECT
    geography,

    MAX(value) FILTER (
        WHERE energy_type = 'Electricity'
    ) AS electricity_pct,

    MAX(value) FILTER (
        WHERE energy_type = 'Natural gas'
    ) AS natural_gas_pct,

    MAX(value) FILTER (
        WHERE energy_type = 'Heating oil'
    ) AS heating_oil_pct,

    COUNT(*) FILTER (
        WHERE status = 'F'
    ) AS suppressed_fuels

FROM clean.overall

WHERE year = 2021

  AND measure = 'Proportion of total energy'

  AND energy_type IN (
      'Electricity',
      'Natural gas',
      'Heating oil'
  )

  AND geography <> 'Canada'

GROUP BY geography

ORDER BY geography;



-- ------------------------------------------------------------
-- 6. Identify the dominant household energy source
-- ------------------------------------------------------------
-- Purpose:
-- Classify the dominant fuel in each province.
--
-- A fuel is considered dominant when it accounts for more
-- than 50% of total household energy consumption.
--
-- Because each identified dominant fuel has a majority share,
-- suppressed values for another fuel cannot overturn the
-- dominant-fuel classification.
-- ------------------------------------------------------------

WITH fuel_mix AS (

    SELECT
        geography,

        MAX(value) FILTER (
            WHERE energy_type = 'Electricity'
        ) AS electricity_pct,

        MAX(value) FILTER (
            WHERE energy_type = 'Natural gas'
        ) AS natural_gas_pct,

        MAX(value) FILTER (
            WHERE energy_type = 'Heating oil'
        ) AS heating_oil_pct,

        COUNT(*) FILTER (
            WHERE status = 'F'
        ) AS suppressed_fuels

    FROM clean.overall

    WHERE year = 2021

      AND measure = 'Proportion of total energy'

      AND energy_type IN (
          'Electricity',
          'Natural gas',
          'Heating oil'
      )

      AND geography <> 'Canada'

    GROUP BY geography
)

SELECT
    geography,
    electricity_pct,
    natural_gas_pct,
    heating_oil_pct,
    suppressed_fuels,

    CASE
        WHEN electricity_pct > 50 THEN 'Electricity'
        WHEN natural_gas_pct > 50 THEN 'Natural gas'
        WHEN heating_oil_pct > 50 THEN 'Heating oil'
        ELSE 'No clear majority'
    END AS dominant_fuel

FROM fuel_mix

ORDER BY geography;