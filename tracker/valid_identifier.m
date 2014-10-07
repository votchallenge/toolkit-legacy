function [valid, conditional] = valid_identifier(identifier)

if ~ischar(identifier)
    valid = false;
	conditional = false;
    return;
end;

alpha = (identifier >= 'a' & identifier <= 'z') | (identifier >= 'A' & identifier <= 'Z');
numeric = (identifier >= '0' & identifier <= '9');
symbol = identifier == '_';

valid = all(alpha | numeric | symbol);
conditional = all(alpha | numeric | symbol | identifier == '-');
