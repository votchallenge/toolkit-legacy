function workspace_test(tracker, sequences, varargin)
% workspace_test Tests the integration of a tracker into the toolkit
%
% Tests the integration of a tracker into the toolkit in a manual or
% automatic mode, visualizes results and estimates time to complete
% an experiment.
%
% Input:
% - tracker (structure): A valid tracker structure.
% - sequences (cell or structure): Array of sequence structures.
%

if isempty(sequences)
    error('No sequence provided');
end

print_text('');
print_text('***************************************************************************');
print_text('');
print_text('Welcome to the VOT workspace testing utility!');
print_text('This process will help you prepare your tracker for the evaluation.');
print_text('When beginning with the integration it is recommended to use the tool ');
print_text('to see if the tracker is behaving correctly.');
print_text('');
print_text('***************************************************************************');
print_text('');

debug_state = get_global_variable('trax_debug', false);
set_global_variable('trax_debug', true);
set_global_variable('trax_debug_console', true);

if is_octave()
use_gui = get_global_variable('gui', true);
else
use_gui = get_global_variable('gui', usejava('awt'));
end;

try

    while 1

        current_sequence = sequence_select(sequences);

        if ~isempty(current_sequence)

            print_text('Sequence "%s"', sequences{current_sequence}.name);

            data.figure = 1;
            data.sequence = sequences{current_sequence};
            data.index = 1;
			data.gui = use_gui;
            data.channels = {};

            tracker_run(tracker, @callback, data);

        else
            break;
        end;

    end

catch e
    % Restore debug flag
    set_global_variable('trax_debug', debug_state);
    set_global_variable('trax_debug_console', false);
    rethrow(e);
end

end


function [image, region, properties, data] = callback(state, data)

	region = [];
	image = [];
    properties = struct();

    if isempty(data.channels)
        if ~all(ismember(state.channels, fieldnames(data.sequence.channels)));
            error('Sequence does not contain all channels required by the tracker.');
        end;
        data.channels = state.channels;
    end;
    
	% Handle initial frame (initialize for the first time)
	if isempty(state.region)
		region = sequence_get_region(data.sequence, data.index);
		image = sequence_get_image(data.sequence, data.index, data.channels);
		return;
	end;

	if data.gui

		image_path = sequence_get_image(data.sequence, data.index);
		hf = sfigure(data.figure);
		set(hf, 'Name', sprintf('%s (%d/%d t=%.3fs)', data.sequence.name, data.index, data.sequence.length, state.time), 'NumberTitle', 'off');
		imshow(imread(image_path));
		hold on;
		region_draw(sequence_get_region(data.sequence, data.index), [1 0 0], 2);
		region_draw(state.region, [0 1 0], 1);
		hold off;
		drawnow;
		try
		    [~, ~, c] = ginput(1);
		catch
		    c = -1;
		end
		try
		    if c == ' ' || c == 'f' || uint8(c) == 29

		    elseif c == 'q' || c == -1
		        print_text('Quitting.');
		        return;
		    end
		catch e
		    print_text('Error %s', e.message);
		end

	else

		c = input('(space/Q) ', 's');

		if c == 'q'
			print_text('Quitting.');
		    return;
		end
	end;

	data.index = data.index + 1;

	% End of sequence
	if data.index > data.sequence.length
		return;
	end

    image = sequence_get_image(data.sequence, data.index, data.channels);

end





