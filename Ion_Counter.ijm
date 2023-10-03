// This ImageJ macro first opens the directory specified by the user's input
// and identifies the respective image channels needed to define the cyoplasm, nucleus, and ion
// fluorescent signal.

// The macro creates ROI files of the segmented cytoplasm and nuclear signal regions.
// It then determines if the center of mass (COM) of a nuclear region is within a cytoplasmic region.
// It then creates a new csv file to store the rois of the cell regions that correspond to a cell body and its nucleus 

// The macro then utilizes the respective images to define regions of interest (ROIs)
// of the cell structures and applies them to the ion channel signal. Images are generated from the ion signal
// cropped by the roi of each cell region.

// A particle count is then performed on the selected cell cytoplasm and nucleus region to determine quantitiy
// of ion signal in each region.

// The difference in total ion signal (cytoplasm enclosing region) and the nuclear signal is the quantitty of ion
// signaling strictly in the cytoplasm. Finallly the results table for the specific image input is written 
// and saved containing ion channel count for each consolidated cell region,
// in addition to the segmentation overlay onto the merged channel input image.


////////// Initialization of Directory Info and User Input ///////////
//Get the path of the input directory that holds the individual channel images for a sample


inputer = getDirectory("Choose Directory! ");
print( "Current Input Directory: "+inputer);

// Retrieving the path of the nd2 file and sorting it in an array
fileList = getFileList(inputer); 
Array.print(fileList);
num_image= fileList.length;

Dialog.create("Directory Level Updates");

Dialog.addMessage("Begining analysis of images in input directory");
Dialog.addMessage("Total of "+num_image +" Images to analyze");
Dialog.show();

for (t = 0; t < num_image; t++) {
	
	curr_im_num =t+1;
	
	Dialog.create("Image Level Updates");
	Dialog.addMessage("Analyzing image " +curr_im_num+" out of "+num_image);
	Dialog.show();

	mainFileLoop(inputer+fileList[t], t);
	
	Dialog.create("Image Level Updates");
	Dialog.addMessage("(�?� ◕‿◕ )�?�");
	Dialog.addMessage(" ** Woww Amazing! **");
	Dialog.addMessage("ლ( ͡▀̿ ̿ ͜ʖ ͡▀̿ ̿ )ლ");
	Dialog.show()
}

Dialog.addMessage("All images have been analyzed");
Dialog.show();


