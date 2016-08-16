/*#define DEBUG*/
/*#define DEBUG_PAUSE*/
/*#define DEBUG_SEARCH*/
/*#define DEBUG_SEARCH_PAUSE*/

/*=============================================================
% function qHistogram = ndHistc (mData, vEdge1, vEdge2, ... )
%
% * Input Arguments: 
%
%      + mData: nRecord by nDim 2-dimensional array of doubles
%      + vEdge1, vEdge2, ... : nDim vectors of histogram edges
%
% * Return value:
%
%      + qHistogram: nDim-dimensional data cube 
%           containing number of points in each cell 
%           defined by histogram edges. For instance, 
%           qHistogram(1,1,1,...) means number of data points
%           satisfying 
%               vEdge1(1) <= mData(:,1) < vEdge1(2) & ...
%               vEdge2(1) <= mData(:,2) < vEdge1(2) & ...
%               vEdge3(1) <= mData(:,3) < vEdge1(3) & ...
%               ...
%      
% * Comparison with ndhist.m (compiled using mcc -x ndhist)
%      + 1e6 by 2 data -> 5 by 6
%          ndhist.m    79.49   sec
%          ndhistc.c    0.4610 sec
%
%      + 1e6 by 5 data -> 5 by 6 by 7 by 8 by 9
%          ndhist.m   199.32   sec
%          ndhistc.c    2.4430 sec
%
%      ==> More efficient if More data points & Less dimensions
%

%   CopyLEFT (c) 2003 by Kangwon "Wayne" Lee. ;)
%   $Revision: 1.0 $
%   Implemented in a MATLAB mex file.
============================================================*/

#include "mex.h"

#ifndef HAVE_OCTAVE
#include "matrix.h"
#endif

int* vnDim2vnMul (const int*vnDim, const int nDim);
int vCoord2iAddr (const int*vCoord, const int*vnMul, const int nDim);
mxArray * hist2dc(const mxArray *pmYX, const mxArray *pveY, const mxArray *pveX);
mxArray * ndhistc(const int nIn, const mxArray *paramIn[]);
int search(const double *pveX, const int nX, const double rX);

/*Function entry point*/
void mexFunction(int nOut, mxArray *paramOut[], int nIn, const mxArray *paramIn[])
{
  /* Declare variables. */ 
  int nNonZero = 0, count = 0; 
  const int *vnDimIn;
  
  /* Check for proper number of input and output arguments. */    
  if(nIn < 2) 
  {
    mexErrMsgTxt("At least two input arguments required.");
  } 
  
  /* Check data type of input argument. */
  if(!(mxIsDouble(paramIn[0]))) 
  {
    mexErrMsgTxt("Input array must be of type double.");
  }
/******************************************************************************************/    
  vnDimIn = mxGetDimensions(paramIn[0]);

#ifdef DEBUG
    mexPrintf("vnDimIn %x\n",vnDimIn);
#endif

  /*mexEvalString("pause");     */

  if ((vnDimIn[1]+1) > nIn)
  {
    mexPrintf("nDimIn == %d : nIn == %d\n",vnDimIn[1], nIn);
    mexErrMsgTxt("# edges < # Input array column.");
  }
  
  if ((vnDimIn[1]+1) < nIn)
  {
    mexPrintf("nDimIn == %d : nIn == %d\n",vnDimIn[1], nIn);
    mexWarnMsgTxt("# edges > # Input array column. Using first [# Input array column] edges.");
    nIn = (vnDimIn[1]+1);
  }

/******************************************************************************************/    
    paramOut[0] = ndhistc(nIn, paramIn);

}

/******************************************************************************************

    Build writing address multipler
    
    vnMul = [1, lenDim1, lenDim1 * lenDim2, ... ]
    
    iAddress = vnMul * vCoord'

    2D array
    [00 01]
    [10 11]
    [20 21];
    Matlab matrix in memory
    [00]  0   = 0 x 1 + 0 x 3
    [10]  1   = 1 x 1 + 0 x 3
    [20]  2   = 2 x 1 + 0 x 3
    [01]  3   = 0 x 1 + 1 x 3
    [11]  4   = 1 x 1 + 1 x 3
    [21]  5   = 2 x 1 + 1 x 3
%                   ^       ^ multiplier for dim 2 == size of dim 1
    
******************************************************************************************/
int* vnDim2vnMul (const int*vnDim, const int nDim)
{
    int * vnMul = mxCalloc (nDim, sizeof(int)), iDim;

#ifdef DEBUG
    mexPrintf("vnDim2vnMul\n");
#endif
    
    vnMul[0] = 1;
    for ( iDim = 1; iDim < nDim; iDim ++ )
    {
        int iDimPrev = iDim - 1;
        vnMul[iDim] = vnMul[iDimPrev] * vnDim[iDimPrev];

#ifdef DEBUG
        mexPrintf("iDim %d/%d, iDimPrev %d, vnMul[iDimPrev] %d, vnMul[iDim] %d\n",
            iDim, nDim, iDimPrev, vnMul[iDimPrev], vnMul[iDim]);
#endif
        
    }
    
    return vnMul;
}

