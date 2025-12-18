% script_test_fcn_TimeClean_checkTimeSamplingConsistency.m
% tests fcn_TimeClean_checkTimeSamplingConsistency.m

% REVISION HISTORY
% 
% 2023_07_01 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally using INTERNAL function from
% checkTimeConsistency
% 
% 2024_11_11 by Sean Brennan, sbrennan@psu.edu
% - Updated test scripts for new consistency testing
% 
% 2025_12_17 by Sean Brennan, sbrennan@psu.edu
% - Updated test script formatting to allow sections
% - Added real-world test case


% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEMO figures start with 1

close all;
fprintf(1,'Figure: 1XXXX: DEMO cases\n');


%% DEMO case: basic example - no inputs, verbose, all fail modes
fig_num = 10001; 
titleString = sprintf('DEMO case: basic example - no inputs, verbose, all fail modes');
fprintf(1,'Figure %.0f: %s\n',fig_num, titleString);
figure(fig_num); clf;


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
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));


%%%%%%
% Bad centiSecond setting - causes ALL to fail yet caught on first one
modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 50;

% FAIL
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,0));

assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));



%%%%%%%%
% One bad sample - causes type 1 to fail but others to pass
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor2.GPS_Time(5)  = modified_test_structure.sensor2.GPS_Time(5)+(0.01)*0.8;

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,0));
assert(isequal(offending_sensor,'sensor2'));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

%%%%%%
% Centiseconds slightly off - causes modes 0 and 1 to pass, but 2 to fail
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor1.GPS_Time  = (0:0.053:2)';


% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

%% DEMO case: basic example - no inputs, not verbose - all fail modes
fig_num = 10002; 
titleString = sprintf('DEMO case: basic example - no inputs, not verbose - all fail modes');
fprintf(1,'Figure %.0f: %s\n',fig_num, titleString);
figure(fig_num); clf;




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
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));


%%%%%%
% Bad centiSecond setting - causes ALL to fail yet caught on first one
modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 50;

% FAIL
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));



%%%%%%%%
% One bad sample - causes type 1 to fail but others to pass
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor2.GPS_Time(5)  = modified_test_structure.sensor2.GPS_Time(5)+(0.01)*0.8;

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,0));
assert(isequal(offending_sensor,'sensor2'));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

%%%%%%
% Centiseconds slightly off - causes modes 0 and 1 to pass, but 2 to fail
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor1.GPS_Time  = (0:0.053:2)';


% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sampling_matches_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.GPS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));


%% DEMO case: basic example - changing field_name, verbose
fig_num = 10003; 
titleString = sprintf('DEMO case: basic example - changing field_name, verbose');
fprintf(1,'Figure %.0f: %s\n',fig_num, titleString);
figure(fig_num); clf;



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
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sampling_matches_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));


%%%%%%
% Bad centiSecond setting - causes ALL to fail yet caught on first one
modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 50;

% FAIL
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sampling_matches_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));

% FAIL
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));



%%%%%%%%
% One bad sample - causes type 1 to fail but others to pass
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor2.ROS_Time(5)  = modified_test_structure.sensor2.ROS_Time(5)+(0.01)*0.8;

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% FAIL
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sampling_matches_centiSeconds,0));
assert(isequal(offending_sensor,'sensor2'));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

%%%%%%
% Centiseconds slightly off - causes modes 0 and 1 to pass, but 2 to fail
modified_test_structure = initial_test_structure;
% Force one time sample to have a bad interval
modified_test_structure.sensor1.ROS_Time  = (0:0.053:2)';


% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sampling_matches_centiSeconds,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds,0));
assert(strcmp(offending_sensor,'sensor1'));


%% DEMO case: basic example - changing sensors_to_check, verbose
fig_num = 10004; 
titleString = sprintf('DEMO case: basic example - changing sensors_to_check, verbose');
fprintf(1,'Figure %.0f: %s\n',fig_num, titleString);
figure(fig_num); clf;


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

[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_car_sensors,1));
assert(strcmp(offending_sensor,''));

