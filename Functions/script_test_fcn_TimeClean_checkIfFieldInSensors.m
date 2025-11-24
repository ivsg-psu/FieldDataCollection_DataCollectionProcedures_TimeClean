% script_test_fcn_TimeClean_checkIfFieldInSensors.m
% tests fcn_TimeClean_checkIfFieldInSensors.m

% REVISION HISTORY
% 
% 2023_07_01 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally using INTERNAL function from
% checkTimeConsistency

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


%      [flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(...
%          dataStructure,field_name,...
%          (flags),(string_any_or_all),(sensors_to_check),(fid))



%% CASE 1: basic example - no inputs, not verbose
flags = []; 
string_any_or_all = '';
sensors_to_check = '';
fid = 0;

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.cow1.sound = 'moo';
initial_test_structure.cow2.sound = 'moo moo';
initial_test_structure.cow3.sound = 'moo moo moo';
initial_test_structure.pig1.sound  = 'oink';
initial_test_structure.quiet_pig.weight  = 4;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(initial_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,0));
assert(strcmp(offending_sensor,'quiet_pig'));

modified_test_structure = initial_test_structure;
modified_test_structure.quiet_pig.sound  = 'oink oink';
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(modified_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 2: basic example - no inputs, verbose
flags = []; 
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.cow1.sound = 'moo';
initial_test_structure.cow2.sound = 'moo moo';
initial_test_structure.cow3.sound = 'moo moo moo';
initial_test_structure.pig1.sound  = 'oink';
initial_test_structure.quiet_pig.weight  = 4;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(initial_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,0));
assert(strcmp(offending_sensor,'quiet_pig'));

modified_test_structure = initial_test_structure;
modified_test_structure.quiet_pig.sound  = 'oink oink';
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(modified_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 3: show that empty matricies, empty strings, and nan do not work
flags = []; 
string_any_or_all = '';
sensors_to_check = '';
fid = 1;

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.cow1.sound = 'moo';
initial_test_structure.cow2.sound = 'moo moo';
initial_test_structure.cow3.sound = 'moo moo moo';
initial_test_structure.pig1.sound  = 'oink';
initial_test_structure.quiet_pig.weight  = 4;

% empty matrix field
modified_test_structure = initial_test_structure;
modified_test_structure.quiet_pig.sound  = [];

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(modified_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,0));
assert(strcmp(offending_sensor,'quiet_pig'));

% empty string field
modified_test_structure = initial_test_structure;
modified_test_structure.quiet_pig.sound  = '';

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(modified_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,0));
assert(strcmp(offending_sensor,'quiet_pig'));

% nan field
modified_test_structure = initial_test_structure;
modified_test_structure.quiet_pig.sound  = nan;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(modified_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,0));
assert(strcmp(offending_sensor,'quiet_pig'));

%% CASE 4: basic example - string_any_or_all changed, verbose
flags = []; 
string_any_or_all = 'any';
sensors_to_check = '';
fid = 1;

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.cow1.sound = 'moo';
initial_test_structure.cow2.sound = 'moo moo';
initial_test_structure.cow3.sound = 'moo moo moo';
initial_test_structure.pig1.sound  = 'oink';
initial_test_structure.quiet_pig.weight  = 4;

% Run with 'any' option - it changes the flag name, and shows at least one
% sensor passes
fprintf(1,'\n\nTESTING: any option on default structure: \n');
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(initial_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_at_least_one_sensor,1));
assert(strcmp(offending_sensor,''));

fprintf(1,'\n\nTESTING: any option on modified structure: \n');
modified_test_structure = initial_test_structure;
modified_test_structure.quiet_pig.sound  = 'oink oink';
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(modified_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_at_least_one_sensor,1));
assert(isequal(offending_sensor,''));

% Run same thing with 'all' option - it changes the flag name, and does not
% pass the first case
string_any_or_all = 'all';
sensors_to_check = '';
fid = 1;

fprintf(1,'\n\nTESTING: all option on default structure: \n');
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(initial_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,0));
assert(strcmp(offending_sensor,'quiet_pig'));

fprintf(1,'\n\nTESTING: all option on modified structure: \n');
modified_test_structure = initial_test_structure;
modified_test_structure.quiet_pig.sound  = 'oink oink';
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(modified_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_sensors,1));
assert(isequal(offending_sensor,''));

%% CASE 5: basic example - sensors_to_check changed, verbose
flags = []; 
string_any_or_all = '';
sensors_to_check = 'cow';
fid = 1;

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.cow1.sound = 'moo';
initial_test_structure.cow2.sound = 'moo moo';
initial_test_structure.cow3.sound = 'moo moo moo';
initial_test_structure.pig1.sound  = 'oink';
initial_test_structure.quiet_pig.weight  = 4;

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(initial_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_cow_sensors,1));
assert(strcmp(offending_sensor,''));

sensors_to_check = 'pig';
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(initial_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_all_pig_sensors,0));
assert(isequal(offending_sensor,'quiet_pig'));

%% CASE 6: advanced example - all options used

% Fill in some silly test data
initial_test_structure = struct;
initial_test_structure.cow1.sound = 'moo';
initial_test_structure.cow2.sound = 'moo moo';
initial_test_structure.cow3.sound = 'moo moo moo';
initial_test_structure.pig1.sound  = 'oink';
initial_test_structure.quiet_pig.weight  = 4;

flags = struct; 
flags.stuff = 1; 
string_any_or_all = 'any';
sensors_to_check = 'pig';
fid = 1;


[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(initial_test_structure,'sound',flags, string_any_or_all, sensors_to_check,fid);
assert(isequal(flags.sound_exists_in_at_least_one_pig_sensor,1));
assert(isequal(flags.stuff,1));
assert(strcmp(offending_sensor,''));



