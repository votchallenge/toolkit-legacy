
#include <stdio.h>

#include "mex.h"
#include "region.h"

Region* get_polygon(const mxArray * input) {
    
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
   
    }  
    
    return p;
    
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	Region* p1;
	Region* p2;

	if( nrhs != 2 ) mexErrMsgTxt("Two vector arguments (regions) required.");
	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

	for (int i = 0; i < 2; i++) {
        // TODO: accept integer for special frames
		if (mxGetClassID(prhs[i]) != mxDOUBLE_CLASS)
			mexErrMsgTxt("All input arguments must be of type double");
	
		if ( mxGetNumberOfDimensions(prhs[i]) > 2 || mxGetM(prhs[i]) > 1 ) mexErrMsgTxt("All input arguments must be vectors");

	}

	p1 = get_polygon(prhs[0]);
    p2 = get_polygon(prhs[1]);
    
    plhs[0] = mxCreateDoubleMatrix(1, 3, mxREAL);
    double *result = (double*) mxGetPr(plhs[0]);
            
    if (p1 && p2) {
        
        Overlap overlap = region_compute_overlap(p1, p2);

        result[0] = overlap.overlap;
        result[1] = overlap.only1;
        result[2] = overlap.only2;
        
    } else {
        
        result[0] = mxGetNaN();
        result[1] = mxGetNaN();
        result[2] = mxGetNaN();
        
    }
    
    if (p1) region_release(&p1);
    if (p2) region_release(&p2);

}

