
#include <stdio.h>
#include <vector>
#include <fstream>

#include "mex.h"
#include "region.h"

char* getString(const mxArray *arg) {

	if (mxGetM(arg) != 1)
		mexErrMsgTxt("Must be a string");

    int l = mxGetN(arg);

    char* str = (char *) malloc(sizeof(char) * (l + 1));
    
    mxGetString(arg, str, (l + 1));
    
    return str;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	if( nrhs != 2 ) mexErrMsgTxt("Exactly one string input argument and one cell array argument required.");
	if( nlhs != 0 ) mexErrMsgTxt("No output arguments required.");

	char* path = getString(prhs[0]);

	std::vector<Region*> regions;

	if (!mxIsCell(prhs[1]))
		mexErrMsgTxt("Second argument must be a cell array");

	int length = MAX(mxGetM(prhs[1]), mxGetN(prhs[1]));

	if ( MIN(mxGetM(prhs[1]), mxGetN(prhs[1])) != 1 )
		mexErrMsgTxt("Cell array must be a vector");

	for (int i = 0; i < length; i++) {

		mxArray* val = mxGetCell (prhs[1], i);
		double *d = (double*) mxGetPr(val);
		Region* region = NULL;

		int l = MAX(mxGetM(val), mxGetN(val));

		if (MIN(mxGetM(val), mxGetN(val)) == 1) { 

			if (l == 1) {

				region = region_create_special(d[0]);

			} else if (l == 4) {

				region = region_create_rectangle(d[0], d[1], d[2], d[3]);

			} else if (l > 5 && l % 2 == 0) {

				region = region_create_polygon(l / 2);

				for (int j = 0; j < l / 2; j++) {
					region->data.polygon.x[j] = d[j * 2];
					region->data.polygon.y[j] = d[j * 2 + 1];
				}
			}

		}

		if (region) {
			regions.push_back(region);
		} else {
			char message[128];
			sprintf(message, "Not a valid region at position %d, skipping", i+1);
			mexWarnMsgTxt(message);
		}

	}

	std::ofstream ofs;
	ofs.open (path, std::ofstream::out | std::ofstream::app);

	if (ofs.is_open()) {

    	for (int i = 0; i < regions.size(); i++) {

			Region* region = regions[i];

			char * tmp = region_string(region);

			if (tmp) {
				ofs << tmp << "\n";
				free(tmp);
			}
			
			region_release(&region);

		}

	} else {

		free(path);
		mexErrMsgTxt("Unable to open file for writing.");
	}

	ofs.close();
	free(path);
}

