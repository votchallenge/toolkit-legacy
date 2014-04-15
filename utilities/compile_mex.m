function [success] = compile_mex(name, files, includes, directory)

if exist(name, 'file') == 3
     success = true;
     return;
end

arguments = {};

if nargin < 3
	includes = cell(0);
end

if nargin < 4
    directory = '';
end;

includes = cellfun(@(x) sprintf('-I%s', x), includes, 'UniformOutput', false);

old_dir = pwd;

try

    if ~isempty(directory)
        cd(directory)
    end;

    if is_octave() 

        mkoctfile('-mex', '-o', name, includes{:}, files{:}, arguments{:});

    else

        mex('-output', name, includes{:}, files{:}, arguments{:});

    end

    cd(old_dir);
    
    success = true;

catch e
    
    print_text('ERROR: Unable to compile MEX function: "%s".', e.message);
    success = false;

end
