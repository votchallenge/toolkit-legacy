

#include <stdio.h>
#include <vector>

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

	if( nrhs != 1 ) mexErrMsgTxt("Exactly one string input argument required.");
	if( nlhs != 1 ) mexErrMsgTxt("Exactly one output argument required.");

	char* path = getString(prhs[0]);

	FILE* fp = fopen(path, "r");

	std::vector<Region*> regions;

	if (fp) {

		size_t line_size = sizeof(char) * 2048;
		char* line_buffer = (char*) malloc(line_size);
		ssize_t line_length = 0;
		int line = 0;

    	while (1) {

			line++;

		    if ((line_length = getline(&line_buffer, &line_size, fp)) < 1)
		        break;

			if ((line_buffer)[line_length - 1] == '\n') { (line_buffer)[line_length - 1] = '\0'; }

			Region* region;

			if (region_parse(line_buffer, &region)) {

				regions.push_back(region);

			} else {

				char message[128];
				sprintf(message, "Unable to parse region at line %d, skipping", line);
				mexWarnMsgTxt(message);

			}

		}

		plhs[0] = mxCreateCellMatrix(regions.size(), 1);

		for (int i = 0; i < regions.size(); i++) {

			mxArray* val = NULL;
			Region* region = regions[i];

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

	fclose(fp);
	free(path);
}

