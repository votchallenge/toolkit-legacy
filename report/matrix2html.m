function matrix2html(matrix, filename, varargin)
% matrix2html Generates a HTML table for a given matrix
%
% The function generates a HTML table based on a given matrix or cell array.
% 
% Input
% - matrix (matrix): A 2 dimensional numerical or cell array
% - filename (string): A valid filename or a file handle
% - varargs[RowLabels] (array): Can be used to label the rows of the table
% - varargs[ColumnLabels] (array): Can be used to label the columns of the table
% - varargs[Format] (string): Format of the numeric input data in the printf format.
% - varargs[Class] (string): CSS class of the table.
% - varargs[Title] (string): Title of the table.
% - varargs[EmbedNumers] (boolean): Embed numerical data as data attributes.
%

    rowLabels = [];
    colLabels = [];
    format = '%.2f';
    css_class = [];
    title = [];
    embed_numbers = true;
    if (rem(nargin,2) == 1 || nargin < 2)
        error('Incorrect number of arguments to %s.', mfilename);
    end

    for i = 1:2:length(varargin)
        switch lower(varargin{i}) 
            case 'rowlabels'
                rowLabels = varargin{i+1};
            case 'columnlabels'
                colLabels = varargin{i+1};    
            case 'format'
                format = lower(varargin{i+1});
            case 'class'
                css_class = [css_class, ' ', varargin{i+1}];
            case 'title'
                title = varargin{i+1};
            case 'embednumbers'
                embed_numbers = varargin{i+1};    
            otherwise 
                error(['Unknown switch ', varargin{i}, '!']) ;
        end
    end     

    rowLabels = matrix2cells(rowLabels, 'th', format, false);
    colLabels = matrix2cells(colLabels, 'th', format, false);
    matrix = matrix2cells(matrix, 'td', format, embed_numbers);                

    if (ischar(filename))
        fid = fopen(filename, 'w');
        close_file = 1;
    else
        fid = filename;
        close_file = 0;
    end;
    
    if ~isempty(colLabels) && ~isempty(rowLabels)

        stub = cell(size(colLabels, 1), size(rowLabels, 2));        
        stub{1, 1} = sprintf('<th colspan="%d" rowspan="%d">&nbsp;</th>', ...
                size(rowLabels, 2), size(colLabels, 1));
        
        head = cat(2, stub, colLabels);
            
        body = cat(2, rowLabels, matrix);

    elseif ~isempty(colLabels)

        head = colLabels;
        
        body = matrix;

    elseif ~isempty(rowLabels)
       
        head = [];
        body = cat(2, rowLabels, matrix);

    end;


    if(~isempty(title))
        fprintf(fid, '<div class="title">%s</div>\n', title);
    end
    
    if(~isempty(css_class))
        fprintf(fid, '<table class="%s">\n', css_class);
    else
        fprintf(fid, '<table>\n');
    end

    if ~isempty(head)
    
        skip = cellfun(@(x) isempty(x), head, 'UniformOutput', true);
        fprintf(fid, '<thead>');
        for i = 1 : size(head, 1)
            fprintf(fid, '<tr>');
            cellfun(@(x) fwrite(fid, x), head(i, ~skip(i, :)), 'UniformOutput', true);
            fprintf(fid, '</tr>');
        end;    
        fprintf(fid, '</thead>');
    end;
    
    skip = cellfun(@(x) isempty(x), body, 'UniformOutput', true);
    
    fprintf(fid, '<tbody>');
    for i = 1 : size(body, 1)
        fprintf(fid, '<tr>');
        cellfun(@(x) fwrite(fid, x), body(i, ~skip(i, :)), 'UniformOutput', true);
        fprintf(fid, '</tr>');
    end;
    fprintf(fid, '</tbody>');
    
    fprintf(fid, '</table>\r\n');
    
    if (close_file)
        fclose(fid);
    end;

end

function [cells] = matrix2cells(matrix, element, format, embed_numbers)

    if isnumeric(matrix)
        matrix = num2cell(matrix);
    end;
    [cells, rowspan, colspan, attributes] = cellfun(@(x) cell2cell(x, format, embed_numbers), ...
        matrix, 'UniformOutput', false);
    rowspan = cell2mat(rowspan);
    colspan = cell2mat(colspan);

    width = size(matrix, 2);
    height = size(matrix, 1);

    for h=1:height
        for w=1:width
            if rowspan(h, w) == 0 || colspan(h, w) == 0
                cells{h, w} = '';
            elseif rowspan(h, w) == 1 && colspan(h, w) == 1
                cells{h, w} = sprintf('<%s %s>%s</%s>', element, ...
                    attributes{h, w}, cells{h, w}, element);
            elseif rowspan(h, w) == 1
                cells{h, w} = sprintf('<%s colspan="%d" %s>%s</%s>', ...
                    element, colspan(h, w), attributes{h, w}, cells{h, w}, element);
            elseif colspan(h, w) == 1
                cells{h, w} = sprintf('<%s rowspan="%d" %s>%s</%s>', ...
                    element, rowspan(h, w), attributes{h, w}, cells{h, w}, element);
            else
                cells{h, w} = sprintf('<%s colspan="%d" rowspan="%d" %s>%s</%s>', ...
                    element, colspan(h, w), rowspan(h, w), attributes{h, w}, cells{h, w}, element);
            end;
        end
    end

%     max_width = max(sum(colspan));
%     max_height = max(sum(rowspan));
%     
%     if max_width < width
%         cells = cells(:, 1:max_width);
%     end
%     
%     if max_height < height
%         cells = cells(:, 1:max_height);
%     end
    
end

function [str, rowspan, colspan, cell_attributes] = cell2cell(s, format, embed_numbers)

    rowspan = 1;
    colspan = 1;

    cell_attributes = '';
    
    if isnumeric(s)
        str = num2str(s, format);
        if embed_numbers
            cell_attributes = [cell_attributes, sprintf(' data-numeric="%f" ', s)];
        end;
        return;
    elseif ~isstruct(s)
        str = s;
        return;
    end;

    if ~isfield(s, 'text')
        rowspan = 0;
        colspan = 0;
        str = [];
        return;
    end;

    if isfield(s, 'format')
        format = s.format;
    end;

    if isfield(s, 'columns')
        colspan = s.columns;
    end
    
    if isfield(s, 'rows')
        rowspan = s.rows;
    end

    if isnumeric(s.text)
        if embed_numbers
            cell_attributes = [cell_attributes, sprintf(' data-numeric="%f" ', s.text)];
        end;
        str = num2str(s.text, format);
    else
        str = s.text;
    end;

    element = 'span';
    attributes = '';
    
    if isfield(s, 'class')
        cell_attributes = [cell_attributes, ' class="', s.class, '" '];
    end

    if isfield(s, 'tooltip')
        attributes = [attributes, ' title="', s.tooltip, '" '];
    end

    if isfield(s, 'url')
        element = 'a';
        attributes = [attributes, ' href="', s.url, '" '];
    end    
    
    if ~isempty(attributes)
       str = sprintf('<%s %s>%s</%s>', element, attributes, str, element);     
    end
    
end
