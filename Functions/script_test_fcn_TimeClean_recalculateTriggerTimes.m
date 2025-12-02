% script_test_fcn_TimeClean_recalculateTriggerTimes.m
% tests fcn_TimeClean_recalculateTriggerTimes

% Revision history
% 2023_06_25 - sbrennan@psu.edu
% -- wrote the code originally
%
% 2025_11_29 by Sean Brennan, sbrennan@psu.edu
% - Added a test case that was failing from cleanTimeInStruct (first demo)

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)



%% Set up the workspace
close all



%% CASE 1: Fix the Trigger_Time in all sensors - NOT verbose
% Define a dataset with corrupted Trigger_Time where the field is missing
time_time_corruption_type = 2^9; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure);
assert(isequal(flags.Trigger_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

fprintf(1,'\nCASE 1: fixing trigger time in all sensors, NOT verbose\n');
fixed_dataStructure = fcn_TimeClean_recalculateTriggerTimes(BadDataStructure);
fprintf(1,'\nCASE 1: Done!\n\n');

% Make sure it worked
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);
assert(isequal(flags.Trigger_Time_exists_in_all_GPS_sensors,1));


%% CASE 2: Fix the Trigger_Time in all sensors - NOT verbose
fid = 1; 

% Define a dataset with corrupted Trigger_Time where the field is missing
time_time_corruption_type = 2^9; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure);
assert(isequal(flags.Trigger_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

fprintf(1,'\nCASE 2: fixing trigger time in all sensors, verbose\n');
fixed_dataStructure = fcn_TimeClean_recalculateTriggerTimes(BadDataStructure,'', fid);
fprintf(1,'\nCASE 2: Done!\n\n');

% Make sure it worked
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);
assert(isequal(flags.Trigger_Time_exists_in_all_GPS_sensors,1));


%% Fix the data only in "GPS" sensors
fid = 1; 

% Define a dataset with corrupted Trigger_Time where the field is missing
time_time_corruption_type = 2^9; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure);
assert(isequal(flags.Trigger_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

fprintf(1,'\nCASE 3: fixing trigger time only in GPS sensors, verbose\n');
fixed_dataStructure = fcn_TimeClean_recalculateTriggerTimes(BadDataStructure,'GPS', fid);
fprintf(1,'\nCASE 3: Done!\n\n');

% Make sure it worked
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);
assert(isequal(flags.Trigger_Time_exists_in_all_GPS_sensors,1));

%% TEST case:
% Using data collected from cleanTimeInStruct
fullExampleFilePath = fullfile(cd,'Data','ExampleData_recalculateTriggerTimes.mat');
load(fullExampleFilePath,'dataStructure');

fid = 1;

temp = fcn_TimeClean_recalculateTriggerTimes(dataStructure,[],fid);
        


%% Fail conditions
if 1==0
    

end
