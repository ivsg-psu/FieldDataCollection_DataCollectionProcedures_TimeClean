% script_test_fcn_TimeClean_checkFieldDifferencesForMissings.m
% tests fcn_TimeClean_checkFieldDifferencesForMissings.m

% Revision history
% 2023_07_02 - sbrennan@psu.edu
% -- wrote the code originally using INTERNAL function from
% checkTimeConsistency

% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(...
%          dataStructure, field_name, ...
%          (flags),...
%          (threshold_in_standard_deviations),...
%          (custom_lower_threshold),...
%          (string_any_or_all),(sensors_to_check),(fid))
%



%% CASE 1: basic example - no inputs, not verbose
% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 10;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;


% NOTE: pigs have no 'values' field - this is to show that this sets the
% flag to zero

field_name = 'data';
flags = [];  
threshold_for_agreement = [];  
expectedJump = goodCentiSeconds/100; 
string_any_or_all = ''; 
sensors_to_check = ''; 
fid = 0; 

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Fix the error
modified_test_structure = initial_test_structure;
modified_test_structure.pig3.data  = good_data;

% Show an error is no longer detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(modified_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 2: basic example - no inputs, verbose
% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 10;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;

% NOTE: pigs have no 'values' field - this is to show that this sets the
% flag to zero

field_name = 'data';
flags = []; 
threshold_for_agreement = []; 
expectedJump = goodCentiSeconds/100; 
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Fix the error
modified_test_structure = initial_test_structure;
modified_test_structure.pig3.data  = good_data;

% Show an error is not detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(modified_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 3: basic example - show effect of fields
% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 10;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;


field_name = 'data';
flags = []; 
threshold_for_agreement = []; 
expectedJump = goodCentiSeconds/100; 
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure,field_name,flags,threshold_for_agreement, expectedJump,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Try a different field, which is bad in cow1
field_name = 'measurements';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.measurements_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'cow1'));

% Try a different field, which is bad in pig data because it does not
% contain any 'values' field
field_name = 'values';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.values_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig1'));


%% CASE 4: show that flags passes through
% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 10;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;

% NOTE: pigs have no 'values' field - this is to show that this sets the
% flag to zero

field_name = 'data';
flags = struct; 
threshold_for_agreement = []; 
expectedJump = goodCentiSeconds/100; 
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

flags.this_is_a_test = 1;
% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure,field_name,flags,threshold_for_agreement, expectedJump,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

assert(isequal(flags.this_is_a_test,1));


%% CASE 5: show that threshold_for_agreement works
% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 10;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;

% NOTE: pigs have no 'values' field - this is to show that this sets the
% flag to zero

field_name = 'data';
flags = []; 
threshold_for_agreement = 5; 
expectedJump = goodCentiSeconds/100; 
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show no error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,1));
assert(isempty(offending_sensor));


%% CASE 6: basic example - expectedJump changed, verbose
% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 1;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
% bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;

% NOTE: pigs have no 'values' field - this is to show that this sets the
% flag to zero

field_name = 'data';
flags = []; 
threshold_for_agreement = []; 
expectedJump = goodCentiSeconds/100; 
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show no error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,1));
assert(isempty(offending_sensor));



%% CASE 7 - string_any_or_all changed, verbose

% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 10;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;

% NOTE: pigs have no 'values' field - this is to show that this sets the
% flag to zero

flags = []; 
threshold_for_agreement = []; 
expectedJump = goodCentiSeconds/100; 

sensors_to_check = '';
fid = 1;

% Show an error is detected
field_name = 'data';

string_any_or_all = 'any';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

string_any_or_all = 'all';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_all_sensors,1));
assert(strcmp(offending_sensor,''));


% Try a different field, which is bad in cow1
field_name = 'measurements';

string_any_or_all = 'any';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.measurements_has_no_missing_sample_differences_in_any_sensors,0));
assert(strcmp(offending_sensor,'cow1'));

string_any_or_all = 'all';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.measurements_has_no_missing_sample_differences_in_all_sensors,1));
assert(strcmp(offending_sensor,''));

% Try a different field, and limit to JUST cows - these are ALL bad
field_name = 'measurements';
sensors_to_check = 'cow';

string_any_or_all = 'any';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.measurements_has_no_missing_sample_differences_in_any_cow_senso,0));
assert(strcmp(offending_sensor,'cow1'));

string_any_or_all = 'all';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.measurements_has_no_missing_sample_differences_in_all_cow_senso,0));
assert(strcmp(offending_sensor,'cow1'));


%% CASE 8: sensors_to_check changed, verbose

% Fill in some silly test data
initial_test_structure = struct;
goodCentiSeconds = 10;
good_data = goodCentiSeconds/100*(1:100)';
std_dev = 0;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = good_data;
bad_data(jump) = bad_data(jump)+0.003;

initial_test_structure.cow1.data = good_data;
initial_test_structure.cow2.data = good_data;
initial_test_structure.cow3.data = good_data;

initial_test_structure.cow1.measurements = bad_data;
initial_test_structure.cow2.measurements = bad_data;
initial_test_structure.cow3.measurements = bad_data;

initial_test_structure.cow1.values = good_data;
initial_test_structure.cow2.values = good_data;
initial_test_structure.cow3.values = good_data;

initial_test_structure.pig1.data = good_data;
initial_test_structure.pig2.data = good_data;
initial_test_structure.pig3.data = bad_data;

initial_test_structure.pig1.measurements = good_data;
initial_test_structure.pig2.measurements = good_data;
initial_test_structure.pig3.measurements = good_data;

% NOTE: pigs have no 'values' field - this is to show that this sets the
% flag to zero

field_name = 'data';
flags = []; 
threshold_for_agreement = 5; 
expectedJump = goodCentiSeconds/100; 
string_any_or_all = '';
% sensors_to_check = '';
fid = 1;

% Show an error is detected in pig data
sensors_to_check = 'pig';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_pig_sensors,1));
assert(isempty(offending_sensor));

% Show an error is not detected in cow data
sensors_to_check = 'cow';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(initial_test_structure, field_name, (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all),(sensors_to_check),(fid));
assert(isequal(flags.data_has_no_missing_sample_differences_in_any_cow_sensors,1));
assert(strcmp(offending_sensor,''));
