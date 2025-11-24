% script_test_fcn_TimeClean_checkDataStrictlyIncreasing.m
% tests fcn_TimeClean_checkDataStrictlyIncreasing.m

% REVISION HISTORY
% 
% 2024_11_06 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally using INTERNAL function from
% checkTimeConsistency

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


close all

%% CASE 1: basic example - no inputs, not verbose, PASS
figNum = 1;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
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
sensors_to_check = [];
fid = [];
figNum = [];

[flags,offending_sensor,return_flag] = fcn_TimeClean_checkDataStrictlyIncreasing(initial_test_structure, field_name, (flags), (sensors_to_check), (fid), (figNum));

assert(isequal(flags.GPS_Time_strictly_ascends_in_all_sensors,1));
assert(strcmp(offending_sensor,''));
assert(return_flag==0)

%% CASE 2: basic example - no inputs, verbose, PASS
figNum = 2;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
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
sensors_to_check = [];
fid = 1;
figNum = [];

[flags,offending_sensor,return_flag] = fcn_TimeClean_checkDataStrictlyIncreasing(initial_test_structure, field_name, (flags), (sensors_to_check), (fid), (figNum));

assert(isequal(flags.GPS_Time_strictly_ascends_in_all_sensors,1));
assert(strcmp(offending_sensor,''));
assert(return_flag==0)


%% CASE 3: basic example - no inputs, verbose, FAIL
figNum = 3;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
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


initial_test_structure.sensor2.GPS_Time(10,1) = initial_test_structure.sensor2.GPS_Time(10,1)-0.2;
initial_test_structure.car3.GPS_Time(10,1) = initial_test_structure.car3.GPS_Time(10,1)-0.2;

field_name = 'GPS_Time';
flags = []; 
sensors_to_check = [];
fid = 1;
figNum = [];

[flags,offending_sensor,return_flag] = fcn_TimeClean_checkDataStrictlyIncreasing(initial_test_structure, field_name, (flags), (sensors_to_check), (fid), (figNum));

assert(isequal(flags.GPS_Time_strictly_ascends_in_all_sensors,0));
assert(strcmp(offending_sensor,'sensor2 car3'));
assert(return_flag==1)

%% CASE 4: basic example - sensor specified, verbose, PASS
figNum = 4;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
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


initial_test_structure.car3.GPS_Time(10,1) = initial_test_structure.car3.GPS_Time(10,1)-0.2;

field_name = 'GPS_Time';
flags = []; 
sensors_to_check = 'sensor';
fid = 1;
figNum = [];

[flags,offending_sensor,return_flag] = fcn_TimeClean_checkDataStrictlyIncreasing(initial_test_structure, field_name, (flags), (sensors_to_check), (fid), (figNum));

assert(isequal(flags.GPS_Time_strictly_ascends_in_sensor_sensors,1));
assert(strcmp(offending_sensor,''));
assert(return_flag==0)

%% CASE 900: Real world data
figNum = 900;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataTimeConsistency.mat');
load(fullExampleFilePath,'dataStructure');

field_name = 'GPS_Time';
flags = []; 
sensors_to_check = 'GPS';
fid = 1;
figNum = [];

[flags,offending_sensor,return_flag] = fcn_TimeClean_checkDataStrictlyIncreasing(dataStructure, field_name, (flags), (sensors_to_check), (fid), (figNum));

assert(isequal(flags.GPS_Time_strictly_ascends_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));
assert(return_flag==0)




