function [supported] = tracker_test(tracker)
% trax_test Test tracker's support for TraX protocol
%
% This function tries to run the tracker and communicate with it using the
% TraX protocol to determine if it supports it. The results are chached
% in the workspace cache directory.
%
% Input:
% - tracker: Tracker structure.
%
% Output:
% - supported (boolean): Is the protocol supported.

% Check if the result of the test is already cached
cache = fullfile(get_global_variable('directory'), 'cache', 'trax');

tracker_hash = md5hash(sprintf('%s-%s-%s', tracker.command, tracker.interpreter, strjoin(tracker.linkpath, '-')));
mkpath(cache);
cache_file = fullfile(cache, sprintf('trax_%s_%s.mat', tracker.identifier, tracker_hash));

supported = [];
if exist(cache_file, 'file')
    load(cache_file);
    if ~isempty(supported)
        return;
    end;
end;

print_text('Testing TraX protocol support for tracker %s.', tracker.identifier);

try

    data.header = false;

    data = tracker_run(tracker, @callback, data);

    supported = data.header;

catch

    supported = false;

end

if supported
    % Only cache if support is detected
    save(cache_file, 'supported');
    print_text('TraX support detected.');
else
	print_text('TraX support not detected.');
end

end

function [image, region, properties, data] = callback(state, data)

    image = [];
    region = [];
    properties = struct();

    data.header = true;
    data.state = state;

end


