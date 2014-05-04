function plotc(x, y, varargin)

    x = [x(:); x(1)];
    y = [y(:); y(1)];

    plot(x, y, varargin{:});
    
end