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
temporary_fid = fopen(temporary_file, 'w');

template_file = get_global_variable('report_template');

target_file = fullfile(context.root, sprintf('%s%s.html', context.prefix, name));

document = struct('fid', temporary_fid, ...
    'temporary_file', temporary_file, 'title', title, ...
    'template_file', template_file, 'target_file', target_file);

document.url = sprintf('%s%s.html', context.prefix, name);

document.write = @() write_report_document(document);

document.chapter = @(text, varargin) insert_chapter(document, sprintf(text, varargin{:}));

document.section = @(text, varargin) insert_section(document, sprintf(text, varargin{:}));

document.subsection = @(text, varargin) insert_subsection(document, sprintf(text, varargin{:}));

document.text = @(text, varargin) insert_text(document, sprintf(text, varargin{:}));

document.table = @(data, varargin) insert_table(document, data, varargin{:});

document.link = @(url, text, varargin) insert_link(document, url, sprintf(text, varargin{:}));

document.figure = @(handle, id, title) insert_figure(context, document.fid, handle, id, title);

document.raw = @(text, varargin) fprintf(document.fid, text, varargin{:});

end

function write_report_document(document)

    fclose(document.fid);

    generate_from_template(document.target_file, document.template_file, ...
        'body', fileread(document.temporary_file), 'title', document.title, ...
        'timestamp', datestr(now, 31));
    
    delete(document.temporary_file);
    
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

function insert_table(document, data, varargin)

    fprintf(document.fid, '<div class="table">');

    matrix2html(data, document.fid, varargin{:});

    fprintf(document.fid, '</div>');

end


