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

document.include('css', 'report.css');

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
        url = sprintf('%s/%s/%s', 'resources', resources{i}.type, resources{i}.name);

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
    
    generate_from_template(document.target_file, document.template_file, ...
        'body', fileread(document.temporary_file), 'title', document.title, ...
        'timestamp', datestr(now, 31), 'head', head);
    
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

function insert_figure(context, fid, handle, id, title)

    fprintf(fid, '<div class="plot">\n');

    export_figure(handle, fullfile(context.images, [context.prefix, id]), 'png', 'cache', context.cache);

    fprintf(fid, ...
        '<img src="%s/%s%s.png" alt="%s" /><span class="caption">%s</span>\n', ...
        context.imagesurl, context.prefix, id, title, title);

    if context.exportlatex

            export_figure(handle, fullfile(context.images, [context.prefix, id]), 'eps', 'cache', context.cache);
            
            fprintf(fid, '<a href="%s/%s%s.eps" class="export eps">EPS</a>', ...
                context.imagesurl, context.prefix, id);

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

            fprintf(fid, '<a href="%s/%s%s.fig" class="export eps">FIG</a>', ...
                context.imagesurl, context.prefix, id);
    end;

    fprintf(fid, '</div>\n');
    
end