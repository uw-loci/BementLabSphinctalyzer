# BementLabSphinctalyzer
> The Sphinctalyzer quantifies signal during the cell repair process.  It will work with anything that has a radial axis of symmetry or something close to it.  The key feature of this tool is the ability to track the edge of the wound over time.

## Dependencies
<ul>
  <li>MATLAB (preferably 2022b, but other versions should work fine)</li>
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
  <li>To run the GUI, simply open the SphinctalyzerGUI.m file in the SphinctalyzerFiles folder and run it. In the GUI interface, click Open File to load an image, input the necessary parameters, and click Sphinctalyze.</li>
  <li>Alternatively, The individual scripts can be run, following this manual: https://docs.google.com/document/d/1uKmW1dC0txRcns8DQJE83nbw5Co0auBl/edit?usp=sharing&ouid=112831865674885079233&rtpof=true&sd=true </li>
</ul>