/******************************************************************************************

    Converting multi dimensional indices into an address
    
    iAddress = vnMul * vCoord'

    vnMul = [1, lenDim1, lenDim1 * lenDim2, ... ]
    
    2D array
    [00 01]
    [10 11]
    [20 21];
    Matlab matrix in memory
    [00]  0   = 0 x 1 + 0 x 3
    [10]  1   = 1 x 1 + 0 x 3
    [20]  2   = 2 x 1 + 0 x 3
    [01]  3   = 0 x 1 + 1 x 3
    [11]  4   = 1 x 1 + 1 x 3
    [21]  5   = 2 x 1 + 1 x 3
%                   ^       ^ multiplier for dim 2 == size of dim 1
    
******************************************************************************************/
int vCoord2iAddr (const int*vCoord, const int*vnMul, const int nDim)
{
    int iAddr = vCoord[0];
    int iDim/* = 1*/;
    for (iDim = 1;iDim < nDim; iDim++)
    {
        iAddr += vCoord[iDim] * vnMul[iDim];
        /*iDim ++;*/
    }
    return iAddr;
}

/******************************************************************************************

    Function ndhistc - Major part of the program
    
    
    
******************************************************************************************/
mxArray * ndhistc(const int nIn, const mxArray *paramIn[]) 
/* const mxArray *pmData, const mxArray *pveY, const mxArray *pveX) */
{
    /*Table Data*/
    const mxArray *pmData = paramIn[0];                 /* Input data table */
    int *vnDimIn = mxGetDimensions(pmData);       /* Input table size */
    const int nRecord = vnDimIn[0], nDim = vnDimIn[1];  /* Input table size */
    const double * pData = mxGetPr(pmData);             /* Pointer to input data table */

    /*Edge Data*/
    int *vnDimOut = (int *)mxCalloc (nDim, sizeof(int)), 
        *vnMulOut = 0, 
        *vnEdge = mxCalloc (nDim, sizeof(int)), 
        *vCoord = mxCalloc (nDim, sizeof(int));
    double ** vpvEdge = (double **)mxCalloc (nDim, sizeof(double *));
    int *vnAdd = (int *)mxCalloc (nDim, sizeof(int)); 
    
    /*control variables : loop, break*/
    int iRecord = 0;
    int bError = 0;

    /*Return buffer*/
    mxArray * mxHist;
    double * pmHist;
    int nSizeHist;

    /*
    Build edge vector data group
    vnEdge   : array of edge size
    vnDimOut : size of histogram
    vpvEdge  : array of pointers to edge
    vnAdd    : to calculate address of input data within the table
    vnMulOut : to calculate address of output data within the histogram
    */
    
    int iDim = 0;
    /*(int )vnDimIn &*/
/*    if (!((int )vnDimOut & (int )vnEdge & (int )vCoord & (int )vpvEdge & (int )vnAdd))
    {
        mexPrintf("vnDimOut %d, vnEdge %d, vCoord %d, vpvEdge %d, vnAdd %d\n",
            (int )vnDimOut, (int )vnEdge, (int )vCoord, (int )vpvEdge, (int )vnAdd);
        mexErrMsgTxt("Memory allocation error (1)");
    }*/
    

    for(iDim = 0;iDim < nDim; iDim++)
    {
        const mxArray * pveDim = paramIn[iDim + 1];
        
        /*mexEvalString("pause");     */
        
        vnEdge[iDim] = mxGetNumberOfElements(pveDim);
        vnDimOut[iDim] = vnEdge[iDim]-1;
        vpvEdge[iDim] = mxGetPr(pveDim);
        vnAdd[iDim] = (iDim)?(vnAdd[iDim-1] + nRecord):(0);
#ifdef DEBUG
        mexPrintf("iDim %d | vnDimOut[iDim] %d| vpvEdge[iDim] %x| vnEdge[iDim] %d| vnAdd[iDim] %d\n",
            iDim, vnDimOut[iDim], vpvEdge[iDim], vnEdge[iDim], vnAdd[iDim]);
#endif
        
        /*iDim++*/;
    }
    
    vnMulOut = vnDim2vnMul (vnDimOut, nDim);

    if (!(vnMulOut))
    {
        mexErrMsgTxt("Memory allocation error (2)");
    }
    
    /* Output : Histogram */
    mxHist = mxCreateNumericArray(nDim, (const int *)vnDimOut, mxDOUBLE_CLASS, mxREAL);
    pmHist = mxGetPr(mxHist);
    nSizeHist = mxGetNumberOfElements(mxHist);
    
#ifdef DEBUG
    for (iDim = 0; iDim < nDim; iDim ++)
    {
        mexPrintf("vnMulOut[%d] %d ", iDim, vnMulOut[iDim]);
    }
    mexPrintf("\n");
#endif

    /*Build Row adder vector*/
    /*
    nRow = 4
    00    01    02    03    04
    10    11    12    13    14
    20    21    22    23    24
    30    31    32    33    34
    
     0     4     8    12    16
     1     5     9    13    17
     2     6    10    14    18
     3     7    11    15    19
     
     1     5     9    13    17
     iRec + 0
           iRec + nRow
                 iRow + nRow + nRow
                       iRow + nRow + nRow + nRow
                             iRow + nRow + nRow + nRow + nRow
    */

    for (iRecord = 0; iRecord < nRecord; iRecord++)
    {
        /*Begin - dimension loop*/
        int iInTable = iRecord, iOutTable;
        bError = 0;
        
        
#ifdef DEBUG
        mexPrintf("iRecord %d\n",iRecord);
        /*mexEvalString("pause");  */
#endif
        
        for (iDim = 0; iDim < nDim; iDim ++)
        {
            /*Begin dimension loop*/
            const double rX = pData[iInTable];
            
#ifdef DEBUG
            mexPrintf("iDim %d rX %g ",iDim, rX);
            /*mexEvalString("pause");     */
#endif
            
            /*Find the index for xX within vpvEdge[iDim]*/
            vCoord[iDim] = search(vpvEdge[iDim], vnDimOut[iDim], rX);

#ifdef DEBUG
            mexPrintf("vCoord[%d] %d\n", iDim, vCoord[iDim]);
#endif
            
            if (vCoord[iDim] < 0)
            {
                bError = 1;
#ifdef DEBUG
            mexPrintf("bError %d\n", bError);
#endif
                break;
            }
            
            /*End dimension loop*/
            iInTable += nRecord;
            
        }
        /*End - dimension loop*/
        
        if(bError)
        {
            break;
        }
        
        iOutTable = vCoord2iAddr (vCoord, vnMulOut, nDim);
#ifdef DEBUG
        mexPrintf("iOutTable %d\n", iOutTable);
#endif
        if (nSizeHist<=iOutTable)
        {
            mexErrMsgTxt("Histogram out of bound");
        }
        pmHist[iOutTable] += 1.;
        
#ifdef DEBUG
        mexPrintf("iRecord %d/%d : pmHist[%d/%d] == %f\n", iRecord, nRecord, iOutTable, nSizeHist, pmHist[iOutTable]);
#endif
        
    }
    /*Free allocated memory*/
    
/*#ifdef DEBUG
        mexPrintf("Free vnDimIn\n");
#endif
    mxDestroyArray (vnDimIn);*/
    

#ifdef DEBUG
        mexPrintf("Free vnMulOut\n");
#endif
    mxFree (vnMulOut);
#ifdef DEBUG
        mexPrintf("Free vnDimOut\n");
#endif
    mxFree (vnDimOut);
#ifdef DEBUG
        mexPrintf("Free vnEdge\n");
#endif
    mxFree (vnEdge);
#ifdef DEBUG
        mexPrintf("Free vpvEdge\n");
#endif
    mxFree (vpvEdge);
#ifdef DEBUG
        mexPrintf("Free vnAdd\n");
#endif
    mxFree (vnAdd);
#ifdef DEBUG
        mexPrintf("Free vCoord\n");
#endif
    mxFree (vCoord);
    
    
    /*Return*/
    return mxHist;
}

