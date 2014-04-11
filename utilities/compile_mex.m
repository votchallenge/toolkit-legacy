function [success] = compile_mex(name, files, includes)

if exist(name, 'file') == 3
     success = true;
     return;
end

if nargin < 3
	includes = cell(0);
end

includes = cellfun(@(x) sprintf('-I%s', x), includes, 'UniformOutput', false);

if is_octave() 
    
    mkoctfile('-mex', '-o', name, includes{:}, files{:});
    
else
   
    mex('-output', name, includes{:}, files{:});
    
end

success = true;
