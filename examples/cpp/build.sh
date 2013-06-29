#!/bin/sh

g++ static.cpp -Wall -pedantic -I/usr/include/opencv -lopencv_core -lopencv_video -lopencv_imgproc -lopencv_highgui -o static
    