/*
    Binary search implementation
    Computational complexity : log2(n)
        n -> n/2 -> n/4 -> ... -> 2 -> 1
    ==> take log2(.)
        log2(n) -> log2(n) - 1 -> log2(n) - 2 -> ... -> 1 -> 0
    ref: http://www.tbray.org/ongoing/When/200x/2003/03/22/Binary
*/

int search(const double *pveX, const int nX, const double rX)
{
/*in: a sorted array in */
    int high = nX, low = 0, probe, ret;
#ifdef DEBUG_SEARCH
        mexPrintf("nX %d, rX%g\n", nX, rX);
#endif
    if (pveX[low] > rX)
    {
        ret = -1;
    }
    else if (pveX[low] == rX)
    {
        ret = low;
    }
    else if (pveX[high] < rX)
    {
        ret = -1;
    }
    else
    {
#ifdef DEBUG_SEARCH
            mexPrintf("pveX[%d] %g | rX %g | pveX[%d] %g\n", low, pveX[low] , rX, high, pveX[high]);
#ifdef DEBUG_SEARCH_PAUSE
            mexEvalString("pause");
#endif
#endif
        while (high - low > 1)
        {
            probe = (high + low) / 2;
            if (pveX[probe] <= rX)
                low = probe;
            else
                high = probe;
#ifdef DEBUG_SEARCH
            mexPrintf("pveX[%d] %g | rX %g | pveX[%d] %g\n", low, pveX[low] , rX, high, pveX[high]);
#ifdef DEBUG_SEARCH_PAUSE
            mexEvalString("pause");
#endif
#endif
        }
        if (low == nX || !( (pveX[high] > rX) && (pveX[low] <= rX) ))
        {
            ret = -1;
#ifdef DEBUG_SEARCH
            mexPrintf("pveX[%d] %g | rX %g | pveX[%d] %g\n", low, pveX[low] , rX, high, pveX[high]);
#ifdef DEBUG_SEARCH_PAUSE
            mexEvalString("pause");
#endif
#endif
        }
        else
        {
            ret = low;
        }
    }

#ifdef DEBUG_SEARCH
    mexPrintf("ret %d\n", ret);
#endif
    return ret;
}

