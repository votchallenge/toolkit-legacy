function string = format_interval(time)
% format_interval Format a time interval
%
% Formats a given time interval in seconds to a string containing
% days, hours and minutes.
%
% Input:
% - time (dobule): A numeric representation of time interval in seconds.
%
% Output:
% - string (string): A string representation of the interval
%


days = floor(time / (24*60*60));

time = time - days * (24*60*60);

hours = floor(time / (60*60));

time = time - hours * (60*60);

minutes = floor(time / (60));

%time = time - minutes * (60);

string = sprintf('%d days %d hours %d minutes', days, hours, minutes);