

#include <stdio.h>
#include <vector>
#include <string>
#include <fstream>

#include "mex.h"
#include "region.h"

using namespace std;

char* getString(const mxArray *arg) {

	if (mxGetM(arg) != 1)
		mexErrMsgTxt("Must be a string");

    int l = (int) mxGetN(arg);

    char* str = (char *) malloc(sizeof(char) * (l + 1));
    
    mxGetString(arg, str, (l + 1));
    
    return str;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	if( nrhs != 1 ) mexErrMsgTxt("Exactly one string input argument required.");
	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

	char* path = getString(prhs[0]);

	std::ifstream ifs;
	ifs.open (path, std::ifstream::in);

	vector<region_container*> regions;

	if (ifs.is_open()) {

		int line_size = sizeof(char) * 2048;
		char* line_buffer = (char*) malloc(line_size);
		int line = 0;

    	while (ifs.good()) {

			line++;

			ifs.getline(line_buffer, line_size);

			if (!ifs.good()) break;

			region_container* region = NULL;

			if (region_parse(line_buffer, &region)) {

				regions.push_back(region);

			} else {

				char message[128];
				sprintf(message, "Unable to parse region at line %d, skipping", line);
				mexWarnMsgTxt(message);

			}

		}

        free(line_buffer);

		plhs[0] = mxCreateCellMatrix((int)regions.size(), 1);

		for (int i = 0; i < regions.size(); i++) {

			mxArray* val = NULL;
			region_container* region = regions[i];

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
				p[0] = region->data.special;
				break;
			}
			}

			if (val) mxSetCell(plhs[0], i, val);

			region_release(&region);

		}

	} else {
		free(path);
		mexErrMsgTxt("Unable to open file for reading.");
	}

	ifs.close();
	free(path);
}


