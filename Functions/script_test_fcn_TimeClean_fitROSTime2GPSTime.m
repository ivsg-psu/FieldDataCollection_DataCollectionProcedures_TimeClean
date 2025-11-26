% script_test_fcn_TimeClean_fitROSTime2GPSTime.m
% tests fcn_TimeClean_fitROSTime2GPSTime.m

% REVISION HISTORY
% 
% 2024_11_18 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally 

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


close all;



%% CASE 2: basic example - verbose
figNum = 900;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
    clf;
end


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = 1;

[flags, fitParameters] = fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (figNum));

assert(isequal(flags.ROS_Time_calibrated_to_GPS_Time,1));
assert(length(fitParameters)==2);

% script_test_fcn_VGraph_generateDilationRobustnessMatrix
% Tests: fcn_VGraph_generateDilationRobustnessMatrix

% REVISION HISTORY:
% 
% As: script_test_fcn_algorithm_generate_dilation_robustness_matrix
% 
% 2024_02_01 by S. Harnett
% - first write of script
%
% As: script_test_fcn_BoundedAStar_generateDilationRobustnessMatrix
% 
% 2025_10_06 by Sean Brennan, sbrennan@psu.edu
% - removed addpath calls
% - removed calls to fcn_visibility_clear_and_blocked_points_global,
%   % replaced with fcn_Visibility_clearAndBlockedPointsGlobal
% - removed calls to fcn_algorithm_generate_dilation_robustness_matrix,
%   % replaced with fcn_BoundedAStar_generateDilationRobustnessMatrix
% - removed calls to fcn_MapGen_fillPolytopeFieldsFromVertices,
%   % replaced with fcn_MapGen_polytopesFillFieldsFromVertices
% 
% 2025_10_20 by Sean Brennan, sbrennan@psu.edu
% - refactored script to make test cases more clear, do fast mode, etc.
%
% As: script_test_fcn_Visibility_generateDilationRobustnessMatrix
% 
% 2025_10_31 by Sean Brennan, sbrennan@psu.edu
% - moved function to Visibility Graph library
% - cleaned up test cases near header that are now in demo sections
%
% As: script_test_fcn_VGraph_generateDilationRobustnessMatrix
% 
% 2025_11_07 by Sean Brennan, sbrennan@psu.edu
% - Renamed script_test_fcn_Visibility_generateDilationRobustnessMatrix to script_test_fcn_VGraph_generateDilationRobustnessMatrix
%
% 2025_11_16 by Sean Brennan, sbrennan@psu.edu
% - Cleaned up variable naming
%
% 2025_11_17 by Sean Brennan, sbrennan@psu.edu
% - Updated formatting to Markdown on Rev history
% - Cleaned up variable naming in all functions
%   % fig+_num to figNum
%   % vis+ibilityMatrix to vGraph
%   % all_+pts to pointsWithData

% TO-DO:
% 2025_11_21 by Sean Brennan, sbrennan@psu.edu
% - (add items here)


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

%% DEMO case: Basic example
figNum = 10001;
titleString = sprintf('DEMO case: Basic example');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
load(fullExampleFilePath,'dataStructure');

flags = []; 
fid = 1;

% Call the function
[flags, fitParameters] = fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (figNum));

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(flags));
assert(iscell(fitParameters));

% Check variable sizes
assert(size(fitParameters,1)==2);
assert(size(fitParameters,2)==1);

