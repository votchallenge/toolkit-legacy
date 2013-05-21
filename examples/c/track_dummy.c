/* -*- Mode: C++; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * This example is based on the camshiftdemo.c code from the OpenCV repository
 * It compiles with OpenCV 2.1
 * The main function of this example is to show the developers how to modify
 * their trackers to work with the evaluation environment.
 */

#ifdef _CH_
#pragma package <opencv>
#endif

#define CV_NO_BACKWARD_COMPATIBILITY

#ifndef _EiC
#include <cv.h>
#include <highgui.h>
#include <stdio.h>
#include <ctype.h>
#endif

IplImage *image = 0, *hsv = 0, *hue = 0, *mask = 0, *backproject = 0, *histimg = 0;
CvHistogram *hist = 0;

int track_object = 0;
CvRect selection;
CvRect track_window;
CvBox2D track_box;
CvConnectedComp track_comp;
int hdims = 16;
float hranges_arr[] = {0,180};
float* hranges = hranges_arr;
int vmin = 10, vmax = 256, smin = 30;

CvRect read_rectangle(const char* filename) {

    int i;
    FILE *inputfile = fopen(filename, "r");
    size_t linesiz = sizeof(char) * 32;
    char* linebuf = (char*) malloc(sizeof(char) * 32);
    float* pointbuf = (float*) malloc(sizeof(float) * 4);
    ssize_t linelen = 0;
    CvRect rect; rect.x = 0; rect.y = 0; rect.width = 0; rect.height = 0;
    
    for (i = 0; i < 4; i++) {
        if ((linelen=getdelim(&linebuf, &linesiz, ',', inputfile))>0) {
            if ((linebuf)[linelen - 1] == ',') {
                (linebuf)[linelen - 1] = '\0';
            }

            pointbuf[i] = atof(linebuf);
        } else 
            return rect;

    }

    rect.x = pointbuf[0];
    rect.y = pointbuf[1];
    rect.width = pointbuf[2];
    rect.height = pointbuf[3];

    free(linebuf);
    free(pointbuf);
    fclose(inputfile);

    return rect;
}

CvScalar hsv2rgb( float hue )
{
    int rgb[3], p, sector;
    static const int sector_data[][3]=
        {{0,2,1}, {1,2,0}, {1,0,2}, {2,0,1}, {2,1,0}, {0,1,2}};
    hue *= 0.033333333333333333333333333333333f;
    sector = cvFloor(hue);
    p = cvRound(255*(hue - sector));
    p ^= sector & 1 ? 255 : 0;

    rgb[sector_data[sector][0]] = 255;
    rgb[sector_data[sector][1]] = 0;
    rgb[sector_data[sector][2]] = p;

    return cvScalar(rgb[2], rgb[1], rgb[0],0);
}

void printbox(FILE* out, CvBox2D box) {

    CvPoint2D32f pt0, pt1, pt2, pt3;
    double x, y, width, height;

    double _angle = box.angle*CV_PI/180.0; 
    float a = (float)cos(_angle)*0.5f; 
    float b = (float)sin(_angle)*0.5f; 
     
    pt0.x = box.center.x - a*box.size.height - b*box.size.width; 
    pt0.y = box.center.y + b*box.size.height - a*box.size.width; 
    pt1.x = box.center.x + a*box.size.height - b*box.size.width; 
    pt1.y = box.center.y - b*box.size.height - a*box.size.width; 
    pt2.x = 2 * box.center.x - pt0.x; 
    pt2.y = 2 * box.center.y - pt0.y; 
    pt3.x = 2 * box.center.x - pt1.x; 
    pt3.y = 2 * box.center.y - pt1.y; 

    x = cvFloor(MIN(MIN(MIN(pt0.x, pt1.x), pt2.x), pt3.x)); 
    y = cvFloor(MIN(MIN(MIN(pt0.y, pt1.y), pt2.y), pt3.y));
    width = cvCeil(MAX(MAX(MAX(pt0.x, pt1.x), pt2.x), pt3.x)) - x - 1; 
    height = cvCeil(MAX(MAX(MAX(pt0.y, pt1.y), pt2.y), pt3.y)) - y - 1; 

    fprintf(out, "%f,%f,%f,%f\n", x, y, width, height);

}


