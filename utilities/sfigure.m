function h = sfigure(h)
% SFIGURE  Create figure window (minus annoying focus-theft).

if nargin>=1
if ishandle(h)
    set(0, 'CurrentFigure', h);
else
    h = figure(h);
end
else
    h = figure;
end
