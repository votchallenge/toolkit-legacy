#!/bin/sh

OPENCV_INCLUDES=/usr/include/opencv
TRAX_INCLUDES=../../../native
TRAX_LIBRARY=../../../native

gcc static.c -I$TRAX_INCLUDES -L$TRAX_LIBRARY -ltraxstatic -lm -g -o static_c

g++ static.cpp -I$TRAX_INCLUDES -L$TRAX_LIBRARY -ltraxstatic -lm -g -o static_cpp

g++ static_rgbd.cpp -I$TRAX_INCLUDES -L$TRAX_LIBRARY -ltraxstatic -lm -g -o static_cpp_rgbd

g++ ncc.cpp -I$OPENCV_INCLUDES -I$TRAX_INCLUDES -L$TRAX_LIBRARY -ltraxstatic -lm -lopencv_core -lopencv_video -lopencv_imgproc -lopencv_highgui -g -o ncc

