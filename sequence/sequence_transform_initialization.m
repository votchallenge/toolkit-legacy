function tranform_sequence = sequence_transform_initialization(sequence, transform, format)
% sequence_transform_initialization Returns sequence with transformed initialization
%
% This sequence converter returns a sequence that has a modified initialize handler that
% transforms the region before handing it over to the tracker. This can be used to 
% to introduce noise.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - transform (function): A handle of transformation function.
% - format (string, optional): Region format identifier for coercion.
%
% Output:
% - tranform_sequence (structure): A sequence descriptor of a converted sequence.

if nargin < 3
    format = [];
end;

tranform_sequence = sequence;
tranform_sequence.initialize = @transform_initialization;
tranform_sequence.initialize_transform = transform;
tranform_sequence.initialize_format = format;

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