int main( int argc, char** argv)
{

    int f = 0;
    selection = read_rectangle("region.txt");
    FILE *imagesfile = fopen("images.txt", "r");
    FILE *outputfile = fopen("output.txt", "w");
    size_t linesiz = sizeof(char) * 1024;
    char* linebuf = (char *) malloc(sizeof(char) * 1024);
    ssize_t linelen = 0;
    track_object = -1;

    for(f = 1;; f++)
    {
        int i, bin_w, c;

        if ((linelen=getline(&linebuf, &linesiz, imagesfile))<1)
            break;

        if ((linebuf)[linelen - 1] == '\n') {
            (linebuf)[linelen - 1] = '\0';
        }

        // In trax mode images are read from the disk. The master program tells the
        // tracker where to get them.
        IplImage* frame = cvLoadImage(linebuf, CV_LOAD_IMAGE_COLOR);

        if( !frame )
            break;

        if( !image )
        {
            /* allocate all the buffers */
            image = cvCreateImage( cvGetSize(frame), 8, 3 );
            image->origin = frame->origin;
            hsv = cvCreateImage( cvGetSize(frame), 8, 3 );
            hue = cvCreateImage( cvGetSize(frame), 8, 1 );
            mask = cvCreateImage( cvGetSize(frame), 8, 1 );
            backproject = cvCreateImage( cvGetSize(frame), 8, 1 );
            hist = cvCreateHist( 1, &hdims, CV_HIST_ARRAY, &hranges, 1 );
            histimg = cvCreateImage( cvSize(320,200), 8, 3 );
            cvZero( histimg );
        }

        cvCopy( frame, image, 0 );
        cvCvtColor( image, hsv, CV_BGR2HSV );

        if( track_object )
        {
            int _vmin = vmin, _vmax = vmax;

            cvInRangeS( hsv, cvScalar(0,smin,MIN(_vmin,_vmax),0),
                        cvScalar(180,256,MAX(_vmin,_vmax),0), mask );
            cvSplit( hsv, hue, 0, 0, 0 );

            if( track_object < 0 )
            {
                float max_val = 0.f;
                cvSetImageROI( hue, selection );
                cvSetImageROI( mask, selection );
                cvCalcHist( &hue, hist, 0, mask );
                cvGetMinMaxHistValue( hist, 0, &max_val, 0, 0 );
                cvConvertScale( hist->bins, hist->bins, max_val ? 255. / max_val : 0., 0 );
                cvResetImageROI( hue );
                cvResetImageROI( mask );
                track_window = selection;
                track_object = 1;

                cvZero( histimg );
                bin_w = histimg->width / hdims;
                for( i = 0; i < hdims; i++ )
                {
                    int val = cvRound( cvGetReal1D(hist->bins,i)*histimg->height/255 );
                    CvScalar color = hsv2rgb(i*180.f/hdims);
                    cvRectangle( histimg, cvPoint(i*bin_w,histimg->height),
                                 cvPoint((i+1)*bin_w,histimg->height - val),
                                 color, -1, 8, 0 );
                }
            }

            cvCalcBackProject( &hue, backproject, hist );
            cvAnd( backproject, mask, backproject, 0 );
            cvCamShift( backproject, track_window,
                        cvTermCriteria( CV_TERMCRIT_EPS | CV_TERMCRIT_ITER, 10, 1 ),
                        &track_comp, &track_box );
            track_window = track_comp.rect;

            if( !image->origin )
                track_box.angle = -track_box.angle;
            cvEllipseBox( image, track_box, CV_RGB(255,0,0), 3, CV_AA, 0 );
        }

        printbox(outputfile, track_box);

    }

    free(linebuf);
    fclose(imagesfile);
    fclose(outputfile);

    return 0;
}

#ifdef _EiC
main(1,"camshiftdemo.c");
#endif
