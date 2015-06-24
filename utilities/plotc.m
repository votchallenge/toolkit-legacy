function plotc(x, y, varargin)
% plotc Plot closed polygon
%
% Plot a closed polygon (line between first and last point) on the current figure.
%
% Input:
% - x (double vector): A vector of x coordinates of a polygon
% - y (double vector): A vector of y coordinates of a polygon
% - varargin (cell): Additional arguments that are passed to the plot function.
%


    x = [x(:); x(1)];
    y = [y(:); y(1)];

    plot(x, y, varargin{:});
    
end
