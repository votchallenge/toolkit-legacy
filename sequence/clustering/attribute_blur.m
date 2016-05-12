function [mean_val, var_val, frames] = attribute_blur(sequence)
% attribute_blur Computes the blur attribute in the given seqeunce
%
% Image blur attribute was measured by the Bayes-spectral-entropy camera focus measure
% For more details, please see this paper: M. Kristan, J. Perš, M. Perše, S. Kovacic. 
% "A Bayes-Spectral-Entropy-Based Measure of Camera Focus Using 
% a Discrete Cosine Transform". Pattern Recognition Letters, 
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of blur for the sequence
% - val_val  : variance of blur for the sequence
% - frames   : image blure for each frame

% parameters used in the paper
low_f = 0 ;                    % bottom threshold on frequency
high_f = 6 ;                   % top threshold on frequency
window = [ 8, 8 ] ;            % subwindow size

frames = zeros(sequence.length, 1);
for i = 1:sequence.length
    image_name = sequence.images{i};
    full_image_name = fullfile(sequence.directory, image_name);
    image = double(rgb2gray(imread(full_image_name)));

    region = round(region_convert(get_region(sequence, i), 'rectangle'););

    if isnan(region(1))
        frames(i) = NaN;
    else
        x1 = max(1, region(1)+1);
        y1 = max(1, region(2)+1);
        x2 = min(size(image, 2), region(1)+region(3)+1);
        y2 = min(size(image, 1), region(2)+region(4)+1);

        % extract focusing image
        subImage = image( y1 : y2 , x1 : x2 );
        % evaluate focus measure 
        frames(i) = bayesdct( subImage, window, low_f, high_f );
    end
end
mean_val = mean(frames(~isnan(frames)));
var_val = var(frames(~isnan(frames)));
