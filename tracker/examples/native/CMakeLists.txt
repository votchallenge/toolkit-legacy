PROJECT(static)
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# Try to find TraX header and library ...
FIND_FILE(TRAX_HEADER NAMES trax.h PATHS ../../../native)
IF (EXISTS ${TRAX_HEADER})
    GET_FILENAME_COMPONENT(TRAX_DIR ${TRAX_HEADER} DIRECTORY)
    ADD_DEFINITIONS(-DTRAX) # Added to enable TraX protocol support
    LINK_DIRECTORIES(${TRAX_DIR}) # Add library directory
    INCLUDE_DIRECTORIES(${TRAX_DIR}) # Add includes directory
ENDIF()

ADD_EXECUTABLE(static_c static.c) # Generate executable for C tracker
ADD_EXECUTABLE(static_cpp static.cpp) # Generate executable for C++ tracker

IF (EXISTS ${TRAX_HEADER})
    TARGET_LINK_LIBRARIES(static_c trax) # Link with trax library
    TARGET_LINK_LIBRARIES(static_cpp trax) # Link with trax library
ENDIF()

