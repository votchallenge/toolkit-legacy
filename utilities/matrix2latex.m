function matrix2latex(matrix, filename, varargin)

% function: matrix2latex(...)
% Author:   M. Koehler
% Contact:  koehler@in.tum.de
% Version:  1.1
% Date:     May 09, 2004

% This software is published under the GNU GPL, by the free software
% foundation. For further reading see: http://www.gnu.org/licenses/licenses.html#GPL

% Usage:
% matrix2late(matrix, filename, varargs)
% where
%   - matrix is a 2 dimensional numerical or cell array
%   - filename is a valid filename, in which the resulting latex code will
%   be stored
%   - varargs is one ore more of the following (denominator, value) combinations
%      + 'rowLabels', array -> Can be used to label the rows of the
%      resulting latex table
%      + 'columnLabels', array -> Can be used to label the columns of the
%      resulting latex table
%      + 'alignment', 'value' -> Can be used to specify the alginment of
%      the table within the latex document. Valid arguments are: 'l', 'c',
%      and 'r' for left, center, and right, respectively
%      + 'format', 'value' -> Can be used to format the input data. 'value'
%      has to be a valid format string, similar to the ones used in
%      fprintf('format', value);
%      + 'size', 'value' -> One of latex' recognized font-sizes, e.g. tiny,
%      HUGE, Large, large, LARGE, etc.
%
% Example input:
%   matrix = [1.5 1.764; 3.523 0.2];
%   rowLabels = {'row 1', 'row 2'};
%   columnLabels = {'col 1', 'col 2'};
%   matrix2latex(matrix, 'out.tex', 'rowLabels', rowLabels, 'columnLabels', columnLabels, 'alignment', 'c', 'format', '%-6.2f', 'size', 'tiny');
%
% The resulting latex file can be included into any latex document by:
% /input{out.tex}
%
% Enjoy life!!!

    rowLabels = [];
    colLabels = [];
    alignment = 'l';
	prefix = [];
	suffix = [];
    format = '%.2f';
    textsize = [];
    if (rem(nargin,2) == 1 || nargin < 2)
        error('Incorrect number of arguments to %s.', mfilename);
    end

    okargs = {'rowlabels','columnlabels', 'alignment', 'format', 'size', 'prefix', 'suffix'};
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
                case 3  % alignment
                    switch lower(pval);
                        case 'right'
                            alignment = 'r';
                        case 'left'
                            alignment = 'l';
                        case 'center'
                            alignment = 'c';
                        otherwise
                            alignment = 'l';
                            warning('Unkown alignment. (Set it to \''left\''.)');
                    end
                case 4  % format
                    format = lower(pval);
                case 5  % size
                    textsize = pval;
                case 6
                    prefix = pval;
                case 7
                    suffix = pval;
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
            	matrix{h, w} = num2str(matrix{h, w}, format);
            end
        end
        
    elseif iscell(matrix)
        for h=1:height
            for w=1:width
                if isnumeric(matrix{h, w})
                    matrix{h, w} = num2str(matrix{h, w}, format);
                elseif isstruct(matrix{h, w})
                    matrix{h, w} = struct2latexstr(matrix{h, w}, format);
                end;
            end
        end
    end;

    
    if(~isempty(textsize))
        fprintf(fid, '\\begin{%s}', textsize);
    end

    fprintf(fid, '\\begin{tabular}{|');

    if(~isempty(rowLabels))
        fprintf(fid, 'l|');
    end
    for i=1:width
        fprintf(fid, '%c|', alignment);
    end
    fprintf(fid, '}\r\n');
    
    fprintf(fid, '\\hline\r\n');
    
	if (~isempty(prefix))
	    fprintf(fid, '%s\\\\\r\n\\hline\r\n', prefix);
	end;

    if(~isempty(colLabels))
        if(~isempty(rowLabels))
            fprintf(fid, '&');
        end
        for w=1:width-1
            fprintf(fid, '\\textbf{%s}&', str2latex(colLabels{w}));
        end
        fprintf(fid, '\\textbf{%s}\\\\\\hline\r\n', str2latex(colLabels{width}));
    end
    
    for h=1:height
        if(~isempty(rowLabels))
            fprintf(fid, '\\textbf{%s}&', str2latex(rowLabels{h}));
        end
        for w=1:width-1
            fprintf(fid, '%s&', matrix{h, w});
        end
        fprintf(fid, '%s\\\\\\hline\r\n', str2latex(matrix{h, width}));
    end

	if (~isempty(suffix))
	    fprintf(fid, '%s\\\\\r\n\\hline\r\n', suffix);
	end;


    fprintf(fid, '\\end{tabular}\r\n');
    
    if(~isempty(textsize))
        fprintf(fid, '\\end{%s}', textsize);
    end

    if (close_file)
        fclose(fid);
    end;
end

function str = struct2latexstr(s, format)

    if ~isfield(s, 'text')
        str = '';
        return;
    end;

    if isnumeric(s.text)
        str = num2str(s.text, format);
    else
        str = s.text;
    end;
    
    if isfield(s, 'class')
        str = sprintf('\\%s{%s}', s.class, str);
    end

end
