function vot_deinitialize(results)

if size(results, 2) ~= 4
	error('Illegal result format');
end;

csvwrite('output.txt', results);