function mainFileLoop(inputDir, curr_image){


//Open nd2 and seperate channels
name = inputDir;
image_name= fileList[curr_image];

print(image_name+" Loading Large .nd2 image....");

print("Loading Large .nd2 image");


run("Bio-Formats Importer", "open=[" + inputDir+ "] autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT");

just_name = File.nameWithoutExtension();
// Create an image output folder for the temp and final images
image_output_folder = inputer+ File.nameWithoutExtension() +" Image Outputs";
File.makeDirectory(image_output_folder);

selectWindow(image_name + " - C=0");
run("Z Project...", "projection=[Max Intensity]");
close(image_name+ " - C=0");
selectWindow("MAX_"+ image_name + " - C=0");
run("Enhance Contrast", "saturated=0.35");
saveAs("Tiff", image_output_folder+ "/MAX_" + File.nameWithoutExtension() + "_green.tif");
rename("MAX_"+ image_name + " - C=0");

selectWindow(image_name + " - C=2");
run("Z Project...", "projection=[Max Intensity]");
close(image_name + " - C=2");
selectWindow("MAX_"+ image_name + " - C=2");
run("Enhance Contrast", "saturated=0.35");
saveAs("Tiff", image_output_folder+ "/MAX_" + File.nameWithoutExtension() + "_red.tif");
rename("MAX_"+image_name + " - C=2");

selectWindow(image_name + " - C=1");
run("Z Project...", "projection=[Max Intensity]");
close(image_name + " - C=1");
selectWindow("MAX_"+ image_name + " - C=1");
run("Enhance Contrast", "saturated=0.35");
saveAs("Tiff",image_output_folder+ "/MAX_" + File.nameWithoutExtension() + "_blue.tif");
rename("MAX_"+ image_name + " - C=1");

run("Merge Channels...", "c1="+"[MAX_"+ image_name + " - C=1]" + " c2="+"[MAX_"+ image_name + " - C=0]" +" c3="+"[MAX_"+ image_name + " - C=2]" +" create");
saveAs("Tiff", image_output_folder+ "/MAX_" + File.nameWithoutExtension() + "_merge.tif");

run("Close All");


fileList = getFileList(image_output_folder); 

//
Array.sort(fileList);
Array.print(fileList);

// Creating an array of the image files without their extensions
file_just_names_Array = newArray(0);
for (i = 0; i < fileList.length; i++) {
	open(image_output_folder+"/"+fileList[i]);
	curr_string = File.nameWithoutExtension();
	file_just_names_Array = Array.concat(file_just_names_Array, curr_string);
}

run("Tile");
Array.print(file_just_names_Array);
wait(3000);



run("Close All");


// Looping through the sorted array of image file names without their extensions to find the position of the blue, green, merged, and red channels in the image file path array
for (i = 0; i < file_just_names_Array.length; i++) {
	
	//Setting the current file name as the string to process and classify, and measuring its length
	str = file_just_names_Array[i];
	y=lengthOf(str);

	// Selecting the substring of the last two letters in the file name and determing if they match with the last two letters of the words blue, green, merge, and red. If there is a match the iterator variable i is assigned to position variable for the corresponding channel.
	z=substring(str,y-2,y);

	if (z == 'ue'){
		blue_channel_pos = i;
	};
	if (z == 'en'){
		green_channel_pos = i;
	};

	if (z == 'ge'){
		merge_pos = i;
	};
	if (z == 'ed'){
		red_channel_pos = i;
	};
};

// Creating the output folder to hold the results and final overlay image
Main_Output_Folder =  inputer+ just_name + " Ion Region Count Results Output";
File.makeDirectory(Main_Output_Folder);


////////// Start of analysis script ////////////


/////////Major region segmentation function based on an input 

////Creating the roi data output for the cytoplasm channel (red)
Major_Region_Segmentation_Analysis(fileList[red_channel_pos],image_output_folder,Main_Output_Folder,file_just_names_Array[red_channel_pos],"red");

// Saving the roi manager and results 
red_out =Save_ROI_and_Results(Main_Output_Folder, "/"+file_just_names_Array[red_channel_pos],fileList[red_channel_pos],"yes clear");
cytoplasm_roi_zip_path = red_out[0];
cytoplasm_results_path = red_out[1];

////Creating the roi data output for the nuclei channel (blue)
Major_Region_Segmentation_Analysis(fileList[blue_channel_pos],image_output_folder,Main_Output_Folder,file_just_names_Array[blue_channel_pos],"blue");
// Saving the roi manager and results 
blue_out =Save_ROI_and_Results(Main_Output_Folder, "/"+file_just_names_Array[blue_channel_pos],fileList[blue_channel_pos],"yes clear");
nuclei_roi_zip_path = blue_out[0];
nuclei_results_path = blue_out[1];


/////////Nuclei to cytoplasm association
consolidated_array_match_array =Check_within(fileList[blue_channel_pos],cytoplasm_roi_zip_path,nuclei_results_path);

run("Close All");

/////////ROI Overlay and ion signal integrated density calculation
Overlay_ROI(fileList[green_channel_pos], cytoplasm_roi_zip_path,nuclei_roi_zip_path,consolidated_array_match_array);



////////ROI Overlay onto merged image
overlay_merge_out(fileList[merge_pos],cytoplasm_roi_zip_path,nuclei_roi_zip_path,consolidated_array_match_array);

 

wait(10000);
close("*");

// Analysis Done Celebrate
};



////////// Start of Function Definitions ////////////

// Function to segment the areas for the specific regions
function Major_Region_Segmentation_Analysis(input_image,input_directory,output_dir_name,nameWithoutExtension,type) {
	
	open(input_directory +"/"+input_image);
	
	run("8-bit");
	
	setMinAndMax(108, 270);
	
	if (type == "blue"){
	run("Enhance Contrast", "saturated=0.35");}

	run("Threshold...");
	title = "WaitForUserDemo";
	msg = "If necessary, use the \"Threshold\" tool to\nadjust the threshold, then click \"OK\".";
	waitForUser(title, msg);
	close("Threshold");
	

	
	print( "Creating Mask" );
	run("Create Mask");
	run("Fill Holes");

	setOption("BlackBackground", false);


	run("Set Measurements...", "area centroid center shape feret's skewness limit display redirect=None decimal=3");



	run("Analyze Particles...", "size=200-40000 display clear overlay add");
	

	if (type == "blue"){
	run("Analyze Particles...", "size=20-300 display clear overlay add");}

	print( "Setting scale and particle selection" );
	
	roiManager("UseNames", "true");
 
	for (k=0; k<nResults; k++) {
		roiManager("Select", k);
    		oldLabel = getResultLabel(k);
    		newLabel = Roi.getName;
    		setResult("Label", k, newLabel);
	}

  
}


