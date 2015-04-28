Integration examples (old approach)
===================================

This folder contains several examples of tracker integration for the old file-based integration approach and the new TraX based approach. It is recommended that you use the new approach, based on the [TraX protocol](https://github.com/lukacu/trax/), however, we also plan to support the old approach for some time.

Old approach
------------

At the moment the utilities that are provided with the examples supports storing the region in either axis-aligned rectangles (VOT2013) or four point polygons (VOT2014). In theory there is nothing in the toolkit that would prevent addition of more complex region descriptions, however, you will have to write the code yourself (see the part about the new region format in at the [Github wiki](https://github.com/vicoslab/vot-toolkit/wiki).).

TraX protocol
-------------

Only a Matlab example is included, for native tracker integration you can look at the [official TraX examples](https://github.com/lukacu/trax/tree/master/trackers).
