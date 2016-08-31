
#include <stdio.h>
#include <string.h>

#include "mex.h"
#include "region.h"

#define MEX_TEST_DOUBLE(I) (mxGetClassID(prhs[I]) == mxDOUBLE_CLASS)
#define MEX_TEST_VECTOR(I) (mxGetNumberOfDimensions(prhs[I]) == 2 && mxGetM(prhs[I]) == 1)

#if defined(__OS2__) || defined(__WINDOWS__) || defined(WIN32) || defined(WIN64) || defined(_MSC_VER) 
#define strcmpi _strcmpi
#else
#define strcmpi strcasecmp
#endif

region_container* get_polygon(const mxArray * input) {
    
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

    return 0;
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

	region_container* p = NULL;

	if( nrhs < 3 ) mexErrMsgTxt("One vector and two integer arguments required.");
	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

	if (!MEX_TEST_VECTOR(0) || !MEX_TEST_DOUBLE(0)) mexErrMsgTxt("First argument must be a vector of type double");

    region_clear_flags(REGION_LEGACY_RASTERIZATION);
    if (nrhs > 3) {
	    char* codestr = get_string(prhs[3]);
	    if (strcmpi(codestr, "legacy") == 0) 
		    region_set_flags(REGION_LEGACY_RASTERIZATION);
	    free(codestr);
    }

	int width = getSingleInteger(prhs[1]);
	int height = getSingleInteger(prhs[2]);

	p = get_polygon(prhs[0]);
	float* tmp = p->data.polygon.x; p->data.polygon.x = p->data.polygon.y; p->data.polygon.y = tmp;

    plhs[0] = mxCreateLogicalMatrix(height, width);
    char *result = (char*) mxGetData(plhs[0]);
            
    region_get_mask(p, result, width, height);
    
    if (p) region_release(&p);

}

