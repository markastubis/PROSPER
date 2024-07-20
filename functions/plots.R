plot_coefficient_histograms <- function(data) {
  for (col_name in names(data)) {
    # Filter out NA, NaN, and infinite values for the current column
    col_data <- data[[col_name]]
    col_data <- col_data[is.finite(col_data)]
    
    if (length(col_data) == 0) {
      warning(paste("Column", col_name, "contains no finite values"))
      next
    }
    
    # Define a custom bin width based on the range of the data
    bin_width <- (max(col_data) - min(col_data)) / 30
    
    # Define the breaks for the x-axis
    x_breaks <- pretty(col_data, n = 5)
    
    # Create a histogram using ggplot2
    p <- ggplot(data.frame(col_data), aes(x = col_data)) +
      geom_histogram(binwidth = bin_width, fill = "blue", color = "black", alpha = 0.7) +
      ggtitle(paste("Histogram of", col_name)) +
      xlab(col_name) +
      ylab("Frequency") +
      theme_minimal() +
      scale_x_continuous(limits = c(min(col_data), max(col_data)), breaks = x_breaks) +
      scale_y_continuous(expand = c(0, 0)) +
      theme(
        plot.title = element_text(hjust = 0.5),
        axis.title.x = element_text(size = 12),
        axis.title.y = element_text(size = 12)
      )
    
    # Print the plot
    print(p)
  }
}