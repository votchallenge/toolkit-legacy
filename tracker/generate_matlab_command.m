function command = generate_matlab_command(script, paths)
% generate_matlab_command Generate command line for Matlab tracker
%
% This function generates the appropritate command string that will 
% run the matlab executable and execute the given script that includes your
% tracker implementation.
%
% Input:
% - script (string): Name of the tracker script to be executed.
% - paths (cell): An array of strings that denote directories to be added to Matlab path.
%
% Output:
% - command (string): Generated command string.
%

trax_mex = get_global_variable('trax_mex');

% If path to trax mex file is set then we attempt to export it to tracker
if ~isempty(trax_mex)
    paths{end+1} = trax_mex;
end

path_string = strjoin(cellfun(@(p) sprintf('addpath(''%s'');', p), paths, 'UniformOutput', false), '');

if ispc()
	matlab_executable = ['"', fullfile(matlabroot, 'bin', 'matlab.exe'), '"'];
	matlab_flags = {'-nodesktop', '-nosplash', '-wait', '-minimize'};
else
	matlab_executable = fullfile(matlabroot, 'bin', 'matlab');
	matlab_flags = {'-nodesktop', '-nosplash'};
end

argument_string = strjoin(matlab_flags, ' ');

matlab_script = sprintf('try; diary ''runtime.log''; %s%s; catch ex; disp(getReport(ex)); end; quit;', path_string, script);

command = sprintf('%s %s -r "%s"', matlab_executable, argument_string, matlab_script);
