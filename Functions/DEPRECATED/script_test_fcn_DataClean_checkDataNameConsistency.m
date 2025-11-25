% script_test_fcn_DataClean_checkDataNameConsistency.m
% tests fcn_DataClean_checkDataNameConsistency.m

% Revision history
% 2023_07_03 - sbrennan@psu.edu
% -- wrote the code originally


%% Set up the workspace
close all



%% Name consistency checks start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   _   _                         _____                _     _                           _____ _               _        
%  | \ | |                       / ____|              (_)   | |                         / ____| |             | |       
%  |  \| | __ _ _ __ ___   ___  | |     ___  _ __  ___ _ ___| |_ ___ _ __   ___ _   _  | |    | |__   ___  ___| | _____ 
%  | . ` |/ _` | '_ ` _ \ / _ \ | |    / _ \| '_ \/ __| / __| __/ _ \ '_ \ / __| | | | | |    | '_ \ / _ \/ __| |/ / __|
%  | |\  | (_| | | | | | |  __/ | |___| (_) | | | \__ \ \__ \ ||  __/ | | | (__| |_| | | |____| | | |  __/ (__|   <\__ \
%  |_| \_|\__,_|_| |_| |_|\___|  \_____\___/|_| |_|___/_|___/\__\___|_| |_|\___|\__, |  \_____|_| |_|\___|\___|_|\_\___/
%                                                                                __/ |                                  
%                                                                               |___/                                   
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Name%20Consistency%20Checks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check merging of sensors where all are true
% Note that, if a field is missing, it still counts as 'merged'

% Create some test data
testStructure = struct;
testStructure.GPS_SparkFun_RightRear = 'abc';

% Check structure
fid = 1;
[flags, ~] = fcn_DataClean_checkDataNameConsistency(testStructure,fid);

% Check flags
assert(isequal(flags.GPS_SparkFun_RightRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_LeftRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_Front_sensors_are_merged,1));
assert(isequal(flags.ADIS_sensors_are_merged,1));
assert(isequal(flags.sensor_naming_standards_are_used,1));


%% Check merging of sensors where one is repeated false

% Create some test data
testStructure = struct;
testStructure.GPS_SparkFun_RightRear1 = 'abc';
testStructure.GPS_SparkFun_RightRear2 = 'def';

% Check structure
fid = 1;
[flags, ~] = fcn_DataClean_checkDataNameConsistency(testStructure,fid);

% Check flags
assert(isequal(flags.GPS_SparkFun_RightRear_sensors_are_merged,0));
assert(isequal(flags.GPS_SparkFun_LeftRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_Front_sensors_are_merged,1));
assert(isequal(flags.ADIS_sensors_are_merged,1));
assert(isequal(flags.sensor_naming_standards_are_used,1));


%% Check merging of sensors where location is bad

% Create some test data
testStructure = struct;
testStructure.GPS_SparkFun_BadLocation = 'abc';

% Check structure
fid = 1;
[flags, ~] = fcn_DataClean_checkDataNameConsistency(testStructure,fid);

% Check flags
assert(isequal(flags.GPS_SparkFun_RightRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_LeftRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_Front_sensors_are_merged,1));
assert(isequal(flags.ADIS_sensors_are_merged,1));
assert(isequal(flags.sensor_naming_standards_are_used,0));

%% Check merging of sensors where type is bad

% Create some test data
testStructure = struct;
testStructure.Diag_Encoder = 'abc';

% Check structure
fid = 1;
[flags, ~] = fcn_DataClean_checkDataNameConsistency(testStructure,fid);

% Check flags
assert(isequal(flags.GPS_SparkFun_RightRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_LeftRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_Front_sensors_are_merged,1));
assert(isequal(flags.ADIS_sensors_are_merged,1));
assert(isequal(flags.sensor_naming_standards_are_used,0));

%% Check merging of sensors where type is good

% Create some test data
testStructure = struct;
testStructure.Diagostic_IVSG_RearEncoders = 'abc';

% Check structure
fid = 1;
[flags, ~] = fcn_DataClean_checkDataNameConsistency(testStructure,fid);

% Check flags
assert(isequal(flags.GPS_SparkFun_RightRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_LeftRear_sensors_are_merged,1));
assert(isequal(flags.GPS_SparkFun_Front_sensors_are_merged,1));
assert(isequal(flags.ADIS_sensors_are_merged,1));
assert(isequal(flags.sensor_naming_standards_are_used,0));

%% Check merging of sensors for a typical sensor


% Fill in the initial data
fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataNameConsistency.mat');
load(fullExampleFilePath,'dataStructure')

% Check structure
fid = 1;
[flags, ~] = fcn_DataClean_checkDataNameConsistency(dataStructure,fid);

% Check flags
assert(isequal(flags.GPS_SparkFun_RightRear_sensors_are_merged,0));
assert(isequal(flags.GPS_SparkFun_LeftRear_sensors_are_merged,0));
assert(isequal(flags.GPS_SparkFun_Front_sensors_are_merged,0));
assert(isequal(flags.ADIS_sensors_are_merged,1));
assert(isequal(flags.sensor_naming_standards_are_used,0));


%% Fail conditions
if 1==0

end
