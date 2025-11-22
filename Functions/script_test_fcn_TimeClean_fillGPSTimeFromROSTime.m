% script_test_fcn_TimeClean_fillGPSTimeFromROSTime.m
% tests fcn_TimeClean_fillGPSTimeFromROSTime.m

% Revision history
% 2024_11_20 - sbrennan@psu.edu
% -- wrote the code originally 

close all;



%% CASE 1: basic example - verbose, all sensors
fig_num = 1;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = 1;

[~, ~, ~, mean_fit, filtered_median_errors] =  fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (-1));

sensors_to_check = [];
fid = 1;
fig_num = [];

newDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, dataStructure, (sensors_to_check), (fid), (fig_num));

[~,old_sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',sensors_to_check);
[~,fixed_sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(newDataStructure, 'GPSfromROS_Time',sensors_to_check);

assert(isequal(old_sensor_names,fixed_sensor_names));

%% CASE 2: basic example - NOT verbose, all sensors
fig_num = 2;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = [];

[~, ~, ~, mean_fit, filtered_median_errors] =  fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (-1));

sensors_to_check = [];
fid = [];
fig_num = [];

newDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, dataStructure, (sensors_to_check), (fid), (fig_num));

[~,old_sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',sensors_to_check);
[~,fixed_sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(newDataStructure, 'GPSfromROS_Time',sensors_to_check);

assert(isequal(old_sensor_names,fixed_sensor_names));

%% CASE 3: basic example - verbose, selected sensors
fig_num = 3;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = 1;

[~, ~, ~, mean_fit, filtered_median_errors] =  fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (-1));

sensors_to_check = 'GPS';
fid = 1;
fig_num = [];

newDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, dataStructure, (sensors_to_check), (fid), (fig_num));

[~,old_sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',sensors_to_check);
[~,fixed_sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(newDataStructure, 'GPSfromROS_Time',sensors_to_check);

assert(isequal(old_sensor_names,fixed_sensor_names));
