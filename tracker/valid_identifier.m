function valid = valid_identifier(identifier)

if ~ischar(identifier)
    valid = 0;
    return;
end;

alpha = (identifier >= 'a' & identifier <= 'z') | (identifier >= 'A' & identifier <= 'Z');
numeric = (identifier >= '0' & identifier <= '9');
symbol = identifier == '-';

valid = all(alpha | numeric | symbol);