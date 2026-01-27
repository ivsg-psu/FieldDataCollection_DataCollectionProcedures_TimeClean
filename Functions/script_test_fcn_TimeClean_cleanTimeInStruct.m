% script_test_fcn_TimeClean_cleanTimeInStruct.m
% tests fcn_TimeClean_cleanTimeInStruct.m

% REVISION HISTORY:
%
% As: script_test_fcn_TimeClean_cleanTime
% 
% 2024_09_09 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally
%
% As: fcn_TimeClean_cleanTimeInStruct
%
% 2025_11_25 by Sean Brennan, sbrennan@psu.edu
% - Renamed function to better distinguish that it is operating only on a
%   % structure input, not as a full directory-level clean
%   % From: fcn_TimeClean_cleanTime
%   % To: fcn_TimeClean_cleanTimeInStruct
%
% 2025_12_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_TimeClean_cleanTimeInStruct
%   % * Updated formatting


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
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: Load and clean a single bag file
figNum = 10001;
titleString = sprintf('DEMO case: basic call with default inputs');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);


% fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData.mat');
% fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData2.mat');
fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData3.mat');

load(fullExampleFilePath,'dataStructure')

%%%%%
% Run the command
fid = 1;
Flags = [];

% List what will be saved
Identifiers = dataStructure.Identifiers;
clear saveFlags
saveFlags.flag_saveMatFile = 0;
saveFlags.flag_saveMatFile_directory = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_saveImages = 0;
saveFlags.flag_saveImages_directory  = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_forceDirectoryCreation = 1;
saveFlags.flag_forceImageOverwrite = 1;
saveFlags.flag_forceMATfileOverwrite = 1;

% List what will be plotted, and the figure numbers
plotFlags.figNum_checkTimeSamplingConsistency_GPSTime = 1111;
plotFlags.figNum_checkTimeSamplingConsistency_ROSTime = 2222;
plotFlags.figNum_fitROSTime2GPSTime                   = 3333;

dataStructure_cleanedNames = fcn_TimeClean_cleanNaming(dataStructure, (fid), (Flags), (-1));
dataStructure_cleanedTime = fcn_TimeClean_cleanTimeInStruct(dataStructure_cleanedNames, (fid), (Flags), (saveFlags), (plotFlags));

% Check the data
assert(isstruct(dataStructure_cleanedNames))


%% Test 2: Load all bag files from one given directory and all subdirectories
% % figNum = 1;
% % if ~isempty(findobj('Number',figNum))
% %     figure(figNum);
% %     clf;
% % end
% 
% % Grab the identifiers. NOTE: this also sets the reference location for
% % plotting.
% Identifiers = fcn_LoadRawDataToMATLAB_identifyDataByScenarioDate('I376ParkwayPitt', '2024-07-10', 1,-1);
% 
% % Specify the bagQueryString
% bagQueryString = 'mapping_van_2024-07-1*'; % The more specific, the better to avoid accidental loading of wrong information
% 
% % Spedify the fid
% fid = 1; % 1 --> print to console
% 
% % Specify the Flags
% Flags = []; 
% 
% % List which directory/directories need to be loaded
% clear rootdirs
% rootdirs{1} = fullfile(cd,'LargeData','2024-07-10');
% % rootdirs{2} = fullfile(cd,'LargeData','2024-07-11');
% 
% % List what will be saved
% saveFlags.flag_saveMatFile = 0;
% saveFlags.flag_saveMatFile_directory = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
% saveFlags.flag_saveImages = 0;
% saveFlags.flag_saveImages_directory  = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
% saveFlags.flag_forceDirectoryCreation = 1;
% saveFlags.flag_forceImageOverwrite = 1;
% saveFlags.flag_forceMATfileOverwrite = 1;
% 
% % List what will be plotted, and the figure numbers
% plotFlags.figNum_checkTimeSamplingConsistency_GPSTime = []; %1111;
% plotFlags.figNum_checkTimeSamplingConsistency_ROSTime = []; %2222;
% 
% % Call the function
% rawDataCellArray = fcn_LoadRawDataToMATLAB_loadRawDataFromDirectories(rootdirs, Identifiers, (bagQueryString), (fid), (Flags), (saveFlags), (plotFlags));
% 
% % Check the results
% assert(iscell(rawDataCellArray));


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

