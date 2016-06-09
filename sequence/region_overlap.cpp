
#include <stdio.h>
#include <string.h>

#include "mex.h"
#include "region.h"

#if defined(__OS2__) || defined(__WINDOWS__) || defined(WIN32) || defined(WIN64) || defined(_MSC_VER) 
#define strcmpi _strcmpi
#else
#define strcmpi strcasecmp
#endif

region_bounds get_bounds(const mxArray * input) {
    
    region_bounds bounds;

    if (!mxIsDouble(input)) {
        mexErrMsgTxt("Bounds has to be an array of doubles");
    }

	double *r = (double*)mxGetPr(input);
    int l = MAX(mxGetN(input), mxGetM(input));

    if (l == 4) {
        
        bounds.left = r[0];
        bounds.top = r[1];
        bounds.right = r[2];
        bounds.bottom = r[3];
   
    } else if (l == 2) {
        
        bounds.left = 0;
        bounds.top = 0;
        bounds.right = r[0];
        bounds.bottom = r[1];
   
    } else if (l == 0) {
        
        bounds = region_no_bounds;
   
    } else {
        mexErrMsgTxt("Bounds can only be formulated as [left, top, right, bottom] or [width, height] or []");
    }
    
    return bounds;
    
}

region_container* get_polygon(const mxArray * input) {
    
    if (!mxIsDouble(input)) {
        mexErrMsgTxt("Polygon has to be an array of doubles");
    }

    region_container* p = NULL;
	double *r = (double*)mxGetPr(input);
    int l = MAX(mxGetN(input), mxGetM(input));

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
   
    }  
    
    return p;
    
}

region_overlap compute_overlap(const mxArray* r1, const mxArray* r2, region_bounds bounds) {

	region_container* p1;
	region_container* p2;

    if ( mxGetNumberOfDimensions(r1) > 2 || mxGetM(r1) > 1 ) mexErrMsgTxt("All regions must be vectors");
    if ( mxGetNumberOfDimensions(r2) > 2 || mxGetM(r2) > 1 ) mexErrMsgTxt("All regions must be vectors");

    // TODO: accept integer for special frames
    if (mxGetClassID(r1) != mxDOUBLE_CLASS)
	    mexErrMsgTxt("Region input arguments must be of type double");

    if (mxGetClassID(r2) != mxDOUBLE_CLASS)
	    mexErrMsgTxt("Region input arguments must be of type double");

    p1 = get_polygon(r1);
    p2 = get_polygon(r2);
    
    region_overlap overlap;

    if (p1 != NULL && p2 != NULL) {

        overlap = region_compute_overlap(p1, p2, bounds);
	   
    } else {

        overlap.overlap = -1;
      
    }
    
    if (p1) region_release(&p1);
    if (p2) region_release(&p2);

    return overlap;
}

char* get_string(const mxArray *arg) {

	if (mxGetM(arg) != 1)
		mexErrMsgTxt("Must be an array of chars");

    int l = (int) mxGetN(arg);

    char* cstr = (char *) malloc(sizeof(char) * (l + 1));
    
    mxGetString(arg, cstr, (l + 1));

    return cstr;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	if( nrhs < 2 ) mexErrMsgTxt("Two vector or cell arguments (regions) required (plus an optional argument with bounds).");
	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

    region_bounds bounds = region_no_bounds;

    if (nrhs > 2) {
        bounds =  get_bounds(prhs[2]);
    }

    region_clear_flags(REGION_LEGACY_RASTERIZATION);
    if (nrhs > 3) {
	    char* codestr = get_string(prhs[3]);
	    if (strcmpi(codestr, "legacy") == 0) 
		    region_set_flags(REGION_LEGACY_RASTERIZATION);
	    free(codestr);
    }

    if (mxIsCell(prhs[0]) && mxIsCell(prhs[1])) {
	
        if ( MIN(mxGetM(prhs[0]), mxGetN(prhs[0])) != 1 ) mexErrMsgTxt("Cell array must be a vector");
        if ( MIN(mxGetM(prhs[1]), mxGetN(prhs[1])) != 1 ) mexErrMsgTxt("Cell array must be a vector");

        if ( MAX(mxGetM(prhs[0]), mxGetN(prhs[0])) != MAX(mxGetM(prhs[1]), mxGetN(prhs[1])))
            mexErrMsgTxt("Cell arrays must be of equal size");

        int num = MAX(mxGetM(prhs[0]), mxGetN(prhs[0]));

        plhs[0] = mxCreateDoubleMatrix(num, 3, mxREAL);
        double *result = (double*) mxGetPr(plhs[0]);

        for (int i = 0; i < num; i++) {
            mxArray* r1 = mxGetCell (prhs[0], i);
            mxArray* r2 = mxGetCell (prhs[1], i);

            region_overlap overlap = compute_overlap(r1, r2, bounds);

            if (overlap.overlap < 0) {
                result[i] = mxGetNaN();
                result[i + num] = mxGetNaN();
                result[i + num * 2] = mxGetNaN();
            } else {
                result[i] = overlap.overlap;
                result[i + num] = overlap.only1;
                result[i + num * 2] = overlap.only2;
            }
        }


    } else {

        plhs[0] = mxCreateDoubleMatrix(1, 3, mxREAL);
        double *result = (double*) mxGetPr(plhs[0]);
                
        region_overlap overlap = compute_overlap(prhs[0], prhs[1], bounds);
        if (overlap.overlap < 0) {
            result[0] = mxGetNaN();
            result[1] = mxGetNaN();
            result[2] = mxGetNaN();
        } else {
            result[0] = overlap.overlap;
            result[1] = overlap.only1;
            result[2] = overlap.only2;
        }
    }

}

