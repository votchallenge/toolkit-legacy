function document = create_report(title, type)

temporary_file = tempname;
temporary_fid = fopen(temporary_file, 'w');

if strcmp(type, 'html')
    template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');
elseif strcmp(type, 'latex')
    template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.tex');
end;

document = struct('type', type, 'fid', temporary_fid, ...
    'temporary_file', temporary_file, 'title', title, 'template_file', template_file);

document.write = @(target) write_report_document(document, target);

document.chapter = @(text, varargin) insert_chapter(document, sprintf(text, varargin{:}));

document.section = @(text, varargin) insert_section(document, sprintf(text, varargin{:}));

document.subsection = @(text, varargin) insert_subsection(document, sprintf(text, varargin{:}));

document.text = @(text, varargin) insert_text(document, sprintf(text, varargin{:}));

end

function write_report_document(document, target)

    fclose(document.fid);

    generate_from_template(target, document.template_file, ...
        'body', fileread(document.temporary_file), 'title', document.title, ...
        'timestamp', datestr(now, 31));
    
    delete(document.temporary_file);
    
end


function insert_chapter(document, text)

    if strcmp(document.type, 'html')
        fprintf(document.fid, '<h1>%s</h1>', text);
    elseif strcmp(document.type, 'latex')
        fprintf(document.fid, '\\chapter{%s}', str2latex(text));
    end;

end

function insert_section(document, text)

    if strcmp(document.type, 'html')
        fprintf(document.fid, '<h2>%s</h2>', text);
    elseif strcmp(document.type, 'latex')
        fprintf(document.fid, '\\section{%s}', str2latex(text));
    end;

end

function insert_subsection(document, text)

    if strcmp(document.type, 'html')
        fprintf(document.fid, '<h3>%s</h3>', text);
    elseif strcmp(document.type, 'latex')
        fprintf(document.fid, '\\subsection{%s}', str2latex(text));
    end;

end

function insert_text(document, text)

    if strcmp(document.type, 'html')
        fprintf(document.fid, '<p>%s</p>', text);
    elseif strcmp(document.type, 'latex')
        fprintf(document.fid, '%s', str2latex(text));
    end;

end
