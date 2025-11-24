% script_test_fcn_TimeClean_fitROSTime2GPSTime.m
% tests fcn_TimeClean_fitROSTime2GPSTime.m

% REVISION HISTORY
% 
% 2024_11_18 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally 

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


close all;



%% CASE 1: basic example - verbose
figNum = 900;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = 1;

[flags, fitParameters] = fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (figNum));

assert(isequal(flags.ROS_Time_calibrated_to_GPS_Time,1));
assert(length(fitParameters)==2);

