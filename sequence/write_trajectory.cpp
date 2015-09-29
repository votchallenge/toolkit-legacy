
#include <stdio.h>

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

    region_container** regions = NULL;

	if( nrhs != 2 ) mexErrMsgTxt("Exactly one string input argument and one cell array argument required.");
	if( nlhs != 0 ) mexErrMsgTxt("No output arguments required.");

	char* path = getString(prhs[0]);

	if (!mxIsCell(prhs[1]))
		mexErrMsgTxt("Second argument must be a cell array");

	int length = MAX(mxGetM(prhs[1]), mxGetN(prhs[1]));

	if ( MIN(mxGetM(prhs[1]), mxGetN(prhs[1])) != 1 )
		mexErrMsgTxt("Cell array must be a vector");

    regions = (region_container**) malloc(sizeof(region_container*) * length);

	for (int i = 0; i < length; i++) {

		mxArray* val = mxGetCell (prhs[1], i);

		region_container* region = NULL;

        if (val) {

		    double *d = (double*) mxGetPr(val);
		    int l = MAX(mxGetM(val), mxGetN(val));

		    if (!mxIsEmpty(val) && MIN(mxGetM(val), mxGetN(val)) == 1) { 

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

        }

		if (region) {
			regions[i] = region;
		} else {
			char message[128];
			sprintf(message, "Not a valid region at position %d, skipping", i+1);
			mexWarnMsgTxt(message);
            regions[i] = region_create_special(-1);
		}

	}

    FILE* fp = fopen(path, "w");

	if (fp != NULL) {

    	for (int i = 0; i < length; i++) {

			region_container* region = regions[i];

			char* tmp = region_string(region);

			if (tmp) {
				fputs(tmp, fp);
                fputc('\n', fp);
				free(tmp);
			}
			
			region_release(&region);

		}

	} else {

		free(path);
		mexErrMsgTxt("Unable to open file for writing.");
	}

    if (regions)
        free(regions);

	fclose(fp);
	free(path);
}

