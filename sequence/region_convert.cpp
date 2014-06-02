
#include <stdio.h>
#include <string>

#include "mex.h"
#include "region.h"

using namespace std;

Region* array_to_region(const mxArray * input) {
    
    Region* p = NULL;
	double *r = (double*)mxGetPr(input);
    int l = mxGetN(input);
    
    if (l % 2 == 0 && l > 6) {
        
        p = region_create_polygon(l / 2);
        
        for (int i = 0; i < p->data.polygon.count; i++) {
            p->data.polygon.x[i] = r[i*2];
            p->data.polygon.y[i] = r[i*2+1];
        }
        
    } else if (l == 4) {
        
        p = region_create_polygon(4);
        
        p->data.polygon.x[0] = r[0];
        p->data.polygon.x[1] = r[0] + r[2];
        p->data.polygon.x[2] = r[0] + r[2];
        p->data.polygon.x[3] = r[0];

        p->data.polygon.y[0] = r[1];
        p->data.polygon.y[1] = r[1];
        p->data.polygon.y[2] = r[1] + r[3];
        p->data.polygon.y[3] = r[1] + r[3];
   
    } if (l == 1) {
        
        p = region_create_special((int)r[0]);
        
    } 
    
    return p;
    
}

mxArray* region_to_array(const Region* region) {

	mxArray* val = NULL;

	switch (region->type) {
	case RECTANGLE: {
		val = mxCreateDoubleMatrix(1, 4, mxREAL);
		double *p = (double*) mxGetPr(val);
		p[0] = region->data.rectangle.x;
		p[1] = region->data.rectangle.y;
		p[2] = region->data.rectangle.width;
		p[3] = region->data.rectangle.height;
		break;
	}
	case POLYGON: {
		val = mxCreateDoubleMatrix(1, region->data.polygon.count * 2, mxREAL);
		double *p = (double*) mxGetPr(val);

		for (int i = 0; i < region->data.polygon.count; i++) {
			p[i*2] = region->data.polygon.x[i];
			p[i*2+1] = region->data.polygon.y[i];
		}

		break;
	}
	case SPECIAL: {
		val = mxCreateDoubleMatrix(1, 1, mxREAL);
		double *p = (double*) mxGetPr(val);
		p[0] = (double) region->data.special;
		break;
	}
	}

	return val;
}

string get_string(const mxArray *arg) {

	if (mxGetM(arg) != 1)
		mexErrMsgTxt("Must be an array of chars");

    int l = (int) mxGetN(arg);

    char* cstr = (char *) malloc(sizeof(char) * (l + 1));
    
    mxGetString(arg, cstr, (l + 1));
    
	string str(cstr);

	free(cstr);

    return str;
}

bool get_region_code(string str, RegionType& type) {
    
    if (str == "rectangle") {
        type = RECTANGLE;
		return true;
    }
    
    if (str == "polygon") {
        type = POLYGON;
		return true;
    } 

  	return false;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	RegionType format;
	Region* p;
	Region* c;

	if( nrhs != 2 ) mexErrMsgTxt("Two vector arguments (region and format) required.");
	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

	if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
		mexErrMsgTxt("First input argument must be of type double");

	if ( mxGetNumberOfDimensions(prhs[0]) > 2 || mxGetM(prhs[0]) > 1 ) mexErrMsgTxt("First input argument must be a vector");

	if (!get_region_code(get_string(prhs[1]), format))
		mexErrMsgTxt("Not a valid format");

	p = array_to_region(prhs[0]);

	if (!p)
		mexErrMsgTxt("Not a valid region vector");

	c = region_convert(p, format);

	if (!c) {
		if (p) region_release(&p);
		mexErrMsgTxt("Unable to convert region");
	}

    plhs[0] = region_to_array(c);

	if (c) region_release(&c);
	if (p) region_release(&p);
}

