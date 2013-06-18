function [images, region] = vot_initialize();

% read the images file
fimages = fopen('images.txt','r'); 
images = textscan(fimages, '%s');
fclose(fimages);
images = images{1};

% read the region
region = dlmread('region.txt');

if length(region) ~= 4
	error('Illegal input region!')
end;
