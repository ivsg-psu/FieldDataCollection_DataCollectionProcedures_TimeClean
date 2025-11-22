% script_test_fcn_TimeClean_checkTimeSamplingConsistency.m
% tests fcn_TimeClean_checkTimeSamplingConsistency.m

% Revision history
% 2023_07_01 - sbrennan@psu.edu
% -- wrote the code originally using INTERNAL function from
% checkTimeConsistency
% 2024_11_11 - sbrennan@psu.edu
% -- updated test scripts for new consistency testing

close all


%% CASE 1: basic example - no inputs, verbose, all fail modes
fig_num = 1;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.sensor1.GPS_Time = (0:0.05:2)';
initial_test_structure.sensor1.ROS_Time = (0:0.05:2)'; 
initial_test_structure.sensor1.centiSeconds = 5;
initial_test_structure.sensor2.GPS_Time = (0:0.01:2)';
initial_test_structure.sensor2.ROS_Time = (0:0.01:2)'; 
initial_test_structure.sensor2.centiSeconds = 1;
initial_test_structure.car3.GPS_Time = (0:0.1:2)';
initial_test_structure.car3.ROS_Time = (0:0.1:2)';
initial_test_structure.car3.centiSeconds = 10; 

field_name = 'GPS_Time';
flags = []; 
sensors_to_check = '';
fid = 1;

% Pass
verificationTypeFlag = []; % Default is 0
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));


%%%%%%
% Bad centiSecond setting - causes ALL to fail yet caught on first one
modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 50;

% FAIL
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));



%%%%%%%%
% One bad sample - causes type 1 to fail but others to pass
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor2.GPS_Time(5)  = modified_test_structure.sensor2.GPS_Time(5)+(0.01)*0.8;

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,0));
assert(isequal(offending_sensor,'sensor2'));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

%%%%%%
% Centiseconds slightly off - causes modes 0 and 1 to pass, but 2 to fail
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor1.GPS_Time  = (0:0.053:2)';


% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

%% CASE 2: basic example - no inputs, not verbose - all fail modes
fig_num = 2;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.sensor1.GPS_Time = (0:0.05:2)';
initial_test_structure.sensor1.ROS_Time = (0:0.05:2)'; 
initial_test_structure.sensor1.centiSeconds = 5;
initial_test_structure.sensor2.GPS_Time = (0:0.01:2)';
initial_test_structure.sensor2.ROS_Time = (0:0.01:2)'; 
initial_test_structure.sensor2.centiSeconds = 1;
initial_test_structure.car3.GPS_Time = (0:0.1:2)';
initial_test_structure.car3.ROS_Time = (0:0.1:2)';
initial_test_structure.car3.centiSeconds = 10; 

field_name = 'GPS_Time';
flags = []; 
sensors_to_check = '';
fid = 0;

% Pass
verificationTypeFlag = []; % Default is 0
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));


%%%%%%
% Bad centiSecond setting - causes ALL to fail yet caught on first one
modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 50;

% FAIL
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));



%%%%%%%%
% One bad sample - causes type 1 to fail but others to pass
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor2.GPS_Time(5)  = modified_test_structure.sensor2.GPS_Time(5)+(0.01)*0.8;

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,0));
assert(isequal(offending_sensor,'sensor2'));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

%%%%%%
% Centiseconds slightly off - causes modes 0 and 1 to pass, but 2 to fail
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor1.GPS_Time  = (0:0.053:2)';


% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_intervals_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));


%% CASE 3: basic example - changing field_name, verbose
fig_num = 3;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.sensor1.GPS_Time = (0:0.05:2)';
initial_test_structure.sensor1.ROS_Time = (0:0.05:2)'; 
initial_test_structure.sensor1.centiSeconds = 5;
initial_test_structure.sensor2.GPS_Time = (0:0.01:2)';
initial_test_structure.sensor2.ROS_Time = (0:0.01:2)'; 
initial_test_structure.sensor2.centiSeconds = 1;
initial_test_structure.car3.GPS_Time = (0:0.1:2)';
initial_test_structure.car3.ROS_Time = (0:0.1:2)';
initial_test_structure.car3.centiSeconds = 10; 

field_name = 'ROS_Time';
flags = []; 
sensors_to_check = '';
fid = 1;

% Pass
verificationTypeFlag = []; % Default is 0
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_intervals_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));


%%%%%%
% Bad centiSecond setting - causes ALL to fail yet caught on first one
modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 50;

% FAIL
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_intervals_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));



%%%%%%%%
% One bad sample - causes type 1 to fail but others to pass
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor2.ROS_Time(5)  = modified_test_structure.sensor2.ROS_Time(5)+(0.01)*0.8;

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_intervals_match_centiSeconds,0));
assert(isequal(offending_sensor,'sensor2'));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

%%%%%%
% Centiseconds slightly off - causes modes 0 and 1 to pass, but 2 to fail
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor1.ROS_Time  = (0:0.053:2)';


% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_intervals_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));


%% CASE 4: basic example - changing sensors_to_check, verbose
fig_num = 4;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.sensor1.GPS_Time = (0:0.05:2)';
initial_test_structure.sensor1.ROS_Time = (0:0.05:2)'; 
initial_test_structure.sensor1.centiSeconds = 5;
initial_test_structure.sensor2.GPS_Time = (0:0.01:2)';
initial_test_structure.sensor2.ROS_Time = (0:0.01:2)'; 
initial_test_structure.sensor2.centiSeconds = 1;
initial_test_structure.car3.GPS_Time = (0:0.1:2)';
initial_test_structure.car3.ROS_Time = (0:0.1:2)';
initial_test_structure.car3.centiSeconds = 10; 

verificationTypeFlag = [];
flags = []; 
field_name = 'ROS_Time';
sensors_to_check = 'car';
fid = 1;

[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_car_sensors,1));
assert(strcmp(offending_sensor,''));

modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 6;
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_car_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 900: Real world data
fig_num = 900;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end

fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataTimeConsistency.mat');
load(fullExampleFilePath,'dataStructure');


field_name = 'ROS_Time';
flags = []; 
sensors_to_check = 'GPS';
fid = 1;

% Pass
verificationTypeFlag = []; % Default is 0
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_intervals_match_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(fig_num));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));
