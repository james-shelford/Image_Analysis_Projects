# Microtubule tracking data visualisation
# Load in dataframes produced from processing individual experiments, plot data with stats
# Written by James Shelford

require(ggplot2)
require(ggbeeswarm)
library(dplyr)
library(multcomp)
library(cowplot)

# Working directory should be 'Microtubule_tracking'
# Load the dataframes (.rds) for each experiment. These should be in Output/Dataframe
datadir <- 'Output/Dataframe'

my_dataframes <- list.files(datadir, pattern = '*.rds', full.names = TRUE)
combined_df <- bind_rows(lapply(my_dataframes, readRDS))
combined_df$Category <- as.factor(combined_df$Category)

# How many cells in each condition?
summary(combined_df$Category)

# To plot in the correct order, load in the lookup table
look_up_table <- read.table("Data/lookup.csv", header = TRUE, stringsAsFactors = F, sep = ",")
combined_df$Category <- factor(combined_df$Category, levels = look_up_table$Search_category )

# Find the max value for each parameter. This will be used to set axis limits.
speed_highVal <- ceiling(max(combined_df$my_growth_speed, na.rm = TRUE))
lifetime_highVal <- ceiling(max(combined_df$my_growth_lifetime, na.rm = TRUE))
length_highVal <- ceiling(max(combined_df$my_growth_length, na.rm = TRUE))
nucleation_highVal <- ceiling(max(combined_df$my_num_growths, na.rm = TRUE))

# Generate the plots
# theme_cowplot() removes the grid. Comment this out for classic ggplot appearance.
# function to generate the plots
makeTheScatterPlot <- function(parameter, parameter_units, highVal) {
  ggplot(data = combined_df, aes(x = Category, y = parameter, colour = Category)) +
    theme_cowplot() +
    geom_quasirandom(alpha = 0.5, stroke = 0) +
    stat_summary(fun.data = mean_sdl, fun.args = list(mult=1), aes(group = Category)) +
    theme(axis.text.x = element_text(angle=90, hjust=1)) +
    labs(y = parameter_units, x = NULL) + 
    theme(axis.text.x = element_text(face= "plain", color= 'black', size=9, angle = 45, hjust = 1), axis.text.y = element_text(face = 'plain', color= 'black', size=9)) + 
    theme(axis.title.y = element_text(size = 10,face='plain',color='black')) +
    theme(legend.position = 'none') +
    theme(legend.title = element_blank()) +
    ylim(0, highVal)
}

# make each of the four plots
growth_speed_plot <- makeTheScatterPlot(combined_df$my_growth_speed, "Growth speed (microns/min)", speed_highVal)
growth_lifetime_plot <- makeTheScatterPlot(combined_df$my_growth_lifetime, "Growth lifetime (seconds)", lifetime_highVal)
growth_length_plot <- makeTheScatterPlot(combined_df$my_growth_length, "Growth length (microns)", length_highVal)
nucleation_events_plot <- makeTheScatterPlot(combined_df$my_num_growths, "Nucleation events", nucleation_highVal)

# Arrange the plots
# labels = 'AUTO' generates uppercase labels
# align = 'hv' aligns the plots horizontally and vertically
combined_plots <- plot_grid(growth_speed_plot, growth_lifetime_plot, growth_length_plot, nucleation_events_plot, labels = 'AUTO', align = 'hv', rel_widths = c(1, 1), rel_heights = c(1,1)) + theme(aspect.ratio=1)
combined_plots

# Save the plots
# when importing the plot into illustrator save as pdf 
ggsave("./Output/Plots/combined_plots.png", plot = combined_plots, dpi = 300)
ggsave("./Output/Plots/combined_plots.pdf", plot = combined_plots, width = 200, height = 200, units = 'mm', useDingbats = FALSE)
