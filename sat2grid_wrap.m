% Wrapper for sat2grid.m
% Reads a list of variables to be fed into sat2grid.m
% 
% Reads satellite data and makes gridded output
% Output : <varname>.txt or/and <varname>.nc
% 
% The No. of Footings in a day is 2759
% 
% Caveats
% Only the first 10km are written for 3D variables

clear all;
close all;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fileID   = fopen('c3mdatavars.txt','r');
C        = textscan(fileID,'%s %d %s %s\n');
fclose(fileID);
variable = C{1};
dim      = C{2};
longname = C{3};
units    = C{4};

for i = 1:length(variable)
    
    sat2grid_onthefly(variable(i),dim(i),longname(i),units(i))
end