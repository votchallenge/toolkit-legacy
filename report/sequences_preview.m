function [index_file] = sequences_preview(context, sequences, varargin)

temporary_index_file = tempname;
template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');

index_fid = fopen(temporary_index_file, 'w');
latex_fid = [];

set_name = '';

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'latexfile'
            latex_fid = varargin{i+1};
        case 'reporttemplate'
            template_file = varargin{i+1};  
        case 'setname'
            set_name = varargin{i+1};  
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

prefix = 'sequence';

if isempty(set_name)
	index_file = sprintf('%ssequences.html', context.prefix);
	title = 'Sequences';
else
	index_file = sprintf('%ssequences_%s.html', context.prefix, set_name);
	title = sprintf('Sequences %s', set_name);
end;

for s = 1:length(sequences)

    print_indent(1);

    print_text('Processing sequence %s ...', sequences{s}.name);

    fprintf(index_fid, '<div class="grid_small">\n');
    
    insert_figure(context, index_fid, @() generate_sequence_strip(sequences{s}, {}, 'samples', 1, 'window', Inf), ...
        sprintf('%s_%s.png', prefix, ...
        sequences{s}.name), ...
        sprintf('Sequence %s', sequences{s}.name));

    fprintf(index_fid, '</div>\n');
    
    print_indent(-1);

end;

fclose(index_fid);


generate_from_template(fullfile(context.root, index_file), template_file, ...
    'body', fileread(temporary_index_file), 'title', title, ...
    'timestamp', datestr(now, 31));

delete(temporary_index_file);


