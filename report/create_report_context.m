function context = create_report_context(name, varargin)

title = name;
latex = false;
raw = false;
cache = false;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'title'
            title = varargin{i+1};
        case 'latex'
            latex = varargin{i+1};
        case 'raw'
            raw = varargin{i+1};
        case 'cache'
            cache = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 


context.root = fullfile(get_global_variable('directory'), 'reports', name);
context.images = fullfile(context.root, 'images');
context.raw = fullfile(context.root, 'raw');
context.exportlatex = latex;
context.exportraw = raw;
context.prefix = '';
context.imagesurl = 'images';
context.rawurl = 'raw';
context.title = title;
context.cache = cache;

mkpath(context.root);
mkpath(context.images);
mkpath(context.raw);

context.cachedir = fullfile(context.root, 'cache');
mkpath(context.cachedir);
