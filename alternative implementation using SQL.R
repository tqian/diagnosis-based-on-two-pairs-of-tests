library(DBI)
library(duckdb)
library(dplyr)

# — assume test_A_pos, test_B_pos, and diagnosis_df already exist

con <- dbConnect(duckdb::duckdb(), dbdir=":memory:")
dbWriteTable(con, "test_A", test_A_pos)
dbWriteTable(con, "test_B", test_B_pos)

sql_duck_fixed <- "
WITH test_A_pos AS (
  SELECT person_id, date AS a_date
  FROM test_A
),
test_B_pos AS (
  SELECT person_id, date AS b_date
  FROM test_B
),
A_pairs AS (
  SELECT A1.person_id, A1.a_date AS a1, A2.a_date AS a2
  FROM test_A_pos A1
  JOIN test_A_pos A2
    ON A1.person_id = A2.person_id
   AND A2.a_date BETWEEN A1.a_date + INTERVAL '90 days'
                    AND A1.a_date + INTERVAL '365 days'
),
B_pairs AS (
  SELECT B1.person_id, B1.b_date AS b1, B2.b_date AS b2
  FROM test_B_pos B1
  JOIN test_B_pos B2
    ON B1.person_id = B2.person_id
   AND B2.b_date BETWEEN B1.b_date + INTERVAL '90 days'
                    AND B1.b_date + INTERVAL '365 days'
),
valid_pairs AS (
  SELECT A.person_id
  FROM A_pairs A
  JOIN B_pairs B
    ON A.person_id = B.person_id
   AND abs(date_diff('day', A.a1, B.b1)) <= 30
   AND abs(date_diff('day', A.a2, B.b2)) <= 30
  GROUP BY A.person_id
),
all_persons AS (
  SELECT DISTINCT person_id FROM test_A
  UNION
  SELECT DISTINCT person_id FROM test_B
)
SELECT
  p.person_id,
  CASE WHEN v.person_id IS NOT NULL THEN 1 ELSE 0 END AS diagnosis
FROM all_persons p
LEFT JOIN valid_pairs v ON p.person_id = v.person_id
ORDER BY p.person_id;
"

res_sql <- dbGetQuery(con, sql_duck_fixed)

# Compare to your R result
comparison <- diagnosis_df %>%
    full_join(res_sql, by="person_id", suffix=c("_r","_sql")) %>%
    mutate(match = (diagnosis_r == diagnosis_sql))

if (all(comparison$match)) {
    message("✅ SQL and R agree for all persons.")
} else {
    warning("❌ Mismatches:\n", 
            paste0(capture.output(print(filter(comparison, !match))), collapse="\n"))
}

dbDisconnect(con, shutdown=TRUE)