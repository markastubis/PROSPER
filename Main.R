library(readxl)
library(dplyr)
library(broom)
library(knitr)
library(readr)
library(purrr)
library(lubridate)
library(car)
library(e1071)
library(lmtest)
library(ggplot2)


source('functions/standardize.R');
source('functions/match_interest_rates.R');
source('functions/skewedness.R');
source('functions/biases.R');

rawData <- read.csv("RawData.csv", sep = ",");
fedInterestRates <- read.csv("FRB_H15.csv", sep = "," );


# Filtering the dataset to remove any data before 2009-08-01
filteredData <- subset(rawData, ListingCreationDate >= as.Date("2009-08-01"));

# Filtering out empty values;
filteredData <- filteredData %>% filter(complete.cases(.));

# Filtering out loan statuses that are not of interest, keeping only "Completed" and "Defaulted" loans and 
# remapping them to integers 1 and 0 respectively
filteredData <- filteredData %>% filter(LoanStatus %in% c("Completed", "Defaulted")) %>%
  mutate(LoanStatus = case_when(
    LoanStatus == "Completed" ~ 1,
    LoanStatus == "Defaulted" ~ 0
  ))

# Removing columns that is of no use to our experiment

filteredData <- filteredData %>% dplyr::select(-`ProsperRating..Alpha.`)

# Remapping and filter employment status data.
filteredData <- filteredData %>% mutate(EmploymentStatus = case_when(
  EmploymentStatus %in% c("Self-employed", "Part-time", "Full-time", "Employed") ~ 1,
  EmploymentStatus == "Retired" ~ 0,
  TRUE ~ as.integer(NA)
)) %>%
  filter(!is.na(EmploymentStatus)) 


# Handling Boolean variables in the table
filteredData <- filteredData %>%
  mutate(across(where(is.logical), as.numeric))

# Filtering out unverifiable income (only 1 case)
filteredData <- filteredData %>% filter(IncomeVerifiable != 0)


if (!exists("matchedRates")) {
  # Calling the match_interest_rates function to create matchedRates with the FED database
  matchedRates <- match_interest_rates(filteredData, fedInterestRates)
}

filteredData <- filteredData %>%
  left_join(matchedRates, by = "ListingKey")

# Adding a new column by subtracting MatchedInterestRate from BorrowerRate
filteredData <- filteredData %>%
  mutate(AdjustedRate = BorrowerRate - MatchedInterestRate)

# Reordering columns to place AdjustedRate after BorrowerRate
cols <- colnames(filteredData)
borrower_rate_index <- which(cols == "BorrowerRate")
filteredData <- filteredData %>%
  dplyr::select(all_of(cols[1:borrower_rate_index]), AdjustedRate, all_of(cols[(borrower_rate_index + 1):length(cols)]))


averageRow <- filteredData %>%
  summarise(across(where(is.numeric), ~mean(., na.rm = TRUE)))

dependentVar <- filteredData$AdjustedRate
# dependentVar <- (dependentVar - mean(dependentVar)) / sd(dependentVar)

# Regressions

CreditScoreEstimated <- filteredData %>%
  mutate(CreditScoreEstimated = (CreditScoreRangeLower + CreditScoreRangeUpper) / 2) %>%
  # Extracting the column as a vector
  pull(CreditScoreEstimated)  
#  Removed: CurrentDelinquencies, AmountDelinquent, DelinquenciesLast7Years, Recommendations
regressionData <- filteredData %>%
  dplyr::select(Term, ProsperRating..numeric., ProsperScore, IsBorrowerHomeowner, CurrentlyInGroup, CurrentCreditLines, TotalCreditLinespast7years, OpenRevolvingAccounts, OpenRevolvingMonthlyPayment, DebtToIncomeRatio, StatedMonthlyIncome, CurrentDelinquencies, AmountDelinquent, DelinquenciesLast7Years, Recommendations) %>%
  mutate(CreditScoreEstimated = CreditScoreEstimated)


source('functions/multicollinearity.R');
multicollinear_combinations <- test_multicollinearity(dependentVar, regressionData, threshold = 5)
print(multicollinear_combinations)


# regressionData <- apply_transformations(regressionData, c("IsBorrowerHomeowner", "CurrentlyInGroup"))

