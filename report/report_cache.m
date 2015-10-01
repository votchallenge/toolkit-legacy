function result = report_cache(context, identifier, fun, varargin)
% report_cache Cache proxy for report generation
%
% Can be used with report context to cache results of a certain function.
%
% Input:
% - context (structure): Report context structure.
% - identifier (string): Caching identifier.
% - fun (handle): Handle to processing function.
% - varargin (cell): Arguments for processing function.
%
% Output:
% - result: Output argument of the processing function.
%
cache_file = fullfile(context.cachedir, sprintf('%s.mat', identifier));

result = {};
if exist(cache_file, 'file')         
    load(cache_file);       
end;

if isempty(result)

    clear result;

    result = fun(varargin{:});
    
    save(cache_file, 'result');

end;

