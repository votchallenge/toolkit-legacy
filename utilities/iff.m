function result = iff(condition, ontrue, onfalse)

  narginchk(3,3);
  
  if condition
    result = ontrue;
  else
    result = onfalse;
  end