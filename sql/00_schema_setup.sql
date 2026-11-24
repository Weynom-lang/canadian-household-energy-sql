-- ============================================================
-- Canadian Household Energy Consumption Project
-- Database schema setup
-- ============================================================

-- raw:
-- Preserves source data as closely as practical after import.

CREATE SCHEMA raw;

-- clean:
-- Contains analysis-friendly views with clearer naming and
-- unnecessary source metadata removed.

CREATE SCHEMA clean;

-- analysis:
-- Reserved for reusable analytical views and derived results.

CREATE SCHEMA analysis;