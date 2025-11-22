% script_test_fcn_TimeClean_fitROSTime2GPSTime.m
% tests fcn_TimeClean_fitROSTime2GPSTime.m

% Revision history
% 2024_11_18 - sbrennan@psu.edu
% -- wrote the code originally 

close all;



%% CASE 1: basic example - verbose
fig_num = 900;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = 1;

[flags, fitParameters] = fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (fig_num));

assert(isequal(flags.ROS_Time_calibrated_to_GPS_Time,1));
assert(length(fitParameters)==2);