# regressionData <- standardize(regressionData, c("IsBorrowerHomeowner", "CurrentlyInGroup"))



selected_vars <- regressionData %>%
  dplyr::select(ProsperRating..numeric., ProsperScore, CreditScoreEstimated)

# Computing the correlation matrix
correlation_matrix <- cor(selected_vars, use = "complete.obs")

# Fitting lm using all three variables
vif_model <- lm(CreditScoreEstimated ~ ProsperRating..numeric. + ProsperScore, data = selected_vars)

# Calculate VIF to check for multicollinearity if <5 no multi 
vif_values <- vif(vif_model)

rm(selected_vars)
rm(vif_model)


independent_vars <- setdiff(names(regressionData), "dependentVar")

# Initializing a dataframe to store the results
results <- data.frame(Variable = character(), R.Squared = numeric(), stringsAsFactors = FALSE)

results_list <- list()
# Looping over the variable names, run regression, and store results
for (var in independent_vars) {
  # Running the regression with the current variable
  model <- lm(paste("dependentVar ~", var), data = regressionData)
  
  # Geting a  summary of the model
  tidy_model <- tidy(model)
  
  # Extracting R-squared value to see how much of the variance is explained
  r_squared <- summary(model)$r.squared
  
  summary_df <- data.frame(
    Variable = var,
    Coefficient = tidy_model$estimate[2],  # Coefficient of the independent variable
    Std.Error = tidy_model$std.error[2],   # Standard error of the coefficient
    t.value = tidy_model$statistic[2],     # t-value of the coefficient
    P.value = tidy_model$p.value[2],       # p-value of the coefficient
    R.Squared = r_squared
  )
  
  # Appending the summary_df to the results list
  results_list[[var]] <- summary_df
}



results <- do.call(rbind, results_list)

# Removing the model, tidy_model, results_list, summary_df, CreditScoreEstimated, var, r_squared, and independent_vars 
# from the environment to free up memory my computer is a little slow :)
rm(model)
rm(tidy_model)
rm(results_list)
rm(summary_df)
rm(CreditScoreEstimated)
rm(var)
rm(r_squared)
rm(independent_vars)
# "ProsperRating..numeric.", "ProsperScore", "CreditScoreEstimated"

# Creating  fixedVariables by selecting only "ProsperRating..numeric." and "CreditScoreEstimated" columns from regressionData
fixedVariables <- regressionData[, c("ProsperRating..numeric.", "CreditScoreEstimated")]
# Creating an indep variables by exluding fixed variables
independentVariables <- regressionData[, !names(regressionData) %in% c("ProsperRating..numeric.", "ProsperScore", "CreditScoreEstimated")]

# Getting the names of the independent variables
column_names <- names(independentVariables)
#Generating all possible combinations of 3 independent variables from column_names 
combinations <- combn(column_names, 3, simplify = FALSE)
## Remobing column_names as it is not needed any more
rm(column_names)
# Initializing an empty df to store final results
finalResults <- data.frame()
count <- 0;

# Initializing biases_results to store p-values for Omitted Variable Bias tests
biases_results <- data.frame(
  FixedVariables = character(),
  IndependentCombination = character(),
  P.value.OVS = numeric(),
  stringsAsFactors = FALSE
)
#Initializing residuals df with a "Model" column corresponding to each row in dependentVar
residuals <- data.frame(Model = seq_along(dependentVar), stringsAsFactors = FALSE)

