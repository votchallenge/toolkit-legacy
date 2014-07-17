function vot_test(tracker, sequences)

current_sequence = get_global_variable('current_sequence', 1);

if ~exist('trajectory', 'var')
	trajectory = [];
end;

performance = struct('frames', 0, 'time', 0);

print_text('');
print_text('***************************************************************************');
print_text('');
print_text('Welcome to the VOT sandbox!');
print_text('This process will help you prepare your tracker for the evaluation.');
print_text('When beginning with the integration it is recommended to follow the steps ');
print_text('a, b, c to verify the execution and the output data.');
print_text('');
print_text('***************************************************************************');
print_text('');

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

            print_text('Input data generated in directory "%s"', directory);
            print_text('Open the directory in a terminal and manually execute the tracker command.');
            print_text('The current command as defined in the environment is: %s', command);
            print_text('Once the tracker is working as expected, delete the directory.');
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





