# BementLabSphinctalyzer
> The Sphinctalyzer quantifies signal during the cell repair process.  It will work with anything that has a radial axis of symmetry or something close to it.  The key feature of this tool is the ability to track the edge of the wound over time.

## Dependencies
<ul>
  <li>MATLAB (preferably 2022b, but other versions should work fine). The follow Add-Ons should be installed:
  <ul>
    <li>Statistics and Machine Learning Toolbox</li>
    <li>Bioinformatics Toolbox</li>
    <li>Image Processing Toolbox</li>
    <li>Curve Fitting Toolbox</li>
    <li>Mapping Toolbox</li>
  </ul>
  </li>
  <li>Xcode if using a Mac operating system (for compiling mex files)</li>
</ul>

## Setup Instructions
<ol>
  <li>Download the repository onto your computer.</li>
  <li>Open MATLAB and navigate into the SphinctalyzerFiles folder in the repository.</li>
  <li>Compile the three mex files by typing the following three commands into the MATLAB command window, one at a time:<ol>
    <li><code>mex dijkstra.c</code></li>
    <li><code>mex Radjacency.c</code></li>
    <li><code>mex Kadjacency.c</code></li>
  </ol></li>
  <li>Your repository is ready to Sphinctalyze.</li>
</ol>

## Usage
<ul>
  <li>To run the GUI, simply open the SphinctalyzerGUI.m file in the SphinctalyzerFiles folder and run it. In the GUI interface, follow the manual below to process one or multiple images.</li>
  <li>Alternatively, The individual scripts can be run, following this manual: https://docs.google.com/document/d/1uKmW1dC0txRcns8DQJE83nbw5Co0auBl/edit?usp=sharing&ouid=112831865674885079233&rtpof=true&sd=true </li>
</ul>

## GUI Manual

### Processing One File
The general workflow for processing a single image in the Sphinctalyzer tool is:
<ol>
  <li>Click the "Open File" button and select the image in your file browser</li>
  <li>Input the reference frame, reference channel, and other parameters in the main GUI, then click the "Sphinctalyze" button</li>
  <li>The interface will prompt you to trace the brightest path in the selected reference frame</li>
  <li>Once the image is finished processing, an image slider interface and line scan movie will display on your screen. These interfaces enable you to visualize the output data, which is located in a corresponding data folder in the Sphincdata folder.</li>
  <li><b>Optional:</b> use the movie plot options panel to edit the axes, legend location, background color, and other parameters for the line scan movie, then click the "Plot Movie" button to update the movie file and display another line scan movie</li>
  <li>Click Reset to load another image/batch or close if you are done</li>
</ol>

### Batch Processing

Batch processing enables you to process as many images as you'd like in one go.

<ol>
  <li>Check the "Batch Process" checkbox at the top of the interface</li>
  <li>Click the "Open File" button and select multiple images (must be in the same directory)</li>
  <li>Input the parameters for the current image (name is displayed in a file information table), then click the "Trace Reference Frame and Move to Next Image" button</li>
  <li>The interface will prompt you to trace the brightest path for the current image. Then, complete steps 3 and 4 for the next image in the batch. Once you have done steps 3 and 4 for all the images in the batch, the interface will automatically begin processing all the images</li>
  <li>Once the batch is finished processing, use the "Image Selected:" drop down menu to select an image, then click the "Display Movie and Image Slider" to display the line scan movie and image slider interface for the selected image</li>
  <li><b>Optional:</b> use the movie plot options panel to edit the axes, legend location, background color, and other parameters for the line scan movie, then click the "Display Movie and Image Slider" button. This will update the movie file and display another line scan movie and image slider</li>
  <li>Once you are done, click reset to load another image/batch or close the interface</li>
</ol>

<b>NOTE:</b> if any errors occur, simply close out of the GUI and restart your workflow. Do not try to continue on the same GUI.
