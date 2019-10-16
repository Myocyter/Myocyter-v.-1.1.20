// The "MYOCYTER" - Convert cellular and cardiac contractions into numbers with ImageJ 

// MYOCYTER - An analysis tool to convert cellular and muscle tissue contractions into numerical and graphical data with ImageJ

// Tilman Grune 1,2,3,4,5 MD, Christiane Ott 1,3 PhD, Steffen Haeseli 1 B.Sc, Annika Hoehn 1,2 PhD, and Tobias Jung 1,3 PhD 

// 1 Department of Molecular Toxicology, German Institute of Human Nutrition Potsdam-Rehbruecke (DIfE), 14558 Nuthetal, Germany
// 2 German Center for Diabetes Research (DZD), 85764 Muenchen-Neuherberg, Germany
// 3 German Center for Cardiovascular Research (DZHK), 10117 Berlin, Germany
// 4 NutriAct - Competence Cluster Nutrition Research Berlin-Potsdam, 14558 Nuthetal, Germany
// 5 University of Potsdam, Institute of Nutrition, 14588 Nuthetal, Germany

// Correspondence: Tobias Jung, Department of Molecular Toxicology, German Institute of Human Nutrition Potsdam-Rehbruecke (DIfE), Arthur-Scheunert-Allee 114-116, 14558 Nuthetal, Germany; e-mail: tobias.jung@dife.de; phone: +49 (0)33200 88-2490

// MYOCYTER version 1.1.20

// *********************************Global Settings start here, defining JPEG-quality, specify time and date of the evaluation, as well as the parameters measured my ImageJ**********************

requires("1.52q");

filetype=".avi";

run("Colors...", "foreground=black background=black selection=yellow");
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display redirect=None   decimal=3");
run("Input/Output...", "jpeg=90 gif=-1 file=.txt use_file copy_column copy_row save_column save_row");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"); 

if (hour<10) {hours = "0"+hour;}
else {hours=hour;}
if (minute<10) {minutes = "0"+minute;}
else {minutes=minute;}
if (month<10) {months = "0"+(month+1);}
else {months=month+1;}
if (dayOfMonth<10) {dayOfMonths = "0"+dayOfMonth;}
else {dayOfMonths=dayOfMonth;}


// *********************************Global Settings end here**********************


// *********************************Please select what you want to do********

Dialog.create("Please choose...");
  Dialog.addChoice("Select:", newArray("1. Pretest (for size and threshold)", "2. Create a Batch List", "3. Evaluation", "4. Exclude Data", "5. Re-Evaluation"));


Dialog.show();
  
option = Dialog.getChoice();


// ************ The pretest starts here, evaluate the whole video or only the first 300 frames to save time ***********************************

if (option == "1. Pretest (for size and threshold)") {


Dialog.create("Pretest for your video");
Dialog.addChoice("Select test:", newArray("LowMovement", "HighMovement"));
Dialog.addCheckbox("Test only first", false);
Dialog.addNumber("frames: ", 300);
Dialog.show();
  
option= Dialog.getChoice();
qickpretest = Dialog.getCheckbox();
firstlimit = Dialog.getNumber();

// ************ Setting the options for the pretest starts here, for low moving cells a higher sensitivity is applied in order to recognize changes between images induced by moving that are represented by higher pixel-intensities ***********************************



if (option == "LowMovement") {
	testruns=12;
	startthresh=132;
}

if (option == "HighMovement") {
	testruns=12;
	startthresh=254;
}



// ************ Setting the options for the pretest ends here ***********************************


// ************ Select the folder containing the videos, get the file list, process video-files  ***********************************
 
dir=getDirectory("Please choose directory containing videos to pretest");
print(dir); 
preDir=dir + "\pretest "+"("+option+") "+year+"-"+MonthNames[month]+"-"+dayOfMonths+" "+hours+"h"+minutes+"\\"; 
print(preDir); 
File.makeDirectory(preDir); 


list = getFileList(dir); 

for (i=0; i<list.length; i++) {

     if (endsWith(list[i], filetype)){
               print(i + ": " + dir+list[i]);

if (qickpretest==false){
run("AVI...", "open=[" + dir+list[i] + "] use convert");
}



if (qickpretest==true){
run("AVI...", "open=[" + dir+list[i] + "] last="+ firstlimit +" use convert");
}

             imgName=getTitle();

name = indexOf(list[i], filetype);
title = substring(list[i], 0, name);


// ************ Exclude videos with less than 10 frames from evaluation, create two stacks from the video, shift the frames in one stack and calculate the differences between both stacks to get the speed (the difference between two subsequent frames) *******************************


if (nSlices>10) {


selectWindow(title+filetype);

run("Duplicate...", "duplicate");
setSlice(1);
run("Delete Slice");
setSlice(nSlices);
run("Add Slice");
id1=getImageID;


selectWindow(title+filetype);
run("Duplicate...", "duplicate");
id2=getImageID;

imageCalculator("Difference create 8-bit stack", id1, id2);


if (isOpen(title+"-1"+filetype)) {
     selectWindow(title+"-1"+filetype);
     run("Close");
}


if (isOpen(title+"-2"+filetype)) {
     selectWindow(title+"-2"+filetype);
     run("Close");
}

if (isOpen(title+filetype)) {
     selectWindow(title+filetype);
     run("Close");
}


// ******************* Delete the last black frame that contains no difference information to the non-existing next one, overlay all frames to get the mask used for masked evaluation, movement is depicted with brighter pixels, close no longer needed frames ***************


selectWindow("Result of "+title+"-1"+filetype);
setSlice(nSlices);
run("Delete Slice");

run("8-bit");

run("Z Project...", "projection=[Sum Slices]");

rename("SUM_Stack");


if (isOpen("Result of "+title+"-1"+filetype)) {
     selectWindow("Result of "+title+"-1"+filetype);
     run("Close");
}


selectWindow("SUM_Stack");
run("8-bit");

getRawStatistics(nPixels, mean, min, max);
print(nPixels, mean, min, max);
run("Brightness/Contrast...");
run("Enhance Contrast", "saturated=0.35");


getDimensions(width, height, channels, slices, frames);

if ((height/width)>1.8) {
run("Rotate 90 Degrees Left");
}

partdim=((width*height)/(100));
fontsize=round((width/500)*17);


if (fontsize<17){
fontsize=17;
}

roifont=fontsize;
x=1;
y=fontsize;

run("Copy");


for (s=0; s<((testruns*testruns)-1); s++) {
run("Add Slice");
run("Paste");
}


// ******************* Produce a panel that contains different combinations of threshold and particle-size *******************************

run("8-bit");

rename("sum");

setBatchMode(true);

for (m=1; m<(testruns+1); m++) {

for (n=1; n<(testruns+1); n++) {

selectWindow("sum");
setSlice(m*n);


if (option == "LowMovement") {

	threshmin=round(startthresh-((startthresh/testruns)*m));
}

if (option == "HighMovement") {

	threshmin=round(startthresh-((startthresh/(2*testruns))*m));
}


setThreshold(threshmin, 255);

run("Analyze Particles...", "size="+round((n*partdim))+"-Infinity show=[Overlay Masks] display clear include summarize add slice");
R=roiManager("count");

selectWindow("sum");


makeRectangle(1, 1, 1, 1);
run("Add Selection...");


// ******************* Apply the used setting-combinations of threshold and particle-size to the thumbnails produced by the pre-test *******************************


run("Labels...", "color=blue font="+roifont+" show draw bold");
roiManager("Show All");
run("Flatten", "slice");
run("RGB Color");
setFont("Serif" , fontsize, "antialiased");
setColor("black");
drawString("Thr="+threshmin+"; Size>="+round((n*partdim))+"; cells="+R+" ", x, y, "green");

run("Copy");

if (n*m>1){
selectWindow("sum-1");
run("Add Slice");
run("Paste");
close("sum-2");
}

}

}

setBatchMode(false);


close("sum");

//****************************Setting the image size of the images produced by the pretest starts here *******************************


if (width>500){
run("Size...", "width=500 height=500 constrain average interpolation=Bilinear");
}

run("Make Montage...", "columns="+(testruns)+" rows="+(testruns)+" scale=1 first=1 last="+((testruns)*(testruns))+" increment=1 border=1 font=12");


close("sum-1");
saveAs("Jpeg", preDir+title+"-test.jpg");
close(title+"-test.jpg");

run("Close All");

if (isOpen("ROI Manager")) {
     selectWindow("ROI Manager");
     run("Close");
}


//****************************Setting the image size of the images produced by the pretest ends here *******************************

}

     }


}


//**************************** Closing of the remaning opened windows starts here, close only windows that are actually open ******************************************


if (isOpen("Results")) {
     selectWindow("Results");
     run("Close");
}


if (isOpen("B&C")) {
     selectWindow("B&C");
     run("Close");
}


if (isOpen("Log")) {
     selectWindow("Log");
     run("Close");
}


if (isOpen("Summary of sum")) {
     selectWindow("Summary of sum");
     run("Close");
}


while (nImages>0) { 
          selectImage(nImages); 
          close(); 
}





//**************************** Closing of the remaning opened windows ends here *******************************


}


// ****************************** The pretest ends here ***********************************



// ****************************************** Evaluation starts here, apply the desired settings and parameters ****************************



if (option == "3. Evaluation") {


Dialog.create("Please insert values for lower threshold and size from pre-test");
Dialog.addNumber("Lower Threshold: ", 22);
Dialog.addNumber("Size: ", 1600);

Dialog.addCheckbox("Video output", false);
Dialog.addNumber("[%] of max recogized as beat", 20);
Dialog.addNumber("Detection", 4);
Dialog.addCheckbox("Smoother", false);
Dialog.addCheckbox("Force reference-frame", false);
Dialog.addCheckbox("Replace zero from RefFrame", true);
Dialog.addCheckbox("Batching", true);

Dialog.show();
  

thrslow = Dialog.getNumber();
cellsize = Dialog.getNumber();
vidout = Dialog.getCheckbox();
asbeat = Dialog.getNumber()/100;
detection = Dialog.getNumber();
smoother = Dialog.getCheckbox();
forceframe=Dialog.getCheckbox();
refreplace = Dialog.getCheckbox();
batching = Dialog.getCheckbox();


// ****************************************** Select a directory containing the files, get the file list and process only the video-files ********************************


dir=getDirectory("Choose a Directory");

print(dir); 
splitDir=dir + "\VidsMovement "+year+"-"+MonthNames[month]+"-"+dayOfMonths+" "+hours+"h"+minutes+"\\"; 
print(splitDir); 
File.makeDirectory(splitDir); 

diffmovDir=splitDir + "\diffMov\\";
File.makeDirectory(diffmovDir);

isolDir=splitDir + "\isolated\\";
File.makeDirectory(isolDir);


list = getFileList(dir);


// ************************* If batch-mode is activated replace the list, size, threshold and reference frame *******************

// ************************* Hier muss etwas drinstehen, dass später die Speicherung der diff-Files versaut!! ********************

if(batching==true){

if (File.exists(dir+ "\\" + "batch.txt")==true){filestring=File.openAsString(dir+ "\\" + "batch.txt");}

if (File.exists(dir+ "\\" + "batch.txt")==false){exit("Sorry, no <batch.txt> was found." + "\n" + "Please generate one and copy it into your video-folder.");}

batchlines=split(filestring, "\n");
batchdata=split(filestring, "\t\n\r");

batchtitles=split(batchlines[0], "\t");

batchdataonly=Array.slice(batchdata, batchtitles.length);


Array.print(batchdata);

Array.print(batchdataonly);


batchsample=newArray(batchdataonly.length/3);
batchthr=newArray(batchdataonly.length/3);
batchsize=newArray(batchdataonly.length/3);


for (btch=0; btch<batchdataonly.length/3; btch++){
batchsample[btch]=batchdataonly[3*btch];
}


for (btch=0; btch<batchdataonly.length/3; btch++){
batchsize[btch]=batchdataonly[3*btch+1];
}


for (btch=0; btch<batchdataonly.length/3; btch++){
batchthr[btch]=batchdataonly[3*btch+2];
}


Array.print(batchsample);
Array.print(batchthr);
Array.print(batchsize);


list=batchsample;

Array.print(list);


}


for (z=0; z<list.length; z++) {

     if (endsWith(list[z], filetype)){
               print(z + ": " + dir+list[z]); 

if (File.exists(dir+list[z])==true){	
		
	run("AVI...", "open=[" + dir+list[z] + "] use convert");
             imgName=getTitle();

name = indexOf(list[z], filetype);
title = substring(list[z], 0, name);





if (File.exists(dir+ "\\" + "batch.txt")==true){filestring=File.openAsString(dir+ "\\" + "batch.txt");}



if (nSlices>10) {

fps=round(Stack.getFrameRate());

selectWindow(title+filetype);

run("Duplicate...", "duplicate");
setSlice(1);
run("Delete Slice");
setSlice(nSlices);
run("Add Slice");
id1=getImageID;


// ****************** Duplicate the stack, shift the frames and calculate the differences between to get the mask for the individual cells ********************************

selectWindow(title+filetype);
run("Duplicate...", "duplicate");

id2=getImageID;

imageCalculator("Difference create 8-bit stack", id1, id2);


if (isOpen(title+"-1"+filetype)) {
     selectWindow(title+"-1"+filetype);
     run("Close");
}


if (isOpen(title+"-2"+filetype)) {
     selectWindow(title+"-2"+filetype);
     run("Close");
}


selectWindow("Result of "+title+"-1"+filetype);
setSlice(nSlices);
run("Delete Slice");
run("8-bit");

run("Duplicate...", "duplicate");
run("Z Project...", "projection=[Sum Slices]");

rename("SUM");

run("8-bit");

getRawStatistics(nPixels, mean, min, max);
print(nPixels, mean, min, max);
run("Brightness/Contrast...");
run("Enhance Contrast", "saturated=0.35");


setAutoThreshold("Default dark");


if(batching==true){
thrslow=batchthr[z];
cellsize=batchsize[z];
}


setThreshold(thrslow, 255);
run("Analyze Particles...", "size="+cellsize+"-Infinity display clear include summarize add in_situ");

close("SUM");


if (isOpen("Result of "+title+"-2"+filetype)) {
     selectWindow("Result of "+title+"-2"+filetype);
     run("Close");
}

selectWindow(title+filetype);

slicenumber=nSlices+1;

// ****************************** If there is at least ONE ROI (at least one recognized moving structure) starts here ***********************

if (roiManager("count")>0) {

selectWindow(title+filetype); 
run("Duplicate...", "duplicate range=1-1");
roiManager("Show All");


run("Flatten");
saveAs("Jpeg", splitDir+title+"-cells.jpg");



if (isOpen(title+"-1"+filetype)) {
     selectWindow(title+"-1"+filetype);
     run("Close");
}


if (isOpen(title+"-cells.jpg")) {
selectWindow(title+"-cells.jpg");
close();	
} else {
	selectWindow(title+"-2.avi");
close();
	}


// ************************ If there is more than one ROI (more than only a single cell) starts here *****************************

if (roiManager("count")>1) { 
	for (j=0; j<roiManager("count"); j++){
	
selectWindow(title+filetype);
run("Select None");

run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);

selectWindow(title+"-1"+filetype);

roiManager("Select", j);
setBackgroundColor(0, 0, 0);
run("Clear Outside", "stack");

run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);

selectWindow(title+"-2"+filetype);

run("AVI... ", "compression=Uncompressed frame=fps save=["+splitDir+title+"-cell 0"+(j+1)+" ("+fps+"fps)"+filetype+"]");



if (isOpen(title+"-1"+filetype)) {
     selectWindow(title+"-1"+filetype);
     run("Close");
}

if (isOpen(title+"-2"+filetype)) {
     selectWindow(title+"-2"+filetype);
     run("Close");
}
 



// ******************************** produce the videos containing the differences between the single frames and save them for later quantification, apply proper filenames **********************************  


selectWindow(title+filetype);
roiManager("Select", j);
run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);

selectWindow(title+"-1"+filetype);

run("AVI... ", "compression=Uncompressed frame=fps save=["+isolDir+title+"-diff-cell 0"+(j+1)+" ("+fps+"fps)-isolated"+filetype+"]");

if (isOpen(title+"-1"+filetype)) {
     selectWindow(title+"-1"+filetype);
     run("Close");
}

selectWindow("Result of "+title+"-1"+filetype);

run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);

selectWindow("Result of "+title+"-2"+filetype);

roiManager("Select", j);
setBackgroundColor(0, 0, 0);
run("Clear Outside", "stack");

run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);
selectWindow("Result of "+title+"-3"+filetype);

run("AVI... ", "compression=Uncompressed frame=fps save=["+diffmovDir+title+"-diff-cell 0"+(j+1)+" ("+fps+"fps)"+filetype+"]");


if (isOpen("Result of "+title+"-2"+filetype)) {
     selectWindow("Result of "+title+"-2"+filetype);
     run("Close");
}


if (isOpen("Result of "+title+"-3"+filetype)) {
     selectWindow("Result of "+title+"-3"+filetype);
     run("Close");
}



}

}

// **************************** If there is exactly one ROI (a single recognized cell) starts here **************************************

if (roiManager("count")==1) {

selectWindow(title+filetype);


run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);

selectWindow(title+"-1"+filetype);

roiManager("Select", 0);
setBackgroundColor(0, 0, 0);
run("Clear Outside", "stack");

run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);
selectWindow(title+"-2"+filetype);

