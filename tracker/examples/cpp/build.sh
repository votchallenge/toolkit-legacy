#!/bin/sh

g++ static.cpp -Wall -pedantic -I/usr/include/opencv -lopencv_core -lopencv_video -lopencv_imgproc -lopencv_highgui -o static

g++ ncc.cpp -Wall -pedantic -I/usr/include/opencv -lopencv_core -lopencv_video -lopencv_imgproc -lopencv_highgui -o ncc_file

g++ ncc.cpp -DTRAX -Wall -pedantic -I/usr/include/opencv -lopencv_core -lopencv_video -lopencv_imgproc -lopencv_highgui -ltrax -o ncc_trax
