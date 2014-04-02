
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "overlap.h"

#ifndef MAX
#define MAX(a,b) ((a) > (b)) ? (a) : (b)
#endif

#ifndef MIN
#define MIN(a,b) ((a) < (b)) ? (a) : (b)
#endif

#define MAX_MASK 4000

void free_polygon(Polygon* polygon) {

	free(polygon->x);
	free(polygon->y);

	polygon->x = NULL;
	polygon->y = NULL;

	polygon->count = 0;

}

Polygon* allocate_polygon(int count) {

	Polygon* polygon = (Polygon*) malloc(sizeof(Polygon));

	polygon->count = count;

	polygon->x = (float*) malloc(sizeof(float) * count);
	polygon->y = (float*) malloc(sizeof(float) * count);

	memset(polygon->x, 0, sizeof(float) * count);
	memset(polygon->y, 0, sizeof(float) * count);

	return polygon;
}

Polygon* clone_polygon(Polygon* polygon) {

	Polygon* clone = allocate_polygon(polygon->count);

	memcpy(clone->x, polygon->x, sizeof(float) * polygon->count);
	memcpy(clone->y, polygon->y, sizeof(float) * polygon->count);

	return clone;
}

Polygon* offset_polygon(Polygon* polygon, float x, float y) {

	Polygon* clone = clone_polygon(polygon);

	for (int i = 0; i < clone->count; i++) {
		clone->x[i] += x;
		clone->y[i] += y;
	}

	return clone;
}

void print_polygon(Polygon* polygon) {

	printf("%d:", polygon->count);

	for (int i = 0; i < polygon->count; i++) {
		printf(" (%f, %f)", polygon->x[i], polygon->y[i]);
	}

	printf("\n");

}

inline Bounds compute_bounds(Polygon* polygon) {

	Bounds bounds;
	bounds.top = MAX_MASK;
	bounds.bottom = -MAX_MASK;
	bounds.left = MAX_MASK;
	bounds.right = -MAX_MASK;

	for (int i = 0; i < polygon->count; i++) {
		bounds.top = MIN(bounds.top, polygon->y[i]);
		bounds.bottom = MAX(bounds.bottom, polygon->y[i]);
		bounds.left = MIN(bounds.left, polygon->x[i]);
		bounds.right = MAX(bounds.right, polygon->x[i]);
	}

	return bounds;

}

void rasterize_polygon(Polygon* polygon, char* mask, int width, int height) {

	int nodes, pixelX, pixelY, i, j, swap;

	int* nodeX = new int[polygon->count];

	memset(mask, 0, width * height * sizeof(char));

	//  Loop through the rows of the image.
	for (pixelY = 0; pixelY < height; pixelY++) {

		//  Build a list of nodes.
		nodes = 0;
		j = polygon->count - 1;

		for (i = 0; i < polygon->count; i++) {
			if (polygon->y[i] < (double) pixelY && polygon->y[j] >= (double) pixelY ||
					 polygon->y[j] < (double) pixelY && polygon->y[i] >= (double) pixelY) {
				nodeX[nodes++] = (int) (polygon->x[i] + (pixelY - polygon->y[i]) /
					 (polygon->y[j] - polygon->y[i]) * (polygon->x[j] - polygon->x[i])); 
			}
			j = i; 
		}

		//  Sort the nodes, via a simple “Bubble” sort.
		i = 0;
		while (i < nodes-1) {
			if (nodeX[i]>nodeX[i+1]) {
				swap = nodeX[i];
				nodeX[i] = nodeX[i+1];
				nodeX[i+1] = swap; 
				if (i) i--; 
			} else {
				i++; 
			}
		}

		//  Fill the pixels between node pairs.
		for (i=0; i<nodes; i+=2) {
			if (nodeX[i] >= width) break;
			if (nodeX[i+1] > 0 ) {
				if (nodeX[i] < 0 ) nodeX[i] = 0;
				if (nodeX[i+1] > width) nodeX[i+1] = width - 1;
				for (j = nodeX[i]; j < nodeX[i+1]; j++)
					mask[pixelY * width + j] = 1; 
			}
		}
	}

	delete[] nodeX;

}

Overlap compute_overlap(Polygon* p1, Polygon* p2) {

	Bounds b1 = compute_bounds(p1);
	Bounds b2 = compute_bounds(p2);

	int x = MIN(b1.left, b2.left);
	int y = MIN(b1.top, b2.top);

	int width = MAX(b1.right, b2.right) - x;	
	int height = MAX(b1.bottom, b2.bottom) - y;

	char* mask1 = new char[width * height];
	char* mask2 = new char[width * height];

	Polygon* op1 = offset_polygon(p1, -x, -y);
	Polygon* op2 = offset_polygon(p2, -x, -y);
/*
print_polygon(p1);print_polygon(p2);
print_polygon(op1);print_polygon(op2);
*/
	rasterize_polygon(op1, mask1, width, height); 
	rasterize_polygon(op2, mask2, width, height); 

	int mask_1 = 0, mask_2 = 0, mask_intersect = 0;

	for (int i = 0; i < width * height; i++) {
		if (mask1[i] && mask2[i]) mask_intersect++;
        else if (mask1[i]) mask_1++;
        else if (mask2[i]) mask_2++;
	}

	free_polygon(op1);
	free_polygon(op2);

	delete[] mask1;
	delete[] mask2;

    Overlap overlap;
    
    overlap.overlap =  (float) mask_intersect / (float) (mask_1 + mask_2 + mask_intersect);
    overlap.only1 =  (float) mask_1 / (float) (mask_1 + mask_2 + mask_intersect);
    overlap.only2 =  (float) mask_2 / (float) (mask_1 + mask_2 + mask_intersect);
    
	return overlap;

}