run("AVI... ", "compression=Uncompressed frame=fps save=["+splitDir+title+"-cell 01 "+"("+fps+"fps)"+filetype+"]");

if (isOpen(title+"-1"+filetype)) {
     selectWindow(title+"-1"+filetype);
     run("Close");
}



if (isOpen(title+"-2"+filetype)) {
     selectWindow(title+"-2"+filetype);
     run("Close");
}


selectWindow(title+filetype);
roiManager("Select", 0);
run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);

selectWindow(title+"-1"+filetype);

run("AVI... ", "compression=Uncompressed frame=fps save=["+isolDir+title+"-diff-cell 01 "+"("+fps+"fps)-isolated"+filetype+"]");


if (isOpen(title+"-1"+filetype)) {
     selectWindow(title+"-1"+filetype);
     run("Close");
}



selectWindow("Result of "+title+"-1"+filetype);
roiManager("Select", 0);

setBackgroundColor(0, 0, 0);
run("Clear Outside", "stack");

run("Duplicate...", "duplicate range="+"1"+"-"+slicenumber);

selectWindow("Result of "+title+"-2"+filetype);

run("AVI... ", "compression=Uncompressed frame=fps save=["+diffmovDir+title+"-diff-cell 01 "+"("+fps+"fps)"+filetype+"]");


if (isOpen("Result of "+title+"-2"+filetype)) {
     selectWindow("Result of "+title+"-2"+filetype);
     run("Close");
}

roiManager("Select", 0);
roiManager("Delete");


}

// **************************** If there is exactly one ROI ends here ********************************************




 // ******************************* This clears the ROI manager (if there are more than only one recognized cell) ************************************************

b = newArray(roiManager("count"));

if (roiManager("count")>1) {
for (k=0; k<roiManager("count"); k++) b[k]=k;
roiManager("Select", b);
roiManager("Delete");
}


// **************************** End of clearing the ROI manager from multiple ROIs ****************************************


}


if (isOpen(title+filetype)) {
     selectWindow(title+filetype);
     run("Close");
}

if (isOpen("Result of "+title+"-1"+filetype)) {
     selectWindow("Result of "+title+"-1"+filetype);
     run("Close");
}

	}

	}
	}
     
	}



// **************************** Automatic plotting of the data starts here ***********************************


// ******************************* Conversion of difference-movies to intensity-values starts here, the values from every frame are put into arrays *********************************

dir=diffmovDir;
print("\\Clear");
dataDir=dir + "\dataplots\\";
File.makeDirectory(dataDir);

list = getFileList(dir);


