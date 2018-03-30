function [success] = compile_mex(name, files, includes, directory, varargin)
% compile_mex Compile given source files to a MEX function
%
% Compiles or recompiles given source files to a MEX function taking
% into account source files timestamps. Also works in Octave by switching
% to mkoctfile command.
%
% Input:
% - name (string): Name of MEX function.
% - files (cell array): Array of source files.
% - includes (cell array): Optional array of include directories.
% - directory (string): Optional path of target directory.
%
% Output:
% - success (boolean): True if successful.
%

    function datenum = file_timestamp(filename)
        if ~exist(filename, 'file')
            datenum = 0;
            return;
        end;
        file_description = dir(filename);
        datenum = file_description.datenum;
    end

    mexname = fullfile(directory, sprintf('%s.%s', name, mexext));

    if exist(mexname, 'file') == 2 || exist(mexname, 'file') == 3

        function_timestamp = file_timestamp(mexname);

        older = cellfun(@(x) file_timestamp(x) < function_timestamp, files, 'UniformOutput', true);

        if all(older)
            success = true;
            return;
        end;
    end

    mexdebug = get_global_variable('mex_debug', false);

    arguments = {};

    if is_octave()
       arguments{end+1} = '-DOCTAVE';
    else
        arguments{end+1} = '-lut';
    end

    if mexdebug
       arguments{end+1} = '-g';
    end;

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

            [out, status] = mkoctfile('-mex', '-o', name, varargin{:}, includes{:}, files{:}, arguments{:});

            % Clean up mess
            for i = 1:numel(files)
                [pathstr, name, ext] = fileparts(files{i});
                tmpfile = fullfile(directory, [name, '.o']);
                if exist(tmpfile, 'file')
                  delete(tmpfile);
                end
            end

            if status
                error('Compile problem, see compiler output.');
            end;

        else

            mex('-output', name, varargin{:}, includes{:}, files{:}, arguments{:});

        end

        cd(old_dir);

        success = true;

    catch e
        cd(old_dir);
        print_text('ERROR: Unable to compile MEX function: "%s".', e.message);
        success = false;

    end

end
