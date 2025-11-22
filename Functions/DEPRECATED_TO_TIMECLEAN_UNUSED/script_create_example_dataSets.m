% script_create_example_dataSets.m
% creates example data sets used for testing data merging processes

% Revision history
% 2024_09_25 - sbrennan@psu.edu
% -- wrote the code originally

%% Set up the workspace
close all

%% Choose data folder and bag name, read before running the script
% The parsed the data files are saved on OneDrive
% in \IVSG\GitHubMirror\MappingVanDataCollection\ParsedData. To process the
% bag file, please copy file folder to the LargeData folder.


%% Test 1: Load test data from site 1 (requires mat files to be loaded)

% Location for Pittsburgh, site 1
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.44181017');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.76090840');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','327.428');


clear searchIdentifiers
searchIdentifiers.Project = 'PennDOT ADS Workzones'; % This is the project sponsoring the data collection
searchIdentifiers.ProjectStage = 'OnRoad'; % Can be 'Simulation', 'TestTrack', or 'OnRoad'
searchIdentifiers.WorkZoneScenario = 'I376ParkwayPitt'; % Can be one of the ~20 scenarios, see key
searchIdentifiers.WorkZoneDescriptor = 'WorkInRightLaneOfUndividedHighway'; % Can be one of the 20 descriptors, see key
searchIdentifiers.Treatment = 'BaseMap'; % Can be one of 9 options, see key
searchIdentifiers.DataSource = 'MappingVan'; % Can be 'MappingVan', 'AV', 'CV2X', etc. see key
searchIdentifiers.AggregationType = 'PreRun'; % Can be 'PreCalibration', 'PreRun', 'Run', 'PostRun', or 'PostCalibration'

% Specify the bagQueryString
matQueryString = 'mapping_van_2024-07-1*_merged.mat'; % The more specific, the better to avoid accidental loading of wrong information

% Spedify the fid
fid = 1; % 1 --> print to console

% List which directory/directories need to be loaded
clear rootdirs
rootdirs{1} = fullfile(cd,'Data'); % ,'2024-07-10');
% rootdirs{2} = fullfile(cd,'LargeData','2024-07-11');

% List what will be plotted, and the figure numbers
plotFlags.fig_num_plotAllMatTogether = 1111;
plotFlags.fig_num_plotAllMatIndividually = [];

% Call the function
rawDataCellArray = fcn_LoadRawDataToMATLAB_loadMatDataFromDirectories(rootdirs, searchIdentifiers, (matQueryString), (fid), (plotFlags));

% Check the results
assert(iscell(rawDataCellArray));

%% Save the data to examples
dataStructure = rawDataCellArray{1}.rawDataMerged;
fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataNameConsistency.mat');
save(fullExampleFilePath,'dataStructure')

% NOTE: for 'ExampleData_checkDataTimeConsistency.mat', see: fcn_TimeClean_cleanData
% This data set is only going to be valid after some of the data
% consistency checks are finished. In other words, it is a "halfway"
% processed data set and therefore an example is generated in the middle of
% an existing function.

fullExampleFilePath = fullfile(cd,'Data','ExampleData_mergeSensorsByMethod.mat');
save(fullExampleFilePath,'dataStructure')

fullExampleFilePath = fullfile(cd,'Data','ExampleData_findMatchingSensors.mat');
save(fullExampleFilePath,'dataStructure')

fullExampleFilePath = fullfile(cd,'Data','ExampleData_pullDataFromFieldAcrossAllSensors.mat');
save(fullExampleFilePath,'dataStructure')

fullExampleFilePath = fullfile(cd,'Data','ExampleData_plotRawData.mat');
save(fullExampleFilePath,'dataStructure')

fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData.mat');
save(fullExampleFilePath,'dataStructure')