for (y=0; y<list.length; y++) {

     if (endsWith(list[y], filetype)){
               print(y + ": " + dir+list[y]);
             run("AVI...", "open=[" + dir+list[y] + "] use convert");
             imgName=getTitle();


         baseNameEnd=indexOf(imgName, filetype);
         baseName=substring(imgName, 0, baseNameEnd);



fps=round(Stack.getFrameRate());

slicenumber=nSlices;
values = newArray(nSlices);
movalues = newArray(nSlices);
times = newArray(nSlices);
firstdev = newArray(nSlices);

print(baseName);


// *************** Masking the moving parts of the difference movie and evaluation starts here, but only if a threshold (from pretest) is applied at all ***********************


if (thrslow >0) {

run("Duplicate...", "duplicate");
selectWindow(baseName+"-1"+filetype);
run("Z Project...", "projection=[Sum Slices]");
run("8-bit");


if (isOpen(baseName+"-1"+filetype)) {
     selectWindow(baseName+"-1"+filetype);
     run("Close");
}


selectWindow("SUM_"+baseName+"-1"+filetype);

setAutoThreshold("Default dark");
setThreshold(1, 255);
run("Create Selection");

}

selectWindow(baseName+filetype);


for (j=1; j<slicenumber; j++) {

setSlice(j);

if (thrslow >0) {run("Restore Selection");}
run("Measure");
values[j-1]=getResult("Mean");
times[j]=(j/fps);
         
     }


if (isOpen(baseName+filetype)) {
     selectWindow(baseName+filetype);
     run("Close");
}

if (thrslow >0) {
selectWindow("SUM_"+baseName+"-1"+filetype);
close();
}


// *************** Masking the moving parts of the difference movie and evaluation ends here ***********************



//************************* Open the isolated cell, select the reference frame and compare the whole movie to this reference to get the amplitude starts here ************************************


strg=replace(baseName,"-diff","");

open(splitDir+strg+filetype);

run("8-bit");

//************************ If there is a hyperstack-video, convert it into regular greyscale (recent FIJI-problem) starts here) ****************************************

if (Stack.isHyperstack==1) {
selectWindow(strg+filetype);

run("Split Channels");

selectWindow("C1-"+strg+filetype);
run("Make Composite", "display=Grayscale");
selectWindow("C2-"+strg+filetype);
run("Make Composite", "display=Grayscale");
selectWindow("C3-"+strg+filetype);
run("Make Composite", "display=Grayscale");

run("Merge Channels...", "c1=[C1-" + strg+filetype + "] c2=[C2-" + strg+filetype + "] c3=[C3-" + strg+filetype + "]");
selectWindow("RGB");
rename(strg+filetype);

}

//************************ If there is a hyperstack-video, convert it into regular greyscale (recent FIJI-problem) ends here ****************************************


if (forceframe==true){
setSlice(1);
waitForUser( "Select Referenceframe","Please select Referenceframe (use the slider) and click >OK<");
forcedframe=getSliceNumber();
setSlice(1);
}


//*************** Here, we find the lowest difference between two subsequent frames and define the according reference frame from it, if no frame is set by the user ***********************

if (forceframe==false){

run("AVI...", "open=[" + dir+list[y] + "] use convert");

selectWindow(list[y]);
run("8-bit");


slicenumber=nSlices;
differ = newArray(nSlices);

for (j=1; j<slicenumber+1; j++) {
setSlice(j);

run("Measure");

differ[j-1]=getResult("Mean");
         
     }


lowestranks=Array.rankPositions(differ);
lowfrm=lowestranks[0]+1;

if (lowfrm<1) {
lowfrm=1;
}
if (lowfrm>slicenumber) {
lowfrm=slicenumber;
}
selectWindow(list[y]);
close();

}

//******************* Forced reference frame (from user) overwrites the detected one starts here *********************************


if (forceframe==true){
lowfrm=forcedframe;
}


//******************* Forced reference frame overwrites the detected one ends here ******************************


//********************** Now, the reference frame is compared to every other frame of the movie, results are put into an array *****************************


selectWindow(strg+filetype);
setSlice(lowfrm);


run("Duplicate...", " ");

selectWindow(strg+"-1"+filetype);
run("Copy");

setBatchMode(true); 

for (i=1; i<slicenumber+1; i++) {
run("Add Slice");
run("Paste");
}

setBatchMode(false);


selectWindow(strg+filetype);
id2=getImageID;

selectWindow(strg+"-1"+filetype);
id1=getImageID;

imageCalculator("Difference create 8-bit stack", id1, id2);


if (isOpen(strg+filetype)) {
     selectWindow(strg+filetype);
     run("Close");
}


if (isOpen(strg+"-1"+filetype)) {
     selectWindow(strg+"-1"+filetype);
     run("Close");
}


slicenumber=nSlices;
movalues = newArray(nSlices);

selectWindow("Result of "+strg+"-1"+filetype);
run("8-bit");



// ****************** Use a selection to improve specificity, the evaluation of the intensities starts here, if user applied threshold from pretest, evaluation is restricted to the moving cell only **************************
// ****************** Dark pixels, that are outside of the mask (strongest movement) are excluded via threshold, results are put into an array *****************************

if (thrslow >0) {
run("Duplicate...", "duplicate");
selectWindow("Result of "+strg+"-2"+filetype);
run("Z Project...", "projection=[Sum Slices]");
run("8-bit");


if (isOpen("Result of "+strg+"-2"+filetype)) {
     selectWindow("Result of "+strg+"-2"+filetype);
     run("Close");
}


selectWindow("SUM_"+"Result of "+strg+"-2"+filetype);

setAutoThreshold("Default dark");
setThreshold(1, 255);
run("Create Selection");

}

selectWindow("Result of "+strg+"-1"+filetype);


for (jj=1; jj<slicenumber; jj++) {

setSlice(jj);
if (thrslow >0) {run("Restore Selection");}
run("Measure");

movalues[jj-1]=getResult("Mean");
         
     }

if (thrslow >0) {
selectWindow("SUM_"+"Result of "+strg+"-2"+filetype);
close();}


// *********************** Use a selection to improve specificity, the evaluation of the intensities ends here ***********************************


// ********************** Eliminate the zero caused by the reference frame and replace it with the second lowest value starts here, if the user selected that option *********************************

if (refreplace==true){

lowestmoval=Array.copy(movalues);
Array.sort(lowestmoval);
replacer=0;
t=0;

while(replacer==0 && t<lowestmoval.length){
	replacer=lowestmoval[t];t++;}

movalues[lowfrm-1]=replacer;

}


// ********************** Eliminate the zero caused by the reference frame and replace it with the second lowest value ends here **************************


// ********************** Calculate the first derivative of the amplitude ***************************** 

for (j=0; j<slicenumber-1; j++) {
firstdev[j]=movalues[j+1]-movalues[j];
    
     }


if (isOpen("Result of "+strg+"-1"+filetype)) {
     selectWindow("Result of "+strg+"-1"+filetype);
     run("Close");
}



// ************************* Open the isolated cell, select the reference frame and compare the whole movie to this reference to get amplitude ends here **************


// ******************************* Conversion of movies to intensity-values ends here ****************************


// ************ Optional recognition and remove of peaks starts here (last 15% of the array, "jumps" of 10% are considered to be outliners), if set by the user ******************************


if (smoother==true){


valuessmooth=Array.copy(values);
valuessmoothsorted=Array.copy(values);

movaluessmooth=Array.copy(movalues);
movaluessmoothsorted=Array.copy(movalues);

Array.sort(valuessmoothsorted);
Array.sort(movaluessmoothsorted);


limiter=0;
molimiter=0;

for (i=(valuessmoothsorted.length*0.85); i<valuessmoothsorted.length-1 && limiter<1; i++) {

if ((valuessmoothsorted[i+1]/valuessmoothsorted[i])>1.1){
peaklimit=valuessmoothsorted[i+1];
limiter=2;
}

}

for (i=(movaluessmoothsorted.length*0.85); i<movaluessmoothsorted.length-1 && molimiter<1; i++) {

if ((movaluessmoothsorted[i+1]/movaluessmoothsorted[i])>1.1){
mopeaklimit=movaluessmoothsorted[i+1];
molimiter=2;
}

}


// ********************************************** Eradication of the outliners starts here *********************

if (limiter>1){

for (i=0; i<valuessmooth.length; i++) {

if (i<1) {
if(valuessmooth[i]>(peaklimit*0.99)) {
valuessmooth[i]=0;
}
}

if (i>0) {
if(valuessmooth[i]>(peaklimit*0.99)) {
valuessmooth[i]=valuessmooth[i-1];
}
}


}

}


if (molimiter>1){

for (i=0; i<valuessmooth.length; i++) {

if (i<1) {
if(movaluessmooth[i]>(mopeaklimit*0.99)) {
movaluessmooth[i]=0;
}
}

if (i>0) {
if(movaluessmooth[i]>(mopeaklimit*0.99)) {
movaluessmooth[i]=movaluessmooth[i-1];
}
}


}

}



// ******************* Replacement of the original data with the smoothed ones starts here *****************************



values=Array.copy(valuessmooth);

movalues=Array.copy(movaluessmooth);


for (j=0; j<movalues.length-1; j++) {
firstdev[j]=movalues[j+1]-movalues[j];
    
     }


// ******************* Replacement of the original data with the smoothed ones ends here ***************************



// ********************************************** Eradication of the outliners ends here *********************************


}


//****************************** Optional recognition and remove of peaks ends here ************************************


//******************************* Remove the last zero from the value-arrays starts here! ******************************

times = Array.slice(times, 0, times.length-1);
values = Array.slice(values, 0, values.length-1);
movalues = Array.slice(movalues, 0, movalues.length-1);
firstdev = Array.slice(firstdev, 0, firstdev.length-1);


//******************************* Remove the last zero from the values-array ends here! Slicenumber is (values.length+1)! ************************************

//****************************** Printing the analyzed data from the array starts here *****************************


thresh10=0.1;
thresh50=0.5;
thresh90=0.9;

Array.getStatistics(movalues, pmin, pmax, pmean, pstdDev);
Array.getStatistics(values, speedmin, speedmax, speedmean, speedstdDev);

maxima=Array.findMaxima(movalues, (pmax-pmin)/detection);
minima=Array.findMinima(movalues, (pmax-pmin)/detection);
Array.sort(maxima);
Array.sort(minima);

min=0;
max=0;
beats=1;
btimea=0;
btimeabs="";
btimeold=0;
beattimes=newArray();
threshold=asbeat;

//*************** Here, all the minima are paired with the according (following) maxima and the amplitudes are calculated **************************** 


truncmin=Array.copy(minima);
truncmax=Array.copy(maxima);


if (truncmax[0]<truncmin[0]){
truncmax=Array.slice(truncmax,1,truncmax.length);
}


if(truncmax.length>truncmin.length){
	truncmax=Array.slice(truncmax,0,truncmin.length);
}

if(truncmax.length<truncmin.length){
	truncmin=Array.slice(truncmin,0,truncmax.length);
}


maxamplitudes=newArray(truncmax.length);

for (www=0; www<truncmax.length; www++){
	maxamplitudes[www]=movalues[truncmax[www]]-movalues[truncmin[www]];
}

//********************* Printing of the data starts here *******************

// Create Arrays that contain the transition points before and after maxima for the different thresholds starts here

systuserstart=newArray(truncmax.length);
diastuserend=newArray(truncmax.length);

syst10start=newArray(truncmax.length);
diast10end=newArray(truncmax.length);

syst50start=newArray(truncmax.length);
diast50end=newArray(truncmax.length);

syst90start=newArray(truncmax.length);
diast90end=newArray(truncmax.length);

for (transition = 0; transition < truncmax.length; transition++) {

//user
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && movalues[dropleft]>((maxamplitudes[transition])*asbeat)+movalues[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<movalues.length-1 && movalues[dropright]>((maxamplitudes[transition])*asbeat)+movalues[truncmin[transition]]){dropright++;}
systuserstart[transition]=dropleft;
diastuserend[transition]=dropright;

//Thr10%
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && movalues[dropleft]>((maxamplitudes[transition])*0.1)+movalues[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<movalues.length-1 && movalues[dropright]>((maxamplitudes[transition])*0.1)+movalues[truncmin[transition]]){dropright++;}
syst10start[transition]=dropleft;
diast10end[transition]=dropright;

//Thr50%
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && movalues[dropleft]>((maxamplitudes[transition])*0.5)+movalues[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<movalues.length-1 && movalues[dropright]>((maxamplitudes[transition])*0.5)+movalues[truncmin[transition]]){dropright++;}
syst50start[transition]=dropleft;
diast50end[transition]=dropright;

//Thr90%
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && movalues[dropleft]>((maxamplitudes[transition])*0.9)+movalues[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<movalues.length-1 && movalues[dropright]>((maxamplitudes[transition])*0.9)+movalues[truncmin[transition]]){dropright++;}
syst90start[transition]=dropleft;
diast90end[transition]=dropright;
	
}


// Create Arrays that contain the transition points before and after maxima for the different thresholds ends here


//********** defining necessary constants starts here ********************

ampl=0;

peaktime=0;
peaktimeabs=0;
peaktimeold=0;

peaktime10=0;
peaktime10abs=0;
peaktime10old=0;

peaktime50=0;
peaktime50abs=0;
peaktime50old=0;

peaktime90=0;
peaktime90abs=0;
peaktime90old=0;

systime=0;
systimeabs="";
systimeold=0;

diastime=0;
diastimeabs=0;
diastimeold=0;

systime10=0;
systime10abs="";
systime10old=0;

diastime10=0;
diastime10abs=0;
diastime10old=0;

systime50=0;
systime50abs="";
systime50old=0;

diastime50=0;
diastime50abs=0;
diastime50old=0;

systime90=0;
systime90abs="";
systime90old=0;

diastime90=0;
diastime90abs=0;
diastime90old=0;

sys10=newArray();
sys50=newArray();
sys90=newArray();
sysuser=newArray();

dias10=newArray();
dias50=newArray();
dias90=newArray();
diasuser=newArray();

btime10=newArray();
btime50=newArray();
btime90=newArray();
btimeuser=newArray();


//********** Defining necessary constants ends here ********************

// ************ Printing the headlines starts here ********************


print(" ");

print("Frame #" + "\t" + "Time [sec]" + "\t" + "Amplitude [a.u.]" + "\t" + "Amplitude baselined [a.u.]" + "\t" + "Amplitude baselined normalized [a.u.]" + "\t" + "1st deriv. of amplitude" + "\t" + "Absol. 1st deriv. of amplitude" + "\t" + "Speed [a.u.]" + "\t" + "Speed baselined [a.u.]" + "\t" + "Maxima [a.u.]" + "\t" + "Maxamplitude [a.u]" + "\t" + "Minima [a.u.]" + "\t" + "Since last beat [sec]" + "\t" + "Since last beat abs. time [sec]" + "\t" + "Sum of beats" + "\t" + "User threshold (" + asbeat*100 + "%) [a.u.]" + "\t" + "Peak time user [sec]" + "\t" + "Peak time user absolute [sec]" + "\t" + "Systolic interval (user) [sec]" + "\t" + "Systolic interval (user) absol. [sec]" + "\t" + "Diastolic interval (user) [sec]" + "\t" + "Diastolic interval (user) absol. [sec]" + "\t" + "Thr(10%) [a.u.]" + "\t" + "Peak time Thr(10%) [sec]" + "\t" + "Peak time Thr(10%) absol. [sec]" + "\t" + "Systolic interval Thr(10%) [sec]" + "\t" + "Systolic interval Thr(10%) absol. [sec]" + "\t" + "Diastolic interval Thr(10%) [sec]" + "\t" + "Diastolic interval Thr(10%) absol. [sec]" + "\t" + "Thr(50%) [a.u.]" + "\t" + "Peak time Thr(50%) [sec]" + "\t" + "Peak time Thr(50%) absol. [sec]" + "\t" + "Systolic interval Thr(50%) [sec]" + "\t" + "Systolic interval Thr(50%) absol. [sec]" + "\t" + "Diastolic interval Thr(50%) [sec]" + "\t" + "Diastolic interval Thr(50%) absol. [sec]" + "\t" + "Thr(90%) [a.u.]" + "\t" + "Peak time Thr(90%) [sec]" + "\t" + "Peak time Thr(90%) absol. [sec]" + "\t" + "Systolic interval Thr(90%) [sec]" + "\t" + "Systolic interval Thr(90%) absol. [sec]" + "\t" + "Diastolic interval Thr(90%) [sec]" + "\t" + "Diastolic interval Thr(90%) absol. [sec]");



// ************ Printing the headlines ends here

for (rr=0; rr<movalues.length-1; rr++){

//******************** Calculation of the systoles and diastoles for the thresholds (user, 10, 50 and 90%) starts here *************************


if (rr>systuserstart[ampl] && rr<truncmax[ampl]){
	systime=systime+1/fps; 
	systimeold=systime;
}
 else {systime=0;}

// NEU for Gesamtsystole starts here *****************************************************************
if (rr==truncmax[ampl] && systime==0 && systime<=systimeold){
	systimeabs=systimeold;
	sysuser=Array.concat(sysuser, systimeabs);
	
}
 else {systimeabs="";}
// NEU for Gesamtsystole ends here ******************************************************************* 

if (rr>=truncmax[ampl] && rr<diastuserend[ampl]){
	diastime=diastime+1/fps;
	diastimeold=diastime;

}
 else {diastime=0;}


// NEU for GesamtDIAstole starts here *****************************************************************
 if (diastimeold>diastime){
	diastimeabs=diastimeold;
	diastimeold=0;
        diasuser=Array.concat(diasuser, diastimeabs);
}
 else {diastimeabs="";}
// NEU for GesamtDIAstole ends here ******************************************************************* 


if (rr>syst10start[ampl] && rr<truncmax[ampl]){
	systime10=systime10+1/fps;
	systime10old=systime10;
}
 else {systime10=0;}

// NEU for Gesamtsystole 10 starts here *****************************************************************
if (rr==truncmax[ampl] && systime10==0 && systime10<=systime10old){
	systime10abs=systime10old;
	sys10=Array.concat(sys10, systime10abs);
	
}
 else {systime10abs="";}
// NEU for Gesamtsystole 10 ends here ******************************************************************* 


if (rr>=truncmax[ampl] && rr<diast10end[ampl]){
	diastime10=diastime10+1/fps;
	diastime10old=diastime10;
}
 else {diastime10=0;}


// NEU fuer GesamtDIAstole 10 starts here *****************************************************************
 if (diastime10old>diastime10){
	diastime10abs=diastime10old;
	diastime10old=0;
	dias10=Array.concat(dias10, diastime10abs);
}
 else {diastime10abs="";}
// NEU for GesamtDIAstole 10 ends here ******************************************************************* 

if (rr>syst50start[ampl] && rr<truncmax[ampl]){
	systime50=systime50+1/fps;
	systime50old=systime50;
}
 else {systime50=0;}

// NEU for Gesamtsystole 50 starts here *****************************************************************
if (rr==truncmax[ampl] && systime50==0 && systime50<=systime50old){
	systime50abs=systime50old;
	sys50=Array.concat(sys50, systime50abs);
	
}
 else {systime50abs="";}
// NEU for Gesamtsystole 50 ends here ******************************************************************* 

 
if (rr>1){
if (rr>=truncmax[ampl] && rr<diast50end[ampl]){
	diastime50=diastime50+1/fps;
	diastime50old=diastime50;
}
 else {diastime50=0;}}


// NEU fuer GesamtDIAstole 50 starts here *****************************************************************
 if (diastime50old>diastime50){
	diastime50abs=diastime50old;
	diastime50old=0;
	dias50=Array.concat(dias50, diastime50abs);
}
 else {diastime50abs="";}
// NEU for GesamtDIAstole 50 ends here ******************************************************************* 


if (rr>syst90start[ampl] && rr<truncmax[ampl]){
	systime90=systime90+1/fps;
	systime90old=systime90;
}
 else {systime90=0;}


// NEU for Gesamtsystole 90 starts here *****************************************************************
if (rr==truncmax[ampl] && systime90==0 && systime90<=systime90old){
	systime90abs=systime90old;
	sys90=Array.concat(sys90, systime90abs);
	
}
 else {systime90abs="";}
// NEU for Gesamtsystole 90 ends here ******************************************************************* 


if (rr>1){
if (rr>=truncmax[ampl] && rr<diast90end[ampl]){
	diastime90=diastime90+1/fps;
	diastime90old=diastime90;
}
 else {diastime90=0;}}


// NEU for GesamtDIAstole 90 starts here *****************************************************************
 if (diastime90old>diastime90){
	diastime90abs=diastime90old;
	diastime90old=0;
	dias90=Array.concat(dias90, diastime90abs);
}
 else {diastime90abs="";}
// NEU for GesamtDIAstole 90 ends here ******************************************************************* 


// ************************** Calculation of peak times starts here ***************************


if (diastime>0 || systime>0){
	peaktime=peaktime+1/fps;
	peaktimeold=peaktime;

}
 else {peaktime=0;}

if(systime==(1/fps)){peaktime=(1/fps);}
 

// NEU for Gesamtpeakzeit starts here *****************************************************************

if (peaktimeold>peaktime){
	peaktimeabs=peaktimeold;
	peaktimeold=0;
	btimeuser=Array.concat(btimeuser, peaktimeabs);
}
 else {peaktimeabs="";}

// NEU for Gesamtpeakzeit ends here ******************************************************************* 



if (diastime10>0 || systime10>0){
	peaktime10=peaktime10+1/fps;
	peaktime10old=peaktime10;
}
 else {peaktime10=0;}

if(systime10==(1/fps)){peaktime10=(1/fps);}

// NEU for Gesamtpeakzeit 10 starts here *****************************************************************

if (peaktime10old>peaktime10){
	peaktime10abs=peaktime10old;
	peaktime10old=0;
	btime10=Array.concat(btime10, peaktime10abs);
}
 else {peaktime10abs="";}

// NEU for Gesamtpeakzeit 10 ends here ******************************************************************* 


if (diastime50>0 || systime50>0){
	peaktime50=peaktime50+1/fps;
	peaktime50old=peaktime50;
}
 else {peaktime50=0;}

if(systime50==(1/fps)){peaktime50=(1/fps);}

// NEU for Gesamtpeakzeit 50 starts here *****************************************************************

if (peaktime50old>peaktime50){
	peaktime50abs=peaktime50old;
	peaktime50old=0;
	btime50=Array.concat(btime50, peaktime50abs);
}
 else {peaktime50abs="";}

// NEU for Gesamtpeakzeit 50 ends here ******************************************************************* 


if (diastime90>0 || systime90>0){
	peaktime90=peaktime90+1/fps;
	peaktime90old=peaktime90;
}
 else {peaktime90=0;}

if(systime90==(1/fps)){peaktime90=(1/fps);}

 // NEU for Gesamtpeakzeit 90 starts here *****************************************************************

if (peaktime90old>peaktime90){
	peaktime90abs=peaktime90old;
	peaktime90old=0;
	btime90=Array.concat(btime90, peaktime90abs);
}
 else {peaktime90abs="";}

// NEU for Gesamtpeakzeit 90 ends here ******************************************************************* 


// ************************** Calculation of peak times ends here ***************************


//******************** Calculation of the systoles and diastoles for the thresholds (user, 10, 50 and 90%) ends here *************************

btimeold=btimea;
btimea=btimea+(1/fps);


if (systimeabs==0) {
systimeabs="";
}


if (systime10abs==0) {
systime10abs="";
}


if (systime50abs==0) {
systime50abs="";
}


if (systime90abs==0) {
systime90abs="";
}


if(minima[min]==rr) {
print((rr+1) + "\t" + rr/fps + "\t" + movalues[rr] + "\t" + movalues[rr]-pmin + "\t" + (movalues[rr]-pmin)/(pmax-pmin) + "\t" + (movalues[rr+1]-movalues[rr]) + "\t"  + abs((movalues[rr+1]-movalues[rr])) + "\t" + values[rr] + "\t" + (values[rr]-speedmin) + "\t" + "0" + "\t" + "\t" + round(pmax+1) + "\t" + btimea + "\t" + "\t" + "\t" + (movalues[truncmin[ampl]]+(threshold*maxamplitudes[ampl])) + "\t" + peaktime + "\t" + peaktimeabs + "\t" + systime + "\t" + systimeabs + "\t" + diastime + "\t" + diastimeabs + "\t" + (movalues[truncmin[ampl]]+(thresh10*maxamplitudes[ampl])) + "\t" + peaktime10 + "\t" + peaktime10abs + "\t" + systime10 + "\t" + systime10abs + "\t" + diastime10 + "\t" + diastime10abs + "\t" + (movalues[truncmin[ampl]]+(thresh50*maxamplitudes[ampl])) + "\t" + peaktime50 + "\t" + peaktime50abs + "\t" + systime50 + "\t" + systime50abs + "\t" + diastime50 + "\t" + diastime50abs + "\t" + (movalues[truncmin[ampl]]+(thresh90*maxamplitudes[ampl])) + "\t" + peaktime90 + "\t" + peaktime90abs + "\t" + systime90 + "\t" + systime90abs + "\t" + diastime90 + "\t" + diastime90abs);


min=min+1;
if (min>minima.length-1){
	min=minima.length-1;
}

} else if (maxima[max]==rr) {
spacer="";
if (rr==0){btimea=0; spacer=0;}
print((rr+1) + "\t" + rr/fps + "\t" + movalues[rr] + "\t" + movalues[rr]-pmin + "\t" + (movalues[rr]-pmin)/(pmax-pmin) + "\t" + (movalues[rr+1]-movalues[rr]) + "\t" + abs((movalues[rr+1]-movalues[rr])) + "\t" + values[rr] + "\t" + (values[rr]-speedmin) + "\t" + round(pmax+1) + "\t" + maxamplitudes[ampl] + "\t" + "0" + "\t" + btimea + "\t" +spacer+ "\t"+ beats + "\t" + (movalues[truncmin[ampl]]+(threshold*maxamplitudes[ampl])) + "\t" + peaktime + "\t" + peaktimeabs + "\t" +  systime + "\t" + systimeabs + "\t" + diastime + "\t" + diastimeabs + "\t" + (movalues[truncmin[ampl]]+(thresh10*maxamplitudes[ampl])) + "\t" + peaktime10 + "\t" + peaktime10abs + "\t" + systime10 + "\t" + systime10abs + "\t" + diastime10 + "\t" + diastime10abs + "\t" + (movalues[truncmin[ampl]]+(thresh50*maxamplitudes[ampl])) + "\t" + peaktime50 + "\t" + peaktime50abs + "\t" + systime50 + "\t" + systime50abs + "\t" + diastime50 + "\t" + diastime50abs + "\t" + (movalues[truncmin[ampl]]+(thresh90*maxamplitudes[ampl])) + "\t" + peaktime90 + "\t" + peaktime90abs + "\t" + systime90 + "\t" + systime90abs + "\t" + diastime90 + "\t" + diastime90abs);
beattimes=Array.concat(beattimes,btimea);
btimea=0;
beats=beats+1;
max=max+1;
if (max>maxima.length-1){
	max=maxima.length-1;
}

} else {
print((rr+1) + "\t" + rr/fps + "\t" + movalues[rr] + "\t" + movalues[rr]-pmin + "\t" + (movalues[rr]-pmin)/(pmax-pmin) + "\t" + (movalues[rr+1]-movalues[rr]) + "\t" + abs((movalues[rr+1]-movalues[rr])) + "\t" + values[rr] + "\t" + (values[rr]-speedmin) + "\t" + "0" + "\t" + "\t" + "0" + "\t" + btimea + "\t" + btimeabs + "\t" + "\t"  + (movalues[truncmin[ampl]]+(threshold*maxamplitudes[ampl])) + "\t"  + peaktime + "\t" + peaktimeabs + "\t" + systime + "\t" + systimeabs + "\t" + diastime + "\t" + diastimeabs + "\t" + (movalues[truncmin[ampl]]+(thresh10*maxamplitudes[ampl])) + "\t" + peaktime10 + "\t" + peaktime10abs + "\t" + systime10 + "\t" + systime10abs + "\t" + diastime10 + "\t" + diastime10abs + "\t" + (movalues[truncmin[ampl]]+(thresh50*maxamplitudes[ampl])) + "\t" + peaktime50 + "\t" + peaktime50abs + "\t" + systime50 + "\t" + systime50abs + "\t" + diastime50 + "\t" + diastime50abs + "\t" + (movalues[truncmin[ampl]]+(thresh90*maxamplitudes[ampl])) + "\t" + peaktime90 + "\t" + peaktime90abs + "\t" + systime90 + "\t" + systime90abs + "\t" + diastime90 + "\t" + diastime90abs);
}

if (rr<movalues.length && ampl<truncmax.length-1){
	
if   (rr>=(truncmin[ampl+1])) {

	ampl=ampl+1;

}
}

// NEU for GesamtBeatzeit starts here *****************************************************************
 if (btimeold>btimea){
	btimeabs=btimeold+1/fps;
	btimeold=0;
}
 else {btimeabs="";}
// NEU for GesamtBeatzeit ends here ******************************************************************* 

}


// ****************** Getting statistics from the arrays starts here *********************************

Array.getStatistics(beattimes, beattimesmin, beattimesmax, beattimesmean, beattimesstdDev);
Array.getStatistics(maxamplitudes, maxamplitudesmin, maxamplitudesmax, maxamplitudesmean, maxamplitudesstd);

Array.getStatistics(btimeuser, btimeusermin, btimeusermax, btimeusermean, btimeuserstd);
Array.getStatistics(btime10, btime10min, btime10max, btime10mean, btime10std);
Array.getStatistics(btime50, btime50min, btime50max, btime50mean, btime50std);
Array.getStatistics(btime90, btime90min, btime90max, btime90mean, btime90std);

Array.getStatistics(sysuser, sysusermin, sysusermax, sysusermean, sysuserstd);
Array.getStatistics(sys10, sys10min, sys10max, sys10mean, sys10std);
Array.getStatistics(sys50, sys50min, sys50max, sys50mean, sys50std);
Array.getStatistics(sys90, sys90min, sys90max, sys90mean, sys90std);

Array.getStatistics(diasuser, diasusermin, diasusermax, diasusermean, diasuserstd);
Array.getStatistics(dias10, dias10min, dias10max, dias10mean, dias10std);
Array.getStatistics(dias50, dias50min, dias50max, dias50mean, dias50std);
Array.getStatistics(dias90, dias90min, dias90max, dias90mean, dias90std);

frequencies=Array.copy(beattimes);
frequencies=Array.deleteValue(frequencies,0);

for (freq = 0; freq < frequencies.length; freq++) {
frequencies[freq]=1/frequencies[freq];	
}

Array.getStatistics(frequencies, freqmin, freqmax, freqmean, freqstd);


// ****************** Getting statistics from the arrays ends here **********************


// **************** Printing the final statistics with the first and last events starts here ******************

print(" ");
print("Statistics INCLUDING the first and last event");
print(" ");

print("Beats counted: " + "\t" + maxima.length);
print(" ");

print("\t" + "Min" + "\t" + "Max" + "\t" + "Mean" + "\t" + "StdDev");

print("Beattimes [sec]" + "\t" + beattimesmin + "\t" + beattimesmax + "\t" + beattimesmean + "\t" + beattimesstdDev);
print("Frequency [1/sec]" + "\t" + freqmin + "\t" + freqmax + "\t" + freqmean + "\t" + freqstd);

print("Amplitudes [a.u.] " + "\t" + maxamplitudesmin + "\t" + maxamplitudesmax + "\t" + maxamplitudesmean + "\t" + maxamplitudesstd);

print("Peaktimes user [sec] " + "\t" + btimeusermin + "\t" + btimeusermax + "\t" + btimeusermean + "\t" + btimeuserstd);
print("Systoles user [sec] " + "\t" + sysusermin + "\t" + sysusermax + "\t" + sysusermean + "\t" + sysuserstd);
print("Diastoles user [sec] " + "\t" + diasusermin + "\t" + diasusermax + "\t" + diasusermean + "\t" + diasuserstd);

print("Peaktimes Thr10% [sec]" + "\t" + btime10min + "\t" + btime10max + "\t" + btime10mean + "\t" + btime10std);
print("Systoles Thr10% [sec] " + "\t" + sys10min + "\t" + sys10max + "\t" + sys10mean + "\t" + sys10std);
print("Diastoles Thr10% [sec] " + "\t" + dias10min + "\t" + dias10max + "\t" + dias10mean + "\t" + dias10std);

print("Peaktimes Thr50% [sec]" + "\t" + btime50min + "\t" + btime50max + "\t" + btime50mean + "\t" + btime50std);
print("Systoles Thr50% [sec] " + "\t" + sys50min + "\t" + sys50max + "\t" + sys50mean + "\t" + sys50std);
print("Diastoles Thr50% [sec] " + "\t" + dias50min + "\t" + dias50max + "\t" + dias50mean + "\t" + dias50std);

print("Peaktimes Thr90% [sec]" + "\t" + btime90min + "\t" + btime90max + "\t" + btime90mean + "\t" + btime90std);
print("Systoles Thr90% [sec] " + "\t" + sys90min + "\t" + sys90max + "\t" + sys90mean + "\t" + sys90std);
print("Diastoles Thr90% [sec] " + "\t" + dias90min + "\t" + dias90max + "\t" + dias90mean + "\t" + dias90std);

print(" ");
print("Ratios:");
print(" ");
print("Systole/diastole [user] mean:" + "\t" + sysusermean/diasusermean);
print("Systole/diastole [Thr10%] mean:" + "\t" + sys10mean/dias10mean);
print("Systole/diastole [Thr50%] mean:" + "\t" + sys50mean/dias50mean);
print("Systole/diastole [Thr90%] mean:" + "\t" + sys90mean/dias90mean);
print(" ");
print("Amplitude mean/systole [user] mean:" + "\t" + maxamplitudesmean/sysusermean);
print("Amplitude mean/systole [Thr10%] mean:" + "\t" + maxamplitudesmean/sys10mean);
print("Amplitude mean/systole [Thr50%] mean:" + "\t" + maxamplitudesmean/sys50mean);
print("Amplitude mean/systole [Thr90%] mean:" + "\t" + maxamplitudesmean/sys90mean);
print(" ");
print("Amplitude mean/diastole [user] mean:" + "\t" + maxamplitudesmean/diasusermean);
print("Amplitude mean/diastole [Thr10%] mean:" + "\t" + maxamplitudesmean/dias10mean);
print("Amplitude mean/diastole [Thr50%] mean:" + "\t" + maxamplitudesmean/dias50mean);
print("Amplitude mean/diastole [Thr90%] mean:" + "\t" + maxamplitudesmean/dias90mean);
print(" ");
print("Amplitude mean/peaktime [user] mean:" + "\t" + maxamplitudesmean/btimeusermean);
print("Amplitude mean/peaktime [Thr10%] mean:" + "\t" + maxamplitudesmean/btime10mean);
print("Amplitude mean/peaktime [Thr50%] mean:" + "\t" + maxamplitudesmean/btime50mean);
print("Amplitude mean/peaktime [Thr90%] mean:" + "\t" + maxamplitudesmean/btime90mean);


// **************** Printing the final statistics with the first and last events ends here ******************


// **************** Printing the final statistics WITHOUT the first and last events starts here ******************


beattimesshort=Array.slice(beattimes, 1,beattimes.length-1);
maxamplitudesshort=Array.slice(maxamplitudes, 1,maxamplitudes.length-1);

btimeusershort=Array.slice(btimeuser, 1, btimeuser.length-1);
btime10short=Array.slice(btime10, 1, btime10.length-1);
btime50short=Array.slice(btime50, 1, btime50.length-1);
btime90short=Array.slice(btime90, 1, btime90.length-1);

sysusershort=Array.slice(sysuser, 1,sysuser.length-1);
sys10short=Array.slice(sys10, 1, sys10.length-1);
sys50short=Array.slice(sys50, 1, sys50.length-1);
sys90short=Array.slice(sys90, 1, sys90.length-1);


diasusershort=Array.slice(diasuser, 1, diasuser.length-1);
dias10short=Array.slice(dias10, 1, dias10.length-1);
dias50short=Array.slice(dias50, 1, dias50.length-1);
dias90short=Array.slice(dias90, 1, dias90.length-1);


Array.getStatistics(beattimesshort, beattimesshortmin, beattimesshortmax, beattimesshortmean, beattimesshortstdDev);
Array.getStatistics(maxamplitudesshort, maxamplitudesshortmin, maxamplitudesshortmax, maxamplitudesshortmean, maxamplitudesshortstd);

Array.getStatistics(btimeusershort, btimeusershortmin, btimeusershortmax, btimeusershortmean, btimeusershortstd);
Array.getStatistics(btime10short, btime10shortmin, btime10shortmax, btime10shortmean, btime10shortstd);
Array.getStatistics(btime50short, btime50shortmin, btime50shortmax, btime50shortmean, btime50shortstd);
Array.getStatistics(btime90short, btime90shortmin, btime90shortmax, btime90shortmean, btime90shortstd);

Array.getStatistics(sysusershort, sysusershortmin, sysusershortmax, sysusershortmean, sysusershortstd);
Array.getStatistics(sys10short, sys10shortmin, sys10shortmax, sys10shortmean, sys10shortstd);
Array.getStatistics(sys50short, sys50shortmin, sys50shortmax, sys50shortmean, sys50shortstd);
Array.getStatistics(sys90short, sys90shortmin, sys90shortmax, sys90shortmean, sys90shortstd);

Array.getStatistics(diasusershort, diasusershortmin, diasusershortmax, diasusershortmean, diasusershortstd);
Array.getStatistics(dias10short, dias10shortmin, dias10shortmax, dias10shortmean, dias10shortstd);
Array.getStatistics(dias50short, dias50shortmin, dias50shortmax, dias50shortmean, dias50shortstd);
Array.getStatistics(dias90short, dias90shortmin, dias90shortmax, dias90shortmean, dias90shortstd);


frequenciesshort=Array.copy(beattimesshort);
for (freqshort = 0; freqshort < frequenciesshort.length; freqshort++) {
frequenciesshort[freqshort]=1/frequenciesshort[freqshort];	
}

Array.getStatistics(frequenciesshort, freqshortmin, freqshortmax, freqshortmean, freqshortstd);
print(" ");
print("Statistics WITHOUT the first and last event");
print(" ");

print("Beats counted: " + "\t" + maxima.length-2);
print(" ");

print("\t" + "Min" + "\t" + "Max" + "\t" + "Mean" + "\t" + "StdDev");

print("Beattimes [sec]" + "\t" + beattimesshortmin + "\t" + beattimesshortmax + "\t" + beattimesshortmean + "\t" + beattimesshortstdDev);
print("Frequency [1/sec]" + "\t" + freqshortmin + "\t" + freqshortmax + "\t" + freqshortmean + "\t" + freqshortstd);

print("Amplitudes [a.u.] " + "\t" + maxamplitudesshortmin + "\t" + maxamplitudesshortmax + "\t" + maxamplitudesshortmean + "\t" + maxamplitudesshortstd);

print("Peaktimes user [sec] " + "\t" + btimeusershortmin + "\t" + btimeusershortmax + "\t" + btimeusershortmean + "\t" + btimeusershortstd);
print("Systoles user [sec] " + "\t" + sysusershortmin + "\t" + sysusershortmax + "\t" + sysusershortmean + "\t" + sysusershortstd);
print("Diastoles user [sec] " + "\t" + diasusershortmin + "\t" + diasusershortmax + "\t" + diasusershortmean + "\t" + diasusershortstd);

print("Peaktimes Thr10% [sec]" + "\t" + btime10shortmin + "\t" + btime10shortmax + "\t" + btime10shortmean + "\t" + btime10shortstd);
print("Systoles Thr10% [sec] " + "\t" + sys10shortmin + "\t" + sys10shortmax + "\t" + sys10shortmean + "\t" + sys10shortstd);
print("Diastoles Thr10% [sec] " + "\t" + dias10shortmin + "\t" + dias10shortmax + "\t" + dias10shortmean + "\t" + dias10shortstd);

print("Peaktimes Thr50% [sec]" + "\t" + btime50shortmin + "\t" + btime50shortmax + "\t" + btime50shortmean + "\t" + btime50shortstd);
print("Systoles Thr50% [sec] " + "\t" + sys50shortmin + "\t" + sys50shortmax + "\t" + sys50shortmean + "\t" + sys50shortstd);
print("Diastoles Thr50% [sec] " + "\t" + dias50shortmin + "\t" + dias50shortmax + "\t" + dias50shortmean + "\t" + dias50shortstd);

print("Peaktimes Thr90% [sec]" + "\t" + btime90shortmin + "\t" + btime90shortmax + "\t" + btime90shortmean + "\t" + btime90shortstd);
print("Systoles Thr90% [sec] " + "\t" + sys90shortmin + "\t" + sys90shortmax + "\t" + sys90shortmean + "\t" + sys90shortstd);
print("Diastoles Thr90% [sec] " + "\t" + dias90shortmin + "\t" + dias90shortmax + "\t" + dias90shortmean + "\t" + dias90shortstd);

print(" ");
print("Ratios:");
print(" ");
print("Systole/diastole [user] mean:" + "\t" + sysusershortmean/diasusermean);
print("Systole/diastole [Thr10%] mean:" + "\t" + sys10shortmean/dias10shortmean);
print("Systole/diastole [Thr50%] mean:" + "\t" + sys50shortmean/dias50shortmean);
print("Systole/diastole [Thr90%] mean:" + "\t" + sys90shortmean/dias90shortmean);
print(" ");
print("Amplitude mean/systole [user] mean:" + "\t" + maxamplitudesshortmean/sysusershortmean);
print("Amplitude mean/systole [Thr10%] mean:" + "\t" + maxamplitudesshortmean/sys10shortmean);
print("Amplitude mean/systole [Thr50%] mean:" + "\t" + maxamplitudesshortmean/sys50shortmean);
print("Amplitude mean/systole [Thr90%] mean:" + "\t" + maxamplitudesshortmean/sys90shortmean);
print(" ");
print("Amplitude mean/diastole [user] mean:" + "\t" + maxamplitudesshortmean/diasusershortmean);
print("Amplitude mean/diastole [Thr10%] mean:" + "\t" + maxamplitudesshortmean/dias10shortmean);
print("Amplitude mean/diastole [Thr50%] mean:" + "\t" + maxamplitudesshortmean/dias50shortmean);
print("Amplitude mean/diastole [Thr90%] mean:" + "\t" + maxamplitudesshortmean/dias90shortmean);
print(" ");
print("Amplitude mean/peaktime [user] mean:" + "\t" + maxamplitudesshortmean/btimeusershortmean);
print("Amplitude mean/peaktime [Thr10%] mean:" + "\t" + maxamplitudesshortmean/btime10shortmean);
print("Amplitude mean/peaktime [Thr50%] mean:" + "\t" + maxamplitudesshortmean/btime50shortmean);
print("Amplitude mean/peaktime [Thr90%] mean:" + "\t" + maxamplitudesshortmean/btime90shortmean);
print(" ");

if (forceframe==true){
print("Ref. Frame forced: " + lowfrm);
}

if (forceframe==false){
print("Reference Frame: " + "\t" + lowfrm);
}


print("Framerate [1/s]:" + "\t" + fps);


// **************** Printing the final statistics WITHOUT the first and last events ends here ******************



//******************************Printing the analyzed data from the array ends here ****************************


//******************************Plotting the analyzed data starts here ************************************


allminima=newArray(movalues.length);
allmaxima=newArray(movalues.length);

Array.fill(allminima, 0);
Array.fill(allmaxima, 0);

for (allmax=0; allmax<maxima.length; allmax++){
	allmaxima[maxima[allmax]]=round(pmax+1);
	}


for (allmin=0; allmin<minima.length; allmin++){
	allminima[minima[allmin]]=round(pmax+1);
	}


times=newArray(movalues.length);

for (tt=0; tt<movalues.length; tt++) {
times[tt]=tt/fps;
}


print(" \n");
print(" \n");


wdh=20*slicenumber;

if (wdh>8000){
wdh=8000;
}


run("Profile Plot Options...", "width=wdh height=700 font=20 minimum=0 maximum=0 draw draw_ticks interpolate sub-pixel");

shortname=replace(baseName, "-diff", "");

Plot.create(shortname, "Time [sec]", "Amplitude [a.u.]", times, movalues);
setJustification("center");

Plot.addText(shortname, 0.5, 0);
Plot.addText("Amplitude (black); ", 0.1, 0);
Plot.addText("Maxima (red); ", 0.2, 0);
Plot.addText("Minima (green); ", 0.3, 0);
Plot.setColor("red"); 
Plot.add("line", times, allmaxima);
Plot.setColor("green");
Plot.add("line", times, allminima);
Plot.setColor("black");


Plot.show();
Plot.makeHighResolution(shortname, 5.0, "enable");
saveAs("Jpeg", dataDir+shortname+"-plot large.jpg");
close();


run("Profile Plot Options...", "width=1920 height=700 font=12 minimum=0 maximum=0 draw draw_ticks interpolate sub-pixel");
Plot.create(shortname, "Time [sec]", "Amplitude [a.u.]", times, movalues);

setJustification("center");

Plot.addText(shortname, 0.60, 0);
Plot.addText("Amplitude (black); ", 0.1, 0);
Plot.addText("Maxima (red); ", 0.27, 0);
Plot.addText("Minima (green); ", 0.42, 0);
Plot.setColor("red"); 
Plot.add("line", times, allmaxima);
Plot.setColor("green");
Plot.add("line", times, allminima);
Plot.setColor("black");

Plot.update();
Plot.makeHighResolution(shortname, 1.6, "enable");
saveAs("Jpeg", dataDir+shortname+"-plot small.jpg");
close();


//********************************* Plot Animation starts here, if the user selected it, cell is displayed synchronized with its amplitude **********************************

//****************************** The amplitude-plot is produced step by step and the isolated cell is merged with the according image until the whole video is finished **********************


if (vidout==true){

shortname=replace(baseName, "-diff", "");

Array.getStatistics(movalues, min, max, mean, std);

run("Profile Plot Options...", "width=1920 height=800 font=20 minimum=0 maximum="+round(max+1)+" draw draw_ticks interpolate sub-pixel");

for (p=1; p<slicenumber; p++){

Plot.create(shortname, "Time [sec]", "Amplitude [a.u.]", times, movalues);
Plot.setLimits((150/fps)+p/fps-(1/fps)-(150/fps), p/fps-(150/fps), 0, round(max+1));
setJustification("center");
Plot.addText(shortname, 0.5, 0.05);

Plot.update();

if (p==1) {
run("Duplicate...", "title=Plotanimated");
getDimensions(width, height, channels, slices, frames); 
w=width;
h=height;
}

setBatchMode(true);

selectWindow(shortname);

run("Duplicate...", " ");
run("Size...", "width=w height=h constrain average interpolation=Bilinear");
run("Copy");
run("Close");
selectWindow("Plotanimated");
run("Add Slice");
run("Paste");

}

setBatchMode(false);

selectWindow("Plotanimated");
setSlice(1);
run("Delete Slice");
run("Delete Slice");

open(isolDir+baseName+"-isolated"+filetype);

getDimensions(width, height, channels, slices, frames);

if (width>400){
run("Size...", "width=400 height=500 constrain average interpolation=Bilinear");
}

if ((width/height)>1.8) {
run("Rotate 90 Degrees Left");
}

selectWindow(baseName+"-isolated"+filetype);
setSlice(1);
run("Delete Slice");

run("Combine...", "stack1=["+baseName+"-isolated"+filetype+"]"+" stack2=Plotanimated");


selectWindow("Combined Stacks");

setSlice(nSlices);
run("Delete Slice");

run("AVI... ", "compression=JPEG frame=25 save=["+dataDir+shortname+" animated (25fps)"+filetype+"]");

}

// ************************** Plot animation ends here ******************************


// ****************************** Plotting the analyzed data ends here ************************************


// *********************************** Store the amplitudes as arrays for further processing starts here ******************************


movalues=Array.trim(movalues, movalues.length-1);

mostr="amplitudes=newArray(";

for (most=0; most<movalues.length; most++) {
if(most<movalues.length-1) {mostr=mostr + movalues[most] + ",";}
if(most==movalues.length-1) {mostr=mostr + movalues[most];}
}

mostr=mostr+");";

if (isOpen("Ampltudes")==false) {

amplwinname = "[Ampltudes]";
  run("New... ", "name=" + amplwinname + " type=Table");
  
}


print(amplwinname, baseName);

print(amplwinname, " ");

print(amplwinname, mostr);

print(amplwinname, " ");



// *********************************** Store the amplitudes as arrays for further processing ends here *****************************



while (nImages>0) { 
          selectImage(nImages); 
          close(); 
}


}
}


