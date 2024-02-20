
################################################################################
############################ Hyperparameters ###################################
################################################################################

# root <- "D:/Mingxia/2023-07-19/qupath/"
root <- "/media/sam/PP_20TB_2/Mingxia/2023-07-19/qupath/"

setwd(root)

# Get a vector of all .txt files in the directory
files <- list.files(root, pattern = "\\.txt$", full.names = FALSE)

# Vector of experiment specific RNAscope targets in order of channel
targets <- c("TMEM119", "CBD1", "CBD2")
# Vector of thresholds
threshs <- c(0, 0, 0)
filter <- FALSE

################################################################################
######################## Functions and Libraries ###############################
################################################################################
library(parallel)
library(dplyr)

Qupath_converter <- function(path, targets, save=T) {
  data <- readr:::read_delim(path, delim = "\t") 
  chem <- stringr::str_extract(path, "^[^_]+")
  sample <- stringr::str_extract(path, "(?<=_).*?(?=\\.)")
  
  data <- data %>%
    mutate(ID = NA,
           Chemistry = chem,
           Sample = sample)
  
  # Iterate over each row in the data
  for (i in 2:nrow(data)) {
    # Check if the current row's "Class" is not NA
    if (!is.na(data$Class[i])) {
      # Check if the prior row's "Class" is NA
      if (is.na(data$Class[i - 1])) {
        # Assign the row number of the row with NA to ParentID
        data$ID[i] <- i - 1
        data$ID[i-1] <- i - 1
      } else {
        # Check if the Class of the prior row is also not NA
        # Assign the same value in ParentID as the prior row
        data$ID[i] <- data$ID[i - 1]
      }
    } 
  }
  
  # Find the column name that matches the pattern "Centroid X ..."
  centroid_column_X <- grep("^Centroid X .*", colnames(data), value = TRUE)
  centroid_column_Y <- grep("^Centroid Y .*", colnames(data), value = TRUE)
  
  # Extract the units from the last word of the column name
  units <- sub(".*\\s(\\S+)$", "\\1", centroid_column_X)
  
  # Rename the column to "X" and add a new "Units" column
  data <- data %>%
    rename(X = all_of(centroid_column_X),
           Y = all_of(centroid_column_Y),
           Cell_Area = all_of("Cell: Area")) %>%
    mutate(Units = units)
  
  # Function to extract the number from the column name
  get_column_number <- function(col_name) {
    as.numeric(gsub(".*:(\\d+):.*", "\\1", col_name))
  }
  
  # Create an empty vector to store the new column names
  new_column_names <- c("Chemistry", "Sample", "Parent", "ID", "Cell_Area", "X", "Y", "Units")
  
  # Loop through the old column names and rename them
  for (i in seq_along(targets)) {
    old_col_name_spot <- paste("Subcellular: Channel ", i + 1, ": Num spots estimated", sep = "")
    old_col_name_intensity <- paste("Subcellular cluster: Channel ", i + 1, ": Mean channel intensity", sep = "")
    old_col_name_cell <- paste("Cell: Channel ", i + 1, " mean", sep = "")
    data <- data %>%
      rename(
        !!paste0("n_", targets[i]) := !!old_col_name_spot,
        !!paste0("spot_intensity_", targets[i]) := !!old_col_name_intensity,
        !!paste0("cell_intensity_", targets[i]) := !!old_col_name_cell
      )
    # Add the newly created column names to the new_column_names vector
    new_column_names <- c(new_column_names, paste0("n_", targets[i]), 
                          paste0("spot_intensity_", targets[i]), 
                          paste0("cell_intensity_", targets[i]))
  }
  
  # Clean up df
  data <- data %>%
    filter(!is.na(ID)) %>%
    select(all_of(new_column_names)) %>%
    mutate(X = ifelse(is.na(Cell_Area), NA, X),
           Y = ifelse(is.na(Cell_Area), NA, Y)) 
  
  # Flatten the data
  flattened_data <- data %>%
    group_by(ID) %>%
    summarise_all(~ if(all(is.na(.))) NA else na.omit(.)[1]) 
  
  if (save){
    # Save the flattened dataframe
    write.csv(flattened_data, file = paste0(chem, "_", sample, "_data.csv"))
  }
  
  return(flattened_data)
}
################################################################################

# Create an empty data frame to store the final output
full_df <- data.frame()

# loop through all files
# for (f in files) {
#   print(paste("working on", f))
# 
#   path <- f
#   chem <- stringr::str_extract(path, "^[^_]+")
#   sample <- stringr::str_extract(path, "(?<=_).*?(?=\\.)")
#   
#   # Convert Qupath output to useable dataframe
#   flattened_data <- Qupath_converter(f, targets, save=T)
# 
#   
#   if (filter){
#     # Create a filter condition using the thresholds
#     filter_condition <- data.frame(targets = paste0("cell_intensity_", targets), threshs) 
#     
#     # Filter flattened_data based on the filter_condition thresholds
#     filtered_data <- flattened_data %>%
#       rowwise() %>%
#       filter(all(c_across(all_of(filter_condition$targets)) > filter_condition$threshs))
#     
#     # Remove rowwise attribute to get a standard data frame
#     filtered_data <- as.data.frame(filtered_data)
#     # Save this csv
#     write.csv(filtered_data, file = paste0(chem, "_", sample, "_filtered_data.csv"))
#   }
#   
#   # Append the current dataframe to the final output dataframe (full_df)
#   full_df <- bind_rows(full_df, flattened_data)
# }
# Create an empty list to store the results
result_list <- list()

# Define the number of cores to use (you can adjust this as needed)
num_cores <- detectCores()

# Create a cluster for parallel processing
cl <- makeCluster(num_cores)

# Parallel loop using mclapply
result_list <- mclapply(files, function(f) {
  flattened_data <- Qupath_converter(f, targets, save = TRUE)
  return(flattened_data)
}, mc.cores = num_cores)

# Close the cluster
stopCluster(cl)

# Combine the results into a single dataframe
full_df <- do.call(rbind, result_list)

write.csv(full_df, file = paste0(stringr::str_extract(files[1], "^[^_]+"), "_all_data.csv"))
