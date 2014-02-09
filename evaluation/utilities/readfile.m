function varargout = readfile(fname, delim)

    % Initialize the variable output argument
    varargout = cell(nargout, 1);

	% Initialize elements of the cell array to nested cell arrays
	% This syntax is due to {:} producing a comma-separated 
	[varargout{:}] = deal(cell(0, 0));

	fid = fopen(fname, 'r');

	while true
	    % Get the current line
	    ln = fgetl(fid);

	    % Stop if EOF
	    if ln == -1
	        break;
	    end

	    % Split the line string into components and parse numbers
		% elems = strsplit(ln, delim);
		p = strfind(ln, delim);
		if ~isempty(p) 
			% extract the terms        
			nt = numel(p) + 1;
			elms = cell(1, nt);
			sp = 1;
			dl = length(delim);
			for i = 1 : nt-1
			    elms{i} = strtrim(ln(sp:p(i)-1));
			    sp = p(i) + dl;
			end         
			elms{nt} = strtrim(ln(sp:end));
		else
			elms = {ln};
		end        


	    nums = str2double(elms);

	    nans = isnan(nums);

	    % Find the indices of the NaNs 
	    % (i.e. the indices of the strings in the original data)
	    idxnans = find(nans);

	    % Assign each corresponding element in the current line
	    % into the corresponding cell array of varargout
	    for i = 1:nargout
	        % Detect if the current index is a string or a num
	        if any(ismember(idxnans, i))
	            varargout{i}{end+1} = elms{i};
	        else
	            varargout{i}{end+1} = nums(i);
	        end
	    end
	end;

end