// **************************** Automatic plotting of the data ends here ***********************************


//*************************** Saving the extracted data starts here, setings, date, time and ImageJ-version are atttached ***********************************


dest=dataDir+"Results "+year+"-"+MonthNames[month]+"-"+dayOfMonths+"-"+hours+"h"+minutes+".txt";
dest2=dataDir+"Amplitudes only "+year+"-"+MonthNames[month]+"-"+dayOfMonths+"-"+hours+"h"+minutes+".txt";

selectWindow("Log");

print("***** Settings *****");
print(" \n");

if(batching==false){
print("Lower threshold:" + "\t" + thrslow);
print("Cellsize:" + "\t" + cellsize);
}


if(batching==true){
print("Batch List:");
print("Filename" + "\t" + "Size" + "\t" + "Threshold");

for (lst = 0; lst < batchsample.length; lst++) {
print(batchsample[lst] + "\t" + batchsize[lst] + "\t" + batchthr[lst]);	
}

print(" \n");
}


print("[%] of Max recognized as beat:" + "\t" + asbeat*100);
print("Detection:" + "\t" + detection);
print("ImageJ-version:" + "\t" + getVersion());


if (smoother==true) {
print("Smoothing WAS applied");
}

if (smoother==false) {
print("NO smoothing applied");
}

