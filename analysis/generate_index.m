function [index_file] = generate_index(context, documents, varargin)

index_file = sprintf('%sindex.html', context.prefix);
temporary_index_file = tempname;
template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');

index_fid = fopen(temporary_index_file, 'w');

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'reporttemplate'
            template_file = varargin{i+1};  
        case 'reportname'
            index_file = sprintf('%s%s.html', context.prefix, varargin{i+1});          
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

fprintf(index_fid, '<ul class="overview">');

for i = 1:size(documents, 1)
    fprintf(index_fid, '<li><a href="%s">%s</a> - %s</li>', ...
        documents{i, 1}, documents{i, 2}, documents{i, 3});
end;

fprintf(index_fid, '</ul>');

fclose(index_fid);

generate_from_template(fullfile(context.root, index_file), template_file, ...
    'body', fileread(temporary_index_file), 'title', 'Report overview', ...
    'timestamp', datestr(now, 31));

delete(temporary_index_file);
