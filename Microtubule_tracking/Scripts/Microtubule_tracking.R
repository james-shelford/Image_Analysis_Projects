# Script written by James Shelford 
# Script to process multiple .txt files containing output from utrack
# The output is a dataframe saved as .rds for combining with other experiments to further process

# Working directory should be 'Microtubule_tracking'
# Setup preferred directory structure in wd
ifelse(!dir.exists("Data"), dir.create("Data"), "Folder exists already")
ifelse(!dir.exists("Output"), dir.create("Output"), "Folder exists already")
ifelse(!dir.exists("Output/Dataframe"), dir.create("Output/Dataframe"), "Folder exists already")
ifelse(!dir.exists("Output/Plots"), dir.create("Output/Plots"), "Folder exists already")
ifelse(!dir.exists("Scripts"), dir.create("Scripts"), "Folder exists already")

# Load required packages
require(ggplot2)
require(ggbeeswarm)
library(dplyr)
library(multcomp)

# Select directory containing the .txt files
datadir <- rstudioapi::selectDirectory()

# Record the experiment number for use later (useful when combining experiments)
Experiment_number<- 'JS068'

# Search all .txt files in the chosen directory
my_files <- list.files(datadir, pattern='*stats.txt', full.names = TRUE, recursive = TRUE)
my_files_names <- list.files(datadir, pattern='*stats.txt', recursive = TRUE)

# Cleaning the file names for use later
my_files_names <- gsub("/TrackingPackage/mtTracks/","_", my_files_names)

# Creating vectors to store data in
my_num_growths <- vector(mode = "numeric", length = length(my_files))
my_growth_speed <- vector(mode = "numeric", length = length(my_files))
my_growth_lifetime <- vector(mode = "numeric", length = length(my_files))
my_growth_length <- vector(mode = "numeric", length = length(my_files))

# function to get line of interest and extract the data
get_growth_speed <- function(my_filename){
  # import data
  myFile <- readLines(my_filename)
  # get the line with the value we want (as string)
  myLine <- grep(pattern = "growth_speed_mean", x = myFile, value = TRUE)
  
  # get rid of text we don't want and convert to numeric
  myValue <- as.numeric(gsub("growth_speed_mean","", myLine))
  return(myValue)
}

get_num_growths <- function(my_filename){
  
  myFile <- readLines(my_filename)
  myLine <- grep(pattern = "nGrowths", x = myFile, value = TRUE)
  myValue <- as.numeric(gsub("nGrowths","", myLine))
  return(myValue)
}

get_growth_lifetime <- function(my_filename){
 
   myFile <- readLines(my_filename)
  myLine <- grep(pattern = "growth_lifetime_mean", x = myFile, value = TRUE)
  myValue <- as.numeric(gsub("growth_lifetime_mean","", myLine))
  return(myValue)
}

get_growth_length <- function(my_filename){

  myFile <- readLines(my_filename)
  myLine <- grep(pattern = "growth_length_mean", x = myFile, value = TRUE)
  myValue <- as.numeric(gsub("growth_length_mean","", myLine))
  return(myValue)
}

# call the function for each file in the list and fill in vector with extracted number
for(i in 1:length(my_files)){
  
  my_filename <- my_files[i]
  my_num_growths[i] <- get_num_growths(my_filename)
  my_growth_speed[i] <- get_growth_speed(my_filename)
  my_growth_lifetime[i] <- get_growth_lifetime(my_filename)
  my_growth_length[i] <- get_growth_length(my_filename)
}

# create a dataframe combining the filename and data 
df1<- cbind.data.frame(my_files_names, my_num_growths, my_growth_speed, my_growth_lifetime, my_growth_length)

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
df1$Category <- add_categories(df1$my_files_names,
                                     look_up_table$Search_name,
                                     look_up_table$Search_category,
                                     "NA", ignore.case = TRUE)

# save the dateframe so it can be combined with other experiments in a new script
file_name<- paste0("Output/Dataframe/", Experiment_number, "_dataframe.rds")
saveRDS(df1, file = file_name)
