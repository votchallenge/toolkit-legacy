
#include <stdio.h>

#include "mex.h"
#include "region.h"

#define MEX_TEST_DOUBLE(I) (mxGetClassID(prhs[I]) == mxDOUBLE_CLASS)
#define MEX_TEST_VECTOR(I) (mxGetNumberOfDimensions(prhs[I]) == 2 && mxGetM(prhs[I]) == 1)


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

int getSingleInteger(const mxArray *arg) {

	if (mxGetM(arg) != 1 || mxGetN(arg) != 1)
		mexErrMsgTxt("Parameter must be a single value");

    if (mxIsInt32(arg))
        return ((int*)mxGetPr(arg))[0];

    if (mxIsDouble(arg))
        return (int) ((double*)mxGetPr(arg))[0];
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	Region* p = NULL;

	if( nrhs != 3 ) mexErrMsgTxt("Two vector and two integer arguments required.");
	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

	if (!MEX_TEST_VECTOR(0) || !MEX_TEST_DOUBLE(0)) mexErrMsgTxt("First argument must be a vector of type double");

	int width = getSingleInteger(prhs[1]);
	int height = getSingleInteger(prhs[2]);

	p = get_polygon(prhs[0]);
	float* tmp = p->data.polygon.x; p->data.polygon.x = p->data.polygon.y; p->data.polygon.y = tmp;

    plhs[0] = mxCreateLogicalMatrix(height, width);
    char *result = (char*) mxGetData(plhs[0]);
            
    region_mask(p, result, height, width);
    
    if (p) region_release(&p);

}

