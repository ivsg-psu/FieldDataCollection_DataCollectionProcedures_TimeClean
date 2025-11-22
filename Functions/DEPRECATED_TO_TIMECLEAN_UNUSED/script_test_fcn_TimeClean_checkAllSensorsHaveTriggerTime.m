% script_test_fcn_TimeClean_checkAllSensorsHaveTriggerTime.m
% tests fcn_TimeClean_checkAllSensorsHaveTriggerTime.m

% Revision history
% 2024_09_27 - xfc5113@psu.edu
% -- wrote the code originally


%% Set up the workspace
close all


%% Trigger Time checks start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   _______   _                         _______ _                   _____ _               _        
%  |__   __| (_)                       |__   __(_)                 / ____| |             | |       
%     | |_ __ _  __ _  __ _  ___ _ __     | |   _ _ __ ___   ___  | |    | |__   ___  ___| | _____ 
%     | | '__| |/ _` |/ _` |/ _ \ '__|    | |  | | '_ ` _ \ / _ \ | |    | '_ \ / _ \/ __| |/ / __|
%     | | |  | | (_| | (_| |  __/ |       | |  | | | | | | |  __/ | |____| | | |  __/ (__|   <\__ \
%     |_|_|  |_|\__, |\__, |\___|_|       |_|  |_|_| |_| |_|\___|  \_____|_| |_|\___|\___|_|\_\___/
%                __/ | __/ |                                                                       
%               |___/ |___/                                                                        
%                                 
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Name%20Consistency%20Checks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check all sensors have Trigger Time

% Create some test data
testStructure = struct;
testStructure.GPS_SparkFun_RightRear.Trigger_Time = 1;
testStructure.GPS_SparkFun_Front.Trigger_Time = 1;
testStructure.GPS_SparkFun_Front.Trigger_Time = 1;
testStructure.LiDAR_Velodyne_Rear.Trigger_Time = 1;

% Check structure
fid = 1;
flags = struct;
[checked_flags,sensors_without_Trigger_Time] = fcn_TimeClean_checkAllSensorsHaveTriggerTime(testStructure,flags,fid);


% Check flags
assert(isequal(checked_flags.Trigger_Time_exists_in_all_sensors,1));
assert(isempty(sensors_without_Trigger_Time));

%% Check merging of sensors where one has Trigger_Time as nan

% Create some test data
testStructure = struct;
testStructure.GPS_SparkFun_RightRear.Trigger_Time = 1;
testStructure.GPS_SparkFun_Front.Trigger_Time = 1;
testStructure.GPS_SparkFun_Front.Trigger_Time = 1;
testStructure.LiDAR_Velodyne_Rear.Trigger_Time = nan;

% Check structure
fid = 1;
flags = struct;
[checked_flags,sensors_without_Trigger_Time] = fcn_TimeClean_checkAllSensorsHaveTriggerTime(testStructure,flags,fid);


% Check flags
assert(isequal(checked_flags.Trigger_Time_exists_in_all_sensors,0));
assert(length(sensors_without_Trigger_Time)==1);
assert(strcmp(sensors_without_Trigger_Time,"LiDAR_Velodyne_Rear"))

%% Check merging of sensors where one has Trigger_Time as nan array

% Create some test data
testStructure = struct;
testStructure.GPS_SparkFun_RightRear.Trigger_Time = 1;
testStructure.GPS_SparkFun_Front.Trigger_Time = 1;
testStructure.GPS_SparkFun_Front.Trigger_Time = 1;
testStructure.LiDAR_Velodyne_Rear.Trigger_Time = nan(3,1);

% Check structure
fid = 1;
flags = struct;
[checked_flags,sensors_without_Trigger_Time] = fcn_TimeClean_checkAllSensorsHaveTriggerTime(testStructure,flags,fid);


% Check flags
assert(isequal(checked_flags.Trigger_Time_exists_in_all_sensors,0));
assert(length(sensors_without_Trigger_Time)==1);
assert(strcmp(sensors_without_Trigger_Time,"LiDAR_Velodyne_Rear"))


%% Fail conditions
if 1==0

end
