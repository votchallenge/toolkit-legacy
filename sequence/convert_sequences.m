function converted_sequences = convert_sequences(sequences, converter)
% convert_sequences Converts sequences using a converter
%
% This functions is an utility function that converts a set of sequences using 
% a given converter. The benefit of using this function is that each sequence
% is checked if it was already converted.
%
% Input:
% - sequences (cell): Cell array of sequence structures.
% - converter (function, string): A function handle or a string that can be resolved to a converter function.
%
% Output:
% - converted_sequences (cell): Cell array of converted sequence structures.

if isempty(converter)
    converted_sequences = sequences;
    return;
end;

if ischar(converter)
    converter = str2func(converter);
end;

converted_sequences = cellfun(@(x) convert_sequence(x, converter), sequences,'UniformOutput',false);

end

function sequence = convert_sequence(sequence, converter)
% convert_sequence Converts sequence using a converter
%
% Converts a single sequence using a converter
%
% Input:
% - sequence (structure): Input sequence structure.
% - converter (function): A function handle of a converter function.
%
% Output:
% - sequence (structure): Converted sequence structure.
%


    if isfield(sequence, 'converter')
        % If  the sequence is already converted with this converter
        % then do not do it again
        if strcmp(func2str(converter), sequence.converter)
            return;
        end;
    end;

    sequence = converter(sequence);
    
    sequence.converter = func2str(converter);
    
end
