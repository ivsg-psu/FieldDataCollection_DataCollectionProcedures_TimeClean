% script_test_fcn_TimeClean_checkFieldDifferencesForJumps.m
% tests fcn_TimeClean_checkFieldDifferencesForJumps.m

% Revision history
% 2023_07_02 - sbrennan@psu.edu
% -- wrote the code originally using INTERNAL function from
% checkTimeConsistency

% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(...
%          dataStructure, field_name, ...
%          (flags),...
%          (threshold_in_standard_deviations),...
%          (custom_lower_threshold),...
%          (string_any_or_all),(sensors_to_check),(fid))
%



%% CASE 1: basic example - no inputs, not verbose
% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
flags = [];  %#ok<NASGU>
threshold_in_standard_deviations = [];  %#ok<NASGU>
custom_lower_threshold = []; %#ok<NASGU>
string_any_or_all = ''; %#ok<NASGU>
sensors_to_check = ''; %#ok<NASGU>
fid = 0; %#ok<NASGU>

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Fix the error
modified_test_structure = initial_test_structure;
modified_test_structure.pig3.data  = good_data;

% Show an error is not detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(modified_test_structure,field_name);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 2: basic example - no inputs, verbose
% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
threshold_in_standard_deviations = []; 
custom_lower_threshold = [];
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Fix the error
modified_test_structure = initial_test_structure;
modified_test_structure.pig3.data  = good_data;

% Show an error is not detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(modified_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 3: basic example - show effect of fields
% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
threshold_in_standard_deviations = []; 
custom_lower_threshold = [];
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Try a different field, which is bad in cow1
field_name = 'measurements';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.measurements_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'cow1'));

% Try a different field, which is bad in pig data because it does not
% contain any 'values' field
field_name = 'values';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.values_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig1'));


%% CASE 4: show that flags passes through
% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
threshold_in_standard_deviations = []; 
custom_lower_threshold = [];
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

flags.this_is_a_test = 1;
% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

assert(isequal(flags.this_is_a_test,1));


%% CASE 5: show that threshold_in_standard_deviations works
% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
threshold_in_standard_deviations = 5; 
custom_lower_threshold = [];
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Fix the error
modified_test_structure = initial_test_structure;
modified_test_structure.pig3.data  = good_data;

% Show an error is not detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(modified_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,1));
assert(isequal(offending_sensor,''));

% Now lower the threshold, and show error comes back
% NOTE: other than the lower threshold, this is exactly the same as the
% previous segment of code, but with lower standard deviations.
threshold_in_standard_deviations = 1; % One standard deviation will cause many regular data to show up in error
[flags,~] = fcn_TimeClean_checkFieldDifferencesForJumps(modified_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));


%% CASE 6: basic example - custom_lower_threshold changed, verbose
% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
threshold_in_standard_deviations = 5; 
custom_lower_threshold = [];
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Fix the error
modified_test_structure = initial_test_structure;
modified_test_structure.pig3.data  = good_data;

% Show an error is not detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(modified_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,1));
assert(isequal(offending_sensor,''));

% Now lower the threshold, and show error comes back
custom_lower_threshold = .99; % Some jumps are smaller than this

% NOTE: other than the lower threshold, this is exactly the same as the
% previous segment of code, but with lower standard deviations.
[flags,~] = fcn_TimeClean_checkFieldDifferencesForJumps(modified_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));


%% CASE 7 - string_any_or_all changed, verbose

% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
threshold_in_standard_deviations = []; 
custom_lower_threshold = [];

sensors_to_check = '';
fid = 1;

% Show an error is detected
field_name = 'data';

string_any_or_all = 'any';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

string_any_or_all = 'all';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_all_sensors,1));
assert(strcmp(offending_sensor,''));


% Try a different field, which is bad in cow1
field_name = 'measurements';

string_any_or_all = 'any';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.measurements_has_no_sampling_jumps_in_any_sensors,0));
assert(strcmp(offending_sensor,'cow1'));

string_any_or_all = 'all';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.measurements_has_no_sampling_jumps_in_all_sensors,1));
assert(strcmp(offending_sensor,''));

% Try a different field, and limit to JUST cows - these are ALL bad
field_name = 'measurements';
sensors_to_check = 'cow';

string_any_or_all = 'any';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.measurements_has_no_sampling_jumps_in_any_cow_sensors,0));
assert(strcmp(offending_sensor,'cow1'));

string_any_or_all = 'all';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.measurements_has_no_sampling_jumps_in_all_cow_sensors,0));
assert(strcmp(offending_sensor,'cow1'));


%% CASE 8: sensors_to_check changed, verbose

% Fill in some silly test data
initial_test_structure = struct;
good_data = (1:100)';
std_dev = 0.05;
good_data = good_data + std_dev * randn(length(good_data(:,1)),1);

jump = 10;
bad_data  = [good_data(1:10); good_data(11:end)+jump];

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
threshold_in_standard_deviations = 5; 
custom_lower_threshold = [];
string_any_or_all = '';
% sensors_to_check = '';
fid = 1;

% Show an error is detected in pig data
sensors_to_check = 'pig';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_pig_sensors,0));
assert(strcmp(offending_sensor,'pig3'));

% Show an error is not detected in cow data
sensors_to_check = 'cow';
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(initial_test_structure,field_name,flags,threshold_in_standard_deviations, custom_lower_threshold,string_any_or_all,sensors_to_check, fid);
assert(isequal(flags.data_has_no_sampling_jumps_in_any_cow_sensors,1));
assert(strcmp(offending_sensor,''));
