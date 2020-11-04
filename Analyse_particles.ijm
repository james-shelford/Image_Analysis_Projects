// Macro to quantify transferrin uptake in tiff images using 'analyse particles'
// Choose directory containing images to be analysed and choose an output folder to save results to
// For the first image you will need to manually select the thresholding method in the pop up window, i.e. 'RenyiEntropy Dark'
// Output files are named the same as the input image i.e. 'blind_001.csv' and 'blind_001.txt'
// .csv file containing measurements of detected spots & .txt file containing threshold limits used


macro "Automated-Particle-Analysis" {
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
 run("Split Channels");
 
 // Change to select channel of transferrin image
 selectWindow("C3-" + list[i]);
setTool("freehand");
waitForUser("Use the freehand select tool to draw around the cell");
roiManager("Add");
run("Threshold...");
// Can change the thresholding method
setAutoThreshold("RenyiEntropy dark");                           
waitForUser("Choose method, set the threshold and press OK"); 
getThreshold(lower,upper);   
print("your thresholds are; "+lower, "to "+ upper);                                         
run("Convert to Mask");                   
run("Convert to Mask");

// Can change the settings here depending on your requirements
run("Analyze Particles...", "size=0.03-0.8 circularity=0.3-1.00 exclude summarize");
  selectWindow("Summary");
  outputPath=outputFolder+list[i];
  
  //The following two lines removes the file extension
  fileExtension=lastIndexOf(outputPath,"."); 
  if(fileExtension!=-1) outputPath=substring(outputPath,0,fileExtension);
  
  saveAs("Text", outputPath+".csv");
  run("Close"); //closes summary window
  selectWindow("Log");
  outputPath=outputFolder+list[i];
  
  //The following two lines removes the file extension
  fileExtension=lastIndexOf(outputPath,"."); 
  if(fileExtension!=-1) outputPath=substring(outputPath,0,fileExtension);
  
  saveAs("Text", outputPath+".txt");
  selectWindow("Log");
  run("Close"); //closes Threshold window
  run("Close All"); //closes all images
  roiManager("reset");
  
  }
 }

}