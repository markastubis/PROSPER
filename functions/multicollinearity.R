test_multicollinearity <- function(dependentVar, data, threshold = 5) {
  # Ensure there are no missing values
  data <- na.omit(data)
  
  # Remove constant columns (columns with zero variance)
  data <- data[, sapply(data, function(col) var(col) > 0)]
  
  # Initialize a list to store pairs of multicollinear variables
  multicollinear_pairs <- list()
  
  # Get all pairs of columns
  col_names <- names(data)
  num_cols <- length(col_names)
  
  # Loop through each pair of columns
  for (i in 1:(num_cols - 1)) {
    for (j in (i + 1):num_cols) {
      pair_data <- data[, c(col_names[i], col_names[j])]
      # Fit a linear model with the pair of columns
      fit <- lm(data = pair_data, as.formula(paste("dependentVar~", paste(names(pair_data), collapse = " + "))))
      
      # Calculate VIF for the pair
      vif_values <- vif(fit)
      
      # Check if VIF values are above the threshold
      if (any(vif_values > threshold)) {
        multicollinear_pairs <- c(multicollinear_pairs, list(c(col_names[i], col_names[j])))
      }
    }
  }
  
  # Return the list of multicollinear pairs
  return(multicollinear_pairs)
}
