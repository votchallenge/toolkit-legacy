function t = isascii(str)

	if ~ischar(str)
		error('Input must be a string');
	end;

	t = ~any(str  > 127);

    return;
end

