
#include <stdio.h>
#include <string.h>

#include "mex.h"
#include "region.h"

#if defined(__OS2__) || defined(__WINDOWS__) || defined(WIN32) || defined(WIN64) || defined(_MSC_VER) 
#define strcmpi _strcmpi
#else
#define strcmpi strcasecmp
#endif


region_container* array_to_region(const mxArray * input) {
    
    region_container* p = NULL;
	double *r = (double*)mxGetPr(input);
    int l = mxGetN(input);
    
    if (l % 2 == 0 && l > 6) {
        
        p = region_create_polygon(l / 2);
        
        for (int i = 0; i < p->data.polygon.count; i++) {
            p->data.polygon.x[i] = r[i*2];
            p->data.polygon.y[i] = r[i*2+1];
        }
        
    } else if (l == 4) {
        
        region_container* t = NULL;

        t = region_create_rectangle(r[0], r[1], r[2], r[3]);
        
        p = region_convert(t, POLYGON);
   
        region_release(&t);
   
    } if (l == 1) {
        
        p = region_create_special((int)r[0]);
        
    } 
    
    return p;
    
}

mxArray* region_to_array(const region_container* region) {

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

char* get_string(const mxArray *arg) {

	if (mxGetM(arg) != 1)
		mexErrMsgTxt("Must be an array of chars");

    int l = (int) mxGetN(arg);

    char* cstr = (char *) malloc(sizeof(char) * (l + 1));
    
    mxGetString(arg, cstr, (l + 1));

    return cstr;
}

bool get_region_code(char* str, region_type& type) {
    
    if (strcmpi(str, "rectangle") == 0) {
        type = RECTANGLE;
		return true;
    }
    
    if (strcmpi(str, "polygon") == 0) {
        type = POLYGON;
		return true;
    } 

  	return false;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	region_type format;
	region_container* p = NULL;
	region_container* c = NULL;

	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

	if( nrhs == 1 ) {
		char* raw = get_string(prhs[0]);

		region_parse(raw, &c);
		free(raw);

		if (!c)
			mexErrMsgTxt("Not a valid region string");

		plhs[0] = region_to_array(c);
		return;
	}

	if( nrhs != 2 ) mexErrMsgTxt("Two vector arguments (region and format) required.");

	if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
		mexErrMsgTxt("First input argument must be of type double");

	if ( mxGetNumberOfDimensions(prhs[0]) > 2 || mxGetM(prhs[0]) > 1 ) mexErrMsgTxt("First input argument must be a vector");

	char* codestr = get_string(prhs[1]);

	if (!get_region_code(codestr, format)) {
		free(codestr);
		mexErrMsgTxt("Not a valid format");
	}

	free(codestr);

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

