function [images, region] = vot_tracker_initialize();

% read the images file
fimages = fopen('images.txt','r'); 
images = textscan(fimages, '%s');
fclose(fimages);
images = images{1};

% read the region
region = dlmread('region.txt');

if numel(region) == 4
	return;
end;

if numel(region) >= 6 && mod(numel(region), 2) == 0
	return;
end;

error('Illegal format of the input region!');
