function document = create_document(context, name, varargin)

title = name;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'title'
            title = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

temporary_file = tempname;
temporary_metadata = [tempname, '.mat'];
temporary_fid = fopen(temporary_file, 'w');

template_file = get_global_variable('report_template');

target_file = fullfile(context.root, sprintf('%s%s.html', context.prefix, name));

document = struct('fid', temporary_fid, ...
    'temporary_file', temporary_file, 'title', title, ...
    'template_file', template_file, 'target_file', target_file, ...
    'temporary_metadata', temporary_metadata);

document.url = sprintf('%s%s.html', context.prefix, name);

document.raw = @(text, varargin) fprintf(document.fid, text, varargin{:});

document.include = @(type, name) include_resource(context, document, type, name);

document.write = @() write_report_document(document);

document.chapter = @(text, varargin) insert_chapter(document, sprintf(text, varargin{:}));

document.section = @(text, varargin) insert_section(document, sprintf(text, varargin{:}));

document.subsection = @(text, varargin) insert_subsection(document, sprintf(text, varargin{:}));

document.text = @(text, varargin) insert_text(document, sprintf(text, varargin{:}));

document.table = @(data, varargin) insert_table(context, document, data, varargin{:});

document.link = @(url, text, varargin) insert_link(document, url, sprintf(text, varargin{:}));

document.figure = @(handle, id, title) insert_figure(context, document.fid, handle, id, title);


end

function write_report_document(document)

    fclose(document.fid);

    metadata = struct();

    load(document.temporary_metadata);

    resources = struct2cell(metadata.resources);
    tokens = cell(numel(resources), 1);
    
    for i = 1:numel(resources)
        url = sprintf('%s/%s/%s', 'resources', resources{i}.type, resources{i}.name);

        switch resources{i}.type
            case 'js'
                tokens{i} = sprintf('<script type="text/javascript" src="%s"></script>\n', url);
            case 'css'
                tokens{i} = sprintf('<link rel="stylesheet" type="text/css" href="%s"/>\n', url);
            otherwise
                tokens{i} = '';   
        end;

    end;

    generate_from_template(document.target_file, document.template_file, ...
        'body', fileread(document.temporary_file), 'title', document.title, ...
        'timestamp', datestr(now, 31), 'head', strjoin(tokens, ''));
    
    delete(document.temporary_file);
    delete(document.temporary_metadata);
    
end


function insert_chapter(document, text)

    fprintf(document.fid, '<h1>%s</h1>', text);

end

function insert_section(document, text)

    fprintf(document.fid, '<h2>%s</h2>', text);
    
end

function insert_subsection(document, text)

    fprintf(document.fid, '<h3>%s</h3>', text);

end

function insert_text(document, text)

    fprintf(document.fid, '<p>%s</p>', text);

end

function insert_link(document, url, text)

    fprintf(document.fid, '<a href="%s">%s</a>', url, text);

end

function insert_table(context, document, data, varargin)

    if context.exportlatex
    
        document.include('js', 'jquery.js');
        document.include('js', 'jquery.latex.js');

        fprintf(document.fid, '<div class="table latex">');
        
    else
        
        fprintf(document.fid, '<div class="table">');
        
    end;

    matrix2html(data, document.fid, varargin{:});

    fprintf(document.fid, '</div>');

end

function include_resource(context, document, type, name)

    resource_destination = fullfile(context.root, 'resources', type, name);
    resource_source = fullfile(get_global_variable('toolkit_path'), 'report', 'resources', type, name);

    if ~exist(resource_source, 'file')
        return;
    end;

    if ~exist(resource_destination, 'file') || ...
        file_newer_than(resource_source, resource_destination)
        mkpath(fullfile(context.root, 'resources', type));
        copyfile(resource_source, resource_destination);
    end;


    metadata = struct('resources', struct());

    if exist(document.temporary_metadata, 'file')
        load(document.temporary_metadata);
    end;

    resource_id = sprintf('%s_%s', type, name);
    resource_id = strrep(strrep(strrep(resource_id, '/', '_'), '.', '_'), '-', '_');
    
    if ~isfield(metadata.resources, resource_id)
        metadata.resources.(resource_id) = struct('type', type, 'name', name);
        save(document.temporary_metadata, 'metadata');
    end;

end

