/* 
 *  Author : Tomas Vojir
 *  Date   : 2013-06-05
 *  Desc   : Simple class for parsing VOT inputs and providing 
 *           interface for image loading and storing output.
 */ 

#ifndef CPP_VOT_H
#define CPP_VOT_H

#include <string>
#include <fstream>
#include <iostream>
#include "opencv2/opencv.hpp"

class VOT
{
public:
    VOT(const std::string & region_file, const std::string & images, const std::string & ouput)
    {
        p_region_stream.open(region_file.c_str());
        if (p_region_stream.is_open()){
            float x, y, w, h;
            char ch;
            p_region_stream >> x >> ch >> y >> ch >> w >> ch >> h;
            p_init_rectangle = cv::Rect(x, y, w, h);
        }else{
            std::cerr << "Error loading initial region in file " << region_file << "!" << std::endl;
            p_init_rectangle = cv::Rect(0, 0, 0, 0);
        }

        p_images_stream.open(images.c_str());
        if (!p_images_stream.is_open())
            std::cerr << "Error loading image file " << images << "!" << std::endl;

        p_output_stream.open(ouput.c_str());
        if (!p_output_stream.is_open())
            std::cerr << "Error opening output file " << ouput << "!" << std::endl;
    }

    ~VOT()
    {
        p_region_stream.close();
        p_images_stream.close();
        p_output_stream.close();
    }

    inline cv::Rect getInitRectangle() const 
    {   return p_init_rectangle;    }

    inline void outputBoundingBox(const cv::Rect & bbox)
    {   p_output_stream << bbox.x << ", " << bbox.y << ", " << bbox.width << ", " << bbox.height << std::endl;  }

    inline int getNextImage(cv::Mat & img)
    {
		std::string line;
		std::getline (p_images_stream, line);
		img = cv::imread(line, CV_LOAD_IMAGE_COLOR);
		
		if (p_images_stream.eof() || !p_images_stream.is_open())
            return -1;
		else
			return 1;
	}

private:
    cv::Rect p_init_rectangle;
    std::ifstream p_region_stream;
    std::ifstream p_images_stream;
    std::ofstream p_output_stream;

};

#endif //CPP_VOT_H

