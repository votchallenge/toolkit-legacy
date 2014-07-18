function strout = str2latex(strin)

if iscell(strin)
	strout = cellfun(@str2latex, strin, 'UniformOutput', false);
else
	strout = strrep(strin, '_', '\_');
end;

