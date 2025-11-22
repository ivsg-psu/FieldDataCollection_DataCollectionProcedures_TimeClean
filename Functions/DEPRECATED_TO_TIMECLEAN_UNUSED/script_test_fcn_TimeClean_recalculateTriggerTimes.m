% script_test_fcn_TimeClean_recalculateTriggerTimes.m
% tests fcn_TimeClean_recalculateTriggerTimes

% Revision history
% 2023_06_25 - sbrennan@psu.edu
% -- wrote the code originally

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



%% Fail conditions
if 1==0
    

end