#Initializing expected_residuals data frame to store the expected residuals for each regression
expected_residuals <- data.frame(
  Regression = integer(),
  stringsAsFactors = FALSE
)
for (combo in combinations) {
  count <- count + 1;
  # Creating the regression formula by pasting together the fixed and current combination of independent variables
  independent_vars_formula <- paste("dependentVar ~", paste(names(fixedVariables), collapse = " + "), "+", paste(combo, collapse = " + "))
  
  # Running the regression model
  
  model <- lm(independent_vars_formula, data = cbind(fixedVariables, independentVariables[combo]))
  
  # Again, a summary of the model
  tidy_model <- tidy(model)
  
  # Extracting  R-squared
  r_squared <- summary(model)$r.squared
  
  
  model_residuals <- residuals(model)
  
  # Creating a df with residuals and model count
  model_residuals_df <- data.frame(Model = seq_along(model_residuals), Residuals = model_residuals)
  colnames(model_residuals_df) <- c("Model", paste("Residuals", count, sep = "_"))
  
  # Merging with the residuals df
  residuals <- merge(residuals, model_residuals_df, by = "Model", all = TRUE)
  
  # Preparing to store E[u|X] for each variable in the regression
  expected_residuals_row <- data.frame(Regression = count, stringsAsFactors = FALSE)
  
  # Generating E[u|X] for each variable X in the regression
  variables <- names(cbind(fixedVariables, independentVariables[combo]))
  for (var in variables) {
    x <- cbind(fixedVariables, independentVariables[combo])[[var]]
    ex_given_u_model <- lm(model_residuals ~ x)
    ex_given_u <- fitted(ex_given_u_model)
    
    # Adding E[u|X] to the expected_residuals_row df
    expected_residuals_row[[var]] <- mean(ex_given_u)
  }
  
  # Handling variables not in the current regression
  all_vars <- unique(c(names(fixedVariables), unlist(combinations)))
  for (var in setdiff(all_vars, variables)) {
    expected_residuals_row[[var]] <- NA
  }
  
  # Appending the row to the expected_residuals df
  expected_residuals <- bind_rows(expected_residuals, expected_residuals_row)
  
  
  # Appending the results to finalResults df
  
  finalResults <- rbind(finalResults, data.frame(
    FixedVariables = toString(names(fixedVariables)),
    IndependentCombination = toString(combo),
    Variable = tidy_model$term,
    Coefficients = sapply(tidy_model$estimate, format, scientific = FALSE),
    P.values = sapply(tidy_model$p.value, format, scientific = FALSE),
    R.Squared = format(r_squared, scientific = FALSE)
  ))
  finalResults$Coefficients <- as.numeric(finalResults$Coefficients)
  finalResults$P.values <- as.numeric(finalResults$P.values)
  finalResults$R.Squared <- as.numeric(finalResults$R.Squared)
  
}
residual_columns <- residuals %>% dplyr::select(-Model)

# Calculating the variance for each column
residual_variances <- sapply(residual_columns, function(x) {
  x = as.numeric(x);
  var(x, na.rm = TRUE)
})

# Creating a df for the variances
variance_row <- data.frame(Variance = residual_variances, stringsAsFactors = FALSE)

# print_skewness(regressionData)


# Fixing Final Results

independent_var_names <- unique(unlist(combinations))
all_variable_names <- c("(Intercept)", names(fixedVariables), independent_var_names)
finalCoefficients <- data.frame(matrix(NA, nrow = length(combinations), ncol = length(all_variable_names)))
colnames(finalCoefficients) <- all_variable_names
row.names(finalCoefficients) <- seq_along(combinations)

# Populating finalCoefficients with coefficients from finalResults
for (i in seq_along(combinations)) {
  combo <- combinations[[i]]
  
  # Geting the corresponding rows from finalResults
  combo_results <- finalResults[finalResults$IndependentCombination == toString(combo), ]
  
  # Extracting the coefficients and populating the finalCoefficients dataframe
  if (any(combo_results$Variable == "(Intercept)" & combo_results$P.values[combo_results$Variable == "(Intercept)"] <= 0.05)) {
    finalCoefficients[i, "(Intercept)"] <- as.numeric(combo_results$Coefficients[combo_results$Variable == "(Intercept)"])
  }
  #Looping through each combination of fixed variables
  for (fixed_var in names(fixedVariables)) {
    if (fixed_var %in% combo_results$Variable && 
        any(combo_results$Variable == fixed_var & combo_results$P.values[combo_results$Variable == fixed_var] <= 0.05)) {# checking significance
      finalCoefficients[i, fixed_var] <- as.numeric(combo_results$Coefficients[combo_results$Variable == fixed_var])
    }
  }
  #Looping through each combination of indep variables
  for (indep_var in combo) {
    if (indep_var %in% combo_results$Variable && 
        any(combo_results$Variable == indep_var & combo_results$P.values[combo_results$Variable == indep_var] <= 0.05)) { # checking significance
      finalCoefficients[i, indep_var] <- as.numeric(combo_results$Coefficients[combo_results$Variable == indep_var])
    }
  }
}
