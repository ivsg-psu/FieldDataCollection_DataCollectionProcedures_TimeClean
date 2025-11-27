% script_test_fcn_TimeClean_trimRepeatsFromField.m
% tests fcn_TimeClean_trimRepeatsFromField.m

% REVISION HISTORY
% 
% 2023_06_26 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll
%
% 2025_11_26 by Sean Brennan, sbrennan@psu.edu
% - Fixed bug where NaN repeated values getting caught as repeats, but not
%   % being fixed. Corrected this by separating the NaN checking from the
%   % unique values checking, and keeping only indices that are unique AND not
%   % NaN valued.
% - Added structure to demo script to move it more toward standard form

% TO-DO:
% 2025_11_21 by Sean Brennan, sbrennan@psu.edu
% - Fill in fast case testing.
% - Finish demos and other tests. Left these incomplete


%% Set up the workspace
close all

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
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: Test dataset with repeated values in the GPS_Hemisphere time
figNum = 10001;
titleString = sprintf('DEMO case: Test dataset with repeated values in the GPS_Hemisphere time');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fid = 1;
time_time_corruption_type = 2^20; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
[dataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);

% Show that data has errors
[flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(dataStructure,fid);
assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));

field_name = 'GPS_Time';
sensors_to_check = 'GPS';

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure, field_name, flags, sensors_to_check, (fid),(1));
assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,0));
assert(strcmp(offending_sensor,'GPS_Hemisphere'));


% Fix the data using default call
% FORMAT:
%      trimmed_dataStructure = fcn_INTERNAL_trimRepeatsFromField(...
%         dataStructure, (fid), (field_name), (sensors_to_check))
trimmed_dataStructure = fcn_TimeClean_trimRepeatsFromField(dataStructure, (fid), (field_name), (sensors_to_check));


% sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(dataStructure));

% Check variable sizes
assert(size(dataStructure,1)==1); 
assert(size(dataStructure,2)==1); 

% Check variable values
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(trimmed_dataStructure, field_name, flags, sensors_to_check, (fid),(1));
assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,1));

% % Make sure plot opened up
% assert(isequal(get(gcf,'Number'),figNum));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));


%% DEMO case: Test dataset with repeated values in the GPS_Hemisphere time using a generic call
figNum = 10001;
titleString = sprintf('DEMO case: Test dataset with repeated values in the GPS_Hemisphere time using a generic call');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% fid = 1;
% time_time_corruption_type = 2^20; % Type 'help fcn_LoadRawDataToMATLAB_fillTestDataStructure' to ID corruption types
% [dataStructure, error_type_string] = fcn_LoadRawDataToMATLAB_fillTestDataStructure(time_time_corruption_type);
% fprintf(1,'\nData created with following errors injected: %s\n\n',error_type_string);
% 
% % Show that data has errors
% [flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(dataStructure,fid);
% assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,0));
% assert(strcmp(offending_sensor,'GPS_Hemisphere'));
% 
% field_name = 'GPS_Time';
% sensors_to_check = 'GPS';
% 
% [flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure, field_name, flags, sensors_to_check, (fid),(1));
% assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,0));
% assert(strcmp(offending_sensor,'GPS_Hemisphere'));
% 
% 
% % Fix the data using default call
% % FORMAT:
% %      trimmed_dataStructure = fcn_INTERNAL_trimRepeatsFromField(...
% %         dataStructure, (fid), (field_name), (sensors_to_check))
% trimmed_dataStructure = fcn_TimeClean_trimRepeatsFromField(dataStructure); % , (fid), (field_name), (sensors_to_check));
% 
% 
% % sgtitle(titleString, 'Interpreter','none');
% 
% % Check variable types
% assert(isstruct(dataStructure));
% 
% % Check variable sizes
% assert(size(dataStructure,1)==1); 
% assert(size(dataStructure,2)==1); 
% 
% % Check variable values
% [flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(trimmed_dataStructure, field_name, flags, sensors_to_check, (fid),(1));
% assert(isequal(flags.GPS_Time_has_no_repeats_in_GPS_sensors,1));
% 
% % % Make sure plot opened up
% % assert(isequal(get(gcf,'Number'),figNum));
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==figNum));

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
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST mode cases\n');

%% TEST case: Two polytopes with clear space right down middle, edge 5 to 8 on polytope
figNum = 20001;
titleString = sprintf('TEST case: Two polytopes with clear space right down middle, edge 5 to 8 on polytope');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;



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
% Figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

