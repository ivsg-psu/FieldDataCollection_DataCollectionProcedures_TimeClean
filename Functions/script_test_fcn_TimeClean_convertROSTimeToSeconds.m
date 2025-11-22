% script_test_fcn_TimeClean_convertROSTimeToSeconds.m
% tests fcn_TimeClean_convertROSTimeToSeconds.m

% Revision history
% 2023_07_01 - sbrennan@psu.edu
% -- wrote the code originally
% 2024_09_27 - sbrennan@psu.edu
% -- cleaned up script for automated testing

%% Set up the workspace
close all

%% Define a dataset where the ROS_Time has a nanosecond scaling error
% This is injected in the test dataset on GPS_Hemisphere

fid = 1;
time_time_corruption_type = 2^13; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure);

assert(isequal(flags.ROS_Time_scaled_correctly_as_seconds,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

% Fix the data using default call
fixed_dataStructure = fcn_TimeClean_convertROSTimeToSeconds(BadDataStructure);

% Make sure it worked
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);

assert(isequal(flags.ROS_Time_scaled_correctly_as_seconds,1));

% Fix the data using verbose call
fixed_dataStructure = fcn_TimeClean_convertROSTimeToSeconds(BadDataStructure,'',fid);

% Make sure it worked
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);

assert(isequal(flags.ROS_Time_scaled_correctly_as_seconds,1));

% Fix the data using specific call, specifying GPS sensors as the ones to fix

fixed_dataStructure = fcn_TimeClean_convertROSTimeToSeconds(BadDataStructure,'GPS',fid);

% Make sure it worked
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);

assert(isequal(flags.ROS_Time_scaled_correctly_as_seconds,1));


if 1==0 % BAD error cases start here



end
