function [region] = region_offset(region, offset)
% region_offset Translates the region
%
% Translates the region by a given offset and returns the transformed region.
%
% Input:
% - region (double): A valid region.
% - offset (double): A `2x1` vector that denotes the `x` and `y` coordinate of the translation
%
% Output:
% - region: Resulting region.

if isnumeric(region) 
	if numel(region) == 4

        region(1:2) = region(1:2) + offset;

    elseif numel(region) >= 6 && mod(numel(region), 2) == 0

        region = region + repmat(offset(:)', 1, numel(region) / 2);  
        
	end;
        
end;

