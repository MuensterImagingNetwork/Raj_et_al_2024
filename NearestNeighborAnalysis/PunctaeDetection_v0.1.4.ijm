/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

var first = 20; //First Oval diameter
var inc = 235// Oval increment
var number = 7; // number of ovals
var inc2=inc/2;


run("Set Measurements...", "area centroid center bounding display redirect=None decimal=3");

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

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
	//Open the file and duplicate the channel for segmentation		
	run("Bio-Formats", "open=[" + input + "/" + file +"] autoscale color_mode=Default display_rois rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	image = getTitle();
	filename = File.getNameWithoutExtension(input + File.separator + file);
	setTool("polygon");
	rename("Wound");
	getDimensions(image_width, image_height, channels, slices, frames);
	run("Enhance Contrast", "saturated=0.35");
	
	// Get Wound Coordinates
	roiManager("select", 0);
	Roi.getCoordinates(xpoints, ypoints);
	roiManager("Deselect");
	roiManager("Delete");
	makeOval(xpoints[0]-18, ypoints[0]-9,  first, first);
	roiManager("Add");
	Roi.getBounds(x, y, width, height);

	for (p = 0; p < number-1; p++) {
		n= roiManager("count");
		
		if (n==1){
			roiManager("select", n-1);
			Roi.getBounds(x, y, width, height);
			makeOval(x-inc2, y-inc2,  width+inc, height+inc);
			roiManager("Add");
			n= roiManager("count");
			roiManager("deselect");
			roiManager("select", newArray(n-1,n-2));
			roiManager("XOR");
			roiManager("Add");
			roiManager("deselect");
		}
		else {
			roiManager("select", n-2);
			Roi.getBounds(x, y, width, height);
			makeOval(x-inc2, y-inc2,  width+inc, height+inc);
			roiManager("Add");
			roiManager("deselect");
			n= roiManager("count");
			roiManager("select", newArray(n-1,n-3));
			roiManager("XOR");
			roiManager("Add");
			roiManager("deselect");
			n= roiManager("count");
			roiManager("select", n-4);
			roiManager("Delete");
			roiManager("deselect");
		}	
	}
	n= roiManager("count");
	roiManager("select", n-2);
	roiManager("Delete");
	roiManager("deselect");
	roiManager("show None");
	
	
	// Draw ROI around cell. Make sure to include the whole cell for the full time period.
	waitForUser("Draw a ROI around the entire cell and click okay");
	roiManager("add");
	newImage("HyperStack", "8-bit grayscale-mode", image_width, image_height, channels, slices, frames);
	Stack.setXUnit("um");
	run("Properties...", "channels="+channels+" slices="+slices+" frames="+frames+" pixel_width=0.085 pixel_height=0.085 voxel_depth=1");
	roiManager("select", number);
	run("Add Selection...");

	setForegroundColor(255, 255, 255);
	run("Fill", "stack");

	saveAs("tiff", output + "/" + filename + "_Mask.tiff");
	

	//------Open cell Roi and create new Donut Rois only inide the cell-------------

	roiCount=roiManager("count");
	roiCount=roiCount-1; //-1 necessary for the next loop, to not select pos 7,7
	
	for (p = 0; p < roiCount; p++) {
		print(p, number);
		roiManager("select", newArray(p, number));

		roiManager("and");
		
		roiValue=getValue("selection.size"); // check if a new roi is created by the "AND" function. If not we can not add a roi
			if(roiValue>0){
				roiManager("add");
			}
	}

//---------delete old donut Rois-----------
	roiManager("Select", newArray(0,1,2,3,4,5,6,7));
	roiManager("delete");

//---------save new donut rois---------------
	roiManager("deselect");
	roiManager("save", output + "/" + filename + "ROI_Set.zip");
	
	//waitForUser("check");
	
	roiManager("measure");
	saveAs("Results", output + "/" + filename + "ROICoordinates.csv");
	
	close("*");
	
	run("Clear Results");

	
	roiManager("deselect");
	roiManager("delete");

	

}


