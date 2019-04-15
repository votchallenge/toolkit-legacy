PROJECT(static)
CMAKE_MINIMUM_REQUIRED(VERSION 3.3)

# Try to find TraX header and library ...
FIND_PACKAGE(trax REQUIRED COMPONENTS core)
LINK_DIRECTORIES(${TRAX_LIBRARY_DIRS})
LINK_LIBRARIES(${TRAX_LIBRARIES})
INCLUDE_DIRECTORIES(AFTER ${TRAX_INCLUDE_DIRS})

ADD_EXECUTABLE(static_c static.c) # Generate executable for C tracker
ADD_EXECUTABLE(static_cpp static.cpp) # Generate executable for C++ tracker
ADD_EXECUTABLE(static_cpp_rgbd static_rgbd.cpp) # Generate executable for C++ tracker for RGBD sequences

FIND_PACKAGE(OpenCV)

IF (OpenCV_FOUND)
INCLUDE_DIRECTORIES(AFTER ${OpenCV_INCLUDE_DIRS})
ADD_EXECUTABLE(ncc ncc.cpp) # Generate executable for OpenCV demo tracker
TARGET_LINK_LIBRARIES(ncc ${OpenCV_LIBS}) # Link with trax library

IF ("opencv_tracking" IN_LIST OpenCV_LIBS)
FOREACH(TRACKER "CSRT" "MIL" "MedianFlow" "MOSSE" "KCF" "Boosting" "GOTURN")
ADD_EXECUTABLE(opencv_${TRACKER} opencv.cpp)
TARGET_COMPILE_DEFINITIONS(opencv_${TRACKER} PUBLIC -DTRACKER=Tracker${TRACKER})
TARGET_LINK_LIBRARIES(opencv_${TRACKER} ${OpenCV_LIBS}) # Link with OpenCV library
ENDFOREACH(TRACKER)
ENDIF()

ENDIF()

