function result = strsuffix(str, suffix, checkcase)

    if nargin < 3
        checkcase = 1;
    end

    if length(str) < length(suffix)
        result = 0;
    else
        if checkcase
            result = strcmp(str(end-length(suffix)+1:end), suffix);
        else
            result = strcmpi(str(end-length(suffix)+1:end), suffix);
        end;
        
    end;

end