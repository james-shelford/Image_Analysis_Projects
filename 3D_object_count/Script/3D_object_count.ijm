// Macro to detect and take measurements of 3D objects using tiffs containing z stacks of cell outline and object to detect
// Choose directory containing images to be analysed and choose an output folder to save results to
// Output files are named the same as the input image i.e. 'blind_001.csv' and 'blind_001.txt'
// .csv file contains measurements of detected objects & .txt file contains num objects detected and threshold settings


// Manually change threshold settings to meet requirements of dataset
// Manually change the channel name 

macro "3D object counter" {
inputFolder=getDirectory("Choose input folder");
outputFolder=getDirectory("Choose output folder for the results");
list=getFileList(inputFolder);

 
for(i=0; i<list.length; i++) {
 path=inputFolder+list[i];
 if(endsWith(path,".tif")) open(path);
 showProgress(i, list.length);
 if(nImages>=1) {
  if(i==0) {
   
  }

outputPath=outputFolder+list[i];
 // The following two lines removes the file extension
  fileExtension=lastIndexOf(outputPath,"."); 
  if(fileExtension!=-1) outputPath=substring(outputPath,0,fileExtension);

roiManager("reset");
// Set the 3D object counter objects
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box close_original_images_while_processing_(saves_memory) dots_size=5 font_size=10 show_numbers white_numbers redirect_to=none");
run("Split Channels");
// Change to select channel of cell outline
selectWindow("C2-" + list[i]);
setTool("freehand");
waitForUser("Draw around the cell");
roiManager("Add");
// Change to select channel of 3D object i.e pericentrin
selectWindow("C3-" + list[i]);
roiManager("select", 0);
run("Clear Outside", "stack");

// Change the threshold and min value
run("3D Objects Counter", "threshold=400 slice=8 min.=150 max.=898008 statistics summary");


// Save the results window
 selectWindow("Results");
 saveAs("Results", outputPath+".csv");
  run("Close"); //closes summary window
 selectWindow("Log");
 saveAs("Text", outputPath+".txt");
  run("Close"); //closes summary window
  selectWindow("ROI Manager");
  run("Close");
  run("Close All"); //closes all images


 }}}

