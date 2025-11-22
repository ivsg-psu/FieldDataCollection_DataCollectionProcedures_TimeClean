% script_test_fcn_TimeClean_checkDataTimeConsistency_GPS.m
% tests fcn_TimeClean_checkDataTimeConsistency_GPS.m

% Revision history:
%     
% 2024_09_30: sbrennan@psu.edu
% -- wrote the code originally by pulling out of checkDataTimeConsistency


%% Set up the workspace
close all


%% CASE 1: Basic call - NOT verbose

% Fill in the initial data
dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;

fprintf(1,'\nCASE 1: basic consistency check, no errors, NOT verbose\n');
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(dataStructure);
fprintf(1,'\nCASE 1: Done!\n\n');

assert(isequal(flags.GPS_Time_exists_in_at_least_one_GPS_sensor,1));
assert(strcmp(offending_sensor,''));

%% CASE 2: Basic call - verbose mode

% Fill in the initial data
dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;
fid = 1;
flags = [];

% List what will be plotted, and the figure numbers
clear plotFlags
plotFlags.fig_num_checkTimeSamplingConsistency_GPSTime = 1111;


fprintf(1,'\nCASE 2: basic consistency check, no errors, verbose\n');
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(dataStructure, flags, fid, plotFlags);
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


%% Check GPS_Time_exists_in_at_least_one_GPS_sensor - the GPS_Time field is completely missing in all sensors

% Fill in the initial data
dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;
fid = 1;


% Define a dataset with no GPS_Time fields
BadDataStructure = dataStructure;
sensor_names = fieldnames(BadDataStructure); % Grab all the fields that are in dataStructure structure
for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = BadDataStructure.(sensor_name);
    sensor_data_removed_field = rmfield(sensor_data,'GPS_Time');
    BadDataStructure.(sensor_name) = sensor_data_removed_field;    
end
% Clean up variables
clear sensor_name sensor_data sensor_data_removed_field i_data sensor_names
    
error_type_string = 'All GPS_Time fields are missing on all sensors';
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_exists_in_at_least_one_GPS_sensor,0));
assert(strcmp(offending_sensor,'GPS_Sparkfun_RearRight'));

%% Check GPS_Time_exists_in_all_GPS_sensors - the GPS_Time field is missing in at least one GPS sensor
fid = 1;

% Define a dataset with corrupted GPS_Time where the field is missing
time_time_corruption_type = 2^1; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

%% Check GPS_Time_exists_in_all_GPS_sensors - the GPS_Time field is empty
fid = 1;

% Define a dataset with corrupted GPS_Time where the field is empty
time_time_corruption_type = 2^2; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Sparkfun_RearLeft'));

%% Check GPS_Time_exists_in_all_GPS_sensors - the GPS_Time field is only NaNs
fid = 1;

% Define a dataset with corrupted GPS_Time where the field is NaN
time_time_corruption_type = 2^3; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Sparkfun_RearRight'));

%% Check centiSeconds_exists_in_all_GPS_sensors - the centiSeconds field is completely missing
fid = 1;

% Define a dataset with corrupted centiSeconds where the field is missing
time_time_corruption_type = 2^4; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.centiSeconds_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

%% Check centiSeconds_exists_in_all_GPS_sensors - the centiSeconds field is empty
fid = 1;

% Define a dataset with corrupted centiSeconds where the field is empty
time_time_corruption_type = 2^5; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.centiSeconds_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

%% Check centiSeconds_exists_in_all_GPS_sensors - the centiSeconds field is only NaNs
fid = 1;

% Define a dataset with corrupted centiSeconds where the field is NaNs only
time_time_corruption_type = 2^6; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.centiSeconds_exists_in_all_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Sparkfun_RearRight'));

%% Check GPS_Time_has_no_repeats_in_GPS_sensors
fid = 1;

% Define a dataset with corrupted centiSeconds where the field is NaNs only
time_time_corruption_type = 2^20; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));



%% Check GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors
fid = 1;

% Define a dataset with corrupted centiSeconds where the field is
% inconsistent with GPS_Time data
time_time_corruption_type = 2^7; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Sparkfun_RearRight'));


%% Check GPS_Time_has_consistent_start_end_within_5_seconds
% Simulate a time zone error 
fid = 1;

dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;
BadDataStructure = dataStructure;
hours_off = 1;
BadDataStructure.GPS_Sparkfun_RearRight.GPS_Time = BadDataStructure.GPS_Sparkfun_RearRight.GPS_Time - hours_off*60*60; 
clear hours_off
fprintf(1,'\nData created with following errors injected: shifted start point');
flags = [];
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_has_consistent_start_end_within_5_seconds,0));


%% Check GPS_Time_has_consistent_start_end_across_GPS_sensors
fid = 1;

dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;
BadDataStructure = dataStructure;
BadDataStructure.GPS_Sparkfun_RearRight.GPS_Time = BadDataStructure.GPS_Sparkfun_RearRight.GPS_Time - 1; 
fprintf(1,'\nData created with following errors injected: shifted start point');
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_has_consistent_start_end_across_GPS_sensors,0));
assert(strcmp(offending_sensor,'Start values of: GPS_Sparkfun_RearRight GPS_Sparkfun_RearLeft'));


%% Check if GPS_Time_strictly_ascends_in_GPS_sensors
fid = 1;

% Define a dataset with corrupted GPS_Time where the GPS_Time is not increasing 
time_time_corruption_type = 2^12; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
flags = [];
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
assert(isequal(flags.GPS_Time_strictly_ascends_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

% %% Check GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors
% fid = 1;
% 
% % Define a dataset with jump discontinuity in GPS_Time data
% time_time_corruption_type = 2^22; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
% [BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
% fprintf(1,'\nData created with following errors injected: %s\n',error_type_string);
% flags = [];
% [flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(BadDataStructure, flags, fid);
% assert(isequal(flags.GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors,0));
% assert(strcmp(offending_sensor,'GPS_Hemisphere'));



%% Fail conditions
if 1==0
    
end
