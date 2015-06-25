function result = iff(condition, ontrue, onfalse)
% iff A simulation of inline conditional statement
%
% This function simulates a single line conditional statement. Based on the state of the first
% argument it returns either second or third one.
%
% Input:
% - condition (boolean): Condition variable.
% - ontrue: Value to return if condition is true.
% - onfalse: Value to return if condition is false.
%
% Output:
% - result: Either the value of second or third argument.
%


  narginchk(3,3);
  
  if condition
    result = ontrue;
  else
    result = onfalse;
  end