// Function to save segmentation data
function Save_ROI_and_Results(directory_name, file_prefix,image_og_path,clearer) {

	saveAs("Results",directory_name+ file_prefix+"_Measrement_Results.csv");
	print( "Saving Results" );

	roiManager("Save",directory_name+file_prefix+"_RoiSet.zip");

	print( "Saving ROI manager" );

	
	//Clears all iamgeJ windows
	if (clearer == "yes clear"){
	Overlay.clear
	print("\\Clear");
	run("Clear Results");
	close("*");

	roiManager("Deselect");
	roiManager("Delete");}

	pathouts = newArray(directory_name +file_prefix+"_RoiSet.zip", directory_name+ file_prefix +"_Measrement_Results.csv");


	return pathouts;
}


// Function to check if the center of mass or center of roi 2 is within the geometric the perimeter of roi 1 
function Check_within(nuclei_image_path,cytoplasm_roi_zip_path,blue_results_csv) {
	open(image_output_folder+"/"+nuclei_image_path);

	roiManager("Open", cytoplasm_roi_zip_path);
	n = roiManager('count');


	// Initializing Cyt ROI to Nuc ROI Match Array
	matched  = newArray();

	// loop through the ROI Manager
	for (q = 0; q < n; q++) {

		// Loop through the nucleus ROI centroid coordinates and determine if they're contained
		// in the currently slected cytoplasm ROI
		
		// Open Nuclei ROI seg Results CSV
		open(blue_results_csv);

		roiManager("Select", q);
		for (s = 0; s< getValue("results.count"); s++){
			X_centroid = floor(getResult("XM", s));
			Y_centroid= floor(getResult("YM", s));
			nuclear_name =getResultLabel(s);

			toUnscaled(X_centroid, Y_centroid);
			
			is_matched = Roi.contains(X_centroid, Y_centroid);

			if (true == is_matched){
			match_array = newArray(Roi.getName(),nuclear_name);
			matched= Array.concat(matched,match_array);
			break;
			}
			
		}
	}
	roiManager("Deselect");
	roiManager("Delete");
	return matched;
}


// Function to Overlay the ROI from One Channel segmentation to another
function Overlay_ROI(image_path, cyt_roi_overlay_path, nuc_roi_overlay_path,matched_cyt_nuc_array) {
	

	length_match = matched_cyt_nuc_array.length;

	//Loop through the names of the matched rois and overlay and crop from the input image
	for (e = 0; e< length_match; e++) {
		open(image_output_folder+"/"+image_path);
		// Open Cytoplasm and nuclei ROIs
		roiManager("Open", cyt_roi_overlay_path);
		roiManager("Open", nuc_roi_overlay_path);
		selectWindow(image_path);
		run("Duplicate...", " ");
		rename("Base1");
		run("Duplicate...", " ");
		rename("Base2");
		
		cyt_name = matched_cyt_nuc_array[e];
		nuc_name = matched_cyt_nuc_array[e+1];

		cyt_roi_pos = findRoiWithName(cyt_name);

		nuc_roi_pos = findRoiWithName(nuc_name);
		
		selectWindow("Base1");
	
		//Running the ion segmentation on subtracted cyt region
		Create_ROI_image("Base1",cyt_roi_pos,nuc_roi_pos);
		
		//Select window using the window name
		selectWindow("Base1_crop");
		ion_count(cyt_roi_pos, "mixed cyt nuc");
		
		//Save the segmentation result in a seperate folder
		cell_out_dir = Main_Output_Folder+ "/" + "Cell_" +e+"_cytoplasm_roi_"+matched_cyt_nuc_array[e];
		File.makeDirectory(cell_out_dir);
		Save_ROI_and_Results(cell_out_dir, '/CYTO Ions',1,"no clear");
		
		selectWindow("Base2");
		Create_ROI_image("Base2",cyt_roi_pos,nuc_roi_pos);
		
		//Select window using the window name
		selectWindow("Base1_crop");
		// Open Cytoplasm and nuclei ROIs
		roiManager("Open", cyt_roi_overlay_path);
		roiManager("Open", nuc_roi_overlay_path);
		nuc_roi_pos = findRoiWithName(nuc_name);
		ion_count(nuc_roi_pos, "None");

		//Save the segmentation result in a seperate folder
		cell_out_dir = Main_Output_Folder+ "/" + "Cell_" +e+"_nucleus_roi_"+matched_cyt_nuc_array[e+1];
		File.makeDirectory(cell_out_dir);
		Save_ROI_and_Results(cell_out_dir, '/NUC Ions',1,"yes clear");
		e++;

	}
}



