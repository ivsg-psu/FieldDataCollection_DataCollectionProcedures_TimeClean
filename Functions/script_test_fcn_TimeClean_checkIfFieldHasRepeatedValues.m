% script_test_fcn_TimeClean_checkIfFieldHasRepeatedValues.m
% tests fcn_TimeClean_checkIfFieldHasRepeatedValues.m

% REVISION HISTORY
% 
% 2024_11_07 by Sean Brennan, sbrennan@psu.edu
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

flags = []; 
sensors_to_check = '';
fid = 0;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(initial_test_structure,'GPS_Time',flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_has_no_repeats_in_all_sensors,1));
assert(strcmp(offending_sensor,''));


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

flags = []; 
sensors_to_check = '';
fid = 1;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(initial_test_structure,'GPS_Time',flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_has_no_repeats_in_all_sensors,1));
assert(strcmp(offending_sensor,''));


%% CASE 3: basic example - no inputs, verbose, FAIL
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

% Create a duplicate
initial_test_structure.sensor1.GPS_Time(end+1,1) = initial_test_structure.sensor1.GPS_Time(end,1);

flags = []; 
sensors_to_check = '';
fid = 1;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(initial_test_structure,'GPS_Time',flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_has_no_repeats_in_all_sensors,0));
assert(strcmp(offending_sensor,'sensor1'));

%% CASE 4: basic example - changing field_name, verbose, PASS even though other field corrupted
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

% Create a duplicate
initial_test_structure.sensor1.GPS_Time(end+1,1) = initial_test_structure.sensor1.GPS_Time(end,1);

flags = []; 
field_name = 'ROS_Time';
sensors_to_check = '';
fid = 1;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(initial_test_structure,field_name,flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_has_no_repeats_in_all_sensors,1));
assert(strcmp(offending_sensor,''));



%% CASE 5: basic example - changing sensors_to_check, verbose, PASS even though other sensor corrupted
figNum = 5;
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

% Create a duplicate
initial_test_structure.sensor1.GPS_Time(end+1,1) = initial_test_structure.sensor1.GPS_Time(end,1);

flags = []; 
field_name = 'GPS_Time';
sensors_to_check = 'car';
fid = 1;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(initial_test_structure,field_name,flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_has_no_repeats_in_car_sensors,1));
assert(strcmp(offending_sensor,''));


%% CASE 900: Real world data
figNum = 900;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
    clf;
end

fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataTimeConsistency.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
field_name = 'GPS_Time';
sensors_to_check = 'GPS';
fid = 1;


[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure, field_name, flags, sensors_to_check, fid, (figNum));
assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));