% %% Basic example - NO FIGURE
% figNum = 80001;
% fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
% figure(figNum); close(figNum);
% 
% % Load some test data 
% dataSetNumber = 1; % Two polytopes with clear space right down middle
% 
% [pointsWithData, start, finish, vGraph, polytopes, goodAxis] = fcn_INTERNAL_loadExampleData(dataSetNumber);
% mode = '2d';
% 
% plottingOptions.axis = goodAxis;
% plottingOptions.selectedFromToToPlot = [1 6];
% plottingOptions.filename = 'dilationAnimation.gif'; % Specify the output file name
% 
% % Call the function
% dilation_robustness_matrix = ...
%     fcn_VGraph_generateDilationRobustnessMatrix(...
%     pointsWithData, start, finish, vGraph, mode, polytopes,...
%     (plottingOptions), ([]));
% 
% % Check variable types
% assert(isnumeric(dilation_robustness_matrix));
% 
% % Check variable sizes
% Npoints = size(vGraph,1);
% assert(size(dilation_robustness_matrix,1)==Npoints); 
% assert(size(dilation_robustness_matrix,1)==Npoints); 
% 
% % Check variable values
% % 1 is left, 2 is right
% valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),1);
% roundedValueToTest = round(valueToTest,2);
% assert(isequal(roundedValueToTest,0.97));
% valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),2);
% roundedValueToTest = round(valueToTest,2);
% assert(isequal(roundedValueToTest,0.97));
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==figNum));
% 
% 
% %% Basic fast mode - NO FIGURE, FAST MODE
% figNum = 80002;
% fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
% figure(figNum); close(figNum);
% 
% % Load some test data 
% dataSetNumber = 1; % Two polytopes with clear space right down middle
% 
% [pointsWithData, start, finish, vGraph, polytopes, goodAxis] = fcn_INTERNAL_loadExampleData(dataSetNumber);
% mode = '2d';
% plottingOptions.axis = goodAxis;
% plottingOptions.selectedFromToToPlot = [1 6];
% plottingOptions.filename = 'dilationAnimation.gif'; % Specify the output file name
% 
% % Call the function
% dilation_robustness_matrix = ...
%     fcn_VGraph_generateDilationRobustnessMatrix(...
%     pointsWithData, start, finish, vGraph, mode, polytopes,...
%     (plottingOptions), (-1));
% 
% % Check variable types
% assert(isnumeric(dilation_robustness_matrix));
% 
% % Check variable sizes
% Npoints = size(vGraph,1);
% assert(size(dilation_robustness_matrix,1)==Npoints); 
% assert(size(dilation_robustness_matrix,1)==Npoints); 
% 
% % Check variable values
% % 1 is left, 2 is right
% valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),1);
% roundedValueToTest = round(valueToTest,2);
% assert(isequal(roundedValueToTest,0.97));
% valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),2);
% roundedValueToTest = round(valueToTest,2);
% assert(isequal(roundedValueToTest,0.97));
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==figNum));
% 
% 
% %% Compare speeds of pre-calculation versus post-calculation versus a fast variant
% figNum = 80003;
% fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
% figure(figNum);
% close(figNum);
% 
% % Load some test data 
% dataSetNumber = 1; % Two polytopes with clear space right down middle
% 
% [pointsWithData, start, finish, vGraph, polytopes, goodAxis] = fcn_INTERNAL_loadExampleData(dataSetNumber);
% mode = '2d';
% 
% plottingOptions.axis = goodAxis;
% plottingOptions.selectedFromToToPlot = [1 6];
% plottingOptions.filename = 'dilationAnimation.gif'; % Specify the output file name
% 
% 
% Niterations = 1;
% 
% % Do calculation without pre-calculation
% tic;
% for ith_test = 1:Niterations
%     % Call the function
%     dilation_robustness_matrix = ...
%         fcn_VGraph_generateDilationRobustnessMatrix(...
%         pointsWithData, start, finish, vGraph, mode, polytopes,...
%         (plottingOptions), ([]));
% end
% slow_method = toc;
% 
% % Do calculation with pre-calculation, FAST_MODE on
% tic;
% for ith_test = 1:Niterations
%     % Call the function
%     dilation_robustness_matrix = ...
%         fcn_VGraph_generateDilationRobustnessMatrix(...
%         pointsWithData, start, finish, vGraph, mode, polytopes,...
%         (plottingOptions), (-1));
% end
% fast_method = toc;
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==figNum));
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
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==figNum));


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

% close all;

%% BUG 

%% Fail conditions
if 1==0
   
end


%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%§

