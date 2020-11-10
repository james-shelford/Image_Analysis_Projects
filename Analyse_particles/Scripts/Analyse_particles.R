# Script written by James Shelford
# Script to process multiple .csv and .txt files containing output from ImageJ 'Analyse particles'
# The output is a dataframe saved as .rds for combining with other experiments to further process

# Working directory should be 'Analyse_particles'
# Setup preferred directory structure in wd
ifelse(!dir.exists("Data"), dir.create("Data"), "Folder exists already")
ifelse(!dir.exists("Output"), dir.create("Output"), "Folder exists already")
ifelse(!dir.exists("Output/Dataframe"), dir.create("Output/Dataframe"), "Folder exists already")
ifelse(!dir.exists("Output/Plots"), dir.create("Output/Plots"), "Folder exists already")
ifelse(!dir.exists("Scripts"), dir.create("Scripts"), "Folder exists already")

# lookup.csv and log.txt should be in 'Data' subdirectory

# Load required packages
require(ggplot2)
require(ggbeeswarm)
library(dplyr)
library(multcomp)

# Select directory containing .csv and .txt files
datadir <- rstudioapi::selectDirectory()

# Record the experiment number for use later (useful when combining experiments)
Experiment_number<- 'JS103'

# search all .csv files in chosen directory
my_files_csv <- list.files(datadir,pattern='*.csv',full.names = TRUE)
my_files_names_csv <- list.files(datadir,pattern='*.csv')

# Make a matrix to store the data for each file in
my_matrix <- matrix(0,length(my_files_csv),7)

# function definition
build_matrix <- function(my_matrix,my_filename,row_number){
  
  # import data
  my_raw_data <- read.csv(file=my_filename, header=TRUE, stringsAsFactors=FALSE)
  
  # transpose dataframe and select values and add them to the empty matrix
  my_data <- t(my_raw_data)
  my_matrix[row_number, 1:7] <- my_data[1:7, 1]
  return(my_matrix)
}

# call the function for each file in the list
for(i in 1:length(my_files_csv)){
  my_filename <- my_files_csv[i]
  my_matrix <- build_matrix(my_matrix,my_filename,i)
}

#Rename columns
df1 <- as.data.frame(my_matrix)
colnames(df1) <- c('Slice',	'Count',	'Total Area',	'Average Size',	'%Area',	'Mean',	'IntDen')

#Search the .txt files in chosen directory
my_files_txt <- list.files(datadir,pattern='*.txt',full.names = TRUE, recursive = TRUE)
my_files_names_txt <- list.files(datadir,pattern='*.txt', recursive = TRUE)

# Create a vector to store the thresholds in
thresholds <- vector(mode = "numeric", length = length(my_files_txt))

# function to get line of interest and extract the number
get_threshold <- function(my_filename){
  # 
  myFile <- readLines(my_filename)
  # get the line with the value we want (as string)
  myLine <- grep(pattern = "your thresholds", x = myFile, value = TRUE)
  
  # get rid of text we don't want
  myValue <- gsub("your thresholds are; ","", myLine)
  return(myValue)
  
}

# call the function for each file in the list and fill in vector with extracted number
for(i in 1:length(my_files_txt)){
  my_filename <- my_files_txt[i]
  thresholds[i] <- get_threshold(my_filename)
  
}

# Add thresholds to the dataframe
df1$Threshold <- thresholds

# Add experiment number to the dataframe
df1$Experiment <- Experiment_number

# Make blind list with *.csv removed
blind_list <- gsub(".csv","", my_files_names_csv)
df1$blind_list <- blind_list

# Load the log.txt file
blind_log <- read.table('Data/log.txt', header = TRUE)

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

# Load the lookup.csv
look_up_table <- read.table('Data/lookup.csv', header = TRUE, stringsAsFactors = F, sep = ",")

# add a new column to dataframe where categories are defined by searching original name for partial strings
blind_log$Category <- add_categories(blind_log$Original_Name,
                                              look_up_table$Search_name,
                                              look_up_table$Search_category,
                                              "NA", ignore.case = TRUE)

# This line looks up the correct Category from the blind_log
df1$Category <- with(blind_log,
                     Category[match(df1$blind_list,
                                    Blinded_Name)])

# Plotting the Categories in a specific order
df1$Category <- factor(df1$Category, levels = look_up_table$Search_category )

# How many cells per category?
summary(df1$Category)

# Convert 'count' to numeric values so we can plot them
df1$Count <- as.numeric(as.character(df1$Count))

# Generate the plot 
puncta_plot <- ggplot(data = df1, aes(x=Category, y=Count, color=Category)) +
  geom_quasirandom(alpha=0.5, stroke=0) + 
  stat_summary(fun.data = mean_se, geom = 'point', size=2, aes(group=Category))+
  stat_summary(fun.data = mean_sdl, fun.args = list(mult=1), geom = 'errorbar', size=0.8, aes(group=Category), width=0) +
  theme(axis.text.x = element_text(face= "plain", color= 'black', size=9, angle = 0, hjust = 0.5)) +
  theme(axis.title.y = element_text(size = 9,face='plain',color='black'), axis.text.y = element_text(size=8, face='plain',color='black')) +
  labs(y = "Transferrin uptake (puncta)", x = NULL) + 
  theme(legend.position = 'top') +
  theme(legend.title = element_blank()) +
  ylim(0,4000)
  
puncta_plot

# Statistics 

# ANOVA
puncta_ANOVA <- aov(Count ~ Category, df1)
summary(puncta_ANOVA)
plot(puncta_ANOVA,1)
plot(puncta_ANOVA,2)

#Post-hoc test
summary(glht(puncta_ANOVA, linfct = mcp(Category='Tukey')))
puncta_Tukey <- TukeyHSD(puncta_ANOVA)
puncta_Tukey

# save the plot
# when importing the plot into illustrator save as pdf 

ggsave("./Output/Plots/puncta_Plot.png", plot = puncta_plot, dpi = 300)
ggsave("./Output/Plots/puncta_Plot.pdf", plot = puncta_plot, width = 100, height = 100, units = 'mm', useDingbats = FALSE)

# save the dateframe so it can be combined with other experiments in a new script
file_name<- paste0("Output/Dataframe/", Experiment_number, "_dataframe.rds")
saveRDS(df1, file = file_name)
