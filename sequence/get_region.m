function [region] = get_region(sequence, index)

if nargin == 1
    
    region = sequence.groundtruth;
    
else

    if numel(index) == 1
        region = sequence.groundtruth{index};
    else
        region = sequence.groundtruth(index);
    end;

end;


