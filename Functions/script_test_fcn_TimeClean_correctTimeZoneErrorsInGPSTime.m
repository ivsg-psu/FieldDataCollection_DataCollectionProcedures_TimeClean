% script_test_fcn_TimeClean_correctTimeZoneErrorsInGPSTime.m
% tests fcn_TimeClean_correctTimeZoneErrorsInGPSTime.m

% Revision history
% 2023_06_25 - sbrennan@psu.edu
% -- wrote the code originally

%% Set up the workspace
close all


%% Shifted time interval test - one of the sensors is very far off
% Simulate a time zone error 

% Fill in the initial data
fid = 1;
dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;


BadDataStructure = dataStructure;
hours_off = 1;
BadDataStructure.GPS_Sparkfun_RearRight.GPS_Time = BadDataStructure.GPS_Sparkfun_RearRight.GPS_Time - hours_off*60*60; 
clear hours_off
fprintf(1,'\nData created with following errors injected: shifted start point\n\n');

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.GPS_Time_has_consistent_start_end_within_5_seconds,0));
assert(strcmp(offending_sensor,'Start values of: GPS_Sparkfun_RearRight GPS_Hemisphere'));

% Fix the data
fixed_dataStructure = fcn_TimeClean_correctTimeZoneErrorsInGPSTime(BadDataStructure,fid);

% Make sure it worked
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure,fid);
assert(isequal(flags.GPS_Time_has_consistent_start_end_within_5_seconds,1));

%% Fail conditions
if 1==0



end
