function command = generate_python_command(script, paths)
% generate_python_command Generate command line for a Python tracker
%
% This function generates the appropritate command string that will 
% run the python executable and execute the given script that includes your
% tracker implementation.
%
% Input:
% - script (string): Name of the tracker script to be executed.
% - paths (cell): An array of strings that denote directories to be added to Matlab path.
%
% Output:
% - command (string): Generated command string.
%

trax_python = get_global_variable('trax_python');
python_exec = get_global_variable('python');

% If path to python trax implementatin is set then we attempt to export it to tracker
if ~isempty(trax_python)
    paths = cat(1, {trax_python}, paths);
end

path_string = strjoin(cellfun(@(p) sprintf('sys.path.append(''%s'');', p), paths, 'UniformOutput', false), '');

% Attempt to locate python interpreter
if isempty(python_exec)
    if ispc()
	    path_separator = ';';
	    exec_name = 'python.exe';
    else
	    path_separator = ':';
	    exec_name = 'python';
    end

    system_paths = strsplit(getenv('PATH'), path_separator);

    for i = 1:numel(system_paths)
        if exist(fullfile(system_paths{i}, exec_name), 'file') == 2
            python_exec = fullfile(system_paths{i}, exec_name);
        end
    end

end

if isempty(python_exec)
    error('Unable to locate Python interpreter, please set the "python" global variable manually.');
end

if ispc()
	python_executable = ['"', python_exec, '"'];
	python_flags = {};
else
	python_executable = python_exec;
	python_flags = {};
end

argument_string = strjoin(python_flags, ' ');

python_script = sprintf('import sys; %s import %s', path_string, script);

command = sprintf('%s %s -c "%s"', python_executable, argument_string, python_script);