%% TEST case: This one returns nothing since there is no portion of the path in criteria
% figNum = 20001;
% titleString = sprintf('TEST case: This one returns nothing since there is no portion of the path in criteria');
% fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
% figure(figNum); clf;



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
% % Prep a folder for testing
% testFolderNameString = 'Testing_FilenameForTestCase';
% if exist(testFolderNameString,'dir')
%     [SUCCESS,~,~] = rmdir(testFolderNameString,'s');
%     if ~SUCCESS
%         error('Unable to remove Testing_FilenameForTestCase directory');
%     end
% end
% [SUCCESS,~,~] = mkdir(fullfile(pwd,testFolderNameString));
% if ~SUCCESS
%     error('Unable to create Testing_FilenameForTestCase directory');
% end
% 
% % Fill in inputs
% directoryToCheck = fullfile(pwd,testFolderNameString);
% filePrefixString = 'Example_filenameForTestCase_Case9';
% NdigitsInCount = [];
% fileExtensionString = [];
% 
% 
% % Call function
% [fileName, flagSuccessful] = fcn_DebugTools_filenameForTestCase( directoryToCheck, filePrefixString, ...
%          (NdigitsInCount), (fileExtensionString), ([]));
% 
% % sgtitle(titleString, 'Interpreter','none');
% 
% % Check variable types
% assert(ischar(fileName));
% assert(islogical(flagSuccessful));
% 
% % Check variable sizes
% assert(size(fileName,1)==1);
% assert(size(fileName,2)>3);
% assert(size(flagSuccessful,1)==1);
% assert(size(flagSuccessful,1)==1);
% 
% % Check variable values
% assert(flagSuccessful);
% assert(contains(fileName,filePrefixString));
% assert(contains(fileName,'.mat'));
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==figNum));
% 
% % Clean up folder at end
% if exist(testFolderNameString,'dir')
%     [SUCCESS,~,~] = rmdir(testFolderNameString,'s');
%     if ~SUCCESS
%         error('Unable to remove Testing_FilenameForTestCase directory');
%     end
% end
% 
% 
% %% Basic fast mode - NO FIGURE, FAST MODE
% figNum = 80002;
% fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
% figure(figNum); close(figNum);
% 
% % Prep a folder for testing
% testFolderNameString = 'Testing_FilenameForTestCase';
% if exist(testFolderNameString,'dir')
%     [SUCCESS,~,~] = rmdir(testFolderNameString,'s');
%     if ~SUCCESS
%         error('Unable to remove Testing_FilenameForTestCase directory');
%     end
% end
% [SUCCESS,~,~] = mkdir(fullfile(pwd,testFolderNameString));
% if ~SUCCESS
%     error('Unable to create Testing_FilenameForTestCase directory');
% end
% 
% % Fill in inputs
% directoryToCheck = fullfile(pwd,testFolderNameString);
% filePrefixString = 'Example_filenameForTestCase_Case9';
% NdigitsInCount = [];
% fileExtensionString = [];
% 
% 
% % Call function
% [fileName, flagSuccessful] = fcn_DebugTools_filenameForTestCase( directoryToCheck, filePrefixString, ...
%          (NdigitsInCount), (fileExtensionString), (-1));
% 
% % sgtitle(titleString, 'Interpreter','none');
% 
% % Check variable types
% assert(ischar(fileName));
% assert(islogical(flagSuccessful));
% 
% % Check variable sizes
% assert(size(fileName,1)==1);
% assert(size(fileName,2)>3);
% assert(size(flagSuccessful,1)==1);
% assert(size(flagSuccessful,1)==1);
% 
% % Check variable values
% assert(flagSuccessful);
% assert(contains(fileName,filePrefixString));
% assert(contains(fileName,'.mat'));
% 
% % Make sure plot did NOT open up
% figHandles = get(groot, 'Children');
% assert(~any(figHandles==figNum));
% 
% % Clean up folder at end
% if exist(testFolderNameString,'dir')
%     [SUCCESS,~,~] = rmdir(testFolderNameString,'s');
%     if ~SUCCESS
%         error('Unable to remove Testing_FilenameForTestCase directory');
%     end
% end
% 
% %% Compare speeds of pre-calculation versus post-calculation versus a fast variant
% figNum = 80003;
% fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
% figure(figNum);
% close(figNum);
% 
% % Prep a folder for testing
% testFolderNameString = 'Testing_FilenameForTestCase';
% if exist(testFolderNameString,'dir')
%     [SUCCESS,~,~] = rmdir(testFolderNameString,'s');
%     if ~SUCCESS
%         error('Unable to remove Testing_FilenameForTestCase directory');
%     end
% end
% [SUCCESS,~,~] = mkdir(fullfile(pwd,testFolderNameString));
% if ~SUCCESS
%     error('Unable to create Testing_FilenameForTestCase directory');
% end
% 
% % Fill in inputs
% directoryToCheck = fullfile(pwd,testFolderNameString);
% filePrefixString = 'Example_filenameForTestCase_Case9';
% NdigitsInCount = [];
% fileExtensionString = [];
% 
% 
% Niterations = 10;
% 
% % Do calculation without pre-calculation
% tic;
% for ith_test = 1:Niterations
%     % Call function
%     [fileName, flagSuccessful] = fcn_DebugTools_filenameForTestCase( directoryToCheck, filePrefixString, ...
%         (NdigitsInCount), (fileExtensionString), ([]));
% end
% slow_method = toc;
% 
% % Do calculation with pre-calculation, FAST_MODE on
% tic;
% for ith_test = 1:Niterations
%     % Call the function
%     [fileName, flagSuccessful] = fcn_DebugTools_filenameForTestCase( directoryToCheck, filePrefixString, ...
%         (NdigitsInCount), (fileExtensionString), (-1));
% end
% fast_method = toc;
% 
% 
% % Clean up folder at end
% if exist(testFolderNameString,'dir')
%     [SUCCESS,~,~] = rmdir(testFolderNameString,'s');
%     if ~SUCCESS
%         error('Unable to remove Testing_FilenameForTestCase directory');
%     end
% end
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
% 

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

fprintf(1,'Figure: 9XXXXXX: DEMO cases\n');

%% BUG CASE 90001: failure due to GPSfromROS_Time not being found
figNum = 90001;
titleString = sprintf('BUG CASE 90001: failure due to GPSfromROS_Time not being found');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fileName = fullfile(cd,'Data','ExampleData_cleanTimeInStruct_Case90001.mat ');
load(fileName,'rawDataStruct','fid','Flags','saveFlags','plotFlags');
cleanDataStruct = fcn_TimeClean_cleanTimeInStruct(rawDataStruct, (1), (Flags), (saveFlags), (plotFlags));

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

% 
% 
% %% fcn_INTERNAL_loadExampleData
% function tempXYdata = fcn_INTERNAL_loadExampleData(dataSetNumber)
% % Call the function to fill in an array of "path" type
% laps_array = fcn_Laps_fillSampleLaps(-1);
% 
% 
% % Use the last data
% tempXYdata = laps_array{dataSetNumber};
% end % Ends fcn_INTERNAL_loadExampleData















