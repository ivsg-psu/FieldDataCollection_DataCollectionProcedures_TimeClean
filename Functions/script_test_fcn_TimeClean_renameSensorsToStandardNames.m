% script_test_fcn_TimeClean_renameSensorsToStandardNames.m
% tests fcn_TimeClean_renameSensorsToStandardNames.m

% REVISION HISTORY:
% 
% 2023_07_01 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally using INTERNAL function from
%   % checkTimeConsistency
% 
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Deprecated function:
%   % * From: fcn_Data+Clean_renameSensorsToStandardNames
%   % * To: fcn_TimeClean_renameSensorsToStandardNames

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


%      [flags,offending_sensor] = fcn_DataClean_checkIfFieldInSensors(...
%          dataStructure,field_name,...
%          (flags),(string_any_or_all),(sensors_to_check),(fid))

%% Test the basic call

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.Hemisphere_DGPS = [];
initial_test_structure.diagnostic_encoder = [];
initial_test_structure.diagnostic_trigger = [];
initial_test_structure.ntrip_info = [];
initial_test_structure.Raw_Encoder = [];
initial_test_structure.RawTrigger = [];
initial_test_structure.SickLiDAR = [];
initial_test_structure.sparkfun_gps_diag_rear_left = [];
initial_test_structure.sparkfun_gps_diag_rear_right = [];
initial_test_structure.transform = [];
initial_test_structure.GPS_SparkFun_RearRight = [];
initial_test_structure.GPS_SparkFun_RearLeft = [];
initial_test_structure.IMU_Adis_TopCenter = [];

fid = 1;

updated_dataStructure = fcn_TimeClean_renameSensorsToStandardNames(initial_test_structure,fid);

assert(isfield(updated_dataStructure,'GPS_Hemisphere_TopCenter'));
assert(isfield(updated_dataStructure,'DIAGNOSTIC_USDigital_RearAxle'));
assert(isfield(updated_dataStructure,'TRIGGER_TrigBox_RearTop'));
assert(isfield(updated_dataStructure,'NTRIP_Hotspot_Rear'));
assert(isfield(updated_dataStructure,'ENCODER_USDigital_RearAxle'));
assert(isfield(updated_dataStructure,'TRIGGER_TrigBox_RearTop'));
assert(isfield(updated_dataStructure,'LIDAR_Sick_Rear'));
assert(isfield(updated_dataStructure,'DIAGNOSTIC_Sparkfun_LeftRear'));
assert(isfield(updated_dataStructure,'DIAGNOSTIC_Sparkfun_RightRear'));
assert(isfield(updated_dataStructure,'TRANSFORM_ROS_Rear'));
assert(isfield(updated_dataStructure,'GPS_SparkFun_RightRear'));
assert(isfield(updated_dataStructure,'GPS_SparkFun_LeftRear'));
assert(isfield(updated_dataStructure,'IMU_Adis_TopCenter'));



