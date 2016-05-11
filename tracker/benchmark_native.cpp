//
// This MEX function can be used to perform several native benchmarks.

// Normal C / C++ includes
#include <stdio.h>
#include <string.h>

// Including Matlab headers
#include "mex.h"

void convolve2D(double* in, double* out, int dataSizeX, int dataSizeY,  double* kernel, int kernelSizeX, int kernelSizeY) {
    int i, j, m, n;
    double *inPtr, *inPtr2, *outPtr, *kPtr;
    int kCenterX, kCenterY;
    int rowMin, rowMax;                             // to check boundary of input array
    int colMin, colMax;                             //

    // check validity of params
    if(!in || !out || !kernel) return;
    if(dataSizeX <= 0 || kernelSizeX <= 0) return;

    // find center position of kernel (half of kernel size)
    kCenterX = kernelSizeX >> 1;
    kCenterY = kernelSizeY >> 1;

    // init working  pointers
    inPtr = inPtr2 = &in[dataSizeX * kCenterY + kCenterX];  // note that  it is shifted (kCenterX, kCenterY),
    outPtr = out;
    kPtr = kernel;

    // start convolution
    for(i= 0; i < dataSizeY; ++i)                   // number of rows
    {
        // compute the range of convolution, the current row of kernel should be between these
        rowMax = i + kCenterY;
        rowMin = i - dataSizeY + kCenterY;

        for(j = 0; j < dataSizeX; ++j)              // number of columns
        {
            // compute the range of convolution, the current column of kernel should be between these
            colMax = j + kCenterX;
            colMin = j - dataSizeX + kCenterX;

            *outPtr = 0;                            // set to 0 before accumulate

            // flip the kernel and traverse all the kernel values
            // multiply each kernel value with underlying input data
            for(m = 0; m < kernelSizeY; ++m)        // kernel rows
            {
                // check if the index is out of bound of input array
                if(m <= rowMax && m > rowMin)
                {
                    for(n = 0; n < kernelSizeX; ++n)
                    {
                        // check the boundary of array
                        if(n <= colMax && n > colMin)
                            *outPtr += *(inPtr - n) * *kPtr;
                        ++kPtr;                     // next kernel
                    }
                }
                else
                    kPtr += kernelSizeX;            // out of bound, move to next row of kernel

                inPtr -= dataSizeX;                 // move input data 1 raw up
            }

            kPtr = kernel;                          // reset kernel to (0,0)
            inPtr = ++inPtr2;                       // next input
            ++outPtr;                               // next output
        }
    }

}

void maxfilter2D(double* in, double* out, int dataSizeX, int dataSizeY, int kernelSizeX, int kernelSizeY) {

    int kCenterX = kernelSizeX >> 1;
    int kCenterY = kernelSizeY >> 1;

    for (int i = 0; i < dataSizeY; i++) {
        for (int j = 0; j < dataSizeX; j++) {

            double max = in[i * dataSizeX + j];
            for (int k = - kCenterY; k <= kCenterY; k++) {
                for (int l = - kCenterX; l <= kCenterX; l++) {

                    int y = i + k;
                    int x = j + l;

                    if (x < 0 || x >= dataSizeX || y < 0 || y >= dataSizeY) continue;

                    double d = in[y * dataSizeX + x];
                    if (max < d) max = d;

                }
           }

           out[i * dataSizeX + j] = max;
        }
    }

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

char* getString(const mxArray *arg) {

	if (mxGetM(arg) != 1)
		mexErrMsgTxt("Must be an array of chars");

    int l = (int) mxGetN(arg);

    char* str = (char *) malloc(sizeof(char) * (l + 1));
    
    mxGetString(arg, str, (l + 1));
    
    return str;
}

int getOperationIndex(char* operation) {
    
    if (strcmp(operation, "convolution") == 0) {
        return 1;
    }
    
    if (strcmp(operation, "maxfilter") == 0) {
        return 2;
    }

    return 0;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	int N_dims, W, H, N, M;

    N = 3;
    M = 3;

	if( nrhs < 1 ) mexErrMsgTxt("At least one input argument required.");
    
    if (! mxIsChar (prhs[0]) || mxGetNumberOfDimensions (prhs[0]) > 2) mexErrMsgTxt ("First argument must be a string");
    
    char* operation = getString(prhs[0]);
    
    int opcode = getOperationIndex(operation);
    
    free(operation);

    if (opcode == 1) {

        if( nrhs != 3 ) mexErrMsgTxt("Three parameters required.");   

        if( nlhs > 1 ) mexErrMsgTxt("At most one output argument supported.");

        W = mxGetM(prhs[1]);
        H = mxGetN(prhs[1]);

        double *source = (double*)mxGetPr(prhs[1]);

        int kW = mxGetM(prhs[2]);
        int kH = mxGetN(prhs[2]);

        double *kernel = (double*)mxGetPr(prhs[2]);
        
        plhs[0] = mxCreateDoubleMatrix(W, H, mxREAL);
        double *destination = (double*) mxGetPr(plhs[0]);        

      	convolve2D(source, destination, W, H, kernel, kW, kH);

    } else if (opcode == 2) {
        
        if( nrhs != 4 ) mexErrMsgTxt("Four parameters required.");   

        if( nlhs > 1 ) mexErrMsgTxt("At most one output argument supported.");

        int kW = getSingleInteger(prhs[2]);
        int kH = getSingleInteger(prhs[3]);
        
        W = mxGetM(prhs[1]);
        H = mxGetN(prhs[1]);

        double *source = (double*)mxGetPr(prhs[1]);

        plhs[0] = mxCreateDoubleMatrix(W, H, mxREAL);
        double *destination = (double*) mxGetPr(plhs[0]);        

    	maxfilter2D(source, destination, W, H, kW, kH);
        
    } else {
        mexErrMsgTxt("Unknown operation.");
    }
    
}

