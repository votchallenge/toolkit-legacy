function h = sfigure(h)
% sfigure Silently creates a figure window
%
% Creates a figure window without stealing the focus.
%
% Input:
% - h (integer): Optional id of the figure.
%
% Output:
% - h (integer): Resulting id of the figure.

if nargin>=1
if ishandle(h)
    set(0, 'CurrentFigure', h);
else
    h = figure(h);
end
else
    h = figure;
end