modified_test_structure = initial_test_structure;
modified_test_structure.sensor1.centiSeconds = 6;
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(modified_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_car_sensors,1));
assert(isequal(offending_sensor,''));




%% Test cases start here. These are very simple, usually trivial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______ ______  _____ _______ _____
% |__   __|  ____|/ ____|__   __/ ____|
%    | |  | |__  | (___    | | | (___
%    | |  |  __|  \___ \   | |  \___ \
%    | |  | |____ ____) |  | |  ____) |
%    |_|  |______|_____/   |_| |_____/
%
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST mode cases\n');

%% Test case: Plot LL data 

% Plot data onto an empty figure. This will force the code to check to see
% if the figure has data inside it, and if not, it will prepare the figure
% the same way as a new figure.

fig_num = 20001;
titleString = sprintf('Test case: Plot LL data');
fprintf(1,'Figure %.0f: %s\n',fig_num, titleString);
figure(fig_num); clf;


%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FAST Mode figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: TEST mode cases\n');
fprintf(1, 'Plot function - No fast mode tests')

% %% Basic example - NO FIGURE
% 
% fig_num = 80001;
% fprintf(1,'Figure: %.0f: FAST mode, empty fig_num\n',fig_num);
% figure(fig_num); close(fig_num);
% 
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==fig_num));
% 
% 
% %% Basic example - NO FIGURE
% 
% fig_num = 80002;
% fprintf(1,'Figure: %.0f: FAST mode, fig_num=-1\n',fig_num);
% figure(fig_num); close(fig_num);
% 
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==fig_num));
% 
% %% Compare speeds of pre-calculation versus post-calculation versus a fast variant
% 
% fig_num = 80003;
% fprintf(1,'Figure: %.0f: FAST mode comparisons\n',fig_num);
% figure(fig_num); close(fig_num);
% 
% Niterations = 100;
% 
% % Do calculation without pre-calculation
% tic;
% for ith_test = 1:Niterations
% 
% 
% 
% end
% slow_method = toc;
% 
% % Do calculation with pre-calculation, FAST_MODE on
% tic;
% 
% for ith_test = 1:Niterations
% 
% 
% 
% end
% fast_method = toc;
% 
% 
% % Plot results as bar chart
% figure(373737);
% clf;
% hold on;
% 
% X = categorical({'Normal mode','Fast mode'});
% X = reordercats(X,{'Normal mode','Fast mode'}); % Forces bars to appear in this exact order, not alphabetized
% Y = [slow_method fast_method ]*1000/Niterations;
% bar(X,Y)
% ylabel('Execution time (Milliseconds)')
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==fig_num));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

close all;
fprintf(1,'Figure: 9XXXXXX: BUG mode cases\n');



%% CASE 90001: Real world data
fig_num = 90001;
titleString = sprintf('BUG case: Real world data');
fprintf(1,'Figure %.0f: %s\n',fig_num, titleString);
figure(fig_num); clf;

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

fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataTimeConsistency.mat');
load(fullExampleFilePath,'dataStructure');


field_name = 'ROS_Time';
flags = []; 
sensors_to_check = 'GPS';
fid = 1;

% Pass
verificationTypeFlag = []; % Default is 0
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 1; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sampling_matches_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));

% Pass
verificationTypeFlag = 2; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(initial_test_structure,field_name, verificationTypeFlag, flags, sensors_to_check, (fid),(figNum));
assert(isequal(flags.ROS_Time_sample_counts_match_centiSeconds_in_GPS_sensors,1));
assert(strcmp(offending_sensor,''));


%% CASE 90001: Real world data
fig_num = 90001;
titleString = sprintf('BUG case: Real world data');
fprintf(1,'Figure %.0f: %s\n',fig_num, titleString);
figure(fig_num); clf;

fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataTimeSamplingConsistency_CASE90001.mat');
load(fullExampleFilePath,'dataStructure','field_name','verificationTypeFlag','flags','sensors_to_check','fid','figNum');
[timeFlags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(dataStructure,field_name, verificationTypeFlag, flags, sensors_to_check, fid, figNum);
