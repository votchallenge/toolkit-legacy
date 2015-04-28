/* -*- Mode: C++; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <stdio.h>

#ifdef TRAX
#include <trax.h>
#else
#include "vot2014.hpp"
#endif

class NCCTracker
{
public:
    inline void init(cv::Mat & img, cv::Rect rect)
    {
        p_window = MAX(rect.width, rect.height) * 2;

        cv::Mat gray;
        cv::cvtColor(img, gray, CV_BGR2GRAY);

        int left = MAX(rect.x, 0);
        int top = MAX(rect.y, 0);

        int right = MIN(rect.x + rect.width, gray.cols - 1);
        int bottom = MIN(rect.y + rect.height, gray.rows - 1);

        cv::Rect roi(left, top, right - left, bottom - top);

        gray(roi).copyTo(p_template);

        p_position.x = (float)rect.x + (float)rect.width / 2;
        p_position.y = (float)rect.y + (float)rect.height / 2;

        p_size = cv::Size2f(rect.width, rect.height);

    }
    inline cv::Rect track(cv::Mat img)
    {

        cv::Mat gray;
        cv::cvtColor(img, gray, CV_BGR2GRAY);

        float left = MAX(round(p_position.x - (float)p_window / 2), 0);
        float top = MAX(round(p_position.y - (float)p_window / 2), 0);

        float right = MIN(round(p_position.x + (float)p_window / 2), gray.cols - 1);
        float bottom = MIN(round(p_position.y + (float)p_window / 2), gray.rows - 1);

        cv::Rect roi((int) left, (int) top, (int) (right - left), (int) (bottom - top));

        if (roi.width < p_template.cols || roi.height < p_template.rows) {
            cv::Rect result;

            result.x = p_position.x - p_size.width / 2;
            result.y = p_position.y - p_size.height / 2;
            result.width = p_size.width;
            result.height = p_size.height;
            return result;

        }

        cv::Mat matches;
        cv::Mat cut = gray(roi);

        cv::matchTemplate(cut, p_template, matches, CV_TM_CCOEFF_NORMED);

        cv::Point matchLoc;
        cv::minMaxLoc(matches, NULL, NULL, NULL, &matchLoc, cv::Mat());

        cv::Rect result;

        p_position.x = left + matchLoc.x + (float)p_size.width / 2;
        p_position.y = top + matchLoc.y + (float)p_size.height / 2;

        result.x = left + matchLoc.x;
        result.y = top + matchLoc.y;
        result.width = p_size.width;
        result.height = p_size.height;

        return result;
    }

private:
    cv::Point2f p_position;

    cv::Size p_size;

    float p_window;

    cv::Mat p_template;
};

#ifdef TRAX
int main( int argc, char** argv)
{

    NCCTracker tracker;
    trax_image* img = NULL;
    trax_region* reg = NULL;
    trax_region* mem = NULL;

    trax_handle* trax;
    trax_configuration config;
    config.format_region = TRAX_REGION_RECTANGLE;
    config.format_image = TRAX_IMAGE_PATH;

    trax = trax_server_setup_standard(config, NULL);

    bool run = true;

    while(run)
    {

        int tr = trax_server_wait(trax, &img, &reg, NULL);

        if (tr == TRAX_INITIALIZE) {

            cv::Rect rect;
            float x, y, width, height;
            trax_region_get_rectangle(reg, &x, &y, &width, &height);
            rect.x = round(x); rect.y = round(y); rect.width = round(x + width) - rect.x; rect.height = round(y + height) - rect.y;

            cv::Mat image = cv::imread(trax_image_get_path(img));

            tracker.init(image, rect);

            trax_server_reply(trax, reg, NULL);

        } else if (tr == TRAX_FRAME) {

            cv::Mat image = cv::imread(trax_image_get_path(img));

            cv::Rect rect = tracker.track(image);

            trax_region* result = trax_region_create_rectangle(rect.x, rect.y, rect.width, rect.height);

            trax_server_reply(trax, result, NULL);

            trax_region_release(&result);

        } else {

            run = false;

        }

        if (img) trax_image_release(&img);
        if (reg) trax_region_release(&reg);

    }

    if (mem) trax_region_release(&mem);

    trax_cleanup(&trax);

    return 0;

}
#else
int main( int argc, char** argv)
{

    NCCTracker tracker;
    cv::Mat img;

    //load region, images and prepare for output
    VOT vot_io("region.txt", "images.txt", "output.txt");
    
    //img = firts frame, initPos = initial position in the first frame
    VOTPolygon p = vot_io.getInitPolygon();

    int top = round(MIN(p.y1, MIN(p.y2, MIN(p.y3, p.y4))));
    int left = round(MIN(p.x1, MIN(p.x2, MIN(p.x3, p.x4))));
    int bottom = round(MAX(p.y1, MAX(p.y2, MAX(p.y3, p.y4))));
    int right = round(MAX(p.x1, MAX(p.x2, MAX(p.x3, p.x4))));

//printf("R:%d %d %d %d \n", left, top, right, bottom);

    vot_io.getNextImage(img);
    
    //output init also bbox
    vot_io.outputPolygon(p);

    //tracker initialization
    tracker.init(img, cv::Rect(left, top, right - left, bottom - top));

    //track   
    while (vot_io.getNextImage(img) == 1){
        cv::Rect rect = tracker.track(img);

        VOTPolygon result;

        result.x1 = rect.x;
        result.y1 = rect.y;
        result.x2 = rect.x + rect.width;
        result.y2 = rect.y;
        result.x3 = rect.x + rect.width;
        result.y3 = rect.y + rect.height;
        result.x4 = rect.x;
        result.y4 = rect.y + rect.height;

        vot_io.outputPolygon(result);
    }
    
    return 0;

}
#endif
