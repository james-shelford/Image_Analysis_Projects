# Script written by James Shelford
# Script to process multiple .csv files containing output from ImageJ '3D OC'
# The output is a dataframe saved as .rds for combining with other experiments to further process

# Working directory should be '3D_object_count'
# Lookup.csv should be in the 'Data' subdirectory
# Setup preferred directory structure in wd
ifelse(!dir.exists("Data"), dir.create("Data"), "Folder exists already")
ifelse(!dir.exists("Output"), dir.create("Output"), "Folder exists already")
ifelse(!dir.exists("Output/Dataframe"), dir.create("Output/Dataframe"), "Folder exists already")
ifelse(!dir.exists("Output/Plots"), dir.create("Output/Plots"), "Folder exists already")
ifelse(!dir.exists("Script"), dir.create("Script"), "Folder exists already")

# Select directory containing the .csv files
datadir <- rstudioapi::selectDirectory()

# Extract the experiment number for use later (useful when combining experiments)
Experiment_number<- basename(datadir)

# search all .csv files in current working directory
my_files <- list.files(datadir,pattern='*.csv',full.names = TRUE)
my_files_names <- list.files(datadir,pattern='*.csv')

# Create matrix to store the data and convert to dataframe
headings <- c('centrosomes_per_cell', 'ave_volume', 'sum_volume', 'mean_intensity', 'sum_intensity', 'mean_surface_area', 'sum_surface_area', 'file_name')
my_matrix <- matrix(0, length(my_files), length(headings))
colnames(my_matrix) <- headings
df1 <- as.data.frame(my_matrix)

# function definition
build_df1 <- function(df1, my_filename, row_number){
  
# import data
my_raw_data <- read.csv(file=my_filename, header=TRUE, stringsAsFactors=FALSE)
  
# Get the values and add to the correct row&col in dataframe
  
df1$centrosomes_per_cell[i] <- length(my_raw_data[,'Volume..micron.3.'])
df1$ave_volume[i] <- mean(my_raw_data[,'Volume..micron.3.'])
df1$sum_volume[i] <- sum(my_raw_data[,'Volume..micron.3.'])
df1$mean_intensity[i] <- mean(my_raw_data[,'Mean'])
df1$sum_intensity[i] <- sum(my_raw_data[,'Mean'])
df1$mean_surface_area[i] <- mean(my_raw_data[,'Surface..micron.2.'])
df1$sum_surface_area[i] <- sum(my_raw_data[, 'Surface..micron.2.'])
  
# Add the filename
 df1$file_name[i] <- my_files_names[i]
  
  return(df1)
}

# call the function for each file in the list
for(i in 1:length(my_files)){
  my_filename <- my_files[i]
  df1 <- build_df1(df1,my_filename,i)
}

# function to find partial strings in a column and classify them
add_categories = function(x, patterns, replacements = patterns, fill = NA, ...) {
  stopifnot(length(patterns) == length(replacements))
  ans = rep_len(as.character(fill), length(x))    
  empty = seq_along(x)
  for(i in seq_along(patterns)) {
    greps = grepl(patterns[[i]], x[empty], ...)
    ans[empty[greps]] = replacements[[i]]  
    empty = empty[!greps]
  }
  return(ans)
}

# Load the lookup
look_up_table <- read.table('Data/lookup.csv', header = TRUE, stringsAsFactors = F, sep = ",")

# add a new column to dataframe where categories are defined by searching original name for partial strings
df1$Category <- add_categories(df1$file_name,
                                  look_up_table$Search_name,
                                  look_up_table$Search_category,
                                  "NA", ignore.case = TRUE)

# Add the experiment number to the dataframe
df1$Experiment <- Experiment_number

# save the dateframe so it can be combined with other experiments in a new script
file_name<- paste0("Output/Dataframe/", Experiment_number, "_dataframe.rds")
saveRDS(df1, file = file_name)
