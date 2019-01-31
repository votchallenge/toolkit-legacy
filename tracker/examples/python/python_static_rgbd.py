#!/usr/bin/python

import vot
import sys
import time

# *****************************************
# VOT: Create VOT handle at the beginning
#      Then get the initializaton region
#      and the first image
# *****************************************
handle = vot.VOT("rectangle", 'rgbd')
selection = handle.region()

# Process the first frame
colorimage, depthimage = handle.frame()
if not colorimage:
    sys.exit(0)

while True:
    # *****************************************
    # VOT: Call frame method to get path of the
    #      current image frame. If the result is
    #      null, the sequence is over.
    # *****************************************
    colorimage, depthimage = handle.frame()
    if not colorimage:
        break

    # *****************************************
    # VOT: Report the position of the object
    #      every frame using report method.
    # *****************************************
    handle.report(selection)

    time.sleep(0.01)


