function command = generate_octave_command(script, paths)
% generate_octave_command Generate command line for Octave tracker
%
% This function generates the appropritate command string that will
% run the Octave executable and execute the given script that includes your
% tracker implementation.
%
% Input:
% - script (string): Name of the tracker script to be executed.
% - paths (cell): An array of strings that denote directories to be added to Octave path.
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

octave_flags = {};

if ispc()
	octave_executable = ['"', fullfile(matlabroot, 'bin', 'octave.exe'), '"'];
else
	octave_executable = fullfile(matlabroot, 'bin', 'octave');
end

if compare_versions(version(), '4.0.0', '>=')
	octave_flags{end+1} = '--no-gui';
	octave_flags{end+1} = '--no-window-system';
end

argument_string = strjoin(octave_flags, ' ');

octave_script = sprintf('try; diary ''runtime.log''; %s%s; catch ex; disp(ex.message); for i = 1:size(ex.stack) disp(''filename''); disp(ex.stack(i).file); disp(''line''); disp(ex.stack(i).line); endfor; end; quit;', path_string, script);

command = sprintf('%s %s --eval "%s"', octave_executable, argument_string, octave_script);
