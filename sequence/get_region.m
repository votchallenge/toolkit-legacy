function region = get_region(sequence, index)
% get_region Returns region, or multiple regions for the given sequence
%
% Input:
% - sequence: A valid sequence structure.
% - index: A index of a frame or a vector of indices of frames.
%
% Output
% - region: A region description matrix or a cell array of region description matrices if more than one frame was requested.

if nargin == 1
    
    region = sequence.groundtruth;
    
else

    if numel(index) == 1
        region = sequence.groundtruth{index};
    else
        region = sequence.groundtruth(index);
    end;

end;