% Check variable values
assert(isequal(flags.ROS_Time_calibrated_to_GPS_Time,1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Two polytopes with clear space right down middle, all edges
% figNum = 10002;
% titleString = sprintf('DEMO case: Two polytopes with clear space right down middle, all edges');
% fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
% figure(figNum); clf;

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

%% TEST case: Test case generated from fcn_TimeClean_cleanTimeInStruct
figNum = 20001;
titleString = sprintf('TEST case: Test case generated from fcn_TimeClean_cleanTimeInStruct');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;


fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime_TestCase20001.mat');
load(fullExampleFilePath,'dataStructure');

flags = [];
fid = 1;

% Call the function
[flags, fitParameters] = fcn_TimeClean_fitROSTime2GPSTime(dataStructure, (flags), (fid), (figNum));

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(flags));
assert(iscell(fitParameters));

% Check variable sizes
assert(size(fitParameters,1)==2);
assert(size(fitParameters,2)==1);

% Check variable values
assert(isequal(flags.ROS_Time_calibrated_to_GPS_Time,1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

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

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

% Load some test data 
dataSetNumber = 1; % Two polytopes with clear space right down middle

[pointsWithData, start, finish, vGraph, polytopes, goodAxis] = fcn_INTERNAL_loadExampleData(dataSetNumber);
mode = '2d';

plottingOptions.axis = goodAxis;
plottingOptions.selectedFromToToPlot = [1 6];
plottingOptions.filename = 'dilationAnimation.gif'; % Specify the output file name

% Call the function
dilation_robustness_matrix = ...
    fcn_VGraph_generateDilationRobustnessMatrix(...
    pointsWithData, start, finish, vGraph, mode, polytopes,...
    (plottingOptions), ([]));

% Check variable types
assert(isnumeric(dilation_robustness_matrix));

% Check variable sizes
Npoints = size(vGraph,1);
assert(size(dilation_robustness_matrix,1)==Npoints); 
assert(size(dilation_robustness_matrix,1)==Npoints); 

% Check variable values
% 1 is left, 2 is right
valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),1);
roundedValueToTest = round(valueToTest,2);
assert(isequal(roundedValueToTest,0.97));
valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),2);
roundedValueToTest = round(valueToTest,2);
assert(isequal(roundedValueToTest,0.97));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));


%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

% Load some test data 
dataSetNumber = 1; % Two polytopes with clear space right down middle

[pointsWithData, start, finish, vGraph, polytopes, goodAxis] = fcn_INTERNAL_loadExampleData(dataSetNumber);
mode = '2d';
plottingOptions.axis = goodAxis;
plottingOptions.selectedFromToToPlot = [1 6];
plottingOptions.filename = 'dilationAnimation.gif'; % Specify the output file name

% Call the function
dilation_robustness_matrix = ...
    fcn_VGraph_generateDilationRobustnessMatrix(...
    pointsWithData, start, finish, vGraph, mode, polytopes,...
    (plottingOptions), (-1));

% Check variable types
assert(isnumeric(dilation_robustness_matrix));

% Check variable sizes
Npoints = size(vGraph,1);
assert(size(dilation_robustness_matrix,1)==Npoints); 
assert(size(dilation_robustness_matrix,1)==Npoints); 

% Check variable values
% 1 is left, 2 is right
valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),1);
roundedValueToTest = round(valueToTest,2);
assert(isequal(roundedValueToTest,0.97));
valueToTest = dilation_robustness_matrix(plottingOptions.selectedFromToToPlot(1), plottingOptions.selectedFromToToPlot(2),2);
roundedValueToTest = round(valueToTest,2);
assert(isequal(roundedValueToTest,0.97));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));


%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

% Load some test data 
dataSetNumber = 1; % Two polytopes with clear space right down middle

[pointsWithData, start, finish, vGraph, polytopes, goodAxis] = fcn_INTERNAL_loadExampleData(dataSetNumber);
mode = '2d';

plottingOptions.axis = goodAxis;
plottingOptions.selectedFromToToPlot = [1 6];
plottingOptions.filename = 'dilationAnimation.gif'; % Specify the output file name

 
Niterations = 1;

% Do calculation without pre-calculation
tic;
for ith_test = 1:Niterations
    % Call the function
    dilation_robustness_matrix = ...
        fcn_VGraph_generateDilationRobustnessMatrix(...
        pointsWithData, start, finish, vGraph, mode, polytopes,...
        (plottingOptions), ([]));
end
slow_method = toc;

% Do calculation with pre-calculation, FAST_MODE on
tic;
for ith_test = 1:Niterations
    % Call the function
    dilation_robustness_matrix = ...
        fcn_VGraph_generateDilationRobustnessMatrix(...
        pointsWithData, start, finish, vGraph, mode, polytopes,...
        (plottingOptions), (-1));
end
fast_method = toc;

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

% Plot results as bar chart
figure(373737);
clf;
hold on;

X = categorical({'Normal mode','Fast mode'});
X = reordercats(X,{'Normal mode','Fast mode'}); % Forces bars to appear in this exact order, not alphabetized
Y = [slow_method fast_method ]*1000/Niterations;
bar(X,Y)
ylabel('Execution time (Milliseconds)')


% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));


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
