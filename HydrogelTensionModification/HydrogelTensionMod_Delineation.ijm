/*
 * Macro template to process multiple images in a folder
 * 
 * 
 * Folder structure:
 * Main Folder should contain original .czi images
 * Subfolder with  called "ROI" that contains .tif images called 
 * "ROIs + filename + .tif"
 * 
 * 
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".czi") suffix
#@ String (label = "Diameter of first circle", value = 8) input_circle



var firstcircle = input_circle; //First Oval diameter
// See also Process_Folder.py for a version of this code
// in the Python scripting language.

run("Set Measurements...", "area mean standard min centroid integrated median stack display redirect=None decimal=2");
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);

	//Open ROIs and put to manager
	filename = File.getNameWithoutExtension(input + File.separator + file);
	roiname = "ROIs"+filename+".tif";
	open(input + "/ROI/" + roiname);
	roi = getTitle();
	run("To ROI Manager");
	close(roi);
	
	//waitForUser("Warte");


	//Open the file and duplicate the channel for segmentation	
	run("Clear Results");
	
	run("Bio-Formats", "open=[" + input + "/" + file +"] autoscale color_mode=Default display_rois rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	//run("Bio-Formats (Windowless)", "open=[" + input + "/" + file +"] autoscale color_mode=Default display_rois rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	image = getTitle();
	rename("Wound");
	filename = File.getNameWithoutExtension(input + File.separator + file);
	print(filename);
	
	roiManager("Select", 0);
	roiManager("rename", "CellArea");
	roiManager("Select", 1);
	roiManager("rename", "Background");
	
	
	selectImage("Wound");
	roiManager("deselect");
	
	getDimensions(width, height, channels, slices, frames);
	if (channels == 2) {
		run("Select None");
		run("Duplicate...", "duplicate channels=2");
		close("Wound");
		selectWindow("Wound-1");
		rename("Wound");
	}
	run("Enhance Contrast", "saturated=0.35");
	

	
	
	//Measure the intensity around the ablation ROI
	roiManager("select", 3);
	Roi.getBounds(x, y, width, height);
	roiManager("Deselect");
	getPixelSize(unit, pixelWidth, pixelHeight);
	makeOval(x, y,  width, height);
	run("Enlarge...", "enlarge="+firstcircle+"");
	roiManager("Add");
	roiManager("Select", 4);
	roiManager("rename", "AccumulationArea");
	//roiManager("Multi Measure");
	Stack.setFrame(0);
	for (i=1; i<=frames; i++){
    	Stack.setFrame(i);
    	roiManager("measure");	
	} 
	roiManager("deselect");
	
		
	selectImage("Wound");
	roiManager("select", 0);
	Stack.setFrame(0);
	for (i=1; i<=frames; i++){
    	Stack.setFrame(i);
    	roiManager("measure");	
	} 
	roiManager("deselect");
	
	//Draw ROI around the wound area
	
	Stack.setFrame(100);
	//waitForUser("Draw a ROI around the wound area and click ok.");
		
	roiManager("add");
	roiManager("select", 4);
	roiManager("rename", "WoundArea_big");
	Stack.setFrame(0);
	for (i=1; i<=frames; i++){
    	Stack.setFrame(i);
    	roiManager("measure");	
	} 
	
	
	//Segmentation of high accumulation area
	
	//roiManager("multi-measure measure_all append");

	setBackgroundColor(0, 0, 0);
	roiManager("deselect");

	run("Select None");
	run("Duplicate...", "duplicate");
	roiManager("select", 4);
	run("Clear Outside", "stack");
	rename("Wound_Area");
	roiManager("Select", 4);
	run("Clear Outside", "stack");
	
	
	//Segmentation of wound using ilastik
	//run("Run Pixel Classification Prediction", "projectfilename=["+ilastikfile+"] inputimage=Wound_Area pixelclassificationtype=Probabilities");
	//rename("Probabilities");
	//selectImage("Probabilities");
	//run("Duplicate...", "duplicate channels=1");
	//rename("Probability_Wound");
	//segmentation = getTitle();
	//selectImage(segmentation);
	run("Select None");
	run("Median...", "radius=5 stack");
	//run("Threshold...");
	//setAutoThreshold("Otsu dark no-reset stack");
	//waitForUser("Set threshold and press apply");

	
	run("Convert to Mask", "method=Otsu background=Dark black list");
	//run("Convert to Mask", "method=Minimum background=Dark calculate black");
	saveAs("tiff", output + "/" + filename + "_Segmentation.tiff");
	masked_image = getTitle();
	//run("Analyze Particles...", "size=10-Infinity add stack");
	
	run("Analyze Particles...", "size=1-Infinity include summarize add stack");
	saveAs("Results", output + "/" + filename + "_SummaryParticles.txt");
	
	close(masked_image);
	//close(segmentation);
	//close("Probabilities");
	selectWindow("Wound");
	roiManager("Deselect");
	roiManager("Save", output + "/" + filename + "_Roiset.zip");
	
	count = roiManager("count");
	indexes = Array.getSequence(count);
	//double check which image is measured. ROIs at wrong position if you use the cropped duplicate.
	
	for (i=5; i<indexes.length; i++){
    	print("   "+indexes[i]);
    	roiManager("select", indexes[i]);
    	roiManager("measure");	
	}
	
	
	//ROI measurements
	saveAs("Results", output + "/" + filename + "_Results.csv");
	print("Saving to: " + output);
	roiManager("Deselect");
	roiManager("delete");
	
	close("*");
	
}

close("*");