print("Evaluation date and time:" + "\t" + year + "-" + MonthNames[month] + "-" + dayOfMonths + "-" + hours + "h" + minutes);

saveAs("Text", dest); 

selectWindow("Ampltudes");
saveAs("Text", dest2);





// *************************** Saving the plotted data ends here *********************************



// ********************** This closes the remaining open windows (if they are open at all) ***********************



if (isOpen("Ampltudes")) {
selectWindow("Ampltudes");
run("Close");
}


if (isOpen("B&C")) {
     selectWindow("B&C");
     run("Close");
}


if (isOpen("baseName*")) {
     selectWindow("baseName*");
     run("Close");
}


if (isOpen("Results")) {
     selectWindow("Results");
     run("Close");
}


if (isOpen("Log")) {
     selectWindow("Log");
     run("Close");
}


if (isOpen("ROI Manager")) {
     selectWindow("ROI Manager");
     run("Close");
}


if (isOpen("Summary")) {
     selectWindow("Summary");
     run("Close");
}


//********************** End of closing possible opened windows **************


}  


// **************** Evaluation ends here ****************************



//******************** Re-Evaluation starts here, extract the filenames and put the according amplitudes into an array for re-processing of the data *********************


if (option == "5. Re-Evaluation") {


pathfile=File.openDialog("Please choose the <Amplitudes only.txt> file to be opened:");
data=File.openAsString(pathfile);
print(pathfile);
print("");

//***************** extract path from opened file start here ************************

strt=lastIndexOf(pathfile, "\\");
rmve=substring(pathfile, strt+1, lengthOf(pathfile)); 
dir=replace(pathfile, rmve, "");
rmve=replace(rmve, ".txt", "");

//***************** extract path from opened file ends here ************************


titles=newArray();
amplits=newArray();

lines=split(data,"\n");


//************** is it an amplitudes Only file, check starts here
ampltest="false";
atest=0;
while(ampltest=="false" && atest<lines.length){if(indexOf(lines[atest], "amplitudes=newArray(")<0){ampltest="false";}else{ampltest="true";}{atest++;}}
if (ampltest=="false") {exit("Sorry, but this seems not to be an" + "\n" + "<Amplitudes only>-File." + "\n" + "Please choose one.");}

//**************** is it an amplitudes only file, check ends here


count=0;
for (i = 0; i < lines.length; i+=4) {
titles=Array.concat(titles,lines[i]);	
count++;
}

count=0;
for (i = 2; i < lines.length; i+=4) {
amplits=Array.concat(amplits,lines[i]);	
count++;
}


for (runs = 0; runs < 500000; runs++) {
	


// ******************************* Please apply your settings here; you may also change the default-values *******************************

if (runs==0) {

Dialog.create("Please apply your parameters");

Dialog.addNumber("Detection", 20);
Dialog.addNumber("Threshold 1 [%]", 10);
Dialog.addNumber("Threshold 2 [%]", 20);
Dialog.addNumber("Threshold 3 [%]", 50);
Dialog.addNumber("Threshold 4 [%]", 90);
Dialog.addNumber("Framerate  [fps]", 120);

Dialog.show();
detection=Dialog.getNumber();
thresh0=Dialog.getNumber()/100;
thresh1=Dialog.getNumber()/100;
thresh2=Dialog.getNumber()/100;
thresh3=Dialog.getNumber()/100;
fps=Dialog.getNumber();

if(detection<1.1){detection=1.1;}

print("Applied Threshold 1: " + thresh0*100 + "%");
print("Applied Threshold 2: " + thresh1*100 + "%");
print("Applied Threshold 3: " + thresh2*100 + "%");
print("Applied Threshold 4: " + thresh3*100 + "%");
print("Applied Framerate: " + fps);
print("Applied Detection: " + detection);

}

// ******************************* Mark the previous settings starts here, settings are remembered for the next evaluation *******************************

if (runs>0) {
	
Dialog.create("Please apply your parameters");

Dialog.addNumber("Detection", detection);
Dialog.addNumber("Threshold 1 [%]", thresh0*100);
Dialog.addNumber("Threshold 2 [%]", thresh1*100);
Dialog.addNumber("Threshold 3 [%]", thresh2*100);
Dialog.addNumber("Threshold 4 [%]", thresh3*100);
Dialog.addNumber("Framerate  [fps]", fps);

Dialog.show();
detection=Dialog.getNumber();
thresh0=Dialog.getNumber()/100;
thresh1=Dialog.getNumber()/100;
thresh2=Dialog.getNumber()/100;
thresh3=Dialog.getNumber()/100;
fps=Dialog.getNumber();

if(detection<1.1){detection=1.1;}

print("Applied Threshold 1: " + thresh0*100 + "%");
print("Applied Threshold 2: " + thresh1*100 + "%");
print("Applied Threshold 3: " + thresh2*100 + "%");
print("Applied Threshold 4: " + thresh3*100 + "%");
print("Applied Framerate: " + fps);
print("Applied Detection: " + detection);

}

// ******************************* Mark the previous settings ends here *******************************

// ****************************************************** End of user-settings *******************************************



//************** Select your data and convert it into an array for further evaluation starts here **************


Dialog.create("Select your data");
Dialog.addChoice("Please select:", titles);
Dialog.show();
option=Dialog.getChoice();

print("");
print("Selected data: " + option);
print("");

elmt=0;
while (option!=titles[elmt]) {elmt++;}

amplitudes=amplits[elmt];
amplitudes=replace(amplitudes, "amplitudes=newArray", "");
amplitudes=replace(amplitudes, "\\);", "");
amplitudes=replace(amplitudes, "\\(", "");
amplitudes=split(amplitudes, ",");


for (pf=0; pf<amplitudes.length; pf++) {
aa=parseFloat(amplitudes[pf]);
amplitudes[pf]=aa;
}


//*************** Select your data and convert it into an array for further evaluation ends here ******************

// ************ Here, Re-evaluation of the data with the applied parameters starts ********************


Array.getStatistics(amplitudes, pmin, pmax, pmean, pstdDev);

maxima=Array.findMaxima(amplitudes, (pmax-pmin)/detection);
minima=Array.findMinima(amplitudes, (pmax-pmin)/detection);
Array.sort(maxima);
Array.sort(minima);

min=0;
max=0;
beats=1;
btimea=0;
btimeabs="";
btimeold=0;
beattimes=newArray();
threshold=thresh0;



//*************** Here, all the minima are paired with the according (following) maxima and the amplitudes are calculated **************************** 


truncmin=Array.copy(minima);
truncmax=Array.copy(maxima);


if (truncmax[0]<truncmin[0]){
truncmax=Array.slice(truncmax,1,truncmax.length);
}

Array.getStatistics(amplitudes, pmin, pmax, pmean, pstdDev);

maxima=Array.findMaxima(amplitudes, (pmax-pmin)/detection);
minima=Array.findMinima(amplitudes, (pmax-pmin)/detection);
Array.sort(maxima);
Array.sort(minima);

min=0;
max=0;
beats=1;
btimea=0;
btimeabs="";
btimeold=0;
beattimes=newArray();
threshold=thresh0;



//*************** Here, all the minima are paired with the according (following) maxima and the amplitudes are calculated **************************** 


truncmin=Array.copy(minima);
truncmax=Array.copy(maxima);


if (truncmax[0]<truncmin[0]){
truncmax=Array.slice(truncmax,1,truncmax.length);
}


if(truncmax.length>truncmin.length){
	truncmax=Array.slice(truncmax,0,truncmin.length);
}

if(truncmax.length<truncmin.length){
	truncmin=Array.slice(truncmin,0,truncmax.length);
}


maxamplitudes=newArray(truncmax.length);

for (www=0; www<truncmax.length; www++){
	maxamplitudes[www]=amplitudes[truncmax[www]]-amplitudes[truncmin[www]];
}

//********************* Printing of the data starts here *******************

// Create Arrays that contain the transition points before and after maxima for the different thresholds starts here

systuserstart=newArray(truncmax.length);
diastuserend=newArray(truncmax.length);

syst10start=newArray(truncmax.length);
diast10end=newArray(truncmax.length);

syst50start=newArray(truncmax.length);
diast50end=newArray(truncmax.length);

syst90start=newArray(truncmax.length);
diast90end=newArray(truncmax.length);


for (transition = 0; transition < truncmax.length; transition++) {

//amplitudes[truncmin[ampl]]+(thresh10*maxamplitudes[ampl]

//thresh0
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && amplitudes[dropleft]>((maxamplitudes[transition])*thresh0)+amplitudes[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<amplitudes.length-1 && amplitudes[dropright]>((maxamplitudes[transition])*thresh0)+amplitudes[truncmin[transition]]){dropright++;}
systuserstart[transition]=dropleft;
diastuserend[transition]=dropright;

//thresh1
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && amplitudes[dropleft]>((maxamplitudes[transition])*thresh1)+amplitudes[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<amplitudes.length-1 && amplitudes[dropright]>((maxamplitudes[transition])*thresh1)+amplitudes[truncmin[transition]]){dropright++;}
syst10start[transition]=dropleft;
diast10end[transition]=dropright;


//thresh2
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && amplitudes[dropleft]>((maxamplitudes[transition])*thresh2)+amplitudes[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<amplitudes.length-1 && amplitudes[dropright]>((maxamplitudes[transition])*thresh2)+amplitudes[truncmin[transition]]){dropright++;}
syst50start[transition]=dropleft;
diast50end[transition]=dropright;

//thresh3
dropleft=truncmax[transition];
dropright=truncmax[transition];
while(dropleft>0 && amplitudes[dropleft]>((maxamplitudes[transition])*thresh3)+amplitudes[truncmin[transition]]){dropleft=dropleft-1;}
while(dropright<amplitudes.length-1 && amplitudes[dropright]>((maxamplitudes[transition])*thresh3)+amplitudes[truncmin[transition]]){dropright++;}
syst90start[transition]=dropleft;
diast90end[transition]=dropright;
	
}


// Create Arrays that contain the transition points before and after maxima for the different thresholds ends here



//********** defining necessary constants starts here ********************

ampl=0;

peaktime=0;
peaktimeabs=0;
peaktimeold=0;

peaktime10=0;
peaktime10abs=0;
peaktime10old=0;

peaktime50=0;
peaktime50abs=0;
peaktime50old=0;

peaktime90=0;
peaktime90abs=0;
peaktime90old=0;

systime=0;
systimeabs="";
systimeold=0;

diastime=0;
diastimeabs=0;
diastimeold=0;

systime10=0;
systime10abs="";
systime10old=0;

diastime10=0;
diastime10abs=0;
diastime10old=0;

systime50=0;
systime50abs="";
systime50old=0;

diastime50=0;
diastime50abs=0;
diastime50old=0;

systime90=0;
systime90abs="";
systime90old=0;

diastime90=0;
diastime90abs=0;
diastime90old=0;

sys10=newArray();
sys50=newArray();
sys90=newArray();
sysuser=newArray();

dias10=newArray();
dias50=newArray();
dias90=newArray();
diasuser=newArray();

btime10=newArray();
btime50=newArray();
btime90=newArray();
btimeuser=newArray();

thres0line=newArray(amplitudes.length-1);
thres1line=newArray(amplitudes.length-1);
thres2line=newArray(amplitudes.length-1);
thres3line=newArray(amplitudes.length-1);


//********** Defining necessary constants ends here ********************

// ************ Printing the headlines starts here ********************


print("Frame #" + "\t" + "Time [sec]" + "\t" + "Amplitude [a.u.]" + "\t" + "Amplitude baselined [a.u.]" + "\t" + "Amplitude baselined nomalized [a.u.]" + "\t" + "1st deriv. of amplitude" + "\t" + "Absol. 1st deriv. of amplitude" + "\t" + "Maxima [a.u.]" + "\t" + "Maxamplitudes [a.u.]" + "\t" + "Minima [a.u.]" + "\t" + "Since last beat [sec]" + "\t" + "Since last beat abs. time [sec]" + "\t" + "Sum of beats" + "\t" + "User threshold (" + thresh0*100 + "%) [a.u.]" + "\t" + "Peak time user [sec]" + "\t" + "Peak time user absolute [sec]" + "\t" + "Systolic interval (user) [sec]" + "\t" + "Systolic interval (user) absol. [sec]" + "\t" + "Diastolic interval (user) [sec]" + "\t" + "Diastolic interval (user) absol. [sec]" + "\t" + "Thr(" + thresh1*100 + "%) [a.u.]" + "\t" + "Peak time Thr(" + thresh1*100 + "%) [sec]" + "\t" + "Peak time Thr(" + thresh1*100 + "%) absol. [sec]" + "\t" + "Systolic interval Thr(" + thresh1*100 + "%) [sec]" + "\t" + "Systolic interval Thr(" + thresh1*100 + "%) absol. [sec]" + "\t" + "Diastolic interval Thr(" + thresh1*100 + "%) [sec]" + "\t" + "Diastolic interval Thr(" + thresh1*100 + "%) absol. [sec]" + "\t" + "Thr(" + thresh2*100 + "%) [a.u.]" + "\t" + "Peak time Thr(" + thresh2*100 + "%) [sec]" + "\t" + "Peak time Thr(" + thresh2*100 + "%) absol. [sec]" + "\t" + "Systolic interval Thr(" + thresh2*100 + "%) [sec]" + "\t" + "Systolic interval Thr(" + thresh2*100 + "%) absol. [sec]" + "\t" + "Diastolic interval Thr(" + thresh2*100 + "%) [sec]" + "\t" + "Diastolic interval Thr(" + thresh2*100 + "%) absol. [sec]" + "\t" + "Thr(" + thresh3*100 + "%) [a.u.]" + "\t" + "Peak time Thr(" + thresh3*100 + "%) [sec]" + "\t" + "Peak time Thr(" + thresh3*100 + "%) absol. [sec]" + "\t" + "Systolic interval Thr(" + thresh3*100 + "%) [sec]" + "\t" + "Systolic interval Thr(" + thresh3*100 + "%) absol. [sec]" + "\t" + "Diastolic interval Thr(" + thresh3*100 + "%) [sec]" + "\t" + "Diastolic interval Thr(" + thresh3*100 + "%) absol. [sec]");


// ************ Printing the headlines ends here

for (rr=0; rr<amplitudes.length-1; rr++){


//******************** Calculation of the systoles and diastoles for the thresholds (user, 10, 50 and 90%) starts here *************************


if (rr>systuserstart[ampl] && rr<truncmax[ampl]){
	systime=systime+1/fps; 
	systimeold=systime;
}
 else {systime=0;}

// NEU for Gesamtsystole starts here *****************************************************************
if (rr==truncmax[ampl] && systime==0 && systime<=systimeold){
	systimeabs=systimeold;
	sysuser=Array.concat(sysuser, systimeabs);
	
}
 else {systimeabs="";}
// NEU for Gesamtsystole ends here ******************************************************************* 

if (rr>=truncmax[ampl] && rr<diastuserend[ampl]){
	diastime=diastime+1/fps;
	diastimeold=diastime;

}
 else {diastime=0;}


// NEU for GesamtDIAstole starts here *****************************************************************
 if (diastimeold>diastime){
	diastimeabs=diastimeold;
	diastimeold=0;
        diasuser=Array.concat(diasuser, diastimeabs);
}
 else {diastimeabs="";}
// NEU for GesamtDIAstole ends here ******************************************************************* 


if (rr>syst10start[ampl] && rr<truncmax[ampl]){
	systime10=systime10+1/fps;
	systime10old=systime10;
}
 else {systime10=0;}

// NEU for Gesamtsystole 10 starts here *****************************************************************
if (rr==truncmax[ampl] && systime10==0 && systime10<=systime10old){
	systime10abs=systime10old;
	sys10=Array.concat(sys10, systime10abs);
	
}
 else {systime10abs="";}
// NEU for Gesamtsystole 10 ends here ******************************************************************* 



if (rr>=truncmax[ampl] && rr<diast10end[ampl]){
	diastime10=diastime10+1/fps;
	diastime10old=diastime10;
}
 else {diastime10=0;}



// NEU fuer GesamtDIAstole 10 starts here *****************************************************************
 if (diastime10old>diastime10){
	diastime10abs=diastime10old;
	diastime10old=0;
	dias10=Array.concat(dias10, diastime10abs);
}
 else {diastime10abs="";}
// NEU for GesamtDIAstole 10 ends here ******************************************************************* 

if (rr>syst50start[ampl] && rr<truncmax[ampl]){
	systime50=systime50+1/fps;
	systime50old=systime50;
}
 else {systime50=0;}

// NEU for Gesamtsystole 50 starts here *****************************************************************
if (rr==truncmax[ampl] && systime50==0 && systime50<=systime50old){
	systime50abs=systime50old;
	sys50=Array.concat(sys50, systime50abs);
	
}
 else {systime50abs="";}
// NEU for Gesamtsystole 50 ends here ******************************************************************* 

 
if (rr>1){
if (rr>=truncmax[ampl] && rr<diast50end[ampl]){
	diastime50=diastime50+1/fps;
	diastime50old=diastime50;
}
 else {diastime50=0;}}


// NEU fuer GesamtDIAstole 50 starts here *****************************************************************
 if (diastime50old>diastime50){
	diastime50abs=diastime50old;
	diastime50old=0;
	dias50=Array.concat(dias50, diastime50abs);
}
 else {diastime50abs="";}
// NEU for GesamtDIAstole 50 ends here ******************************************************************* 


if (rr>syst90start[ampl] && rr<truncmax[ampl]){
	systime90=systime90+1/fps;
	systime90old=systime90;
}
 else {systime90=0;}


// NEU for Gesamtsystole 90 starts here *****************************************************************
if (rr==truncmax[ampl] && systime90==0 && systime90<=systime90old){
	systime90abs=systime90old;
	sys90=Array.concat(sys90, systime90abs);
	
}
 else {systime90abs="";}
// NEU for Gesamtsystole 90 ends here ******************************************************************* 


if (rr>1){
if (rr>=truncmax[ampl] && rr<diast90end[ampl]){
	diastime90=diastime90+1/fps;
	diastime90old=diastime90;
}
 else {diastime90=0;}}


// NEU for GesamtDIAstole 90 starts here *****************************************************************
 if (diastime90old>diastime90){
	diastime90abs=diastime90old;
	diastime90old=0;
	dias90=Array.concat(dias90, diastime90abs);
}
 else {diastime90abs="";}
// NEU for GesamtDIAstole 90 ends here ******************************************************************* 


// ************************** Calculation of peak times starts here ***************************


if (diastime>0 || systime>0){
	peaktime=peaktime+1/fps;
	peaktimeold=peaktime;

}
 else {peaktime=0;}

if(systime==(1/fps)){peaktime=(1/fps);}

// NEU for Gesamtpeakzeit starts here *****************************************************************

if (peaktimeold>peaktime){
	peaktimeabs=peaktimeold;
	peaktimeold=0;
	btimeuser=Array.concat(btimeuser, peaktimeabs);
}
 else {peaktimeabs="";}

// NEU for Gesamtpeakzeit ends here ******************************************************************* 

if (diastime10>0 || systime10>0){
	peaktime10=peaktime10+1/fps;
	peaktime10old=peaktime10;
}
 else {peaktime10=0;}

if(systime10==(1/fps)){peaktime10=(1/fps);}

// NEU for Gesamtpeakzeit 10 starts here *****************************************************************

if (peaktime10old>peaktime10){
	peaktime10abs=peaktime10old;
	peaktime10old=0;
	btime10=Array.concat(btime10, peaktime10abs);
}
 else {peaktime10abs="";}

// NEU for Gesamtpeakzeit 10 ends here ******************************************************************* 

if (diastime50>0 || systime50>0){
	peaktime50=peaktime50+1/fps;
	peaktime50old=peaktime50;
}
 else {peaktime50=0;}

if(systime50==(1/fps)){peaktime50=(1/fps);}

// NEU for Gesamtpeakzeit 50 starts here *****************************************************************

if (peaktime50old>peaktime50){
	peaktime50abs=peaktime50old;
	peaktime50old=0;
	btime50=Array.concat(btime50, peaktime50abs);
}
 else {peaktime50abs="";}

// NEU for Gesamtpeakzeit 50 ends here ******************************************************************* 


if (diastime90>0 || systime90>0){
	peaktime90=peaktime90+1/fps;
	peaktime90old=peaktime90;
}
 else {peaktime90=0;}

if(systime90==(1/fps)){peaktime90=(1/fps);}

 // NEU for Gesamtpeakzeit 90 starts here *****************************************************************

if (peaktime90old>peaktime90){
	peaktime90abs=peaktime90old;
	peaktime90old=0;
	btime90=Array.concat(btime90, peaktime90abs);
}
 else {peaktime90abs="";}

// NEU for Gesamtpeakzeit 90 ends here ******************************************************************* 




// ************************** Calculation of peak times ends here ***************************



//******************** Calculation of the systoles and diastoles for the thresholds (user, 10, 50 and 90%) ends here *************************

btimeold=btimea;
btimea=btimea+(1/fps);



if (systimeabs==0) {
systimeabs="";
}


if (systime10abs==0) {
systime10abs="";
}


if (systime50abs==0) {
systime50abs="";
}


if (systime90abs==0) {
systime90abs="";
}


if(minima[min]==rr) {
print((rr+1) + "\t" + rr/fps + "\t" + amplitudes[rr] + "\t" + (amplitudes[rr]-pmin) + "\t" + (amplitudes[rr]-pmin)/(pmax-pmin) + "\t" + (amplitudes[rr+1]-amplitudes[rr]) + "\t"  + abs((amplitudes[rr+1]-amplitudes[rr])) + "\t" + "0" + "\t" + "\t" + round(pmax+1) + "\t" + btimea + "\t" + "\t" + "\t" + (amplitudes[truncmin[ampl]]+(threshold*maxamplitudes[ampl])) + "\t" + peaktime + "\t" + peaktimeabs + "\t" + systime + "\t" + systimeabs + "\t" + diastime + "\t" + diastimeabs + "\t" + (amplitudes[truncmin[ampl]]+(thresh1*maxamplitudes[ampl])) + "\t" + peaktime10 + "\t" + peaktime10abs + "\t" + systime10 + "\t" + systime10abs + "\t" + diastime10 + "\t" + diastime10abs + "\t" + (amplitudes[truncmin[ampl]]+(thresh2*maxamplitudes[ampl])) + "\t" + peaktime50 + "\t" + peaktime50abs + "\t" + systime50 + "\t" + systime50abs + "\t" + diastime50 + "\t" + diastime50abs + "\t" + (amplitudes[truncmin[ampl]]+(thresh3*maxamplitudes[ampl])) + "\t" + peaktime90 + "\t" + peaktime90abs + "\t" + systime90 + "\t" + systime90abs + "\t" + diastime90 + "\t" + diastime90abs);

thres0line[rr]=(amplitudes[truncmin[ampl]]+(threshold*maxamplitudes[ampl]));
thres1line[rr]=(amplitudes[truncmin[ampl]]+(thresh1*maxamplitudes[ampl]));
thres2line[rr]=(amplitudes[truncmin[ampl]]+(thresh2*maxamplitudes[ampl]));
thres3line[rr]=(amplitudes[truncmin[ampl]]+(thresh3*maxamplitudes[ampl]));


min=min+1;
if (min>minima.length-1){
	min=minima.length-1;
}


} else if (maxima[max]==rr) {
spacer="";
if (rr==0){btimea=0; spacer=0;}
print((rr+1) + "\t" + rr/fps + "\t" + amplitudes[rr] + "\t" + (amplitudes[rr]-pmin) + "\t" + (amplitudes[rr]-pmin)/(pmax-pmin) + "\t" + (amplitudes[rr+1]-amplitudes[rr]) + "\t" + abs((amplitudes[rr+1]-amplitudes[rr])) + "\t" + round(pmax+1) + "\t" + maxamplitudes[ampl] + "\t" + "0" + "\t" + btimea + "\t" +spacer+  "\t" + beats + "\t" + (amplitudes[truncmin[ampl]]+(threshold*maxamplitudes[ampl])) + "\t" + peaktime + "\t" + peaktimeabs + "\t" +  systime + "\t" + systimeabs + "\t" + diastime + "\t" + diastimeabs + "\t" + (amplitudes[truncmin[ampl]]+(thresh1*maxamplitudes[ampl])) + "\t" + peaktime10 + "\t" + peaktime10abs + "\t" + systime10 + "\t" + systime10abs + "\t" + diastime10 + "\t" + diastime10abs + "\t" + (amplitudes[truncmin[ampl]]+(thresh2*maxamplitudes[ampl])) + "\t" + peaktime50 + "\t" + peaktime50abs + "\t" + systime50 + "\t" + systime50abs + "\t" + diastime50 + "\t" + diastime50abs + "\t" + (amplitudes[truncmin[ampl]]+(thresh3*maxamplitudes[ampl])) + "\t" + peaktime90 + "\t" + peaktime90abs + "\t" + systime90 + "\t" + systime90abs + "\t" + diastime90 + "\t" + diastime90abs);
beattimes=Array.concat(beattimes,btimea);
btimea=0;
beats=beats+1;
max=max+1;


thres0line[rr]=(amplitudes[truncmin[ampl]]+(threshold*maxamplitudes[ampl]));
thres1line[rr]=(amplitudes[truncmin[ampl]]+(thresh1*maxamplitudes[ampl]));
thres2line[rr]=(amplitudes[truncmin[ampl]]+(thresh2*maxamplitudes[ampl]));
thres3line[rr]=(amplitudes[truncmin[ampl]]+(thresh3*maxamplitudes[ampl]));


if (max>maxima.length-1){
	max=maxima.length-1;
}
} else {
print((rr+1) + "\t" + rr/fps + "\t" + amplitudes[rr] + "\t" + (amplitudes[rr]-pmin) + "\t" + (amplitudes[rr]-pmin)/(pmax-pmin) + "\t" + (amplitudes[rr+1]-amplitudes[rr]) + "\t" + abs((amplitudes[rr+1]-amplitudes[rr])) + "\t" + "0" + "\t" + "\t" + "0" + "\t" + btimea + "\t" + btimeabs + "\t" + "\t"  + (amplitudes[truncmin[ampl]]+(threshold*maxamplitudes[ampl])) + "\t"  + peaktime + "\t" + peaktimeabs + "\t" + systime + "\t" + systimeabs + "\t" + diastime + "\t" + diastimeabs + "\t" + (amplitudes[truncmin[ampl]]+(thresh1*maxamplitudes[ampl])) + "\t" + peaktime10 + "\t" + peaktime10abs + "\t" + systime10 + "\t" + systime10abs + "\t" + diastime10 + "\t" + diastime10abs + "\t" + (amplitudes[truncmin[ampl]]+(thresh2*maxamplitudes[ampl])) + "\t" + peaktime50 + "\t" + peaktime50abs + "\t" + systime50 + "\t" + systime50abs + "\t" + diastime50 + "\t" + diastime50abs + "\t" + (amplitudes[truncmin[ampl]]+(thresh3*maxamplitudes[ampl])) + "\t" + peaktime90 + "\t" + peaktime90abs + "\t" + systime90 + "\t" + systime90abs + "\t" + diastime90 + "\t" + diastime90abs);

thres0line[rr]=(amplitudes[truncmin[ampl]]+(threshold*maxamplitudes[ampl]));
thres1line[rr]=(amplitudes[truncmin[ampl]]+(thresh1*maxamplitudes[ampl]));
thres2line[rr]=(amplitudes[truncmin[ampl]]+(thresh2*maxamplitudes[ampl]));
thres3line[rr]=(amplitudes[truncmin[ampl]]+(thresh3*maxamplitudes[ampl]));


}

if (rr<amplitudes.length && ampl<truncmax.length-1){
	
if   (rr>=(truncmin[ampl+1])) {

	ampl=ampl+1;

}

}


// NEU for GesamtBeatzeit starts here *****************************************************************
 if (btimeold>btimea){
	btimeabs=btimeold+1/fps;
	btimeold=0;
}
 else {btimeabs="";}
// NEU for GesamtBeatzeit ends here ******************************************************************* 

}


// ****************** Getting statistics from the arrays starts here *********************************

Array.getStatistics(beattimes, beattimesmin, beattimesmax, beattimesmean, beattimesstdDev);
Array.getStatistics(maxamplitudes, maxamplitudesmin, maxamplitudesmax, maxamplitudesmean, maxamplitudesstd);

Array.getStatistics(btimeuser, btimeusermin, btimeusermax, btimeusermean, btimeuserstd);
Array.getStatistics(btime10, btime10min, btime10max, btime10mean, btime10std);
Array.getStatistics(btime50, btime50min, btime50max, btime50mean, btime50std);
Array.getStatistics(btime90, btime90min, btime90max, btime90mean, btime90std);

Array.getStatistics(sysuser, sysusermin, sysusermax, sysusermean, sysuserstd);
Array.getStatistics(sys10, sys10min, sys10max, sys10mean, sys10std);
Array.getStatistics(sys50, sys50min, sys50max, sys50mean, sys50std);
Array.getStatistics(sys90, sys90min, sys90max, sys90mean, sys90std);

Array.getStatistics(diasuser, diasusermin, diasusermax, diasusermean, diasuserstd);
Array.getStatistics(dias10, dias10min, dias10max, dias10mean, dias10std);
Array.getStatistics(dias50, dias50min, dias50max, dias50mean, dias50std);
Array.getStatistics(dias90, dias90min, dias90max, dias90mean, dias90std);

frequencies=Array.copy(beattimes);
frequencies=Array.deleteValue(frequencies,0);

for (freq = 0; freq < frequencies.length; freq++) {
frequencies[freq]=1/frequencies[freq];	
}

Array.getStatistics(frequencies, freqmin, freqmax, freqmean, freqstd);


// ****************** Getting statistics from the arrays ends here **********************



// **************** Printing the final statistics with the first and last events starts here ******************

print(" ");
print("Statistics INCLUDING the first and last event");
print(" ");

print("Beats counted: " + "\t" + maxima.length);
print(" ");

print("\t" + "Min" + "\t" + "Max" + "\t" + "Mean" + "\t" + "StdDev");

print("Beattimes [sec]" + "\t" + beattimesmin + "\t" + beattimesmax + "\t" + beattimesmean + "\t" + beattimesstdDev);
print("Frequency [1/sec]" + "\t" + freqmin + "\t" + freqmax + "\t" + freqmean + "\t" + freqstd);

print("Amplitudes [a.u.] " + "\t" + maxamplitudesmin + "\t" + maxamplitudesmax + "\t" + maxamplitudesmean + "\t" + maxamplitudesstd);

print("Peaktimes user [sec] " + "\t" + btimeusermin + "\t" + btimeusermax + "\t" + btimeusermean + "\t" + btimeuserstd);
print("Systoles user [sec] " + "\t" + sysusermin + "\t" + sysusermax + "\t" + sysusermean + "\t" + sysuserstd);
print("Diastoles user [sec] " + "\t" + diasusermin + "\t" + diasusermax + "\t" + diasusermean + "\t" + diasuserstd);

print("Peaktimes Thr10% [sec]" + "\t" + btime10min + "\t" + btime10max + "\t" + btime10mean + "\t" + btime10std);
print("Systoles Thr10% [sec] " + "\t" + sys10min + "\t" + sys10max + "\t" + sys10mean + "\t" + sys10std);
print("Diastoles Thr10% [sec] " + "\t" + dias10min + "\t" + dias10max + "\t" + dias10mean + "\t" + dias10std);

print("Peaktimes Thr50% [sec]" + "\t" + btime50min + "\t" + btime50max + "\t" + btime50mean + "\t" + btime50std);
print("Systoles Thr50% [sec] " + "\t" + sys50min + "\t" + sys50max + "\t" + sys50mean + "\t" + sys50std);
print("Diastoles Thr50% [sec] " + "\t" + dias50min + "\t" + dias50max + "\t" + dias50mean + "\t" + dias50std);

print("Peaktimes Thr90% [sec]" + "\t" + btime90min + "\t" + btime90max + "\t" + btime90mean + "\t" + btime90std);
print("Systoles Thr90% [sec] " + "\t" + sys90min + "\t" + sys90max + "\t" + sys90mean + "\t" + sys90std);
print("Diastoles Thr90% [sec] " + "\t" + dias90min + "\t" + dias90max + "\t" + dias90mean + "\t" + dias90std);

print(" ");
print("Ratios:");
print(" ");
print("Systole/diastole [user] mean:" + "\t" + sysusermean/diasusermean);
print("Systole/diastole [Thr10%] mean:" + "\t" + sys10mean/dias10mean);
print("Systole/diastole [Thr50%] mean:" + "\t" + sys50mean/dias50mean);
print("Systole/diastole [Thr90%] mean:" + "\t" + sys90mean/dias90mean);
print(" ");
print("Amplitude mean/systole [user] mean:" + "\t" + maxamplitudesmean/sysusermean);
print("Amplitude mean/systole [Thr10%] mean:" + "\t" + maxamplitudesmean/sys10mean);
print("Amplitude mean/systole [Thr50%] mean:" + "\t" + maxamplitudesmean/sys50mean);
print("Amplitude mean/systole [Thr90%] mean:" + "\t" + maxamplitudesmean/sys90mean);
print(" ");
print("Amplitude mean/diastole [user] mean:" + "\t" + maxamplitudesmean/diasusermean);
print("Amplitude mean/diastole [Thr10%] mean:" + "\t" + maxamplitudesmean/dias10mean);
print("Amplitude mean/diastole [Thr50%] mean:" + "\t" + maxamplitudesmean/dias50mean);
print("Amplitude mean/diastole [Thr90%] mean:" + "\t" + maxamplitudesmean/dias90mean);
print(" ");
print("Amplitude mean/peaktime [user] mean:" + "\t" + maxamplitudesmean/btimeusermean);
print("Amplitude mean/peaktime [Thr10%] mean:" + "\t" + maxamplitudesmean/btime10mean);
print("Amplitude mean/peaktime [Thr50%] mean:" + "\t" + maxamplitudesmean/btime50mean);
print("Amplitude mean/peaktime [Thr90%] mean:" + "\t" + maxamplitudesmean/btime90mean);



// **************** Printing the final statistics with the first and last events ends here ******************



// **************** Printing the final statistics WITHOUT the first and last events starts here ******************


beattimesshort=Array.slice(beattimes, 1,beattimes.length-1);
maxamplitudesshort=Array.slice(maxamplitudes, 1,maxamplitudes.length-1);

btimeusershort=Array.slice(btimeuser, 1, btimeuser.length-1);
btime10short=Array.slice(btime10, 1, btime10.length-1);
btime50short=Array.slice(btime50, 1, btime50.length-1);
btime90short=Array.slice(btime90, 1, btime90.length-1);

sysusershort=Array.slice(sysuser, 1,sysuser.length-1);
sys10short=Array.slice(sys10, 1, sys10.length-1);
sys50short=Array.slice(sys50, 1, sys50.length-1);
sys90short=Array.slice(sys90, 1, sys90.length-1);


diasusershort=Array.slice(diasuser, 1, diasuser.length-1);
dias10short=Array.slice(dias10, 1, dias10.length-1);
dias50short=Array.slice(dias50, 1, dias50.length-1);
dias90short=Array.slice(dias90, 1, dias90.length-1);


Array.getStatistics(beattimesshort, beattimesshortmin, beattimesshortmax, beattimesshortmean, beattimesshortstdDev);
Array.getStatistics(maxamplitudesshort, maxamplitudesshortmin, maxamplitudesshortmax, maxamplitudesshortmean, maxamplitudesshortstd);

Array.getStatistics(btimeusershort, btimeusershortmin, btimeusershortmax, btimeusershortmean, btimeusershortstd);
Array.getStatistics(btime10short, btime10shortmin, btime10shortmax, btime10shortmean, btime10shortstd);
Array.getStatistics(btime50short, btime50shortmin, btime50shortmax, btime50shortmean, btime50shortstd);
Array.getStatistics(btime90short, btime90shortmin, btime90shortmax, btime90shortmean, btime90shortstd);

Array.getStatistics(sysusershort, sysusershortmin, sysusershortmax, sysusershortmean, sysusershortstd);
Array.getStatistics(sys10short, sys10shortmin, sys10shortmax, sys10shortmean, sys10shortstd);
Array.getStatistics(sys50short, sys50shortmin, sys50shortmax, sys50shortmean, sys50shortstd);
Array.getStatistics(sys90short, sys90shortmin, sys90shortmax, sys90shortmean, sys90shortstd);

Array.getStatistics(diasusershort, diasusershortmin, diasusershortmax, diasusershortmean, diasusershortstd);
Array.getStatistics(dias10short, dias10shortmin, dias10shortmax, dias10shortmean, dias10shortstd);
Array.getStatistics(dias50short, dias50shortmin, dias50shortmax, dias50shortmean, dias50shortstd);
Array.getStatistics(dias90short, dias90shortmin, dias90shortmax, dias90shortmean, dias90shortstd);


frequenciesshort=Array.copy(beattimesshort);
for (freqshort = 0; freqshort < frequenciesshort.length; freqshort++) {
frequenciesshort[freqshort]=1/frequenciesshort[freqshort];	
}

Array.getStatistics(frequenciesshort, freqshortmin, freqshortmax, freqshortmean, freqshortstd);
print(" ");
print("Statistics WITHOUT the first and last event");
print(" ");

print("Beats counted: " + "\t" + maxima.length-2);
print(" ");

print("\t" + "Min" + "\t" + "Max" + "\t" + "Mean" + "\t" + "StdDev");

print("Beattimes [sec]" + "\t" + beattimesshortmin + "\t" + beattimesshortmax + "\t" + beattimesshortmean + "\t" + beattimesshortstdDev);
print("Frequency [1/sec]" + "\t" + freqshortmin + "\t" + freqshortmax + "\t" + freqshortmean + "\t" + freqshortstd);

print("Amplitudes [a.u.] " + "\t" + maxamplitudesshortmin + "\t" + maxamplitudesshortmax + "\t" + maxamplitudesshortmean + "\t" + maxamplitudesshortstd);

print("Peaktimes user [sec] " + "\t" + btimeusershortmin + "\t" + btimeusershortmax + "\t" + btimeusershortmean + "\t" + btimeusershortstd);
print("Systoles user [sec] " + "\t" + sysusershortmin + "\t" + sysusershortmax + "\t" + sysusershortmean + "\t" + sysusershortstd);
print("Diastoles user [sec] " + "\t" + diasusershortmin + "\t" + diasusershortmax + "\t" + diasusershortmean + "\t" + diasusershortstd);

print("Peaktimes Thr10% [sec]" + "\t" + btime10shortmin + "\t" + btime10shortmax + "\t" + btime10shortmean + "\t" + btime10shortstd);
print("Systoles Thr10% [sec] " + "\t" + sys10shortmin + "\t" + sys10shortmax + "\t" + sys10shortmean + "\t" + sys10shortstd);
print("Diastoles Thr10% [sec] " + "\t" + dias10shortmin + "\t" + dias10shortmax + "\t" + dias10shortmean + "\t" + dias10shortstd);

print("Peaktimes Thr50% [sec]" + "\t" + btime50shortmin + "\t" + btime50shortmax + "\t" + btime50shortmean + "\t" + btime50shortstd);
print("Systoles Thr50% [sec] " + "\t" + sys50shortmin + "\t" + sys50shortmax + "\t" + sys50shortmean + "\t" + sys50shortstd);
print("Diastoles Thr50% [sec] " + "\t" + dias50shortmin + "\t" + dias50shortmax + "\t" + dias50shortmean + "\t" + dias50shortstd);

print("Peaktimes Thr90% [sec]" + "\t" + btime90shortmin + "\t" + btime90shortmax + "\t" + btime90shortmean + "\t" + btime90shortstd);
print("Systoles Thr90% [sec] " + "\t" + sys90shortmin + "\t" + sys90shortmax + "\t" + sys90shortmean + "\t" + sys90shortstd);
print("Diastoles Thr90% [sec] " + "\t" + dias90shortmin + "\t" + dias90shortmax + "\t" + dias90shortmean + "\t" + dias90shortstd);

print(" ");
print("Ratios:");
print(" ");
print("Systole/diastole [user] mean:" + "\t" + sysusershortmean/diasusermean);
print("Systole/diastole [Thr10%] mean:" + "\t" + sys10shortmean/dias10shortmean);
print("Systole/diastole [Thr50%] mean:" + "\t" + sys50shortmean/dias50shortmean);
print("Systole/diastole [Thr90%] mean:" + "\t" + sys90shortmean/dias90shortmean);
print(" ");
print("Amplitude mean/systole [user] mean:" + "\t" + maxamplitudesshortmean/sysusershortmean);
print("Amplitude mean/systole [Thr10%] mean:" + "\t" + maxamplitudesshortmean/sys10shortmean);
print("Amplitude mean/systole [Thr50%] mean:" + "\t" + maxamplitudesshortmean/sys50shortmean);
print("Amplitude mean/systole [Thr90%] mean:" + "\t" + maxamplitudesshortmean/sys90shortmean);
print(" ");
print("Amplitude mean/diastole [user] mean:" + "\t" + maxamplitudesshortmean/diasusershortmean);
print("Amplitude mean/diastole [Thr10%] mean:" + "\t" + maxamplitudesshortmean/dias10shortmean);
print("Amplitude mean/diastole [Thr50%] mean:" + "\t" + maxamplitudesshortmean/dias50shortmean);
print("Amplitude mean/diastole [Thr90%] mean:" + "\t" + maxamplitudesshortmean/dias90shortmean);
print(" ");
print("Amplitude mean/peaktime [user] mean:" + "\t" + maxamplitudesshortmean/btimeusershortmean);
print("Amplitude mean/peaktime [Thr10%] mean:" + "\t" + maxamplitudesshortmean/btime10shortmean);
print("Amplitude mean/peaktime [Thr50%] mean:" + "\t" + maxamplitudesshortmean/btime50shortmean);
print("Amplitude mean/peaktime [Thr90%] mean:" + "\t" + maxamplitudesshortmean/btime90shortmean);
print(" ");

print("Framerate [1/s]:" + "\t" + fps);

print("Detection:" + "\t" + detection);


 // **************** Printing the final statistics WITHOUT the first and last events ends here ******************

//******************************Printing the analyzed data from the array ends here ******************

//******************************Plotting the data starts here, thresholds are displayed, according images and numeric output cann be saved ******************

allminima=newArray(amplitudes.length);
allmaxima=newArray(amplitudes.length);

Array.fill(allminima, 0);
Array.fill(allmaxima, 0);

for (allmax=0; allmax<maxima.length; allmax++){
	allmaxima[maxima[allmax]]=round(pmax+1);
	}


for (allmin=0; allmin<minima.length; allmin++){
	allminima[minima[allmin]]=round(pmax+1);
	}


times=newArray(amplitudes.length);

for (tt=0; tt<amplitudes.length; tt++) {
times[tt]=tt/fps;
}


run("Profile Plot Options...", "width=1920 height=700 font=10 minimum=pmin maximum=pmax draw draw_ticks interpolate sub-pixel");

Plot.create("Amplitudes", "Time [sec]", "Amplitude [a.u.]", times, amplitudes);
setJustification("center");
Plot.addText("Amplitude (black)", 0.1, 0);
Plot.addText("Maxima (red)", 0.2, 0);
Plot.addText("Minima (green)", 0.3, 0);
Plot.addText("Thr(" + 100*thresh0 + "%, orange)", 0.4, 0);
Plot.addText("Thr(" + 100*thresh1 + "%, cyan)", 0.55, 0);
Plot.addText("Thr(" + 100*thresh2 + "%, pink)", 0.7, 0);
Plot.addText("Thr(" + 100*thresh3 + "%, blue)", 0.85, 0);
Plot.addText("Det=" + detection, 0.95, 0);


Plot.setColor("red"); 
Plot.add("line", times, allmaxima);

Plot.setColor("green");
Plot.add("line", times, allminima);

Plot.setColor("orange");
Plot.setLineWidth(2);
Plot.add("line", times, thres0line);

Plot.setColor("cyan");
Plot.setLineWidth(2);
Plot.add("line", times, thres1line);

Plot.setColor("pink");
Plot.setLineWidth(2);
Plot.add("line", times, thres2line);

Plot.setColor("blue");
Plot.setLineWidth(2);
Plot.add("line", times, thres3line);

Plot.setLineWidth(1);
Plot.setColor("black");

Plot.show();



Plot.makeHighResolution("Amplitudes", 2.0, "enable");


//****************************** Plotting the data ends here ******************


print(" ");
print(" ");


//**************************** The user selects if the data are saved or not ********************

Dialog.create("Save the generated data and restart?");
Dialog.addMessage(">Cancel< aborts the whole macro" + "\n" + ">OK< starts over without saving" + "\n" + "Checking >Yes< and >OK< saves data and starts over");
Dialog.addCheckbox("Yes (save it)", false);
Dialog.show();
storeit = Dialog.getCheckbox();


if (storeit==true) {
reslts=getInfo("log");
File.append(reslts, dir + rmve + " re-revaluated " + year+"-"+MonthNames[month]+"-"+dayOfMonths+"-"+hours+"h"+minutes + ".txt");	

saveAs("Jpeg", dir + option + " re-evaluated " + (runs+1) + " " + year+"-"+MonthNames[month]+"-"+dayOfMonths+"-"+hours+"h"+minutes+ ".jpg");
close();

}



//**************************** Select if data are saved or not starts here ********************

while (nImages>0) { 
          selectImage(nImages); 
          close(); 
}

print("\\Clear");

}



}

