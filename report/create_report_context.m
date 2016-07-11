function context = create_report_context(name, varargin)
% create_report_context Create report context structure
%
% Creates a new report context structure that can be used to generate
% report documents.
%
% Input:
% - name (string): Name of the report. Is used to name a directory where the report is stored in.
% - varargin[Title] (string): A human-friendly name of the report. May be more verbose than report name.
% - varargin[FigureEPS] (boolean): Should the report also generate formaps in Encapsulated PostScript (for LaTeX).
% - varargin[FigureRaw] (boolean): Should internal raw figures and data also be saved for future processing.
% - varargin[Standalone] (boolean): If true (default), the JavaScript and CSS resources are copied to the report.
% - varargin[Cache] (boolean): Should cache be used.
%
% Output:
% - context (structure): A report context structure.
%


title = name;
figure_eps = false;
figure_raw = false;
standalone = true;
cache = false;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'title'
            title = varargin{i+1};
        case 'figureeps'
            figure_eps = varargin{i+1};
        case 'figureraw'
            figure_raw = varargin{i+1};
        case 'standalone'
            standalone = varargin{i+1};
        case 'cache'
            cache = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 


context.root = fullfile(get_global_variable('directory'), 'reports', name);
context.images = fullfile(context.root, 'images');
context.raw = fullfile(context.root, 'raw');
context.data = fullfile(context.root, 'data');
context.exporteps = figure_eps;
context.exportraw = figure_raw;
context.standalone = standalone;
context.prefix = '';
context.imagesurl = 'images';
context.rawurl = 'raw';
context.dataurl = 'data';
context.title = title;
context.cache = cache;

mkpath(context.root);
mkpath(context.images);
mkpath(context.data);
mkpath(context.raw);

context.cachedir = fullfile(context.root, 'cache');
mkpath(context.cachedir);
