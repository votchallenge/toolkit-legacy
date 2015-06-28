function hash = md5hash(data, input, output) %#ok<STOUT,INUSD>
% md5hash Calculate 128 bit MD5 checksum
%
% This function calculates a 128 bit checksum for arrays and files.
%
% Input:
%  - data (matrix, string): Data array or file name. Either numerical or CHAR array.
%           Currently only files and arrays with up to 2^32 bytes (2.1GB) are
%           accepted.
%  - input (string): Type of the input, optional. Default: 'Char'.
%           'File': Data is a file name as string. The digest is calculated
%                   for this file.
%           'Char': Data is a char array to calculate the digest for. Only the
%                   ASCII part of the Matlab CHARs is used, such that the digest
%                   is the same as if the array is written to a file as UCHAR,
%                   e.g. with FWRITE.
%           'Unicode': All bytes of the input are used to calculate the
%                   digest. This is the standard for numerical input.
%  - output (string, optional): Format of the output. Just the first character matters.
%     Optional, default: 'hex'.
%     - 'hex': [1 x 32] string as lowercase hexadecimal number.
%     - 'HEX': [1 x 32] string as uppercase hexadecimal number.
%     - 'Dec': [1 x 16] double vector with UINT8 values.
%     - 'Base64': [1 x 22] string, encoded to base 64 (A:Z,a:z,0:9,+,/).
%
% Output:
% - hash: A 128 bit number is replied in a format depending on output parameter.
%   The chance, that different data sets have the same MD5 sum is about
%   2^128 (> 3.4 * 10^38). Therefore MD5 can be used as "finger-print"
%   of a file rather than e.g. CRC32.
%
% Examples:
%   Three methods to get the MD5 of a file:
%   1. Direct file access (recommended):
%     MD5 = CalcMD5(which('CalcMD5.m'), 'File')
%   2. Import the file to a CHAR array (binary mode for exact line breaks!):
%     FID = fopen(which('CalcMD5.m'), 'rb');
%     S   = fread(FID, inf, 'uchar=>char');
%     fclose(FID);
%     MD5 = CalcMD5(S, 'char')
%   3. Import file as a byte stream:
%     FID = fopen(which('CalcMD5.m'), 'rb');
%     S   = fread(FID, inf, 'uint8=>uint8');
%     fclose(FID);
%     MD5 = CalcMD5(S, 'unicode');  // 'unicode' can be omitted here
%
% Author: Jan Simon, Heidelberg, (C) 2009-2010 J@n-Simon.De
% License: This program is derived from the RSA Data Security, Inc.
%          MD5 Message Digest Algorithm, RFC 1321, R. Rivest, April 1992
%

% If the current Matlab path is the parent folder of this script, the
% MEX function is not found - change the current directory!
error(['JSim:', mfilename, ':NoMex'], 'Cannot find MEX script.');

