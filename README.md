# ImageJ scripts and R code
## Overview
Some ImageJ scripts I have put together over the course of my PhD research to help with image analysis. For each one there is an accompanying R script to process and plot the data generated from ImageJ. I have tried to generalise the scripts in the hope they could be useful for other projects. 

Where log.txt are used, analysis was performed blind to the conditions of the experiment and a Lookup.csv is used in R to add the original label. 

## Analyse particles
This was initially written to quantify transferrin uptake in cells using images acquired by light microscopy (see below).  

![Transferrin image](Example_images/Transferrin_example.png)  

* `Analyse_particles.ijm` will _threshold_ the transferrin to isolate vesciular structures and use _analyse particles_ to create a mask of the particles based on parameters set by the user. The output is a csv file containing the results from _analyse particles_ and a txt file containing the values of the _threshold_ limits used for the analysis.
* `Analyse_particles.R` will process the data (output from ImageJ) to generate a dataframe, plots and calculate statistics. The dataframe and plots are saved to output.  

Suggested data organisation: run the ImageJ script on a directory containing all of the tiff images to be analysed and select a separate directory for the output (data). Using the R script, select the data directory and run the script.

## 3D object counter


## Spindle recruitment

