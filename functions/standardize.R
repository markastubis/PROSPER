
standardize <- function(df, exclude_cols) {
  df %>%
    mutate(across(
      .cols = -all_of(exclude_cols),
      .fns = ~ (.-mean(.)) / sd(.)
    ))
}