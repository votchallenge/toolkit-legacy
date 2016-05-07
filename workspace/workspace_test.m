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

current_sequence = get_global_variable('current_sequence', 1);

if ~exist('trajectory', 'var')
	trajectory = [];
end;

performance = struct('frames', 0, 'time', 0);

print_text('');
print_text('***************************************************************************');
print_text('');
print_text('Welcome to the VOT workspace testing utility!');
print_text('This process will help you prepare your tracker for the evaluation.');
print_text('When beginning with the integration it is recommended to follow the steps ');
print_text('a, b, c to verify the execution and the output data.');
print_text('');
print_text('***************************************************************************');
print_text('');

if ~tracker.trax
    print_text('***************************************************************************');
    print_text('');
    print_text('                       * DEPRECATION WARNING * ');
    print_text('');
    print_text('You are using an outdated mechanism for communication between the tracker');
    print_text('and the VOT toolkit. Starting with the next version of the toolkit the ');
    print_text('support for this mechanism will be removed completely. We recommend that');
    print_text('you switch to TraX protocol before that time to avoid any problems and to');
    print_text('help us with testing of the protocol.');
    print_text('');
    print_text('***************************************************************************');
    print_text('');
end;

while 1
    print_text('Choose action:');
    print_indent(1);

    print_text('a - Generate a directory with input data for manual test');
    print_text('b - Run tracker once within the evaluation');
    if ~isempty(trajectory)
        print_text('c - Visually compare results with the groundtruth');
    end;
    if get_global_variable('debug', 0)
        print_text('d - Disable debug output');
    else
        print_text('d - Enable debug output');
    end;
    if performance.frames > 0
        print_text('t - Estimate required time for a single experiment on the given sequence set');
    end;
    print_text('e - Exit');
    print_indent(-1);

    option = input('Choose action: ', 's');

    switch option
    case 'a'
        current_sequence = select_sequence(sequences);       
        
        if ~isempty(current_sequence)
            
            [command, directory] = tracker.run(tracker, sequences{current_sequence}, struct('repetition', 1, 'repetitions', 1, 'fake', true));

            launcher_script = generate_launcher_script(tracker, command, directory);
            
            print_text('Input data generated in directory "%s"', directory);
            print_text('Open the directory in a terminal and manually execute the generated launch script.');
            print_text('The generated launcher script is named: %s', launcher_script);
            print_text('Once the tracker is working as expected (generates the output.txt), delete the directory.');
        end;
    case 'b'
        current_sequence = select_sequence(sequences);       
        
        if ~isempty(current_sequence)

            print_text('Sequence "%s"', sequences{current_sequence}.name);
            [trajectory, time] = tracker.run(tracker, sequences{current_sequence}, struct('repetition', 1, 'repetitions', 1));

            performance.time = performance.time + mean(time) * sequences{current_sequence}.length;

            performance.frames = performance.frames + sequences{current_sequence}.length;
        end;        
    case 'c'
        if ~isempty(trajectory) && current_sequence > 0 && current_sequence <= length(sequences)
            visualize_sequence(sequences{current_sequence}, trajectory);
        end;
    case 't'
        if performance.frames > 0

            fps = performance.frames / performance.time;
            
            if tracker.trax
                estimate = estimate_completion_time(sequences, 'fps', fps, 'failures', 0);
            else
                estimate = estimate_completion_time(sequences, 'fps', fps);
            end

            print_text('Based on the current estimate (fps = %.2f), the completion time for %d sequences is %s', fps, length(sequences), format_interval(estimate));
            
        end;   
	case 'd'
        set_global_variable('debug', ~get_global_variable('debug', 0));
    case 'e'
        break;
    case 'q'
        break;

    end;
    
end;

end

function launcher_script = generate_launcher_script(tracker, command, directory)

    variables = struct;

    if ispc
        library_var = 'PATH';
        script_suffix = '.bat';
        variable_define = 'set';
    else
        library_var = 'LD_LIBRARY_PATH';
        script_suffix = '.sh';
        variable_define = 'export';
    end;

    if ~isempty(tracker.linkpath)
        userpath = tracker.linkpath{end};
        if length(tracker.linkpath) > 1
            userpath = [sprintf(['%s', pathsep], tracker.linkpath{1:end-1}), userpath];
        end;
        variables.(library_var) = userpath;
    end;
    
    launcher_script = fullfile(directory, ['launcher', script_suffix]);
    
    fid = fopen(launcher_script, 'w');
    
    fields = repmat(fieldnames(variables), numel(variables), 1);
    values = struct2cell(variables);
    
    cellfun(@(x, y) fprintf(fid, '%s "%s=%s"\n', variable_define, x, y), fields, values, 'UniformOutput', 0);
    
    fprintf(fid, '%s\n', command);
    
    fclose(fid);
    
    if isunix && ~is_octave
       fileattrib(launcher_script, '+x'); 
    end
    
end





