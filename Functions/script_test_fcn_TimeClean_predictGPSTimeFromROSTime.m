% script_test_fcn_TimeClean_predictGPSTimeFromROSTime.m
% tests fcn_TimeClean_predictGPSTimeFromROSTime.m

% Revision history
% 2024_11_18 - sbrennan@psu.edu
% -- wrote the code originally 

close all;



%% CASE 1: basic example - verbose
fig_num = 1;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = 1;

[flags, fitting_parameters, fit_sensors, mean_fit, filtered_median_errors] =  fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (-1));

[cell_array_ROS_Time,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',    'GPS');
[cell_array_GPS_Time,~]            = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'GPS_Time',    'GPS');


% Check the fit
GPSfromROS_Time        = cell(length(cell_array_GPS_Time),1); % Preallocate the data
GPSfromROS_Time_errors = cell(length(cell_array_GPS_Time),1); % Preallocate the data
for ith_array = 1:length(cell_array_ROS_Time)
    ROS_Time = cell_array_ROS_Time{ith_array};
    GPSfromROS_Time{ith_array} = fcn_TimeClean_predictGPSTimeFromROSTime(mean_fit, filtered_median_errors, ROS_Time);
    GPSfromROS_Time_errors{ith_array} = GPSfromROS_Time{ith_array} - cell_array_GPS_Time{ith_array};


    assert(isequal(length(GPSfromROS_Time_errors{ith_array}(:,1)),length(ROS_Time(:,1))));


end

% Plot the GPS prediction errors
figure(fig_num)
hold on;
grid on;
xlabel('Duration of Data Collection (seconds)');
ylabel('Deviations in Time (seconds)');
title('Unit slope fitting error','Interpreter','none');
for ith_sensor = 1:length(sensor_names)
    this_GPS_Time = cell_array_GPS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
    plot(this_GPS_Time,GPSfromROS_Time_errors{ith_sensor},'DisplayName',sensor_names{ith_sensor});
end
legend('Interpreter','none')

