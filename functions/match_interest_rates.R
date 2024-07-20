match_interest_rates <- function(filteredData, fedInterestRates) {
  
  # Ensure date columns are in Date format
  filteredData <- filteredData %>%
    mutate(ListingCreationDate = as.Date(ListingCreationDate, format = "%Y-%m-%d %H:%M:%S"))
  
  fedInterestRates <- fedInterestRates %>%
    mutate(Series.Description = as.Date(Series.Description, format = "%Y-%m-%d"))
  
  # Check for any conversion issues
  if (any(is.na(filteredData$ListingCreationDate))) {
    stop("There are NA values in the ListingCreationDate column after conversion. Please check the date format.")
  }
  if (any(is.na(fedInterestRates$Series.Description))) {
    stop("There are NA values in the Series.Description column after conversion. Please check the date format.")
  }
  
  # Create a lookup table for terms to interest rate columns
  term_lookup <- data.frame(
    Term = c(12, 36, 60),
    InterestRateColumn = c("Market.yield.on.U.S..Treasury.securities.at.1.year...constant.maturity..quoted.on.investment.basis",
                           "Market.yield.on.U.S..Treasury.securities.at.3.year...constant.maturity..quoted.on.investment.basis",
                           "Market.yield.on.U.S..Treasury.securities.at.5.year...constant.maturity..quoted.on.investment.basis")
  )
  
  # Ensure interest rate columns are numeric, converting "ND" to NA
  fedInterestRates <- fedInterestRates %>%
    mutate(across(all_of(term_lookup$InterestRateColumn), ~ as.numeric(gsub("ND", NA, .))))
  
  # Initialize result dataframe
  result_df <- data.frame(
    ListingCreationDate = as.Date(character()),
    MatchedInterestRate = numeric(),
    ListingKey = character()
  )
  
  # Function to find the closest previous numeric value
  find_closest_previous_rate <- function(date, interest_rate_column) {
    current_date <- date
    while(TRUE) {
      closest_date <- max(fedInterestRates$Series.Description[fedInterestRates$Series.Description <= current_date], na.rm = TRUE)
      matched_rate <- fedInterestRates %>%
        filter(Series.Description == closest_date) %>%
        pull(all_of(interest_rate_column))
      if(!is.na(matched_rate)) {
        return(matched_rate / 100)
      }
      current_date <- current_date - days(1)
    }
  }
  
  # Iterate over each row in filteredData
  for (i in 1:nrow(filteredData)) {
    listing_date <- filteredData$ListingCreationDate[i]
    term <- filteredData$Term[i]
    listing_key <- filteredData$ListingKey[i]
    
    # Get the corresponding interest rate column name
    interest_rate_column <- term_lookup$InterestRateColumn[term_lookup$Term == term]
    
    # Get the matched interest rate and divide by 100
    matched_rate <- find_closest_previous_rate(listing_date, interest_rate_column)
    
    # Add the result to the result dataframe
    result_df <- rbind(result_df, data.frame(
      ListingCreationDate = listing_date,
      MatchedInterestRate = matched_rate,
      ListingKey = listing_key
    ))
  }
  
  return(result_df)
}