//******************** Re-Evaluation ends here *********************

 // ******************* Creation of a batch-list starts here ******************************************************************

 if (option == "2. Create a Batch List") {


filetype=".jpg";

names=newArray();
xcoord=newArray();
ycoord=newArray();

dir=getDirectory("Choose the directory containig the pretest-images"); 

list = getFileList(dir); 

Array.print(list);

jpgtest=0;
jpgfound="false";
while(jpgfound=="false" && jpgtest<list.length){if (endsWith(list[jpgtest], ".jpg")) {jpgfound="true";} {jpgtest++;}}

if(jpgfound=="false"){jpgfound="false";exit("There seem to be NO JPG-images in this folder...");}


a=0;

for (i=0; i<list.length; i++) { 
     if (endsWith(list[i], filetype)){ 
               print(i + ": " + dir+list[i]); 
             open(dir+list[i]); 
             

if(a==0){

run("RGB Color");
rename("panels");

if (isOpen(list[i])){
selectWindow(list[i]);
close();
}

selectWindow("panels");
getDimensions(width, height, channels, slices, frames);
makeRectangle(0, 0, width/12, height/12);
run("Duplicate...", "title=" + "["+"Please insert <SIZE>" + "]");

selectWindow("panels");

close();

Dialog.create("Please insert the value for <SIZE>");
Dialog.addNumber("Please insert <SIZE> as shown in the image: ", 0);
Dialog.addChoice("Select applied pretest setting:", newArray("LowMovement", "HighMovement"), "LowMovement");
Dialog.show();
sizelowerlimit = Dialog.getNumber();
option= Dialog.getChoice();

if (isOpen("Please insert <SIZE>")){
selectWindow("Please insert <SIZE>");
close();
}

	
open(dir+list[i]);	
a++;
	
	}


name=getTitle();
name2=replace(name, "-test.jpg", ".avi");
getDimensions(width, height, channels, slices, frames);

setTool("point");

getCursorLoc(x, y, z, modifiers);

while(modifiers!=16){
getCursorLoc(x, y, z, modifiers);
}

getCursorLoc(x, y, z, modifiers);

names=Array.concat(names,name2);
xcoord=Array.concat(xcoord,x);
ycoord=Array.concat(ycoord,y);

close();

print("\\Clear");


     }

}

print("\\Clear");

print("Title" + "\t" + "Size" + "\t" + "Threshold");

if (option=="HighMovement") {	
for (j = 0; j < names.length; j++) {
print(names[j] + "\t" + (sizelowerlimit+floor((12*xcoord[j]/width))*sizelowerlimit) + "\t" + round((243-(((243-127)/11)*floor(12*ycoord[j]/height)))));	
}
}

if (option=="LowMovement") {
for (j = 0; j < names.length; j++) {
print(names[j] + "\t" + (sizelowerlimit+floor((12*xcoord[j]/width))*sizelowerlimit) + "\t" + round((121-(11*floor(12*ycoord[j]/height)))));	
}
}


selectWindow("Log");
batchlist=dir+"batch.txt";
saveAs("Text", batchlist);

run("Close All");

Dialog.create("Done!");
Dialog.addMessage("Batch List created!" + "\n" + "Please copy the list into your video-folder," + "\n" + "select <Batch>-option for evaluation.");
Dialog.show();
 
}

