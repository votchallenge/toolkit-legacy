function document = create_document(context, name, varargin)
% create_document Create a document handle
%
% Create a handle structure for a new HTML document that resides in a given report.
%
% Input:
% - context (structure): A valid report context structure.
% - name (string): Name of the document, used to create a HTML file.
% - varargin[Title] (string): A human-friendly title of the document.
%
% Output:
% - document (structure): Document handle structure.
%


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

template_file = fullfile(fileparts(mfilename('fullpath')), 'templates', 'report.html');
% Check if template is manually defined
template_file = get_global_variable('report_template', template_file);

target_file = fullfile(context.root, sprintf('%s%s.html', context.prefix, name));

document = struct('fid', temporary_fid, ...
    'temporary_file', temporary_file, 'title', title, ...
    'template_file', template_file, 'target_file', target_file, ...
    'temporary_metadata', temporary_metadata);

document.url = sprintf('%s%s.html', context.prefix, name);

document.raw = @(text, varargin) fprintf(document.fid, text, varargin{:});

document.include = @(type, name) include_resource(context, document, type, name);

document.write = @() write_report_document(document);

document.section = @(text, varargin) insert_section(document, sprintf(text, varargin{:}));

document.subsection = @(text, varargin) insert_subsection(document, sprintf(text, varargin{:}));

document.text = @(text, varargin) insert_text(document, sprintf(text, varargin{:}));

document.table = @(data, varargin) insert_table(context, document, data, varargin{:});

document.link = @(url, text, varargin) insert_link(document, url, sprintf(text, varargin{:}));

document.figure = @(handle, id, title) insert_figure(context, document.fid, handle, id, title);

document.script = @(script) insert_script(document, script);

document.include('css', 'bootstrap.css');
document.include('css', 'report.css');
document.include('js', 'jquery.js');
document.include('js', 'bootstrap.js');
document.include('js', 'layout.js');

end

function write_report_document(document)

    fclose(document.fid);

    metadata = struct('resources', struct());

    if exist(document.temporary_metadata, 'file')
        load(document.temporary_metadata);
    end;

    resources = struct2cell(metadata.resources);
    head_tokens = cell(numel(resources), 1);
    
    for i = 1:numel(resources)
        url = resources{i}.url;

        switch resources{i}.type
            case 'js'
                head_tokens{i} = sprintf('<script type="text/javascript" src="%s"></script>\n', url);
            case 'css'
                head_tokens{i} = sprintf('<link rel="stylesheet" type="text/css" href="%s"/>\n', url);
            otherwise
                head_tokens{i} = '';   
        end;

    end;

    if isempty(head_tokens)
        head = '';
    else
        head = strjoin(head_tokens, '');
    end;
    
    version = toolkit_version();

    generate_from_template(document.target_file, document.template_file, ...
        'body', fileread(document.temporary_file), 'title', document.title, ...
        'timestamp', datestr(now, 31), 'head', head, ... 
        'toolkit', sprintf('VOT toolkit %d.%d', version.major, version.minor));
    
    delete(document.temporary_file);
    delete(document.temporary_metadata);
    
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

function insert_script(document, script)

    fprintf(document.fid, '<script type="text/javascript">%s</script>', script);

end

function insert_table(context, document, data, varargin)

    document.include('js', 'jquery.export.js');

    fprintf(document.fid, '<div class="table-wrapper">');
    
    matrix2html(data, document.fid, varargin{:}, 'class', 'table');

    fprintf(document.fid, '</div>');

end

function include_resource(context, document, type, name)

    resource_source = fullfile(get_global_variable('toolkit_path'), 'report', 'resources', type, name);

    if ~exist(resource_source, 'file')
        return;
    end;
    
    metadata = struct('resources', struct());

    if exist(document.temporary_metadata, 'file')
        load(document.temporary_metadata);
    end;

    resource_id = sprintf('%s_%s', type, name);
    resource_id = strrep(strrep(strrep(resource_id, '/', '_'), '.', '_'), '-', '_');

        if ~isfield(metadata.resources, resource_id)
            
                
        if context.standalone

            resource_destination = fullfile(context.root, 'resources', type, name);

            if ~exist(resource_destination, 'file') || ...
                file_newer_than(resource_source, resource_destination)
                mkpath(fullfile(context.root, 'resources', type));
                copyfile(resource_source, resource_destination);
            end;
            resource_relative = relativepath(resource_destination, context.root);

        else

            resource_relative = relativepath(resource_source, context.root);

        end  

            if ispc()
                resource_url = strrep(resource_relative, '\', '/');
            else
                resource_url = resource_relative;
            end;
            
            metadata.resources.(resource_id) = struct('type', type, 'name', name, 'url', resource_url);
            save(document.temporary_metadata, 'metadata');
        end;


    
end

function insert_figure(context, fid, handle, id, title)

    fprintf(fid, '<div class="image-wrapper stacking">\n');

    export_figure(handle, fullfile(context.images, [context.prefix, id]), 'png', 'cache', context.cache);

    data = [];

    if context.exporteps
        export_figure(handle, fullfile(context.images, [context.prefix, id]), 'eps', 'cache', context.cache);
        data = [data, sprintf(' data-alternative-eps="%s/%s%s.eps"', context.imagesurl, context.prefix, id)];
    end;

    if context.exportraw
            
        file = export_figure(handle, fullfile(context.raw, [context.prefix, id]), 'fig', 'cache', context.cache);
        
        % Hack : try to fix potential figure invisibility
        try
            f = load(file, '-mat');
            n = fieldnames(f);
            f.(n{1}).properties.Visible = 'on';
            save(file, '-struct', 'f'); 
        catch e
            print_debug('Warning: unable to fix figure visibility: %s', e.message);
        end;

        data = [data, sprintf(' data-alternative-fig="%s/%s%s.fig"', context.imagesurl, context.prefix, id)];
    end;

    fprintf(fid, ...
        '<img src="%s/%s%s.png" alt="%s" %s /><div class="title">%s</div>\n', ...
        context.imagesurl, context.prefix, id, title, data, title);

    fprintf(fid, '</div>\n');
    
end
