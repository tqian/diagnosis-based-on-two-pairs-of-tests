library(tidyverse)

# 1. Combine A and B positives and join the diagnosis details
df_plot <- bind_rows(
    test_A_pos %>% mutate(test = "A"),
    test_B_pos %>% mutate(test = "B")
) %>%
    left_join(diagnosis_df, by = "person_id") %>%
    mutate(
        highlight = case_when(
            diagnosis == 1 & test == "A" & date %in% c(A1_date, A2_date) ~ "highlight",
            diagnosis == 1 & test == "B" & date %in% c(B1_date, B2_date) ~ "highlight",
            TRUE                                                           ~ "normal"
        )
    )

# 2. Compute each person’s observation span for the horizontal lines
line_df <- df_plot %>%
    group_by(person_id) %>%
    summarise(
        min_date = min(date),
        max_date = max(date),
        .groups = "drop"
    )

# 3. Plot
ggplot() +
    # background span per person
    geom_segment(
        data = line_df,
        aes(
            x = min_date,
            xend = max_date,
            y = factor(person_id),
            yend = factor(person_id)
        ),
        color = "grey80"
    ) +
    # all positive tests, colored by highlight status, shaped by test type
    geom_point(
        data = df_plot,
        aes(
            x     = date,
            y     = factor(person_id),
            shape = test,
            color = highlight
        ),
        size = 3
    ) +
    scale_shape_manual(
        name   = "Test Type",
        values = c(A = 16, B = 4)
    ) +
    scale_color_manual(
        name   = "Diagnosis Pair",
        values = c(normal    = "steelblue",
                   highlight = "red")
    ) +
    labs(
        x     = "Date",
        y     = "Person ID",
        title = "Test A (●) and Test B (×) Positives with Diagnosis Pairs Highlighted"
    ) +
    theme_minimal() +
    theme(
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank()
    )