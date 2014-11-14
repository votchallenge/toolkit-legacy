function matrix2html(matrix, filename, varargin)
% matrix2html(matrix, filename, varargs)
% where
%   - matrix is a 2 dimensional numerical or cell array
%   - filename is a valid filename or a file handler be stored
%   - varargs is one ore more of the following (denominator, value) combinations
%      + 'rowLabels', array -> Can be used to label the rows of the
%      resulting latex table
%      + 'columnLabels', array -> Can be used to label the columns of the
%      resulting latex table
%      + 'format', 'value' -> Can be used to format the input data. 'value'
%      has to be a valid format string, similar to the ones used in
%      fprintf('format', value);
%      + 'class', 'value' -> CSS class of the table
%
% Example input:
%   matrix = [1.5 1.764; 3.523 0.2];
%   rowLabels = {'row 1', 'row 2'};
%   columnLabels = {'col 1', 'col 2'};
%   matrix2html(matrix, 'out.html', 'rowLabels', rowLabels, 'columnLabels', columnLabels, 'format', '%-6.2f');
%

    rowLabels = [];
    colLabels = [];
    format = '%.2f';
    css_class = [];
    title = [];
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
                css_class = varargin{i+1};
            case 'title'
                title = varargin{i+1};    
            otherwise 
                error(['Unknown switch ', varargin{i}, '!']) ;
        end
    end     

    rowLabels = matrix2cells(rowLabels, 'th', format);
    colLabels = matrix2cells(colLabels, 'th', format);
    matrix = matrix2cells(matrix, 'td', format);                

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
        
        matrix = cat(2, cat(1, stub, rowLabels), cat(1, colLabels, matrix));

    elseif ~isempty(colLabels)

        matrix = cat(1, colLabels, matrix);

    elseif ~isempty(rowLabels)

        matrix = cat(2, rowLabels, matrix);

    end;


    if(~isempty(title))
        fprintf(fid, '<div class="title">%s</div>\n', title);
    end
    
    if(~isempty(css_class))
        fprintf(fid, '<table class="%s">\n', css_class);
    else
        fprintf(fid, '<table>\n');
    end
    
    skip = cellfun(@(x) isempty(x), matrix, 'UniformOutput', true);
    
    for i = 1 : size(matrix, 1)
        fprintf(fid, '<tr>');

        cellfun(@(x) fprintf(fid, x), matrix(i, ~skip(i, :)), 'UniformOutput', true);

        fprintf(fid, '</tr>');
    end;

    fprintf(fid, '</table>\r\n');
    
    if (close_file)
        fclose(fid);
    end;

end

function [cells] = matrix2cells(matrix, element, format)

    if isnumeric(matrix)
        cells =  cellfun(@(x) num2str(x, format), ...
            num2cell(matrix), 'UniformOutput', false);
        rowspan = ones(size(cells));
        colspan = ones(size(cells));
        attributes = repmat({''}, size(cells, 1), size(cells, 2));
    else
        [cells, rowspan, colspan, attributes] = cellfun(@(x) cell2cell(x, format), ...
            matrix, 'UniformOutput', false);
        rowspan = cell2mat(rowspan);
        colspan = cell2mat(colspan);
    end    

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

function [str, rowspan, colspan, cell_attributes] = cell2cell(s, format)

    rowspan = 1;
    colspan = 1;

    cell_attributes = '';
    
    if isnumeric(s)
        str = num2str(s, format);
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
