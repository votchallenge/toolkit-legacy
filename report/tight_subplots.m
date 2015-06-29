function handles = tight_subplots(rows, columns, gap, row_margin, column_margin)
% tight_subplots Initializes a grid of axes
%
% Initializes a grid of axes with adjustable gaps and margins 
% and returns their handles.
%
% Credit: Pekka Kumpulainen (2010) @tut.fi Tampere University of Technology / Automation Science and Engineering
%
% Input:
% - rows (integer): Number of axes in hight (vertical direction).
% - columns (integer): Number of axes in width (horizontal direction).
% - gap (double): Gaps between the axes in normalized units (0...1)
%   or [gap_h gap_w] for different gaps in height and width. 
% - row_margin (<type>): Margins in height in normalized units (0...1)
%   or [lower upper] for different lower and upper margins.
% - column_margin (<type>): Margins in width in normalized units (0...1)
%   or [left right] for different left and right margins 
%
% Output:
% - handles (matrix): Matrix of handles for the axes objects
%   starting from upper left corner, going row-wise as in
%   going row-wise as in.
%

if nargin<3; gap = .02; end
if nargin<4 || isempty(row_margin); row_margin = .05; end
if nargin<5; column_margin = .05; end

if numel(gap)==1; 
    gap = [gap gap];
end
if numel(column_margin)==1; 
    column_margin = [column_margin column_margin];
end
if numel(row_margin)==1; 
    row_margin = [row_margin row_margin];
end

axh = (1-sum(row_margin)-(rows-1)*gap(1))/rows; 
axw = (1-sum(column_margin)-(columns-1)*gap(2))/columns;

py = 1-row_margin(2)-axh; 

handles = zeros(rows*columns,1);
ii = 0;
for ih = 1:rows
    px = column_margin(1);
    
    for ix = 1:columns
        ii = ii+1;
        handles(ii) = axes('Units','normalized', ...
            'Position',[px py axw axh], ...
            'XTickLabel','', ...
            'YTickLabel',''); %#ok<LAXES>
        px = px+axw+gap(2);
    end
    py = py-axh-gap(1);
end