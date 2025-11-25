% script_test_fcn_TimeClean_cleanNaming.m
% tests fcn_TimeClean_cleanNaming.m

% REVISION HISTORY:
% 
% 2024_09_09 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally
% 
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Renamed function:
%   % * From: fcn_Data+Clean_cleanNaming
%   % * To: fcn_TimeClean_cleanNaming 
% - Changed in-use function name
%   % * From: fcn_Data+Clean_cleanNaming
%   % * To: fcn_TimeClean_cleanNaming

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)

% Set up the workspace
close all

%% Test 1: Load and clean a single bag file
figNum = 1;
if ~isempty(findobj('Number',figNum))
    figure(figNum);
    clf;
end


% fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData.mat');
fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData2.mat');
load(fullExampleFilePath,'dataStructure')

%%%%%
% Run the command
fid = 1;
Flags = [];
dataStructure_cleanedNames = fcn_TimeClean_cleanNaming(dataStructure, (fid), (Flags), (figNum));

% Check the data
assert(isstruct(dataStructure_cleanedNames))

%%

%% Fail conditions
if 1==0
    %% ERROR situation: 
end



































