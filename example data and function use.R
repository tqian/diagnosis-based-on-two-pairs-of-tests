# Load necessary library
library(tidyverse)

set.seed(42)

# 1. Create fake datasets ----------------------------------------

n_persons   <- 5
dates_range <- seq.Date(from = as.Date("2020-01-01"),
                        to   = as.Date("2022-12-31"),
                        by   = "day")

test_A_raw <- tibble(
    person_id = sample(1:n_persons, 150, replace = TRUE),
    date      = sample(dates_range, 150, replace = TRUE),
    result    = sample(c("Positive", "Negative"),
                       150,
                       replace = TRUE,
                       prob    = c(0.3, 0.7))
)

test_B_raw <- tibble(
    person_id = sample(1:n_persons, 150, replace = TRUE),
    date      = sample(dates_range, 150, replace = TRUE),
    result    = sample(c("Positive", "Negative"),
                       150,
                       replace = TRUE,
                       prob    = c(0.3, 0.7))
)

# 2. Keep only positives, keep result column ---------------------

test_A_pos <- test_A_raw %>%
    filter(result == "Positive") %>%
    select(person_id, date, result)

test_B_pos <- test_B_raw %>%
    filter(result == "Positive") %>%
    select(person_id, date, result)

# 3. Helper: generate all date-pairs (ensuring Date type) ---------

make_pairs <- function(dates) {
    dates <- sort(unique(dates))
    if (length(dates) < 2) {
        return(tibble(
            date1 = as.Date(character()),
            date2 = as.Date(character())
        ))
    }
    mat <- combn(dates, 2)
    tibble(
        date1 = as.Date(mat[1, ], origin = "1970-01-01"),
        date2 = as.Date(mat[2, ], origin = "1970-01-01")
    )
}

# 4. Process each person individually -----------------------------

persons <- sort(unique(c(test_A_pos$person_id, test_B_pos$person_id)))
records <- vector("list", length(persons))

for (i in persons) {
    # This person's positive test records
    A_rec <- test_A_pos %>% filter(person_id == i)
    B_rec <- test_B_pos %>% filter(person_id == i)
    
    # Generate & filter A-pairs
    A_pairs <- make_pairs(A_rec$date) %>%
        mutate(diff_A = as.numeric(date2 - date1)) %>%
        filter(diff_A >= 90, diff_A <= 365)
    
    # Generate & filter B-pairs
    B_pairs <- make_pairs(B_rec$date) %>%
        mutate(diff_B = as.numeric(date2 - date1)) %>%
        filter(diff_B >= 90, diff_B <= 365)
    
    # Initialize defaults
    diag_flag <- 0
    out <- tibble(
        person_id = i,
        diagnosis = 0,
        A1_date   = as.Date(NA), A1_result = NA_character_,
        A2_date   = as.Date(NA), A2_result = NA_character_,
        B1_date   = as.Date(NA), B1_result = NA_character_,
        B2_date   = as.Date(NA), B2_result = NA_character_,
        diff_A    = NA_real_,
        diff_B    = NA_real_,
        align1    = NA_real_,
        align2    = NA_real_
    )
    
    # Search for first valid alignment
    if (nrow(A_pairs) > 0 && nrow(B_pairs) > 0) {
        found <- FALSE
        for (rA in seq_len(nrow(A_pairs))) {
            for (rB in seq_len(nrow(B_pairs))) {
                a1 <- A_pairs$date1[rA]; a2 <- A_pairs$date2[rA]
                b1 <- B_pairs$date1[rB]; b2 <- B_pairs$date2[rB]
                al1 <- abs(as.numeric(a1 - b1))
                al2 <- abs(as.numeric(a2 - b2))
                if (al1 <= 30 && al2 <= 30) {
                    # record this match
                    diag_flag <- 1
                    out <- tibble(
                        person_id = i,
                        diagnosis = 1,
                        A1_date   = a1,
                        A1_result = A_rec %>% filter(date == a1) %>% pull(result) %>% first(),
                        A2_date   = a2,
                        A2_result = A_rec %>% filter(date == a2) %>% pull(result) %>% first(),
                        B1_date   = b1,
                        B1_result = B_rec %>% filter(date == b1) %>% pull(result) %>% first(),
                        B2_date   = b2,
                        B2_result = B_rec %>% filter(date == b2) %>% pull(result) %>% first(),
                        diff_A    = as.numeric(a2 - a1),
                        diff_B    = as.numeric(b2 - b1),
                        align1    = al1,
                        align2    = al2
                    )
                    found <- TRUE
                    break
                }
            }
            if (found) break
        }
    }
    
    records[[i]] <- out
}

# 5. Combine into final diagnosis_df ------------------------------

diagnosis_df <- bind_rows(records)

# 6. Inspect results ----------------------------------------------

View(diagnosis_df)
