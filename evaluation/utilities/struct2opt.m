function options = struct2opt(s)

fname = fieldnames(s);
fval = struct2cell(s);
c = [fname, fval]';
options = c(:);