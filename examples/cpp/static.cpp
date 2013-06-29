/* 
 *  Author : Tomas Vojir
 *  Date   : 2013-06-05
 *  Desc   : Example of VOT integration for C++ tracker.
 */ 

#include "opencv2/opencv.hpp"
#include "vot.hpp"

using namespace cv;

// This is an example tracker that just returns the initial position for every frame.
// It can be extended with your own code.
class SampleTracker
{
public:
    inline void init(Mat & img, Rect & bb)
    {
        p_returnPosition = Rect(img.cols/2 - bb.width/2, img.rows/2 - bb.height/2, bb.width, bb.height);
    }
    inline Rect track(Mat & img)
    {
        return p_returnPosition;
    }

private:
    Rect p_returnPosition;
};

int main(int argc, char* argv[])
{
    SampleTracker tracker;
    cv::Mat img;

    //load region, images and prepare for output
    VOT vot_io("region.txt", "images.txt", "output.txt");
    
    //img = firts frame, initPos = initial position in the first frame
    cv::Rect initPos = vot_io.getInitRectangle();
    vot_io.getNextImage(img);
    
    //output init also bbox
    vot_io.outputBoundingBox(initPos);

    //tracker initialization
    tracker.init(img, initPos);

    //track   
    while (vot_io.getNextImage(img) == 1){
		cv::Rect bbox= tracker.track(img);
        vot_io.outputBoundingBox(bbox);
    }
    
    return 0;
}

