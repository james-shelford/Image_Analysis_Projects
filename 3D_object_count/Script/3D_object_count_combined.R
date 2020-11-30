# 3D object count data visualisation
# Load in dataframes produced from processing individual experiments and plot data
# Written by James Shelford

# Working directory should be '3D_object_count '

# Load the required packages
require(ggplot2)
require(ggbeeswarm)
library(dplyr)
library(multcomp)
library(cowplot)
library(ggpubr)
library(scales)

# Load the dataframes (.rds) for each experiment. These should be in Output/Dataframe
datadir <- 'Output/Dataframe'

my_dataframes <- list.files(datadir, pattern = '*.rds', full.names = TRUE)
combined_df <- bind_rows(lapply(my_dataframes, readRDS))
combined_df$Category <- as.factor(combined_df$Category)

# Add a category to classify number of objects detected
combined_df$centrosome_cat <- 2
combined_df$centrosome_cat[combined_df$centrosomes_per_cell>2] <- '>2'

# How many cells in each condition? Add this to df.
num_conditions <- summary(combined_df$Category)
combined_df$total_cell_num[combined_df$Category=='Condition 1'] <- num_conditions['Condition 1']
combined_df$total_cell_num[combined_df$Category=='Condition 2'] <- num_conditions['Condition 2']
combined_df$total_cell_num[combined_df$Category=='Condition 3'] <- num_conditions['Condition 3']
combined_df$total_cell_num[combined_df$Category=='Condition 4'] <- num_conditions['Condition 4']
combined_df$total_cell_num[combined_df$Category=='Condition 5'] <- num_conditions['Condition 5']
combined_df$total_cell_num <- as.numeric(combined_df$total_cell_num)

# To plot in the correct order, load in the lookup table
look_up_table <- read.table("Data/lookup.csv", header = TRUE, stringsAsFactors = F, sep = ",")
combined_df$Category <- factor(combined_df$Category, levels = look_up_table$Search_category )

# Find the max value for each parameter. This will be used to set axis limits.
volume_highVal <- ceiling(max(combined_df$ave_volume, na.rm = TRUE))
surfarea_highVal <- ceiling(max(combined_df$mean_surface_area, na.rm = TRUE))

# function to generate the plots
# theme_cowplot() removes the grid. Comment this out for classic ggplot appearance.
makeTheScatterPlot <- function(parameter, parameter_units, high_value) {
  ggplot(data = combined_df, aes(x = Category, y = parameter, fill = Category)) +
    theme_cowplot() +
    geom_violin() +
    geom_boxplot(width=0.1, fill = "white", outlier.shape = NA) +
    theme(axis.text.x = element_text(angle=90, hjust=1)) +
    labs(y = parameter_units, x = NULL) + 
    theme(axis.text.x = element_text(face= "plain", color= 'black', size=9, angle = 90, hjust = 0.5, vjust = 0.5), axis.text.y = element_text(face = 'plain', color= 'black', size=9)) + 
    theme(axis.title.y = element_text(size = 10, face='plain',color='black')) +
    theme(legend.title = element_blank(), legend.position = 'none') + 
    ylim(0, high_value)
}

# Make the individual plots
p1 <- makeTheScatterPlot(combined_df$ave_volume, expression(Mean ~ volume ~ (microns^3)), volume_highVal)
p2 <- makeTheScatterPlot(combined_df$mean_surface_area, expression(Mean ~ surface ~ area ~ (microns^2)), surfarea_highVal)

# Combine the plots into one figure
# labels = 'AUTO' generates uppercase labels
# align = 'hv' aligns the plots horizontally and vertically
combined_plots <- plot_grid(p1, p2, labels = 'AUTO', align = 'hv', rel_widths = c(1, 1), rel_heights = c(1,1)) + theme(aspect.ratio=1)
combined_plots

# Plot object number (centrosomes) categories as a stacked barchart to see the frequency

p3 <- ggplot(data = combined_df, aes(fill=centrosome_cat, y=total_cell_num, x=Category)) + 
  theme_cowplot() + 
  coord_flip() +
  geom_bar(position = "fill",stat = "identity",width = 0.96) +
  theme(axis.text.x = element_text(face= "plain", color= 'black', size=9, angle = 0, hjust = 0.3, vjust = 0.5), axis.text.y = element_text(face = 'plain', color= 'black', size=9)) + 
  theme(axis.title.x = element_text(size = 10, face='plain',color='black')) +
  labs(y = "Frequency", x = NULL) + 
  scale_y_continuous(labels=percent, expand = c(0,0)) +
  scale_x_discrete(limits = rev(levels(combined_df$Category)), expand = c(0,0)) +
  theme(legend.title = element_blank(), legend.position = 'right', legend.justification = 'centre', legend.text = element_text(size = 9, colour = 'black')) + 
  scale_fill_discrete(labels = c(">2", "Bipolar")) 
p3

# Save the plots
# when importing the plot into illustrator save as pdf 
ggsave("./Output/Plots/combined_plots.png", plot = combined_plots, dpi = 300)
ggsave("./Output/Plots/combined_plots.pdf", plot = combined_plots, width = 200, height = 200, units = 'mm', useDingbats = FALSE)
ggsave("./Output/Plots/stacked_bar.png", plot = p3, dpi = 300)
ggsave("./Output/Plots/stacked_bar.pdf", plot = p3, width = 200, height = 200, units = 'mm', useDingbats = FALSE)
