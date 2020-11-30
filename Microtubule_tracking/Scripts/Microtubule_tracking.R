# Script written by James Shelford 
# Script to process multiple .txt files containing output from utrack
# The output is a dataframe saved as .rds for combining with other experiments to further process

# Working directory should be 'Microtubule_tracking'
# Lookup.csv should be in the 'Data' subdirectory
# Setup preferred directory structure in wd
ifelse(!dir.exists("Data"), dir.create("Data"), "Folder exists already")
ifelse(!dir.exists("Output"), dir.create("Output"), "Folder exists already")
ifelse(!dir.exists("Output/Dataframe"), dir.create("Output/Dataframe"), "Folder exists already")
ifelse(!dir.exists("Output/Plots"), dir.create("Output/Plots"), "Folder exists already")
ifelse(!dir.exists("Scripts"), dir.create("Scripts"), "Folder exists already")

# Select directory containing the .txt files
datadir <- rstudioapi::selectDirectory()

# Extract the experiment number for use later (useful when combining experiments)
Experiment_number<- basename(datadir)

# Search all .txt files in the chosen directory
my_files <- list.files(datadir, pattern='*stats.txt', full.names = TRUE, recursive = TRUE)
my_files_names <- list.files(datadir, pattern='*stats.txt', recursive = TRUE)

# Cleaning the file names for use later
my_files_names <- gsub("/TrackingPackage/mtTracks/","_", my_files_names)

# Make a dataframe to store the extracted data
headings <- c('growth_speed', 'number_of_growths', 'growth_lifetime', 'growth_length', 'Name_of_file')
df1 <- matrix(0, length(my_files), length(headings))
df1 <- as.data.frame(df1)
colnames(df1) <- headings

# Function to extract the data from each txt file and add it to the appropriate place in the df

extract_data <- function(dataframe, file_name, row_num){
  my_file <- readLines(file_name)
  speed_line <- grep(pattern = "growth_speed_mean_", x = my_file, value = TRUE, fixed = TRUE)
  growth_num_line <- grep(pattern = "nGrowths", x = my_file, value = TRUE, fixed = TRUE)
  growth_lifetime_line <- grep(pattern = "growth_lifetime_mean_", x = my_file, value = TRUE, fixed = TRUE)
  growth_length_line <- grep(pattern = "growth_length_mean", x = my_file, value = TRUE, fixed = TRUE)
 dataframe$growth_speed[row_num] <- gsub("growth_speed_mean_IncludeAllPause","", speed_line)
 dataframe$number_of_growths[row_num] <- gsub("nGrowths","", growth_num_line)
 dataframe$growth_lifetime[row_num] <- gsub("growth_lifetime_mean_IncludeAllPause","", growth_lifetime_line)
 dataframe$growth_length[row_num] <- gsub("growth_length_mean","", growth_length_line)
 dataframe$Name_of_file [row_num] <- my_files_names[row_num]
 
 return(dataframe)
}

# Call the function for each file

for (i in 1:length(my_files)){
  file_name <- my_files[i]
  df1 <- extract_data(df1, file_name, i)
}

# Convert character to numeric
df1$growth_length <- as.numeric(df1$growth_length)
df1$growth_speed <- as.numeric(df1$growth_speed)
df1$number_of_growths <- as.numeric(df1$number_of_growths)
df1$growth_lifetime <- as.numeric(df1$growth_lifetime)

# Add experiment number to the dataframe
df1$Experiment <- Experiment_number

# Load lookup.csv
look_up_table <- read.table('Data/lookup.csv', header = TRUE, stringsAsFactors = F, sep = ",")

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

# add a new column to dataframe where categories are defined by searching original name for partial strings
df1$Category <- add_categories(df1$Name_of_file,
                                     look_up_table$Search_name,
                                     look_up_table$Search_category,
                                     "NA", ignore.case = TRUE)

# save the dateframe so it can be combined with other experiments in a new script
file_name<- paste0("Output/Dataframe/", Experiment_number, "_dataframe.rds")
saveRDS(df1, file = file_name)
