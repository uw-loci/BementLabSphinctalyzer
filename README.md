# BementLabSphinctalyzer
> The Sphinctalyzer quantifies signal during the cell repair process.  It will work with anything that has a radial axis of symmetry or something close to it.  The key feature of this tool is the ability to track the edge of the wound over time.

# Installation of the source-code version
## Dependencies
<ul>
  <li>MATLAB (preferably 2023b, but other versions should work fine). The follow Add-Ons should be installed:
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
  <li>To run the GUI, simply open the sphinctalyzerInitializerGUI.m file in the SphinctalyzerFiles folder and run it. In the GUI interface, follow the manual below to process one or multiple images.</li>
  <li>Alternatively, The individual scripts can be run, following [this manual]( https://docs.google.com/document/d/1uKmW1dC0txRcns8DQJE83nbw5Co0auBl/edit?usp=sharing&ouid=112831865674885079233&rtpof=true&sd=true) </li>
</ul>


# Installation of the standalone APP
The lastest standaloen version (v0.2.8-Beta2) for MAC(intel) can be downloaded from [the release page](https://github.com/uw-loci/BementLabSphinctalyzer/releases/tag/v0.2.8).  Follow the manual there to install and launch this standalone app.

# GUI Manual

The general workflow for processing image(s) in the Sphinctalyzer tool is listed blow. We are still working on a [more detailed manual](https://docs.google.com/document/d/1HpSfCLoYQDokeb5a44ElrpeCNgRjTkTBXIt11EEFtHs/edit?usp=sharing).
<ol>
  <li>Click the "Open File(s)" button and select the desired image(s) in your file browser.</li>
  <li>If an user wants to use customized parameters for the analysis/post-processing of one or more images, before importing any images in step 1, click the "Load Parameters" button to load a previously saved "parameters.csv" file.</li>  
  <li>A new GUI will open with an image previewer, parameters panel, and Image Queue table.</li><ul>
    <li>You can slide through the timepoints, change the channel, and customize the colormap of the current image displayed in the previewer.</li>
    <li>You can navigate between difference images in a batch using the Image Queue Table.</li>
  </ul>
  <li><b>For each image, input the reference frame(s), reference channel(s), and other parameters. Once you are done inputting the parameters for <i>ALL</i> images, click the "Sphinctalyze" button</b></li>
  <li>The interface will prompt you to trace the brightest path in the selected reference frame(s) for each image.</li>
  <li>Once the image or batch of images is finished processing, another GUI will open with a movie plot options panel, viewer selection table, image previewer, and image queue table. On the viewer selection table, you can select either "Image Timepoints" or "scan movietalyzerResults_1" to display the image timepoints or the line scan, respectively.
  <ul>
    <li>On the image timepoints viewer, you can slide through the timepoints, change the channel, and customize the colormap of the current image.</li>
    <li>Use the movie plot options panel to edit the axes, legend location, background color, and other parameters for the line scan movie, then click the "Write Movie" button. You will be prompted to either overwrite an existing line scan or create a new one.</li>
    <li>You can navigate between different images in a batch using Image Queue Table.</li>
  </li>
  </ul>
  <li>Once you are done, simply exit out of the GUI.</li>
</ol>
