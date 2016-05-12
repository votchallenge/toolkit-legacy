Sequence clustering module
==========================

The clustering module contains functions related to sequence clustering and cluster analysis.
The purpose of sequence clustering is to reduce the size of the dataset while retaining all the
representative attributes.

Module functions
----------------

### Clustering

-    [run_clustering](run_clustering.m) - Perform the automatic sequence clustering procedure in the current workspace
-    [compute_attributes](compute_attributes.m) - Calculates automatic sequence attributes for given sequences
-    [compute_performance_difficulty](compute_performance_difficulty.m) - Measures sequence difficulty as a averaged trackers performance
-    [compute_clusters](compute_clusters.m) - Clusters the sequences based on feature vectors
-    [compute_features](compute_features.m) - Calculates feature vectors for each sequence from their attributes 
-    [sequence_selection](sequence_selection.m) - Algorithm for automatic sequence sampling from clusters using greedy approach
-    [visualize_clusters](visualize_clusters.m) - Saves sequences per cluster

### Attributes

-    [attribute_illumination_change](attribute_illumination_change.m) - Computes the illumination change attribute of the object in seqeunce
-    [attribute_motion_absolute](attribute_motion_absolute.m) - Computes the absolute motion attribute of the object in seqeunce
-    [attribute_scene_complexity](attribute_scene_complexity.m) - Computes the scene complexity attribute in seqeunce
-    [attribute_blur](attribute_blur.m) - Computes the blur attribute in seqeunce
-    [attribute_motion_change](attribute_motion_change.m) - Computes the object motion attribute of the object in seqeunce
-    [attribute_clutter](attribute_clutter.m) - Computes the amount of clutter in seqeunce
-    [attribute_aspect_ratio](attribute_aspect_ratio.m) - Computes the aspect ratio change attribute for the object in seqeunce
-    [attribute_color_change](attribute_color_change.m) - Computes the color change attribute of the object in seqeunce
-    [attribute_deformation](attribute_deformation.m) - Computes the deformation attribute of the object in seqeunce
-    [attribute_size_change](attribute_size_change.m) - Computes the object size change attribute of the object in seqeunce
-    [attribute_camera_motion](attribute_camera_motion.m) - Computes the camera motion attribute in seqeunce

