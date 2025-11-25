% script_test_fcn_TimeClean_sortSensorDataByGPSTime.m
% tests fcn_TimeClean_sortSensorDataByGPSTime.m

% REVISION HISTORY
% 
% 2023_07_01 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


%% Set up the workspace
close all


%% Define a dataset with corrupted GPS_Time where the GPS_Time is not increasing 
time_time_corruption_type = 2^12; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure);
assert(isequal(flags.GPS_Time_strictly_ascends_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

% Fix the data using default call
fixed_dataStructure = fcn_TimeClean_sortSensorDataByGPSTime(BadDataStructure);

% Make sure it worked
[flags, ~] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);
assert(isequal(flags.GPS_Time_strictly_ascends_in_GPS_sensors,1));

% Fix the data using verbose call
field_to_sort = 'GPS_Time';
sensors_to_search = 'GPS';
fid = 1;
fixed_dataStructure = fcn_TimeClean_sortSensorDataByGPSTime(BadDataStructure,field_to_sort,sensors_to_search, fid);

% Make sure it worked
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(fixed_dataStructure);
assert(isequal(flags.GPS_Time_strictly_ascends_in_GPS_sensors,1));

% Fix the data using specific call
field_name = 'GPS_Time';
sensors_to_check = 'GPS';
fid = 1;
fixed_dataStructure = fcn_TimeClean_sortSensorDataByGPSTime(BadDataStructure, field_name,sensors_to_check,fid);

% Make sure it worked
[data,sensorNames] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(fixed_dataStructure, 'GPS_Time','GPS');

for i_data = 1:length(sensorNames)
    unique_values = unique(data{i_data});
    assert(isequal(unique_values,data{i_data}));
end % Ends for loop


if 1==0 % BAD error cases start here



end
