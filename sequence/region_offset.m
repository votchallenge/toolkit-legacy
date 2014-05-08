function [region] = region_offset(region, offset)

if isnumeric(region) 
	if numel(region) == 4

        region(1:2) = region(1:2) + offset;

    elseif numel(region) >= 6 && mod(numel(region), 2) == 0

        region = region + repmat(offset(:)', 1, numel(region) / 2);  
        
	end;
        
end;

