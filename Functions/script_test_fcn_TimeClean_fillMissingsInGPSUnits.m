% script_test_fcn_TimeClean_fillMissingsInGPSUnits.m
% tests fcn_TimeClean_fillMissingsInGPSUnits.m

% Revision history
% 2024_10_02 - xfc5113@psu.edu
% -- wrote the code originally


%% Set up the workspace
close all



%% Name consistency checks start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%
%  ______ _ _ _   __  __ _         _               _____          _____ _____   _____   _    _       _ _
% |  ____(_) | | |  \/  (_)       (_)             |_   _|        / ____|  __ \ / ____| | |  | |     (_) |
% | |__   _| | | | \  / |_ ___ ___ _ _ __   __ _    | |  _ __   | |  __| |__) | (___   | |  | |_ __  _| |_ ___
% |  __| | | | | | |\/| | / __/ __| | '_ \ / _` |   | | | '_ \  | | |_ |  ___/ \___ \  | |  | | '_ \| | __/ __|
% | |    | | | | | |  | | \__ \__ \ | | | | (_| |  _| |_| | | | | |__| | |     ____) | | |__| | | | | | |_\__ \
% |_|    |_|_|_| |_|  |_|_|___/___/_|_| |_|\__, | |_____|_| |_|  \_____|_|    |_____/   \____/|_| |_|_|\__|___/
%                                           __/ |
%                                          |___/
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fill%20Missing%20In%20GPS%20Units
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % Location for Test Track base station
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.86368573');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-77.83592832');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','344.189');

%% Basic demonstration
fig_num = 1;
figure(fig_num);
clf;

% Note that, if a field is missing, it still counts as 'merged'
goodTime = (0:0.1:1.2)';
testTime1 = goodTime([1:4,6:end],:);
testTime2 = goodTime([1,3,6:end],:);
testTime3 = goodTime([2:5,7:end],:);


% Create some test data
testStructure = struct;

badDataSource = testTime1;
GPSdataStructure.GPS_Time = badDataSource;
GPSdataStructure.Latitude = 40.86368573*ones(length(badDataSource),1);
GPSdataStructure.Longitude = -77.83592832*ones(length(badDataSource),1);
GPSdataStructure.Altitude = 344.189*ones(length(badDataSource),1);
GPSdataStructure.centiSeconds = 10;
GPSdataStructure.Npoints = length(badDataSource);
testStructure.GPS_SparkFun_RightRear = GPSdataStructure;

badDataSource = testTime2;
GPSdataStructure.GPS_Time = badDataSource;
GPSdataStructure.Latitude = 40.86368573*ones(length(badDataSource),1);
GPSdataStructure.Longitude = -77.83592832*ones(length(badDataSource),1);
GPSdataStructure.Altitude = 344.189*ones(length(badDataSource),1);
GPSdataStructure.centiSeconds = 10;
GPSdataStructure.Npoints = length(badDataSource);
testStructure.GPS_SparkFun_LeftRear = GPSdataStructure;

badDataSource = testTime3;
GPSdataStructure.GPS_Time = badDataSource;
GPSdataStructure.Latitude = 40.86368573*ones(length(badDataSource),1);
GPSdataStructure.Longitude = -77.83592832*ones(length(badDataSource),1);
GPSdataStructure.Altitude = 344.189*ones(length(badDataSource),1);
GPSdataStructure.centiSeconds = 10;
GPSdataStructure.Npoints = length(badDataSource);
testStructure.GPS_SparkFun_CenterFront = GPSdataStructure;

% Check structure
fid = 1;
fixed_dataStructure = fcn_TimeClean_fillMissingsInGPSUnits(testStructure, (fid), (fig_num));

% Check fixed structure


%% CASE 900: Real world data
fig_num = 900;
figure(fig_num);
clf;

fullExampleFilePath = fullfile(cd,'Data','ExampleData_fillMissingsInGPSUnits.mat');
load(fullExampleFilePath,'dataStructure');

fid = 1;
fixed_dataStructure = fcn_TimeClean_fillMissingsInGPSUnits(dataStructure, (fid), (fig_num));







%% Fail conditions
if 1==0

end
