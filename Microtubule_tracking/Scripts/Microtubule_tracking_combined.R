# Microtubule tracking data visualisation
# Load in dataframes produced from processing individual experiments, plot data with stats
# Written by James Shelford

# Working directory should be 'Microtubule_tracking'

require(ggplot2)
require(ggbeeswarm)
library(dplyr)
library(multcomp)
library(cowplot)
library(ggpubr)
library(rstatix)

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
speed_highVal <- ceiling(max(combined_df$growth_speed, na.rm = TRUE))
lifetime_highVal <- ceiling(max(combined_df$growth_lifetime, na.rm = TRUE))
length_highVal <- ceiling(max(combined_df$growth_length, na.rm = TRUE))
nucleation_highVal <- ceiling(max(combined_df$number_of_growths, na.rm = TRUE))

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
    theme(axis.text.x = element_text(face= "plain", color= 'black', size=9, angle = 45, hjust = 0.5, vjust = 0.6), axis.text.y = element_text(face = 'plain', color= 'black', size=9)) + 
    theme(axis.title.y = element_text(size = 10,face='plain',color='black')) +
    theme(legend.position = 'none') +
    theme(legend.title = element_blank()) +
    ylim(0, highVal)
}

# make each of the four plots
p1 <- makeTheScatterPlot(combined_df$growth_speed, "Growth speed (microns/min)", speed_highVal)
p2 <- makeTheScatterPlot(combined_df$growth_lifetime, "Growth lifetime (seconds)", lifetime_highVal)
p3 <- makeTheScatterPlot(combined_df$growth_length, "Growth length (microns)", length_highVal)
p4 <- makeTheScatterPlot(combined_df$number_of_growths, "Nucleation events", nucleation_highVal)

# Arrange the plots
# labels = 'AUTO' generates uppercase labels
# align = 'hv' aligns the plots horizontally and vertically
combined_plots <- plot_grid(p1, p2, p3, p4, labels = 'AUTO', align = 'hv', rel_widths = c(1, 1), rel_heights = c(1,1)) + theme(aspect.ratio=1)
combined_plots

# Save the plots
# when importing the plot into illustrator save as pdf 
ggsave("./Output/Plots/combined_plots.png", plot = combined_plots, dpi = 300)
ggsave("./Output/Plots/combined_plots.pdf", plot = combined_plots, width = 200, height = 200, units = 'mm', useDingbats = FALSE)

#---------------------------------- Statistics ----------------------------------

# Visualise distribution of data
# Density plot
ggdensity(combined_df$growth_lifetime, fill = 'lightgray')
# QQ plot
ggqqplot(combined_df$growth_lifetime)

# Use significance test to check normality
# Use the rstatix package which is pipe-friendly. Null hypothesis is norm dist.
combined_df %>% group_by(Category) %>% shapiro_test(growth_lifetime)

# Check for homogeneity of variance across the Categories using levene test, uses rstatix package and is pipe-friendly. Null is equal variances
combined_df %>% levene_test(growth_lifetime ~ Category)

## Independent two-samples t-test, uses rstatix package
stats_result <- combined_df %>% t_test(growth_lifetime ~ Category, ref.group = 'Control', var.equal = TRUE)

