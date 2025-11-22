% script_test_fcn_TimeClean_checkDataTimeConsistency.m
% tests fcn_TimeClean_checkDataTimeConsistency.m

% Revision history
% 2023_06_19 - sbrennan@psu.edu
% -- wrote the code originally
% 2023_06_30 - sbrennan@psu.edu
% -- fixed verbose mode bug


%% Set up the workspace
close all


%% CASE 1: Basic call - NOT verbose

% Fill in the initial data
dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;

fprintf(1,'\nCASE 1: basic consistency check, no errors, NOT verbose\n');
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(dataStructure);
fprintf(1,'\nCASE 1: Done!\n\n');

assert(isequal(flags.GPS_Time_exists_in_at_least_one_GPS_sensor,1));
assert(strcmp(offending_sensor,''));

%% CASE 2: Basic call - verbose mode with plotting

% Fill in the initial data
dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;
fid = 1;


% List what will be plotted, and the figure numbers
plotFlags.fig_num_checkTimeSamplingConsistency_GPSTime = 1111;
plotFlags.fig_num_checkTimeSamplingConsistency_ROSTime = 2222;


fprintf(1,'\nCASE 2: basic consistency check, no errors, verbose\n');
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(dataStructure,fid, plotFlags);
fprintf(1,'\nCASE 2: Done!\n\n');

assert(isequal(flags.GPS_Time_exists_in_at_least_one_GPS_sensor,1));
assert(strcmp(offending_sensor,''));


%% GPS_Time tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    _____ _____   _____            _______ _                   _______        _       
%   / ____|  __ \ / ____|          |__   __(_)                 |__   __|      | |      
%  | |  __| |__) | (___               | |   _ _ __ ___   ___      | | ___  ___| |_ ___ 
%  | | |_ |  ___/ \___ \              | |  | | '_ ` _ \ / _ \     | |/ _ \/ __| __/ __|
%  | |__| | |     ____) |             | |  | | | | | | |  __/     | |  __/\__ \ |_\__ \
%   \_____|_|    |_____/              |_|  |_|_| |_| |_|\___|     |_|\___||___/\__|___/
%                          ______                                                      
%                         |______|                                                     
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=GPS%20_%20Time%20%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% See script_test_fcn_TimeClean_checkDataTimeConsistency_GPS


%% Trigger_Time Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   _______   _                                  _______ _                   _______        _       
%  |__   __| (_)                                |__   __(_)                 |__   __|      | |      
%     | |_ __ _  __ _  __ _  ___ _ __              | |   _ _ __ ___   ___      | | ___  ___| |_ ___ 
%     | | '__| |/ _` |/ _` |/ _ \ '__|             | |  | | '_ ` _ \ / _ \     | |/ _ \/ __| __/ __|
%     | | |  | | (_| | (_| |  __/ |                | |  | | | | | | |  __/     | |  __/\__ \ |_\__ \
%     |_|_|  |_|\__, |\__, |\___|_|                |_|  |_|_| |_| |_|\___|     |_|\___||___/\__|___/
%                __/ | __/ |            ______                                                      
%               |___/ |___/            |______|                                                     
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Trigger%20_%20Time%20%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check Trigger_Time_exists_in_all_GPS_sensors - the Trigger_Time field is only NaNs
fid = 1;

% Define a dataset with corrupted Trigger_Time where the field is only NaNs
time_time_corruption_type = 2^11; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.Trigger_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

%% ROS_Time Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   _____   ____   _____            _______ _                   _______        _       
%  |  __ \ / __ \ / ____|          |__   __(_)                 |__   __|      | |      
%  | |__) | |  | | (___               | |   _ _ __ ___   ___      | | ___  ___| |_ ___ 
%  |  _  /| |  | |\___ \              | |  | | '_ ` _ \ / _ \     | |/ _ \/ __| __/ __|
%  | | \ \| |__| |____) |             | |  | | | | | | |  __/     | |  __/\__ \ |_\__ \
%  |_|  \_\\____/|_____/              |_|  |_|_| |_| |_|\___|     |_|\___||___/\__|___/
%                          ______                                                      
%                         |______|                                                     
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=ROS%20_%20Time%20%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check ROS_Time_exists_in_all_GPS_sensors- the ROS_Time field is completely missing
fid = 1;
 
% Define a dataset with corrupted ROS_Time where the field is missing
time_time_corruption_type = 2^14; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Sparkfun_RearLeft'));

%% Check ROS_Time_exists_in_all_GPS_sensors - the ROS_Time field is empty
fid = 1;

% Define a dataset with corrupted ROS_Time where the field is empty
time_time_corruption_type = 2^15; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

%% Check ROS_Time_exists_in_all_GPS_sensors - the ROS_Time field is only NaNs
fid = 1;

% Define a dataset with corrupted ROS_Time where it contains only NaNs
time_time_corruption_type = 2^16; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));


%% Check ROS_Time_scaled_correctly_as_seconds
fid = 1;

% Define a dataset with corrupted ROS_Time where the ROS_Time has a
% nanosecond scaling
time_time_corruption_type = 2^13; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_scaled_correctly_as_seconds,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));


%% Check ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors
fid = 1;

% Define a dataset with corrupted centiSeconds where the field is
% inconsistent with ROS_Time data
time_time_corruption_type = 2^8; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors,1));

%% Check ROS_Time_strictly_ascends_in_all_sensors
fid = 1;

% Define a dataset with corrupted ROS_Time where it is not increasing
time_time_corruption_type = 2^17; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_strictly_ascends_in_all_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

%% Check ROS_Time_strictly_ascends_in_all_sensors
fid = 1;

% Define a dataset with corrupted ROS_Time via repeat
time_time_corruption_type = 2^18; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_strictly_ascends_in_all_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

%% Check ROS_Time_has_same_length_as_Trigger_Time_in_GPS_sensors
fid = 1;

% Define a dataset with corrupted ROS_Time length
time_time_corruption_type = 2^19; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.ROS_Time_has_same_length_as_Trigger_Time_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));


% %% Check ROS_Time_rounds_correctly_to_Trigger_Time
% fid = 1;
% 
% % Define a dataset with corrupted ROS_Time length
% time_time_corruption_type = 2^21; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
% [BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
% fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);
% 
% [flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
% assert(isequal(flags.ROS_Time_rounds_correctly_to_Trigger_Time_in_GPS_sensors,0));
% assert(strcmp(offending_sensor,'GPS_Hemisphere'));
% 


%% Fail conditions
if 1==0
    
end
