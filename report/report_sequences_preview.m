function [document] = report_sequences_preview(context, sequences, varargin)
% report_sequences_preview Create an overview document for the given sequences
%
% The function generates a report document for the given sequences by providing a
% preview of each sequence.
%
% Input:
% - context (structure): A report context structure.
% - sequences (cell): An array of sequence descriptors.
% - varargin[Frames] (integer): Number of frames for each sequence to present in a strip.
%
% Output:
% - document (structure): A document structure.
%

document = create_document(context, 'sequences', 'title', 'Sequences overview');

frames = 6;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'frames'
            frames = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end

tags = {'empty'};
total_size = 0;

for s = 1:length(sequences)
    tags = union(tags, sequences{s}.tags.names);
    total_size = total_size + sequences{s}.length;
end;

document.raw('Total size: %d sequences, %d frames', numel(sequences), total_size);

if ~isempty(tags)

    document.section('Tags distribution');

    tags_count = zeros(numel(tags), 1);

    for s = 1:length(sequences)
        for l = 1:length(tags)
            tags_count(l) = tags_count(l) + numel(query_tag(sequences{s}, tags{l}));
        end;
    end;

    handle = generate_plot('title', 'Tags distribution');

    bar(tags_count ./ total_size);
    set(gca, 'TickLabelInterpreter', 'none');
    set(gca, 'XTickLabel', tags);

    document.figure(handle, 'tagss_distribution', 'Tags distribution');

    close(handle);

    document.subsection('Tags in sequences');

    for l = 1:length(tags)
        subset = cellfun(@(s) ~isempty(sequence_query_tag(s, tags{l})), sequences, 'UniformOutput', true);
        document.text('Tag %s: %s', tags{l}, strjoin(cellfun(@(s) s.name, sequences(subset), 'UniformOutput', false), ', '));
    end;

end;

for s = 1:length(sequences)

    print_indent(1);

    print_text('Processing sequence %s ...', sequences{s}.name);

    document.raw('<div class="timeline">\n');

    figure_id = sprintf('sequence_preview_%s', sequences{s}.name);

    document.figure(@() generate_sequence_strip(sequences{s}, {}, 'samples', frames, 'window', Inf), ...
        figure_id, sprintf('Sequence %s', sequences{s}.name));

    document.raw('</div>\n');

    print_indent(-1);

end;

document.write();



