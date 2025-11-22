% script_test_fcn_TimeClean_trimDataToCommonStartEndTriggerTimes.m
% tests fcn_TimeClean_trimDataToCommonStartEndTriggerTimes.m

% Revision history
% 2023_06_25 - sbrennan@psu.edu
% -- wrote the code originally

%% Set up the workspace
close all


%% Corrupt the GPS times on some of the sensors to mis-align them

% Fill in the initial data
dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;
fid = 1;
warning('on','backtrace');
warning('The fcn_TimeClean_trimDataToCommonStartEndTriggerTimes test script does not seem to work.');

% BadDataStructure = dataStructure;
% BadDataStructure.GPS_Sparkfun_RearRight.Trigger_Time = BadDataStructure.GPS_Sparkfun_RearRight.GPS_Time - 1.03; 
% BadDataStructure.GPS_Sparkfun_RearLeft.Trigger_Time = BadDataStructure.GPS_Sparkfun_RearLeft.GPS_Time - 1.03; 
% 
% fprintf(fid,'\nData created with shifted up/down GPS_Time fields');
% 
% % Show that the data are not aligned by performing a consistency check. It
% % should show that the GPS_Sparkfun_RearRight has the lowest time, and
% % GPS_Hemisphere has the largest time
% 
% % Fix the data
% trimmed_dataStructure = fcn_TimeClean_trimDataToCommonStartEndTriggerTimes(BadDataStructure,fid);
% 
% % Make sure it worked
% sensor_names = fieldnames(trimmed_dataStructure); % Grab all the fields that are in dataStructure structure
% start_time = trimmed_dataStructure.(sensor_names{1}).GPS_Time(1);
% end_time = trimmed_dataStructure.(sensor_names{1}).GPS_Time(end);
% for i_data = 2:length(sensor_names)
%     % Grab the sensor subfield name
%     sensor_name = sensor_names{i_data};
% 
%     % Make sure the sensor stops within one sampling period of start/end
%     % times (it is 10 Hz)
%     assert(trimmed_dataStructure.(sensor_name).GPS_Time(1,1)>= start_time-0.1);
%     assert((trimmed_dataStructure.(sensor_name).GPS_Time(end,1) - end_time)+0.1);
% end

%% Fail conditions
if 1==0
    


end
