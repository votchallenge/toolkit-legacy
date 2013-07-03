function string = format_interval(time)

days = floor(time / (24*60*60));

time = time - days * (24*60*60);

hours = floor(time / (60*60));

time = time - hours * (60*60);

minutes = floor(time / (60));

%time = time - minutes * (60);

string = sprintf('%d days %d hours %d minutes', days, hours, minutes);