Sequence module
===============

The sequence module contains functions related to sequence, trajectory and region.
The toolkit defines a region as a description of a set of
pixels in an image frame, a trajectory as a list of regions that can
either describe groundtruth annotations or tracker result, and a
sequence as a combination of a list of images, their corresponding
groundtruth annotations and additional metadata.

Sequence descriptor
-------------------

Each sequence is described using a sequence descriptor structure. The
structure contains the following fields:

-   **name** *(string)*: Sequence name string.
-   **directory** *(string)*: The directory path where images of the
    sequence are located.
-   **mask** *(string)*: Sequence name string.
-   **length** *(integer)*: Number of frames in the sequence
-   **file** *(string)*: Name of the groundtruth annotations file.
-   **images** *(cell)*: Cell array of strings that represent names of
    image files.
-   **groundtruth** *(cell)*: Cell array of matrices that represent
    region annotations.
-   **width** *(integer)*: Width of images in the sequence.
-   **height** *(integer)*: Height of images in the sequence.
-   **channels** *(integer)*: Number of color channels in the sequence.
-   **grayscale** *(boolean)*: True if the sequence is grayscale.
-   **labels** *(structure)*: Contains per-frame label data.
    -   **names** *(cell)*: Cell array of label names.
    -   **data** *(boolean)*: A boolean matrix where each column
            denotes per-frame label presence for a corresponding name in
            the *names* field.

-   **values** *(structure)*: Contains per-frame value data.
    -   **names** *(cell)*: Cell array of value names.
    -   **data** *(double)*: A double matrix where each column
            denotes per-frame value for a corresponding name in the
            *names* field.

-   **properties** *(structure)*: Additional sequence metadata.
-   **initialize** *(function)*: Function handle that is used to create
    initialization region for the tracker. By default the function
    simply returns groundtruth annotation for the given frame.

Most of the values in the descriptor are determined from the content of
the sequence directory.

Trajectory format
-----------------

The stored output of the tracker (the final combined trajectory) is encoded as 
text file where a region for each frame is encoded as comma-separated list. 
The absolute coordinates of a region have an origin in the top-left corner of the 
image with coordinates `0,0`. Currently there are three types of region formats 
that are supported by the system.

 * **Rectangle** - Specified by four values: `left`, `top`, `width`, and `height`.
 * **Polygon** - Specified by even number of at least six values that define points in the polygon (`x` and `y` coordinates).
 * **Special**: This stored sequence describes the entire tracking trial process 
    with failures and re-initializations encoded between regular frames 
    in a special format that is specified by a single value. This value can 
    have a special meaning. Initialization of the tracker is denoted 
    by `1`, failure of the tracker is denoted by `2` and undefined state (e.g. due to frame skipping) is denoted by `0`.


Module functions
----------------

### Loading

-   [create_sequence](create_sequence.m) - Create a new sequence descriptor
-   [load_sequences](load_sequences.m) - Load a set of sequences

### Conversion


-   [convert_sequences](convert_sequences.m) - Converts sequences using a converter
-   [sequence_grayscale](sequence_grayscale.m) - Returns grayscale sequence
-   [sequence_pixelchange](sequence_pixelchange.m) - Returns sequence with arbitrary pixel transformation
-   [sequence_resize](sequence_resize.m) - Returns resized sequence
-   [sequence_reverse](sequence_reverse.m) - Returns a reversed sequence
-   [sequence_skipping](sequence_skipping.m) - Returns sequence with skipped frames
-   [sequence_transform_initialization](sequence_transform_initialization.m) - Returns sequence with transformed initialization
-   [sequence_fragment](sequence_fragment.m) - Returns an array of subsequences

### Access

-   [get_image](get_image.m) - Returns image path for the given sequence
-   [get_region](get_region.m) - Returns region, or multiple regions for the given sequence
-   [get_frame_value](get_frame_value.m) - Returns frame values for the given sequence
-   [get_labels](get_labels.m) - Returns labels for a given frame
-   [query_label](query_label.m) - Find label in sequence

### Visualization

These functions are used to maniputate visualization information for
sequences.

-   [visualize_sequence](visualize_sequence.m) - Interactive sequence visualization
-   [select_sequence](select_sequence.m) - Select sequence from a list interactively

### Trajectory

-   [calculate_overlap](calculate_overlap.m) - Calculates overlap for two trajectories
-   write_trajectory - A MEX function that writes trajectory to a file
-   read_trajectory - A MEX function that reads trajectory from a file

### Region

-   [draw_region](draw_region.m) - Draw a region on the current figure
-   [region_offset](region_offset.m) - Translates the region
-   region_overlap - A MEX function that calculates the overlap between two regions
-   region_convert - A MEX function that converts between different region formats
-   region_mask - A MEX function that converts a region to a binary mask

Submodules
----------
 
-   [clustering](clustering/) - Sequence clustering code


