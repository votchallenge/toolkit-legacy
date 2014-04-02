
#ifndef _OVERLAP_H_
#define _OVERLAP_H_

typedef struct Polygon {

	int count;

	float* x;
	float* y;

} Polygon;

typedef struct Bounds {

	float top;
	float bottom;
	float left;
	float right;

} Bounds;

typedef struct Overlap {

	float overlap;    
    float only1;
    float only2;

} Overlap;

void free_polygon(Polygon* polygon);

Polygon* allocate_polygon(int count);

void print_polygon(Polygon* polygon);

Overlap compute_overlap(Polygon* p1, Polygon* p2);

#endif
