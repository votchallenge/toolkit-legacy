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
#include <opencv2/opencv.hpp>

// Bounding box type
typedef struct {
    float x1;
    float y1;
    float x2;
    float y2;
    float x3;
    float y3;
    float x4;
    float y4;
} VOTPolygon;

class VOT
{
public:
    VOT(const std::string & region_file, const std::string & images, const std::string & ouput)
    {
        p_region_stream.open(region_file.c_str());
        VOTPolygon p;
        if (p_region_stream.is_open()){
            char ch;
            p_region_stream >> p.x1 >> ch >> p.y1 >> ch;
            p_region_stream >> p.x2 >> ch >> p.y2 >> ch;
            p_region_stream >> p.x3 >> ch >> p.y3 >> ch;
            p_region_stream >> p.x4 >> ch >> p.y4;

        }else{
            std::cerr << "Error loading initial region in file " << region_file << "!" << std::endl;
            p.x1=0;
            p.y1=0;
            p.x2=0;
            p.y2=0;
            p.x3=0;
            p.y3=0;
            p.x4=0;
            p.y4=0;
        }

        p_init_polygon = p;

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

    inline VOTPolygon getInitPolygon() const 
    {   return p_init_polygon;    }

    inline void outputPolygon(const VOTPolygon & poly)
    {
      p_output_stream << poly.x1 << "," << poly.y1 << ",";
      p_output_stream << poly.x2 << "," << poly.y2 << ",";
      p_output_stream << poly.x3 << "," << poly.y3 << ",";
      p_output_stream << poly.x4 << "," << poly.y4 << std::endl;
    }

    inline int getNextImage(cv::Mat & img)
    {
    if (p_images_stream.eof() || !p_images_stream.is_open())
            return -1;

    std::string line;
    std::getline (p_images_stream, line);
	if (line.empty() && p_images_stream.eof()) return -1;
    img = cv::imread(line, CV_LOAD_IMAGE_COLOR);
 
    return 1;
  }

private:
    VOTPolygon p_init_polygon;
    std::ifstream p_region_stream;
    std::ifstream p_images_stream;
    std::ofstream p_output_stream;

};

#endif //CPP_VOT_H
