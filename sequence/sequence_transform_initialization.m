function noisy_sequence = sequence_transform_initialization(sequence, transform, format)

if nargin < 3
    format = [];
end;

noisy_sequence = sequence;
noisy_sequence.initialize = @transform_initialization;
noisy_sequence.initialize_transform = transform;
noisy_sequence.initialize_format = format;

end

function [region] = transform_initialization(sequence, index, context)
        
    region = get_region(sequence, index);

    transform = sequence.initialize_transform(sequence, index, context);
    
    if size(transform, 1) ~= 3 || size(transform, 2) ~= 3
        return;
    end;

    bounds = region_convert(region, 'rectangle');
    
    origin = bounds(1:2) + bounds(3:4) / 2;
    
    shift = [1, 0, origin(1); 0, 1, origin(2); 0, 0, 1];

    transform = shift * transform / shift;

    if isnumeric(region) 
        polygon = region_convert(region, 'polygon');

        region = cat(2, reshape(polygon, 2, numel(polygon) / 2)', ...
            ones(numel(polygon) / 2 , 1));

        region =  transform * region';
        region = reshape(region(1:2, :), 1, numel(polygon));

    end;
    
    if ~isempty(sequence.initialize_format)
        region = region_convert(region, sequence.initialize_format);
    end;
    
end
