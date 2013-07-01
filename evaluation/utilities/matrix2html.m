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
    format = [];
    css_class = [];
    if (rem(nargin,2) == 1 || nargin < 2)
        error('Incorrect number of arguments to %s.', mfilename);
    end

    okargs = {'rowlabels','columnlabels', 'format', 'class'};
    for j=1:2:(nargin-2)
        pname = varargin{j};
        pval = varargin{j+1};
        k = strmatch(lower(pname), okargs);
        if isempty(k)
            error('Unknown parameter name: %s.', pname);
        elseif length(k)>1
            error('Ambiguous parameter name: %s.', pname);
        else
            switch(k)
                case 1  % rowlabels
                    rowLabels = pval;
                    if isnumeric(rowLabels)
                        rowLabels = cellstr(num2str(rowLabels(:)));
                    end
                case 2  % column labels
                    colLabels = pval;
                    if isnumeric(colLabels)
                        colLabels = cellstr(num2str(colLabels(:)));
                    end
                case 3  % format
                    format = lower(pval);
                case 4  % format
                    css_class = pval;
            end
        end
    end

    if (ischar(filename))
        fid = fopen(filename, 'w');
        close_file = 1;
    else
        fid = filename;
        close_file = 0;
    end;
    
    width = size(matrix, 2);
    height = size(matrix, 1);

    if isnumeric(matrix)
        matrix = num2cell(matrix);
        for h=1:height
            for w=1:width
                if(~isempty(format))
                    matrix{h, w} = num2str(matrix{h, w}, format);
                else
                    matrix{h, w} = num2str(matrix{h, w});
                end
            end
        end
    end
    
    if(~isempty(css_class))
        fprintf(fid, '<table class="%s">\n', css_class);
    else
        fprintf(fid, '<table>\n');
    end
    
    if(~isempty(colLabels))
        fprintf(fid, '<tr>');
        if(~isempty(rowLabels))
            fprintf(fid, '<th>&nbsp;</th>');
        end
        for w=1:width
            fprintf(fid, '<th>%s</th>', colLabels{w});
        end
        fprintf(fid, '</tr>\r\n');
    end
    
    for h=1:height
        fprintf(fid, '<tr>');
        if(~isempty(rowLabels))
            fprintf(fid, '<th>%s</th>', rowLabels{h});
        end
        for w=1:width
            fprintf(fid, '<td>%s</td>', matrix{h, w});
        end
        fprintf(fid, '</tr>\r\n');
    end

    fprintf(fid, '</table>\r\n');
    
    if (close_file)
        fclose(fid);
    end;