// Function to create an image from an roi and input image and open it in a new window
function Create_ROI_image(Base_Window,cyt_roi_pos,nuc_roi_pos) {
	//Use the current roi to crop from image path and create a new image window with it
	roiManager("Deselect");
	roiManager("Delete");

	roiManager("Open", cyt_roi_overlay_path);
	roiManager("Open", nuc_roi_overlay_path);


	roiManager("Select", newArray(cyt_roi_pos,nuc_roi_pos));


	if (Base_Window != "Base1"){
		close("Base1_crop");
		roiManager("Select", nuc_roi_pos);}

	if (Base_Window == "Base1"){
		roiManager("XOR");
		roiManager("Add");
		roiManager("Select", roiManager("Count")-1);}

	selectWindow(Base_Window);
	run("Crop");
	rename("Base1_crop");
}


// Function to select an roi by its name
function findRoiWithName(roiName) { 
	nR = roiManager("Count"); 
 
	for (a=0; a<nR; a++) { 
		roiManager("Select", a); 
		rName = Roi.getName(); 
		if (matches(rName, roiName)) { 
			return a; 
		} 
	} 
	return -1; 
} 

function findRoisWithName(roiName) { 
	nR = roiManager("Count"); 
	roiIdx = newArray(nR); 
	b=0; 
	clippedIdx = newArray(0); 
	 
	for (t=0; t<nR; t++) { 
		roiManager("Select", t); 
		rName = Roi.getName(); 
		if (matches(rName, roiName) ) { 
			roiIdx[b] = t; 
			b++; 
		} 
	} 
	if (b>0) { 
		clippedIdx = Array.trim(roiIdx,b); 
	} 
	 
	return clippedIdx; 
}



// Function to apply the segmentation protocol on the current open window for ion channel count
function ion_count(roi_selection, roi_type) {

	run("8-bit");

	setMinAndMax(2, 40);
	
	selectWindow("Base1_crop");

	if (e==0){
	run("Threshold...");
	title = "Wait for User Threshold Input";
	msg = "If necessary, use the \"Threshold\" tool to\nadjust the threshold, then click \"OK\".";
	waitForUser(title, msg);}

	selectWindow("Threshold");

	print( "Creating Mask" );

	setOption("BlackBackground", false);
	run("Convert to Mask");

	run("Set Measurements...", "area centroid center bounding shape feret's skewness limit display integrated redirect=None decimal=3");
	
	if(roi_type == "mixed cyt nuc"){
		roiManager("Select", roiManager("Count")-1);
	}
	else{roiManager("Select", roi_selection)};

	run("Analyze Particles...", "size=0-300 display clear overlay add");
	
	print( "Setting scale and particle selection" );
	
	roiManager("UseNames", "true");

  
	for (k=0; k<nResults; k++) {
		roiManager("Select", k);
    		oldLabel = getResultLabel(k);
    		newLabel = Roi.getName;
    		setResult("Label", k, newLabel);
	}


}

//Function to create an overlay of the found cytoplasm and matched nucleus roi on the merged channel image
function overlay_merge_out(image_path, cyt_roi_overlay_path, nuc_roi_overlay_path,matched_cyt_nuc_array){
	//Open the merge imgae
	open(image_output_folder+"/"+image_path);
	rename("Merge");

	length_match = matched_cyt_nuc_array.length;

	Dialog.create("Image Level Updates")

	Success = " ////////// Yay! /////////// ";

	Dialog.addMessage(Success,14);

	Dialog.addMessage("All Done",14);
	Dialog.show() 

	Dialog.addMessage("( ͡° ͜ʖ ͡° )");
	Dialog.addMessage("Lets see the results ?");
	Dialog.show() 

	//Loop through the names of the matched rois and overlay and crop from the input image
	for (e = 0; e< length_match; e++) {
		// Open Cytoplasm and nuclei ROIs
		roiManager("Open", cyt_roi_overlay_path);
		roiManager("Open", nuc_roi_overlay_path);
		selectWindow("Merge");
		
		cyt_name = matched_cyt_nuc_array[e];
		nuc_name = matched_cyt_nuc_array[e+1];

		cyt_roi_pos = findRoiWithName(cyt_name);
		run("Add Selection...", "stroke=cyan");

		nuc_roi_pos = findRoiWithName(nuc_name);
		run("Add Selection...", "stroke=yellow");
		
		e++;

	}

	roiManager("Deselect");
	roiManager("Delete");

	run("Show Overlay");
	Overlay.flatten;

	saveAs("Tiff", image_output_folder+ "/Merge_Ion_Count");
	close("Merge");
	open(image_output_folder+"/"+image_path);
	roiManager("Deselect");
	run("Tile");
	File.delete(image_output_folder)
		
}
