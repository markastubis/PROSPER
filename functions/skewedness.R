library(dplyr)
library(e1071)      # For skewness calculation
library(MASS)       # For Box-Cox transformation
library(bestNormalize) # For Yeo-Johnson transformation
library(scales)     # For rescale
library(car)        # For logit transformation
library(DescTools)  # For Winsorization


# Function to apply log transformation to numeric columns
log_transform <- function(data, col) {
  data[[col]] <- ifelse(is.na(data[[col]]), NA, log(data[[col]] + 1)) # Adding 1 to avoid log(0)
  return(data)
}

# Function to apply square root transformation
sqrt_transform <- function(data, col) {
  data[[col]] <- sqrt(data[[col]])
  return(data)
}

# Function to apply cube root transformation
cube_root_transform <- function(data, col) {
  data[[col]] <- sign(data[[col]]) * abs(data[[col]])^(1/3)
  return(data)
}

# Function to apply Yeo-Johnson transformation
yeo_johnson_transform <- function(data, col) {
  # Apply Yeo-Johnson transformation with error handling
  tryCatch({
    yj_transformation <- yeojohnson(data[[col]])
    data[[col]] <- yj_transformation$x.t
  }, error = function(e) {
    warning(paste("Yeo-Johnson transformation failed for column:", col, "with error:", e$message))
  })
  
  return(data)
}

rank_normal_transform <- function(data, col) {
  data[[col]] <- qnorm((rank(data[[col]], na.last = "keep") - 0.5) / sum(!is.na(data[[col]])))
  return(data)
}

# Function to apply Winsorization
winsorize_transform <- function(data, col) {
  data[[col]] <- Winsorize(data[[col]], probs = c(0.05, 0.95))
  return(data)
}


# Function to check skewness and apply transformations conditionally
apply_transformations <- function(data, exclude_cols = NULL) {
  # Identify numeric columns
  numeric_cols <- data %>% dplyr::select(where(is.numeric)) %>% colnames()
  
  # Exclude specified columns
  if (!is.null(exclude_cols)) {
    numeric_cols <- setdiff(numeric_cols, exclude_cols)
  }
  
  # Apply transformations to skewed numeric columns conditionally
  for (col in numeric_cols) {
    skewness_value <- skewness(data[[col]], na.rm = TRUE)
    if (skewness_value > 0.5 || skewness_value < -0.5) { # Threshold for initial skewness check
      # Apply log transformation to a temporary column
      temp_col <- ifelse(is.na(data[[col]]), NA, log(data[[col]] + 1)) # Adding 1 to avoid log(0)
      
      # Check the skewness of the transformed column
      temp_skewness <- skewness(temp_col, na.rm = TRUE)
      
      # Apply transformation only if the transformed skewness is within the desired range
      if (temp_skewness > -0.5 && temp_skewness < 0.5) {
        data[[col]] <- temp_col
        print(paste("Log transformation applied to column:", col))
      } else {
        # Try square root transformation
        temp_col <- sqrt_transform(data, col)[[col]]
        temp_skewness <- skewness(temp_col, na.rm = TRUE)
        if (temp_skewness > -0.5 && temp_skewness < 0.5) {
          data[[col]] <- temp_col
          print(paste("Square root transformation applied to column:", col))
        } else {
          # Try cube root transformation
          temp_col <- cube_root_transform(data, col)[[col]]
          temp_skewness <- skewness(temp_col, na.rm = TRUE)
          if (temp_skewness > -0.5 && temp_skewness < 0.5) {
            data[[col]] <- temp_col
            print(paste("Cube root transformation applied to column:", col))
          } 
          else {
            # Apply Yeo-Johnson transformation
            temp_data <- yeo_johnson_transform(data, col)
            temp_skewness <- skewness(temp_data[[col]], na.rm = TRUE)
            if (temp_skewness > -0.5 && temp_skewness < 0.5) {
              data <- temp_data;
              print(paste("Yeo-Johnson transformation applied to column:", col))
            } else {
                warning(paste("Failed to normalize column:", col, "with any transformation"))
            }
          }
        }
      }
    }
  }
  
  return(data)
}

print_skewness <- function(data) {
  # Identify all columns
  column_names <- colnames(data)
  
  # Loop through each column and compute skewness
  for (col in column_names) {
    # Check if column is numeric
    if (is.numeric(data[[col]])) {
      skewness_value <- skewness(data[[col]], na.rm = TRUE)
      print(paste(col, ":", skewness_value))
    } else {
      print(paste(col, ": not numeric"))
    }
  }
}