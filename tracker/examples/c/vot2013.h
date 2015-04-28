/* -*- Mode: C++; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * This header file contains C functions that can be used to quickly integrate
 * VOT challenge support into your C or C++ tracker.
 *
 * Copyright (c) 2015, VOT Committee
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 

 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * The views and conclusions contained in the software and documentation are those
 * of the authors and should not be interpreted as representing official policies, 
 * either expressed or implied, of the FreeBSD Project.
 */

#ifndef _VOT_TOOLKIT_H
#define _VOT_TOOLKIT_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

// Bounding box type
typedef struct {
    float x;
    float y;
    float width;
    float height;
} VOTRectangle;

// Internal global variables:
// Current position in the sequence
int _vot_sequence_position = 0;
// Size of the sequence
int _vot_sequence_size = 0;
// List of image file names
char** _vot_sequence = NULL;
// List of results
VOTRectangle* _vot_result = NULL;

/**
 * Reads the input data and initializes all structures. Returns the initial 
 * position of the object as specified in the input data. This function should
 * be called at the beginnin of the tracking program.
 */
VOTRectangle vot_initialize() {

    int i, j;
    FILE *inputfile = fopen("region.txt", "r");
    FILE *imagesfile = fopen("images.txt", "r");

    if (!inputfile) {
        fprintf(stderr, "Initial region file (region.txt) not available. Stopping.\n");
        exit(-1);
    }

    if (!imagesfile) {
        fprintf(stderr, "Image list file (images.txt) not available. Stopping.\n");
        exit(-1);
    }

    size_t linesiz = sizeof(char) * 1024;
    char* linebuf = (char*) malloc(sizeof(char) * 1024);
    float* pointbuf = (float*) malloc(sizeof(float) * 4);
    ssize_t linelen = 0;
    VOTRectangle rect; rect.x = 0; rect.y = 0; rect.width = 0; rect.height = 0;
    
    for (i = 0; i < 4; i++) {
        if ((linelen = getdelim(&linebuf, &linesiz, ',', inputfile))>0) {
            if ((linebuf)[linelen - 1] == ',') {
                (linebuf)[linelen - 1] = '\0';
            }

            pointbuf[i] = atof(linebuf);
        } else 
            return rect;

    }

    rect.x = pointbuf[0];
    rect.y = pointbuf[1];
    rect.width = pointbuf[2];
    rect.height = pointbuf[3];

    free(pointbuf);
    fclose(inputfile);

    j = 32;
    _vot_sequence = (char**) malloc(sizeof(char*) * j);

    while (1) {

        if ((linelen=getline(&linebuf, &linesiz, imagesfile))<1)
            break;

        if ((linebuf)[linelen - 1] == '\n') {
            (linebuf)[linelen - 1] = '\0';
        }

        if (_vot_sequence_size == j) {
            j += 32;
            _vot_sequence = (char**) realloc(_vot_sequence, sizeof(char*) * j);
        }

        _vot_sequence[_vot_sequence_size] = (char *) malloc(sizeof(char) * (strlen(linebuf) + 1));

        strcpy(_vot_sequence[_vot_sequence_size], linebuf);

        _vot_sequence_size++;
    }

    free(linebuf);

    _vot_result = (VOTRectangle*) malloc(sizeof(VOTRectangle) * _vot_sequence_size);

    return rect;
}

/**
 * Returns the file name of the current frame. This function does not advance 
 * the current position.
 */
const char* vot_frame() {

    if (_vot_sequence_position >= _vot_sequence_size)
        return NULL;

    return _vot_sequence[_vot_sequence_position];

}

/**
 * Used to report position of the object. This function also advances the
 * current position.
 */
void vot_report(const VOTRectangle rect) {

    if (_vot_sequence_position >= _vot_sequence_size)
        return;
        
    _vot_result[_vot_sequence_position] = rect;
    _vot_sequence_position++;
}

/**
 * Stores results to the result file and frees memory. This function should be 
 * called at the end of the tracking program.
 */
void vot_deinitialize() {

    int i;

    FILE *outputfile = fopen("output.txt", "w");

    for (i = 0; i < _vot_sequence_position; i++) {
        VOTRectangle r = _vot_result[i];
        fprintf(outputfile, "%f,%f,%f,%f\n", r.x, r.y, r.width, r.height); 
    }

    fclose(outputfile);

    if (_vot_sequence) {
        for (i = 0; i < _vot_sequence_size; i++)
            free(_vot_sequence[i]);

        free(_vot_sequence);
    }

    if (_vot_result)
        free(_vot_result);

}

#endif
