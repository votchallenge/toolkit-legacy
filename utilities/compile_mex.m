function [success] = compile_mex(name, files, includes, directory)

    function datenum = file_timestamp(filename)
        if ~exist(filename, 'file')
            datenum = 0;
            return;
        end;
        file_description = dir(filename);
        datenum = file_description.datenum;
    end

    if exist(name, 'file') == 3

        function_timestamp = file_timestamp(which(name));

        older = cellfun(@(x) file_timestamp(x) < function_timestamp, files, 'UniformOutput', true);

        if all(older)
        
            success = true;
            return;
        end;
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

        cd(old_dir);
        print_text('ERROR: Unable to compile MEX function: "%s".', e.message);
        success = false;

    end
    
end
