{{ config(
        materialized='incremental',
        on_schema_change='fail'
    ) }}

WITH src_reviews AS (
    SELECT *
    FROM {{ ref('src_reviews') }}
)
SELECT * FROM src_reviews
WHERE review_text IS NOT NULL
{% if is_incremental() %}
  AND review_date > (SELECT MAX(review_date) FROM {{ this }})
{% endif %} -- This ensures that only new reviews are added during incremental runs, preventing duplicates and maintaining data integrity.

-- If we write the query in plain SQL:
-- SELECT *
-- FROM src_reviews
-- WHERE review_text IS NOT NULL
-- AND review_date > (SELECT MAX(review_date) FROM fct_reviews)

-- But this would fail during the initial run when the fct_reviews table doesn't exist yet, hence the use of the is_incremental() macro in DBT is crucial to handle this scenario gracefully.