// ******************* Creation of a batch-list ends here ******************************************************************



// ******************* EXCLUSION of unwanted data starts here ******************************************************************

if (option == "4. Exclude Data") {

for (repeats = 0; repeats < 1000; repeats++) {


filetype1=".jpg";
filetype2=".txt";
excluded=newArray();
included=newArray();

dir=getDirectory("Please select the results-directory (<dataplots>)"); 

list = getFileList(dir); 

// ******** Find the txt-file containing the results and put them linewise into an array ****************

Array.print(list);

j=0;
found=0;

while (j < list.length && found==0) {
if (indexOf(list[j], "Results") >= 0) {
if (indexOf(list[j], "Results (selected)") < 0){filestring=File.openAsString(dir + list[j]);
found=1;
}
}
j++;
}

if (found==0) {exit("Sorry, no Results-file was found.");}
	

results=split(filestring, "\n");

 // ********************* Remove all files that are NOT a small Amplitude-plot from the file-list ****************

for (k = 0; k < list.length; k++) {if ((indexOf(list[k], "fps)-plot small.jpg") <= 0)) {list[k]=0;}}

list=Array.deleteValue(list, 0);

// *********** Open only the small Amplitude-plots and select if the according data are EXCLUDED ***********


for (i=0; i<list.length; i++) { 
     if (endsWith(list[i], filetype1)){ 
               print(i + ": " + dir+list[i]); 
             open(dir+list[i]); 


name = indexOf(list[i], filetype1);
title = substring(list[i], 0, name);

Dialog.create("EXCLUDE this data?");
Dialog.addMessage(">Cancel< aborts the whole macro" + "\n" + ">OK< INCLUDE this data" + "\n" + "Checking >EXCLUDE!< and >OK< EXCLUDES this data!");
Dialog.addCheckbox("EXCLUDE!", false);
Dialog.show();
exclude = Dialog.getCheckbox();


title2=replace(title, "-plot small", "");

if (exclude==true) {

excluded=Array.concat(excluded,title2);

if(indexOf(title2, "-diff-cell")<0){
title2=replace(title2, "-cell", "-diff-cell");
}


a=0;
while(indexOf(results[a], title2)<0) {a++;}

b=a+3;
while(indexOf(results[b], "-diff-cell")<0 && results[b]!="***** Settings *****") {b++;}

print("Delete elements " + a + " to " + b);

for (delete = a; delete < b; delete++) {results[delete]="removed";}
results=Array.deleteValue(results, "removed");

}



if (exclude==false) {
included=Array.concat(included,title2);
}



if (isOpen(title+filetype1)){
selectWindow(title+filetype1);
close();
     }
     
}

}

// ****************** Print the remaining Results-Array and save it as text in the results folder **********

print("\\Clear");

for (i = 0; i < results.length; i++) {
print(results[i]);	
}

print("");
print("INCLUDED Data:");
print("");

for (i = 0; i < included.length; i++) {
print(included[i]);	
}


print("");
print("EXCLUDED Data:");
print("");

for (i = 0; i < excluded.length; i++) {
print(excluded[i]);	
}

dest=dir+"Results (selected) "+year+"-"+MonthNames[month]+"-"+dayOfMonths+"-"+hours+"h"+minutes+".txt";
selectWindow("Log");
saveAs("Text", dest); 

run("Close All");

}

}

