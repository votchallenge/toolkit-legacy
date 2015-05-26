function [valid, conditional] = valid_identifier(identifier)
% valid_identifier Verifies tracker identifier
%
% Tests if a given input string is a valid tracker identifier. A valid identifier contains only
% upper and lower case letters, digits and underscore.
%
% A conditionally valid identifier also contains dash. This is used for legacy reasons but is 
% discouraged for new trackers.
%
% Input:
% - identifier: A string to test.
%
% Ouput:
% - valid: True if the string is a valid identifier. 
% - conditional: True if the string is a conditionally valid identifier.

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
