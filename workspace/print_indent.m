function print_indent(indent)
% print_indent Modify the indent of the output
%
% Increases of decreases the indent of the output for function print_text.
% Can be used to structure the output in hierarchical calls.
%
% Input:
% - indent (integer): The amount of tabs that the indent is increased (positive) or decreased (negative) for.
%

set_global_variable('indent', get_global_variable('indent', 0) + indent);

