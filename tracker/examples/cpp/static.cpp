/* 
 *  Author : Tomas Vojir
 *  Date   : 2013-06-05
 *  Desc   : Example of VOT integration for C++ tracker.
 */ 

#include "opencv2/opencv.hpp"
#include "vot2014.hpp"

using namespace cv;

// This is an example tracker that just returns the initial position for every frame.
// It can be extended with your own code.
class SampleTracker
{
public:
    inline void init(Mat & img, VOTPolygon poly)
    {
        p_returnPosition = poly;
    }
    inline VOTPolygon track(Mat img)
    {
        return p_returnPosition;
    }

private:
    VOTPolygon p_returnPosition;
};

int main(int argc, char* argv[])
{
    SampleTracker tracker;
    cv::Mat img;

    //load region, images and prepare for output
    VOT vot_io("region.txt", "images.txt", "output.txt");
    
    //img = firts frame, initPos = initial position in the first frame
    VOTPolygon initPos = vot_io.getInitPolygon();
    vot_io.getNextImage(img);
    
    //output init also bbox
    vot_io.outputPolygon(initPos);

    //tracker initialization
    tracker.init(img, initPos);

    //track   
    while (vot_io.getNextImage(img) == 1){
        VOTPolygon poly= tracker.track(img);
        vot_io.outputPolygon(poly);
    }
    
    return 0;
}