// ******************* EXCLUSION of unwanted data ends here ******************************************************************


// ************************************* DATA EXTRACTION for Statistics starts here

if (option == "6. Data Extraction") {

for (repeats = 0; repeats < 1000000; repeats++) {

// ****************** Header for date and time starts here


run("Colors...", "foreground=black background=black selection=yellow");
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display redirect=None   decimal=3");
run("Input/Output...", "jpeg=90 gif=-1 file=.txt use_file copy_column copy_row save_column save_row");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"); 

if (hour<10) {hours = "0"+hour;}
else {hours=hour;}
if (minute<10) {minutes = "0"+minute;}
else {minutes=minute;}
if (second<10) {seconds = "0"+second;}
else {seconds=second;}
if (month<10) {months = "0"+(month+1);}
else {months=month+1;}
if (dayOfMonth<10) {dayOfMonths = "0"+dayOfMonth;}
else {dayOfMonths=dayOfMonth;}

// ****************** Header for date and time ends here

// extract correct path and filename
	
pathfile=File.openDialog("Please choose a <Results>-file to be opened for extraction:");

print(pathfile);

data=File.openAsString(pathfile);

strt=lastIndexOf(pathfile, "\\");
dir=substring(pathfile, 0, strt+1);

filename=substring(pathfile, strt+1, lengthOf(pathfile));
filename=replace(filename, ".txt", "");


// ******************** Complete extraction of preserve the titles and names of recognized cells dialog starts here

Dialog.create("Please choose...");
Dialog.addChoice("Select:", newArray("Complete extraction (data only)", "Preserve filename and cell(s)"));

Dialog.show();
  
extractoption = Dialog.getChoice();


// ************ The pretest starts here, evaluate the whole video or only the first 300 frames to save time ***********************************

if (extractoption == "Preserve filename and cell(s)") {}


// ******************** Complete extraction of preserve the titles and names of recognized cells dialog ends here



//************************* Replace all multiple-Tabs and linebreaks starts here

data=replace(data, "\t\t\t\t\t" , "\t gap \t gap \t gap \t gap \t");
data=replace(data, "\t\t\t\t" , "\t gap \t gap \t gap \t");
data=replace(data, "\t\t\t\n" , "\t gap \t gap \t gap \n");
data=replace(data, "\t\t\t" , "\t gap \t gap \t");
data=replace(data, "\t\t\n" , "\t gap \t gap \n");
data=replace(data, "\t\t" , "\t gap \t");
data=replace(data, "\t\n" , "\t gap \n");
data=replace(data, "\n" , "\t gap \n");


print("\\Clear");

//************************* Replace all multiple-Tabs and linebreaks ends here

datalines=split(data, "\n");

//************** is it an amplitudes Only file, check starts here
ampltest="false";
for (i = 0; i < datalines.length; i++) {if(indexOf(datalines[i], "newArray(")>=0){ampltest="true";}}
if (ampltest=="true") {exit("Sorry, but this seems to be an" + "\n" + "<Amplitudes only>-File." + "\n" + "Please choose a <Results>-file.");}

//**************** is it an amplitudes only file, check ends here


//**********************************Extract Headlines starts here
headers="false";
k=0;
while(headers=="false" && k<datalines.length) {if(startsWith(datalines[k], "Frame")) {headlines=datalines[k]; headers="true";} k++;}
headlines=replace(headlines, " gap " , "");
headlinearray=split(headlines, "\t");

//***********************************Extract Headlines ends here

// ***** DATA EXTRACTION preserving filenames and recognized cell(s) starts here

if (extractoption == "Preserve filename and cell(s)") {

for (i = 0; i < datalines.length; i++) {
if ((indexOf(datalines[i], "Frame #")>=0) ||(indexOf(datalines[i], "Statistics")>=0) || (indexOf(datalines[i], "Beats counted")>=0) || (indexOf(datalines[i], "Beattimes")>=0) || (indexOf(datalines[i], "Frequency")>=0) || (indexOf(datalines[i], "Amplitudes")>=0) || (indexOf(datalines[i], "Peaktime")>=0) || (indexOf(datalines[i], "Systole")>=0) || (indexOf(datalines[i], "Diastole")>=0) || (indexOf(datalines[i], "Ratios")>=0) || (indexOf(datalines[i], "Amplitude")>=0) || (indexOf(datalines[i], "Reference")>=0) || (indexOf(datalines[i], "Framerate")>=0) || (indexOf(datalines[i], "Min"+"\t"+"Max"+"\t"+"Mean")>=0) || (indexOf(datalines[i], "Reference")>=0) ) {datalines[i]="del";}
}

removeend=0;
while(indexOf(datalines[removeend], "Settings")<0){removeend++;}

datalines=Array.slice(datalines,0,removeend);

datalines=Array.deleteValue(datalines, "del");
datalines=Array.deleteValue(datalines, "");
	
}


// ***** DATA EXTRACTION preserving filenames and recognized cell(s) ends here


// ***** The COMPLETE DATA EXTRACTION starts here

// ************** Remove everything but the data itself starts here ***********************


if (extractoption == "Complete extraction (data only)"){

for (i = 0; i < datalines.length; i++) {
if ((indexOf(datalines[i], "F")>=0) ||(indexOf(datalines[i], "R")>=0) || (indexOf(datalines[i], "S")>=0) || (indexOf(datalines[i], "A")>=0) || (indexOf(datalines[i], "B")>=0) || (indexOf(datalines[i], "D")>=0) || (indexOf(datalines[i], "P")>=0) || (indexOf(datalines[i], "Ima")>=0) || (indexOf(datalines[i], "Eval")>=0) || (indexOf(datalines[i], "[%]")>=0) || (indexOf(datalines[i], ":\\")>=0) || (indexOf(datalines[i], "avi")>=0) || (indexOf(datalines[i], "fps)")>=0) || (indexOf(datalines[i], "T")>=0) || (indexOf(datalines[i], "M")>=0) || (indexOf(datalines[i], "U")>=0) || (indexOf(datalines[i], "1st")>=0) || (indexOf(datalines[i], "N")>=0) || (startsWith(datalines[i], "\n")) || (startsWith(datalines[i], " ")) || (startsWith(datalines[i], "\t")) || (startsWith(datalines[i], "\r")) ) {datalines[i]="del";}
}

datalines=Array.deleteValue(datalines, "del");
datalines=Array.deleteValue(datalines, "");

}

// ************** Remove everything but the data itself ends here ***********************


// *********** Arrange Data in separate arrays starts here

// Create necessary Arrays for statistics-extraction


times=newArray(datalines.length);
maxamplitudes=newArray(datalines.length);
sincelastbeatabs=newArray(datalines.length);

peakuserabs=newArray(datalines.length);
systuserabs=newArray(datalines.length);
diasuserabs=newArray(datalines.length);

peak10abs=newArray(datalines.length);
syst10abs=newArray(datalines.length);
dias10abs=newArray(datalines.length);

peak50abs=newArray(datalines.length);
syst50abs=newArray(datalines.length);
dias50abs=newArray(datalines.length);

peak90abs=newArray(datalines.length);
syst90abs=newArray(datalines.length);
dias90abs=newArray(datalines.length);

datainfo=newArray(datalines.length);

//*********************** Fill Arrays with data

for (i = 0; i < datalines.length; i++) {
cells=split(datalines[i], "\t");
 if(cells.length<5){datainfo[i]=datalines[i];}

if(cells.length>40){
times[i]=cells[1];
maxamplitudes[i]=cells[10];
sincelastbeatabs[i]=cells[13];

peakuserabs[i]=cells[17];
systuserabs[i]=cells[19];
diasuserabs[i]=cells[21];

peak10abs[i]=cells[24];
syst10abs[i]=cells[26];
dias10abs[i]=cells[28];

peak50abs[i]=cells[31];
syst50abs[i]=cells[33];
dias50abs[i]=cells[35];

peak90abs[i]=cells[38];
syst90abs[i]=cells[40];
dias90abs[i]=cells[42];

if(maxamplitudes[i]>0 && systuserabs[i]==0){maxamplitudes[i]=0;}

}
}



// Remove artefacts and separators

maxamplitudes=Array.deleteValue(maxamplitudes, " gap ");

sincelastbeatabs=Array.deleteValue(sincelastbeatabs, " gap ");
sincelastbeatabs=Array.deleteValue(sincelastbeatabs, "0");

peakuserabs=Array.deleteValue(peakuserabs, " gap ");
systuserabs=Array.deleteValue(systuserabs, " gap ");
diasuserabs=Array.deleteValue(diasuserabs, " gap ");

peak10abs=Array.deleteValue(peak10abs, " gap ");
syst10abs=Array.deleteValue(syst10abs, " gap ");
dias10abs=Array.deleteValue(dias10abs, " gap ");

peak50abs=Array.deleteValue(peak50abs, " gap ");
syst50abs=Array.deleteValue(syst50abs, " gap ");
dias50abs=Array.deleteValue(dias50abs, " gap ");

peak90abs=Array.deleteValue(peak90abs, " gap ");
syst90abs=Array.deleteValue(syst90abs, " gap ");
dias90abs=Array.deleteValue(dias90abs, " gap ");

// Print the extracted data for export

print("\\Clear");

// ****  Print headlines from healdlinearray

print(headlinearray[10] + "\t" + headlinearray[13] + "\t" + headlinearray[17] + "\t" + headlinearray[19] + "\t" + headlinearray[21] + "\t" + headlinearray[24] + "\t" + headlinearray[26] + "\t" + headlinearray[28] + "\t" + headlinearray[31] + "\t" + headlinearray[33] + "\t" + headlinearray[35] + "\t" + headlinearray[38] + "\t" + headlinearray[40] + "\t" + headlinearray[42]);


// ****  Print data from the according arrays

zeilen=newArray(maxamplitudes.length, sincelastbeatabs.length, peakuserabs.length, systuserabs.length, diasuserabs.length, peak10abs.length, syst10abs.length, dias10abs.length, peak50abs.length, syst50abs.length, dias50abs.length, peak90abs.length, syst90abs.length, dias90abs.length);

Array.getStatistics(zeilen, zmin, zmax, zmean, zstdDev);

printarray=newArray(zmax);

line="";

for (i = 0; i < zmax; i++) {
if (i<maxamplitudes.length) {line=line+maxamplitudes[i] + "\t";} else {line=line+"\t";} 
if (i<sincelastbeatabs.length) {line=line+sincelastbeatabs[i] + "\t";} else {line=line+"\t";}	

if (i<peakuserabs.length) {line=line+peakuserabs[i] + "\t";} else {line=line+"\t";}
if (i<systuserabs.length) {line=line+systuserabs[i] + "\t";} else {line=line+"\t";}
if (i<diasuserabs.length) {line=line+diasuserabs[i] + "\t";} else {line=line+"\t";}

if (i<peak10abs.length) {line=line+peak10abs[i] + "\t";} else {line=line+"\t";}
if (i<syst10abs.length) {line=line+syst10abs[i] + "\t";} else {line=line+"\t";}
if (i<dias10abs.length) {line=line+dias10abs[i] + "\t";} else {line=line+"\t";}

if (i<peak50abs.length) {line=line+peak50abs[i] + "\t";} else {line=line+"\t";}
if (i<syst50abs.length) {line=line+syst50abs[i] + "\t";} else {line=line+"\t";}
if (i<dias50abs.length) {line=line+dias50abs[i] + "\t";} else {line=line+"\t";}

if (i<peak90abs.length) {line=line+peak90abs[i] + "\t";} else {line=line+"\t";}
if (i<syst90abs.length) {line=line+syst90abs[i] + "\t";} else {line=line+"\t";}
if (i<dias90abs.length) {line=line+dias90abs[i] + "\t";} else {line=line+"\t";}

printarray[i]=line;
line="";
}

for (i = 0; i < printarray.length; i++) {print(printarray[i]);}

extract=getInfo("log");

File.saveString(extract, dir + "Extracted results (eng) "+ filename + ".txt");

extract=replace(extract, ".", ",");
extract=replace(extract, "\\[a,u\\]", "[a.u]");
File.saveString(extract, dir + "Extracted results (ger) "+ filename + ".txt");

// ***** The COMPLETE DATA EXTRACTION ends here



}

}

// ************************************* DATA EXTRACTION for Statistics ends here
