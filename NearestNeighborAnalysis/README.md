This code was used to determine the nearest neighbor distances between punctae, as described in the methods sections "Quantification of exocytosis and endocytosis punctae upon wounding" and "Nearest-neighbor analysis to assess spatial association of exocytic and endocytic events". <br>

PunctaeDetection_v0.1.4.ijm: <br> 
Image analysis to prepare images for the nearest neighbor analysis. Macro loads wounding ROI and creates circles with increasing distances from wound, and masks the cell to exclude background.

Nearest Neighbor analysis_v0.1.8.ipynb: <br>
Thresholds probability maps derived from applying the Ilastik model, counts and normalizes punctae per circle, calculates nearest neighbor distances. 
  
Figures showing data that were created using this code are: <br>
Figure 2 C and D
