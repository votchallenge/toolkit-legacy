#!/bin/sh

gcc camshift.c -lm -g -I/usr/include/opencv -lopencv_core -lopencv_video -lopencv_imgproc -lopencv_highgui -o camshift

gcc static.c -g -o static
