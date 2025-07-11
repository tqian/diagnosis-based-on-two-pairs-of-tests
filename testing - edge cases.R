library(tidyverse)

# 1. Define an origin date
origin <- as.Date("2020-01-01")

# 2. List of edge‐case definitions
edge_cases <- list(
    list(id = 1,  A = c(0,   90),  B = c(30,  120)),  # valid at lower bounds, perfect 30-day align
    list(id = 2,  A = c(0,  365),  B = c(30,  395)),  # valid at upper bounds, perfect align
    list(id = 3,  A = c(0,   90),  B = c(0,   365)),  # A lower, B upper, alignment fails second
    list(id = 4,  A = c(0,   90),  B = c(0,    89)),  # B just inside/just outside window
    list(id = 5,  A = c(0,  366),  B = c(0,   365)),  # A just outside window
    list(id = 6,  A = c(0,  100),  B = c(31,  130)),  # first align fails (31), second ok (30)
    list(id = 7,  A = c(0,  100),  B = c(0,   131)),  # first ok (0), second align fails (31)
    list(id = 8,  A = c(0,   90, 200), B = c(5,  95, 205)),  # multiple pairs, only one valid
    list(id = 9,  A = c(0,   91),  B = c(0,    91)),  # overlapping dates, zero align
    list(id = 10, A = c(0),        B = c(0,    90)),  # too few A positives
    list(id = 11, A = c(),         B = c()),          # no positives
    list(id = 12, A = c(100,   0), B = c(120,   30))   # unsorted input order
)

# 3. Build test_A_pos and test_B_pos
test_A_pos <- map_dfr(edge_cases, ~ tibble(
    person_id = .x$id,
    date      = origin + .x$A,
    result    = "Positive"
))

test_B_pos <- map_dfr(edge_cases, ~ tibble(
    person_id = .x$id,
    date      = origin + .x$B,
    result    = "Positive"
))

# 4. Inspect
print("Test A positives (edge cases):")
print(test_A_pos)

print("Test B positives (edge cases):")
print(test_B_pos)



# Then run the original code:

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