function [tracker] = create_tracker(identifier, varargin)
% create_tracker Create a new tracker structure
%
% tracker = create_tracker(identifier, ...) 
%
% Create a new tracker structure by searching for a tracker definition file using given
% tracker identifier string.
%
% Input:
% - identifier: A valid tracker identifier string. See `valid_identifier` for more details.
% - varargin[Version]: Version of a tracker. See tracker versioning for more details.
% - varargin[MakeDirectory]: A boolean indicating if a result directory should be automatically generated.
%
% Output:
% - tracker: A new tracker structure.

version = [];
makedirectory = true;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'version'
            version = varargin{i+1};            
        case 'makedirectory'
            makedirectory = varargin{i+1};  
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

if isempty(version)
    tokens = regexp(identifier,':','split');
    if numel(tokens) > 2
        error('Error: %s is not a valid tracker identifier.', identifier);
    elseif numel(tokens) == 2
        family_identifier = tokens{1}; % Override family identifier
        version = tokens{2}; % The second part is the version
    else
        family_identifier = identifier; % By default these are both the same
    end;
else
    family_identifier = identifier;
    identifier = sprintf('%s:%s', identifier, num2str(version));
end;

result_directory = fullfile(get_global_variable('directory'), 'results', identifier);

if makedirectory
    mkpath(result_directory);
end;

[identifier_valid, identifier_conditional] = valid_identifier(family_identifier);
configuration_found = exist(['tracker_' , family_identifier]) ~= 2; %#ok<EXIST>

if ~identifier_conditional
    error('Error: %s is not a valid tracker identifier.', family_identifier);
end;

if configuration_found || ~identifier_valid
    
	if ~identifier_valid
		print_text('WARNING: Identifier %s contains characters that should not be used.', identifier);
	end

    if ~isempty(version)
        tracker_label = sprintf('%s (%s)', family_identifier, num2str(version));
	else
		tracker_label = family_identifier;
    end;
    
    print_text('WARNING: No configuration for tracker %s found', identifier);
    tracker = struct('identifier', identifier, 'command', [], ...
        'directory', result_directory, 'linkpath', [], ...
        'label', tracker_label, 'autogenerated', true, 'metadata', struct(), ...
		'interpreter', [], 'trax', false, 'version', version, ...
        'family', family_identifier);
else

	tracker_metadata = struct();
	tracker_label = identifier;
	tracker_interpreter = [];
	tracker_linkpath = {};
	tracker_trax = true;
    tracker_trax_parameters = {};

	tracker_configuration = str2func(['tracker_' , family_identifier]);
	tracker_configuration();

    if ischar(tracker_label)
        tracker_label = strtrim(tracker_label);
    end;
    
    if ~isempty(version)
        tracker_label = sprintf('%s (%s)', tracker_label, num2str(version));
    end;

	tracker = struct('identifier', identifier, 'command', tracker_command, ...
		    'directory', result_directory, 'linkpath', {tracker_linkpath}, ...
		    'label', tracker_label, 'interpreter', tracker_interpreter, ...
		    'autogenerated', false, 'version', version, 'family', family_identifier);
		
	if tracker_trax
		trax_executable = get_global_variable('trax_client', '');
		if isempty(trax_executable) && ~isempty(tracker.command)
		    error('TraX support not available');
		end;
		tracker.run = @trax_wrapper;
		tracker.trax = true;
        tracker.trax_parameters = tracker_trax_parameters;
		tracker.linkpath{end+1} = fullfile(matlabroot, 'bin', lower(computer('arch')));
	else
		tracker.run = @system_wrapper; %#ok<UNRCH>
		tracker.trax = false;
	end;

	if isstruct(tracker_metadata)
		tracker.metadata = tracker_metadata;
	else
		tracker.metadata = struct();
	end;
end;

performance_filename = fullfile(tracker.directory, 'performance.txt');

if exist(performance_filename, 'file')
    tracker.performance = readstruct(benchmark_hardware(tracker));
end;


