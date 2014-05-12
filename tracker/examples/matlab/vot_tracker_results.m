function vot_tracker_results(results)

if iscell(results)

	fid = fopen('output.txt', 'w');

	for i = 1:numel(results)
		region = results{i};

		if numel(region) == 1
			fprintf(fid, '%f\n', region);
		elseif numel(region) == 4
			fprintf(fid, '%f,%f,%f,%f\n', region(1), region(2), region(3), region(4));
		elseif numel(region) >= 6 && mod(numel(region), 2) == 0
			fprintf(fid, '%f,', region(1:end-1));
			fprintf(fid, '%f\n', region(end));
		else
			error('Illegal result format');
		end;

	end;

	fclose(fid);

	return;
end

if size(results, 2) ~= 4
	error('Illegal result format');
end;

csvwrite('output.txt', results);



