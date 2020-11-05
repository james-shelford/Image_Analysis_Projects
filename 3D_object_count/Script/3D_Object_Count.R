# Script written by James Shelford
# Script to process multiple .csv files containing output from ImageJ '3D OC'
# The output is a dataframe saved as .rds for combining with other experiments to further process

# Working directory should be '3D_object_count'
# Setup preferred directory structure in wd
ifelse(!dir.exists("Data"), dir.create("Data"), "Folder exists already")
ifelse(!dir.exists("Output"), dir.create("Output"), "Folder exists already")
ifelse(!dir.exists("Output/Dataframe"), dir.create("Output/Dataframe"), "Folder exists already")
ifelse(!dir.exists("Output/Plots"), dir.create("Output/Plots"), "Folder exists already")
ifelse(!dir.exists("Script"), dir.create("Script"), "Folder exists already")

# Lookup.csv should be in the 'Data' subdirectory

# Load required packages
require(ggplot2)
require(ggbeeswarm)
library(dplyr)
library(cowplot)
library(scales)

# Record the experiment number for use later (useful when combining experiments)
Experiment_number<- 'JS103'

# Select directory containing the .csv files
datadir <- rstudioapi::selectDirectory()

# search all .csv files in current working directory
my_files <- list.files(datadir,pattern='*.csv',full.names = TRUE)
my_files_names <- list.files(datadir,pattern='*.csv')

# Create matrix to store the data and convert to dataframe
headings <- c('centrosomes_per_cell', 'ave_volume', 'sum_volume', 'mean_intensity', 'sum_intensity', 'mean_surface_area', 'sum_surface_area', 'file_name')
my_matrix <- matrix(0, length(my_files), length(headings))
colnames(my_matrix) <- headings
df1 <- as_tibble(my_matrix)

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

# Select directory containing the lookup and load it
look_up_table <- read.table('Data/lookup.csv', header = TRUE, stringsAsFactors = F, sep = ",")

# add a new column to dataframe where categories are defined by searching original name for partial strings
df1$Category <- add_categories(df1$file_name,
                                  look_up_table$Search_name,
                                  look_up_table$Search_category,
                                  "NA", ignore.case = TRUE)

# Add the experiment number to the dataframe
df1$Experiment <- Experiment_number

# Plotting the Categories in a specific order
df1$Category <- as.factor(df1$Category)
df1$Category <- factor(df1$Category, levels = look_up_table$Search_category)

#How many cells per condition
summary(df1$Category)

# Generate the plots

# function to generate the plots
makeTheScatterPlot <- function(parameter, parameter_units) {
  ggplot(data = df1, aes(x = Category,y = parameter, colour = Category)) +
    geom_quasirandom(alpha=0.5, stroke=0, dodge.width = 1) + 
    stat_summary(fun.data = mean_se, geom = 'point', size=2, aes(group=Category))+
    stat_summary(fun.data = mean_sdl, fun.args = list(mult=1), geom = 'errorbar', size=0.8, aes(group=Category), width=0) +
    theme(axis.text.x = element_text(face= "plain", color= 'black', size=8, angle = 0, hjust = 0.5), axis.text.y = element_text(face = 'plain', color= 'black', size=8)) +
    theme(axis.title.y = element_text(size = 10,face='plain',color='black')) +
    labs(y = parameter_units, x = NULL) + 
    theme(legend.title = element_blank()) + 
    theme(legend.position = 'none')
}

# Individual plots
centrosome_num <- makeTheScatterPlot(centrosomes_per_cell, 'centrosomes per cell')
average_volume <- makeTheScatterPlot(ave_volume, 'micron^3')
sum_volume <- makeTheScatterPlot(sum_volume, 'micron^3')
mean_intensity <- makeTheScatterPlot(mean_intensity, '')
sum_intensity <- makeTheScatterPlot(sum_intensity, '')
mean_surface_area <- makeTheScatterPlot(mean_surface_area, 'micron^2')
sum_surface_area <- makeTheScatterPlot(sum_surface_area, 'micron^2')

# combine the plots into one figure
combined_plots <- plot_grid(centrosome_num, average_volume, sum_volume, mean_intensity, sum_intensity, mean_surface_area, sum_surface_area, rel_widths = c(1, 1), rel_heights = c(1,1)) + theme(aspect.ratio=1)
combined_plots

########## Bar plot of centrosome number ###############

df1$centrosome_cat <- 2
df1$centrosome_cat[df1$centrosomes_per_cell>2] <- '>2'
summary(df1$Category)
df1$total_cell_num <- 0
df1$total_cell_num[df1$Category=='mCherry C1'] <- 21
df1$total_cell_num[df1$Category=='mCherry E4'] <- 22
df1$total_cell_num[df1$Category=='mCherry E7'] <- 19
df1$total_cell_num[df1$Category=='mCherry E8'] <- 29

# Plotting the centrosome number as a percent stacked barchart

centrosome_num_plot <- ggplot(data = df1, aes(fill=centrosome_cat, y=total_cell_num, x=Category)) + geom_bar(position = "fill",stat = "identity",width = 0.96) +
  theme(axis.text.x = element_text(face= "plain", color= 'black', size=8), axis.text.y = element_text(face = 'plain', color= 'black', size=8)) +
  theme(axis.title.y = element_text(size = 8,face='plain',color='black')) +
  theme_cowplot(12) + 
  labs(y = "Frequency", x = NULL) + 
  scale_y_continuous(labels=percent, expand = c(0,0)) +
  theme(legend.title = element_blank()) + 
  theme(legend.position = 'right') +
  scale_fill_discrete(labels = c(">2", "Bipolar")) 
centrosome_num_plot

centrosome_num_plot_flip <- centrosome_num_plot + 
  coord_flip() +
  scale_x_discrete(limits = rev(levels(df1$Category)), expand = c(0,0))
centrosome_num_plot_flip

# save the plots
# when importing the plot into illustrator save as pdf 

ggsave("./Output/Plots/combined_plots.png", plot = combined_plots, dpi = 300)
ggsave("./Output/Plots/combined_plots.pdf", plot = combined_plots, width = 100, height = 100, units = 'mm', useDingbats = FALSE)

# save the dateframe so it can be combined with other experiments in a new script
file_name<- paste0("Output/Dataframe/", Experiment_number, "_dataframe.rds")
saveRDS(df1, file = file_name)
