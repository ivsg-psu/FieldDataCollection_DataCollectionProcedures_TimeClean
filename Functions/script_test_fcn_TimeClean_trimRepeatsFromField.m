% script_test_fcn_TimeClean_trimRepeatsFromField.m
% tests fcn_TimeClean_trimRepeatsFromField.m

% REVISION HISTORY
% 
% 2023_06_26 by Sean Brennan, sbrennan@psu.edu
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

%% Define a dataset with repeated values in the GPS_Hemisphere time

fid = 1;
time_time_corruption_type = 2^20; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[BadDataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(BadDataStructure,fid);
assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

% Fix the data using default call
fixed_dataStructure = fcn_TimeClean_trimRepeatsFromField(BadDataStructure);

% Make sure it worked
[data,sensorNames] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(fixed_dataStructure, 'GPS_Time','GPS');
for i_data = 1:length(sensorNames)
    unique_values = unique(data{i_data});
    assert(isequal(unique_values,data{i_data}));
end % Ends for loop



% Fix the data using specific call
fid = 1;
field_name = 'GPS_Time';
sensors_to_check = 'GPS';
fixed_dataStructure = fcn_TimeClean_trimRepeatsFromField(BadDataStructure,fid, field_name,sensors_to_check);

% Make sure it worked
[data,sensorNames] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(fixed_dataStructure, 'GPS_Time','GPS');
for i_data = 1:length(sensorNames)
    unique_values = unique(data{i_data});
    assert(isequal(unique_values,data{i_data}));
end % Ends for loop


if 1==0 % BAD error cases start here



end
