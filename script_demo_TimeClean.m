%% script_mainDataClean_mappingVan.m
% 
% This main script is used to test the TimeClean functions. It was
% originally written to process and plot the mapping van DGPS data
% collected for the Wahba route on 2019_09_17 with the Penn State Mapping
% Van. It was then part of the main DataClean repo. Once the function list
% became too large, the time-specific cleaning functions were broken off
% in 2025 to create this TimeClean library.
%
% The main purpose of "Time Cleaning" is to correct issues related to the
% alignment, start, stop, and discontinuities in the time stamps associated
% with sensor measurements. There are several different time units in use
% on the mapping van (and in autonomous vehicles in general). Examples
% include:
%
% * GPS time - this is the time recorded during GPS readings, aligned with
% the atomic clock in Boulder Colorado. This time stamp is usually accurate
% to within tens of nanoseconds or better.
%
% * Trigger time - there is a "trigger" system that freezes measurements
% so that they align with GPS time. This is achieved via a trigger box that
% measures the Pulse-Per-Second signal from a GPS receiver, aligns this
% pulse with its internal clock (to within a few microseconds), and then
% outputs user-commanded subdivisions of seconds - 100 pulses a second for
% 100 Hz measurements (encoders for example), 25 pulses a second used for
% camera measurements, etc. Thus, measurements that are "triggered" are,
% within the triggering accuracy (usually microseconds), "locked" to GPS
% time.
%
% * ROS time - the operating system, as data is collected, assigns a time
% stamp to all data. This operating system time has a reported precision of
% nanoseconds, but in actuality is very innacurate. The operating system
% may not update the reported time for long intervals - usually only every 5
% to 15 milliseconds, but sometimes only every 100 to 200 milliseconds. As
% well, compared to the GPS time, the offset or origin of the ROS time
% measurement may be significantly shifted by hundreds of seconds due to
% inaccurate clock settings.
%
% As well, sensors do not all begin recording data simultaneously nor stop
% recording data at the same time. Thus, the start and end of the time
% sequence of sensors - even when they are all on the same time unit - may
% be different. For example, the LiDAR sensors may take many tens of
% seconds to start after encoder sensors have started recording.
%
% 
%
% Authors: Sean Brennan, Liming Gao, Vahan Kazandijian 
% Original Date: 2019_09_24

% REVISION HISTORY:
%
% As: script_mainDataClean_mappingVan
%
% 2019_10_03 by Sean Brennan, sbrennan@psu.edu
% - Functionalization of data loading, error analysis, plotting
% 
% 2019_10_05 by Sean Brennan, sbrennan@psu.edu
% - Additional processing routines added for velocity
% 
% 2019_10_06 to 07 by Sean Brennan, sbrennan@psu.edu
% - worked on time alignment concerns.
% 
% 2019_10_12 by Sean Brennan, sbrennan@psu.edu
% - put in the kinematic regression filter for yawrate.
% 
% 2019_10_14 by Sean Brennan, sbrennan@psu.edu
% - Added sigma calculations for raw data.
% 
% 2019_10_19 by Sean Brennan, sbrennan@psu.edu
% - Added XY delta calculations.
% 
% 2019_10_20 by Sean Brennan, sbrennan@psu.edu
% - Added Bayesian averaging. Collapsed plotting functions.
% 
% 2019_10_23 by Sean Brennan, sbrennan@psu.edu
% - break timeFilteredData into laps instead of only one
% 
% 2019_10_21 by Sean Brennan, sbrennan@psu.edu
% - Added zoom capability. Noticed that sigmas are not passing
%   % correctly for Hemisphere.
% 
% 2019_11_09 by Sean Brennan, sbrennan@psu.edu
% - Fixed errors in standard deviation calculations, fixed
%   % goodIndices, and fixed GPS info showing up in ADIS IMU fields
% 
% 2019_11_15 by Sean Brennan, sbrennan@psu.edu
% - documented program flow, fixed bug in plotting routines,
%   % corrected sigma calculations for yaw based on velocity to include
%   % variance growth between DGPS updates, updated plotting functions to
%   % allow merged data
% 
% 2019_11_17 by Sean Brennan, sbrennan@psu.edu
% - fixed kinematic filtering in clean data
%   % of yaw angle (bug fix).
% 
% 2019_11_19 by Sean Brennan, sbrennan@psu.edu
% - Adding this comment so that Liming can see it :)
% 
% 2019_11_21 by Sean Brennan, sbrennan@psu.edu
% - Continued working on KF signal merging for yaw angle
% 
% 2019_11_22 by Sean Brennan, sbrennan@psu.edu
% - Added time check, as some time vectors are not counting up
% 
% 2019_11_23 by Sean Brennan, sbrennan@psu.edu
% - Fixed plotting to work with new time gaps in NaN from above
% time check.
% 
% 2019_11_24 by Sean Brennan, sbrennan@psu.edu
% - Fixed bugs in plotting (zUp was missing). Added checks for
% NaN values.
% 
% 2019_11_25 by Sean Brennan, sbrennan@psu.edu
% - Fixed bugs in time alignment, where deltaT was wrong.
% 
% 2019_11_26 by Sean Brennan, sbrennan@psu.edu
% - Fixed plotting routines to allow linking during plotting.
% 
% 2019_11_27 by Sean Brennan, sbrennan@psu.edu
% - Worked on KF and Merge functionality. Cleaned up code flow.
% - Added filtering of Sigma values.
% 
% 2019_12_01 by Sean Brennan, sbrennan@psu.edu
% - Did post-processing after merge functions, but before
%   % Kalman filter, adding another function to remove jumps in xData and
%   % yData in Hemisphere, due to DGPS being lost. Fixed a few bugs in the KF
%   % area. Code now runs end to end, producing what appears to be a valid XY
%   % profile. Exports results to KML. (suggest code branch at this point)
% 
% 2020_02_05 by Sean Brennan, sbrennan@psu.edu
% - Fix bugs when DGPS ia active all time
% 
% 2020_05_20 by Sean Brennan, sbrennan@psu.edu
% - fixed bug on the yaw angle plots
% 
% 2020_06_20 by Sean Brennan, sbrennan@psu.edu
% - Add raw data query functions
% 
% 2020_08_30 by Sean Brennan, sbrennan@psu.edu
% - Add database query method
% 
% 2020_10_20 by Sean Brennan, sbrennan@psu.edu
% - Functionalize the database query
% 
% 2021_01_07 by Sean Brennan, sbrennan@psu.edu
% - started new DataClean class funtionality, code works now ONLY
%   % for mapping van data
% 
% 2021_01_08 by Sean Brennan, sbrennan@psu.edu
% - Create a function to query data from database or load from file
% 
% 2021-01-10 by Sean Brennan, sbrennan@psu.edu
% - Integrate the updated database query as a stand-alone function, to clean
%    up large amount of code at top of this script(Done by Liming)
% 
% 2021-01-10  by Sean Brennan, sbrennan@psu.edu
% - Add geoplot capability to results so that we can see XY plots on the map
%   % automatically (Done by Liming)
% 
% 2021_10_15 - Vahan Kazandijian
% - Added ability to process LIDAR time data
% 
% 2022_08_19 by Sean Brennan, sbrennan@psu.edu
% - Added Debug library dependency and usage
% 
% 2023_06_11 by Sean Brennan, sbrennan@psu.edu
% - Automated dependency installs
% - Checked subfields to determine if LIDAR is there
% - Commented out code that doesn't work
% 
% 2023_06_25 by Sean Brennan, sbrennan@psu.edu
% - Added loop-type structure to check data consistency
% - Within the loop, tries to fix inconsistencies
% 
% 2023_06_26 by Sean Brennan, sbrennan@psu.edu
% - Added checks and corrections for duplicated data
% 
% 2023_06_30 by Sean Brennan, sbrennan@psu.edu
% - Added Trigger_Time calculation codes
% 
% 2023_07_01 by Sean Brennan, sbrennan@psu.edu
% - Added code to fix GPS_Time data if not strictly ascending
% 
% 2024_08_29 by Sean Brennan, sbrennan@psu.edu
% - Updated PathClass_v2024_03_14
% - Added PlotRoad_v2024_08_19
% - Added GeometryClass_v2024_08_28
% 
% 2024_09_05 by Sean Brennan, sbrennan@psu.edu
% - Added PlotRoad_v2024_09_04
% - Updated raw load process to push out image grab for data
% - Updated the GPS coordinates of Pittsburgh site 1 to true coordinates
% 
% 2024_09_09 by Sean Brennan, sbrennan@psu.edu
% - Functionalization of cleanData (out of this script, into function)
% - Added fcn_TimeClean_stichStructures
% - deleted fcn_TimeClean_stitchDataStructures (replaced by above)
% - Added PlotRoad_v2024_09_14
% - Added fcn_TimeClean_loadMappingVanDataFromFile
% - Added fcn_TimeClean_loadRawDataFromDirectories
% - Added fcn_TimeClean_mergeRawDataStructures
% - Added fcn_TimeClean_loadMatDataFromDirectories
% - Added reference GPS location for Aliquippa, site 3
% - deleted mainCleanDataStructure - this is now inside cleanData
% - Updated fcn_INTERNAL_clearUtilitiesFromPathAndFolders
% - Updated fcn_TimeClean_renameSensorsToStandardNames
% 
% 2024_10_27 by Sean Brennan, sbrennan@psu.edu
% - Updated DebugTools to 2024_10_27
% 
% 2024_11_05 by Sean Brennan, sbrennan@psu.edu
% - Functionalized out cleanNaming
% - Fixed function checkDataTimeConsistency_GPS and subfunctions
% - Moved INTERNAL functions inside checkDataTimeConsistency_GPS to stand-alone functions 
% 
% 2024_11_07 by Sean Brennan, sbrennan@psu.edu
% - Updated PlotRoad to fix plotting bugs
% 
% 2024_12_16 by Sean Brennan, sbrennan@psu.edu
% - Updated debug library
% 
% 2025_09_27 by Sean Brennan, sbrennan@psu.edu
% - Updated debug library to DebugTools_v2025_09_26
%
% As: script_mainTimeClean_mappingVan
% 
% 2025_09_27 by Sean Brennan, sbrennan@psu.edu
% - Added LoadRawDataToMATLAB_v2025_09_23b
% - Renamed folder, exported to new repo (out of DataClean)
%
% As: script_demo_TimeClean
% 
% 2025_11_22 by Sean Brennan, sbrennan@psu.edu
% - Started modifying rev lists to Markdown format
% - Added auto-installer
% 
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Renamed function:
%   % * From: fcn_Data+Clean_cleanNaming
%   % * To: fcn_TimeClean_cleanNaming 
% - Changed in-use function name
%   % * From: fcn_Data+Clean_cleanNaming
%   % * To: fcn_TimeClean_cleanNaming
% - Deprecated function:
%   % * From: fcn_Data+Clean_checkDataNameConsistency
%   % % To: fcn_TimeClean_checkDataNameConsistency

% Known issues:
%  (as of 2019_10_04) - Odometry on the rear encoders is quite wonky. For
%  some reason, need to do absolute value on speeds - unclear why. And the
%  left encoder is clearly disconnected.
%  UPDATE: encoder reattached in 2019_10_15, but still giving positive/negative flipping errors
%  UPDATE2: encoders rebuilt in 2022 summer to fix this issue
%
%  (as of 2019_11_05) - Need to update variance estimates for GPS mode
%  changes in yaw calculations. Presently assumes 0.01 cm mode.
%
%  (as of 2019_10_13 to 2019_10_17) - Need to confirm signs on the XAccel
%  directions - these look wrong. Suspect that coord system on one is off.
%  They align if plotted right - see fcn_mergeAllXAccelSources - but a
%  coordinate transform is necessary.
%
%  (as of 2019_11_26) - Check that the increments in x and y, replotted as
%  velocities, do not cause violations relative to measured absolute
%  velocity.
%
%  (as of 2019_11_26) - Need to add zUp increments throughout, so that we
%  can KF this variable
%
% (as of 2019_12_09) if run
% find(diff(data_struct.Hemisphere_DGPS.GPSTimeOfWeek)==0), it returns many
% values, whcih means hemisphere did not update its time sometimes? check
% fcn_loadRawData line 255, and maybe add a flag for this type of error


% TO-DO: 
% For each sensor, we need to characterize three time sources:
% 1) GPS_Time - if it has a "true" time source - such as a GPS sensor that reports UTC
% time which is true to the nanosecond level. For sensors that do not have
% this, let's leave this time field empty.
% 2) Triggered_Time - this is the time stamp assuming the data is
% externally triggered. This time is calculated with reference to the trigger source and thus should be
% accurate to microseconds. All sensors should have this time field filled.
% 3) ROS_time - this is the ROS time, which is accurate (usually) to about 10 milliseconds
%
% In later processing steps, we'll need to fix all the data times using the
% above.
%
% Finally, for each of our functions, we need to make the function call
% have a test script with very simple test cases, make sure the function format matches the IVSG
% standard, and make sure that the README.md file is updated.


% *) fix the KF bugs(check page 25 of documents/Route Data Processing Steps_2021_03_04.pptx) for trips_id =7
% *) Go through the functions and add headers / comments to each, and if
% possible, add argument checking (similar to Path class library)
%
% *) Create a Powerpoint document that shows specific examples and outputs
% of each function, so that we know what each subfunction is doing
%
% *) maybe develop some way of indicating the "worst" data result in each
% subfunction, for example where the data is failing - and where the data
% is "good"?
%
% *) Save the "print" results and key plots automatically to a PDF document
% to log the data processing results
%
% *) Create a KF function to hold all the KF merge sub-functions
% *) Add the lidar data process
% *) Add variance and plot at fcn_TimeClean_loadRawData_Lidar ?
% *) Query the data size before query the data. If the data size is too
%    large, split the query into several actions. https://www.postgresqltutorial.com/postgresql-database-indexes-table-size/
%
%             %select table_name, pg_size_pretty( pg_total_relation_size(quote_ident(table_name)) )
%             sqlquery_tablesize = [' select table_name, pg_size_pretty( pg_relation_size(quote_ident(table_name)) )' ...
%                                   ' from information_schema.tables '...
%                                   ' where table_schema = ''public'' '...
%                                   ' order by 2 desc;'];
%             %exec(DB.db_connection,sqlquery_tablesize)
%             sss= fetch(DB.db_connection,sqlquery_tablesize,'DataReturnFormat','table');
%
% *) insert start point to database
%
% 2024_09_28 by Sean Brennan, sbrennan@psu.edu
% - need to change field names in fcn_TimeClean_loadMappingVanDataFromFile so that
% they pass the "standard" names listed in fcn_TimeClean_renameSensorsToStandardNames
% 
% 2024_11_06 by Sean Brennan, sbrennan@psu.edu
% - fix last test case in
% script_test_fcn_TimeClean_checkDataTimeConsistency_GPS. The added error
% that is used for creating a test causes a fail on one of the previous
% flags. The code use to inject failures needs to account for this. (in
% fillTestDataStructure)
% - delete fcn_TimeClean_checkAllSensorsHaveTriggerTime. It can be
% replaced by fcn_TimeClean_checkIfFieldInSensors
% - remove fcn_TimeClean_checkDataTimeConsistency_GPS - started moving
% this code into checkDataTimeConsistency
% - fcn_TimeClean_recalculateTriggerTimes needs better test cases, and
% needs to be formatted correctly

%% Prep the workspace
close all

%% Make sure we are running out of root directory
st = dbstack; 
thisFile = which(st(1).file);
[filepath,name,ext] = fileparts(thisFile);
cd(filepath);

%% Clear paths and folders, if needed
if 1==1
    clear flag_TimeClean_Folders_Initialized
end
if 1==0
    fcn_INTERNAL_clearUtilitiesFromPathAndFolders;
end
if 1==0
    % Resets all paths to factory default
    restoredefaultpath;
end

%% Install dependencies
% Define a universal resource locator (URL) pointing to the repos of
% dependencies to install. Note that DebugTools is always installed
% automatically, first, even if not listed:
clear dependencyURLs dependencySubfolders
ith_repo = 0;

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FieldDataCollection_DataCollectionProcedures_LoadRawDataToMATLAB';
dependencySubfolders{ith_repo} = {'Functions', 'Data'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/PathPlanning_PathTools_PathClassLibrary';
dependencySubfolders{ith_repo} = {'Functions'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FieldDataCollection_GPSRelatedCodes_GPSClass';
dependencySubfolders{ith_repo} = {'Functions'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FeatureExtraction_Association_LineFitting';
dependencySubfolders{ith_repo} = {'Functions'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/PathPlanning_GeomTools_FindCircleRadius';
dependencySubfolders{ith_repo} = {'Functions'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FeatureExtraction_DataClean_BreakDataIntoLaps';
dependencySubfolders{ith_repo} = {'Functions'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FieldDataCollection_VisualizingFieldData_PlotRoad';
dependencySubfolders{ith_repo} = {'Functions','Data'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/PathPlanning_GeomTools_GeomClassLibrary';
dependencySubfolders{ith_repo} = {'Functions','Data'};

%% Do we need to set up the work space?
if ~exist('flag_TimeClean_Folders_Initialized','var')

    % Clear prior global variable flags
    clear global FLAG_*

    % Navigate to the Installer directory
    currentFolder = pwd;
    cd('Installer');
    % Create a function handle
    func_handle = @fcn_DebugTools_autoInstallRepos;

    % Return to the original directory
    cd(currentFolder);

    % Call the function to do the install
    func_handle(dependencyURLs, dependencySubfolders, (0), (-1));

    % Add this function's folders to the path
    this_project_folders = {...
        'Functions','Data'};
    fcn_DebugTools_addSubdirectoriesToPath(pwd,this_project_folders)

    flag_TimeClean_Folders_Initialized = 1;
end


%% Set environment flags that define the ENU origin
% This sets the "center" of the ENU coordinate system for all plotting
% functions

% % Location for Test Track base station
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.86368573');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-77.83592832');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','344.189');

% Location for Pittsburgh, site 1
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.44181017');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.76090840');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','327.428');

% % Location for Site 2, Falling water
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','39.995339');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.445472');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','344.189');

% % Location for Aliquippa, site 3
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.694871');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-80.263755');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','223.294');


%% Set environment flags for plotting
% These are values to set if we are forcing image alignment via Lat and Lon
% shifting, when doing geoplot. This is added because the geoplot images
% are very, very slightly off at the test track, which is confusing when
% plotting data
setenv('MATLABFLAG_PLOTROAD_ALIGNMATLABLLAPLOTTINGIMAGES_LAT','-0.0000008');
setenv('MATLABFLAG_PLOTROAD_ALIGNMATLABLLAPLOTTINGIMAGES_LON','0.0000054');


%% Set environment flags for input checking
% These are values to set if we want to check inputs or do debugging
% setenv('MATLABFLAG_FINDEDGE_FLAG_CHECK_INPUTS','1');
% setenv('MATLABFLAG_FINDEDGE_FLAG_DO_DEBUG','1');
setenv('MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS','1');
setenv('MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG','0');

%% rawData Loading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     _____        _          _                     _ _
%                    |  __ \      | |        | |                   | (_)
%  _ __ __ ___      _| |  | | __ _| |_ __ _  | |     ___   __ _  __| |_ _ __   __ _
% | '__/ _` \ \ /\ / / |  | |/ _` | __/ _` | | |    / _ \ / _` |/ _` | | '_ \ / _` |
% | | | (_| |\ V  V /| |__| | (_| | || (_| | | |___| (_) | (_| | (_| | | | | | (_| |
% |_|  \__,_| \_/\_/ |_____/ \__,_|\__\__,_| |______\___/ \__,_|\__,_|_|_| |_|\__, |
%                                                                              __/ |
%                                                                             |___/
% https://patorjk.com/software/taag/#p=display&f=Big&t=rawData%20Loading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fcn_DebugTools_cprintf('*blue','\tChecking that the practice folders exist: ');
practiceFolderPath = fullfile(pwd,'MappingVanData','ParsedMATLAB_PoseOnly','Merged_00','TestTrack','BaseMap','2024-08-05');
if exist(practiceFolderPath,'dir')
    fcn_DebugTools_cprintf('*Green','PASSED.\n');
else
    fcn_DebugTools_cprintf('*Red','FAILED.\n');
end

if ~exist(practiceFolderPath,'dir')    
    fcn_DebugTools_makeDirectory(practiceFolderPath, -1);
end

%% fcn_TimeClean_loadMappingVanDataFromFile
figNum = 10001;

% Location for Pittsburgh, site 1
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.44181017');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.76090840');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','327.428');

scenarioString = 'BaseMap';
dateString     = '2024-08-05';
searchIdentifiers = fcn_LoadRawDataToMATLAB_identifyDataByScenarioDate(scenarioString, dateString, fid, figNum);


% Specify the bagQueryString
matQueryString = 'mapping_van_*.mat'; % The more specific, the better to avoid accidental loading of wrong information
%matQueryString = 'mapping_van_*_merged.mat'; % The more specific, the better to avoid accidental loading of wrong information

% Spedify the fid
fid = 1; % 1 --> print to console

% % List which directory/directories need to be loaded
% clear rootdirs
% rootdirs{1} = fullfile(cd,'Data'); % ,'2024-07-10');
% % rootdirs{2} = fullfile(cd,'LargeData','2024-07-11');

% Call the function
% searchIdentifiers = [];
rawDataCellArray = fcn_LoadRawDataToMATLAB_loadMatDataFromDirectories(...
    practiceFolderPath, (searchIdentifiers), (matQueryString), (fid), (figNum));



%% fcn_TimeClean_loadRawDataFromDirectories
% imports raw data from bag files contained in a list of specified root
% directories, including all subdirectories. Stores each result into a cell
% array, one for each raw data directory. Produces plots of the data and
% mat files of the data, and can save results to user-chosen directories.
%
% FORMAT:
%
%      rawDataCellArray = fcn_TimeClean_loadRawDataFromDirectories(rootdirs, Identifiers, (bagQueryString), (fid), (Flags), (saveFlags), (plotFlags))


% fig_num = 2;
% figure(fig_num);
% clf;

clear Identifiers
Identifiers.Project = 'PennDOT ADS Workzones'; % This is the project sponsoring the data collection
Identifiers.ProjectStage = 'OnRoad'; % Can be 'Simulation', 'TestTrack', or 'OnRoad'
Identifiers.WorkZoneScenario = 'I376ParkwayPitt'; % Can be one of the ~20 scenarios, see key
Identifiers.WorkZoneDescriptor = 'WorkInRightLaneOfUndividedHighway'; % Can be one of the 20 descriptors, see key
Identifiers.Treatment = 'BaseMap'; % Can be one of 9 options, see key
Identifiers.DataSource = 'MappingVan'; % Can be 'MappingVan', 'AV', 'CV2X', etc. see key
Identifiers.AggregationType = 'PreRun'; % Can be 'PreCalibration', 'PreRun', 'Run', 'PostRun', or 'PostCalibration'
Identifiers.SourceBagFileName =''; % This is filled in automatically for each file

% Specify the bagQueryString
bagQueryString = 'mapping_van_2024-07-1'; % The more specific, the better to avoid accidental loading of wrong information

% Spedify the fid
fid = 1; % 1 --> print to console

% Specify the Flags
Flags = []; 

% List which directory/directories need to be loaded
clear rootdirs
rootdirs{1} = fullfile(cd,'LargeData','2024-07-10');
rootdirs{2} = fullfile(cd,'LargeData','2024-07-11');

% List what will be saved
saveFlags.flag_saveMatFile = 1;
saveFlags.flag_saveMatFile_directory = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_saveImages = 1;
saveFlags.flag_saveImages_directory  = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_forceDirectoryCreation = 1;
saveFlags.flag_forceImageOverwrite = 1;
saveFlags.flag_forceMATfileOverwrite = 1;

% List what will be plotted, and the figure numbers
plotFlags.fig_num_plotAllRawTogether = 1111;
plotFlags.fig_num_plotAllRawIndividually = 2222;

% Call the function
rawDataCellArray = fcn_TimeClean_loadRawDataFromDirectories(rootdirs, Identifiers, (bagQueryString), (fid), (Flags), (saveFlags), (plotFlags));

% Check the results
assert(iscell(rawDataCellArray));

%% fcn_TimeClean_mergeRawDataStructures
% given a cell array of rawData files where the bag files may be in
% sequence, finds the files in sequence and creates merged data structures.
%
% FORMAT:
%
%      [mergedRawDataCellArray, uncommonFieldsCellArray] = fcn_TimeClean_mergeRawDataStructures(rawDataCellArray, (thresholdTimeNearby), (fid), (saveFlags), (plotFlags))

%%%%
% Load the data

% Choose data folder and bag name, read before running the script
% The parsed the data files are saved on OneDrive
% in \IVSG\GitHubMirror\MappingVanDataCollection\ParsedData. To process the
% bag file, please copy file folder to the LargeData folder.

clear Identifiers
Identifiers.Project = 'PennDOT ADS Workzones'; % This is the project sponsoring the data collection
Identifiers.ProjectStage = 'OnRoad'; % Can be 'Simulation', 'TestTrack', or 'OnRoad'
Identifiers.WorkZoneScenario = 'I376ParkwayPitt'; % Can be one of the ~20 scenarios, see key
Identifiers.WorkZoneDescriptor = 'WorkInRightLaneOfUndividedHighway'; % Can be one of the 20 descriptors, see key
Identifiers.Treatment = 'BaseMap'; % Can be one of 9 options, see key
Identifiers.DataSource = 'MappingVan'; % Can be 'MappingVan', 'AV', 'CV2X', etc. see key
Identifiers.AggregationType = 'PreRun'; % Can be 'PreCalibration', 'PreRun', 'Run', 'PostRun', or 'PostCalibration'
Identifiers.SourceBagFileName =''; % This is filled in automatically for each file

% Specify the bagQueryString
bagQueryString = 'mapping_van_2024-07-1'; % The more specific, the better to avoid accidental loading of wrong information

% Spedify the fid
fid = 0; % 1 --> print to console

% Specify the Flags
Flags = []; 

% List which directory/directories need to be loaded
clear rootdirs
rootdirs{1} = fullfile(cd,'LargeData','2024-07-10');
% rootdirs{2} = fullfile(cd,'LargeData','2024-07-11');

% List what will be saved
saveFlags.flag_saveMatFile = 0;
saveFlags.flag_saveMatFile_directory = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_saveImages = 0;
saveFlags.flag_saveImages_directory  = fullfile(cd,'Data','RawData',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_forceDirectoryCreation = 0;
saveFlags.flag_forceImageOverwrite = 0;
saveFlags.flag_forceMATfileOverwrite = 0;

% List what will be plotted, and the figure numbers
plotFlags.fig_num_plotAllRawTogether = [];
plotFlags.fig_num_plotAllRawIndividually = [];

% Call the data loading function
rawDataCellArray = fcn_TimeClean_loadRawDataFromDirectories(rootdirs, Identifiers, (bagQueryString), (fid), (Flags), (saveFlags), (plotFlags));


%%%%%%%%%%%%%%
% Prepare for merging
% Specify the nearby time
thresholdTimeNearby = 2;

% Spedify the fid
fid = 1; % 1 --> print to console

% List what will be saved
saveFlags.flag_saveMatFile = 1;
saveFlags.flag_saveMatFile_directory = fullfile(cd,'Data','RawDataMerged',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_saveImages = 1;
saveFlags.flag_saveImages_directory  = fullfile(cd,'Data','RawDataMerged',Identifiers.ProjectStage,Identifiers.WorkZoneScenario);
saveFlags.flag_saveImages_name = cat(2,Identifiers.WorkZoneScenario,'_merged');
saveFlags.flag_forceDirectoryCreation = 1;
saveFlags.flag_forceImageOverwrite = 1;
saveFlags.flag_forceMATfileOverwrite = 1;

% List what will be plotted, and the figure numbers
plotFlags.fig_num_plotAllMergedTogether = 1111;
plotFlags.fig_num_plotAllMergedIndividually = 2222;
    
plotFlags.mergedplotFormat.LineStyle = '-';
plotFlags.mergedplotFormat.LineWidth = 2;
plotFlags.mergedplotFormat.Marker = 'none';
plotFlags.mergedplotFormat.MarkerSize = 5;


% Call the function
[mergedRawDataCellArray, uncommonFieldsCellArray] = fcn_TimeClean_mergeRawDataStructures(rawDataCellArray, (thresholdTimeNearby), (fid), (saveFlags), (plotFlags));

% Check the results
assert(iscell(mergedRawDataCellArray));

%% fcn_TimeClean_loadMatDataFromDirectories
% imports MATLAB data from files contained in specified root
% directories, including all subdirectories. Stores each result into a cell
% array, one for each mat data file. Produces plots of the data via
% optional plotting flags.
%
% FORMAT:
%
%     matDataCellArray = fcn_TimeClean_loadMatDataFromDirectories(rootdirs, (searchIdentifiers), (matQueryString), (fid), (plotFlags));
%

% Location for Pittsburgh, site 1
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.44181017');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.76090840');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','327.428');

% List which directory/directories need to be loaded
clear rootdirs
rootdirs{1} = fullfile(cd,'Data'); % ,'2024-07-10');
% rootdirs{2} = fullfile(cd,'LargeData','2024-07-11');



clear searchIdentifiers
searchIdentifiers.Project = 'PennDOT ADS Workzones'; % This is the project sponsoring the data collection
searchIdentifiers.ProjectStage = 'OnRoad'; % Can be 'Simulation', 'TestTrack', or 'OnRoad'
searchIdentifiers.WorkZoneScenario = 'I376ParkwayPitt'; % Can be one of the ~20 scenarios, see key
searchIdentifiers.WorkZoneDescriptor = 'WorkInRightLaneOfUndividedHighway'; % Can be one of the 20 descriptors, see key
searchIdentifiers.Treatment = 'BaseMap'; % Can be one of 9 options, see key
searchIdentifiers.DataSource = 'MappingVan'; % Can be 'MappingVan', 'AV', 'CV2X', etc. see key
searchIdentifiers.AggregationType = 'PreRun'; % Can be 'PreCalibration', 'PreRun', 'Run', 'PostRun', or 'PostCalibration'

% Specify the bagQueryString
matQueryString = 'mapping_van_2024-07-1*_merged'; % The more specific, the better to avoid accidental loading of wrong information

% Spedify the fid
fid = 1; % 1 --> print to console



% List what will be plotted, and the figure numbers
plotFlags.fig_num_plotAllMatTogether = 1111;
plotFlags.fig_num_plotAllMatIndividually = [];

% Call the function
rawDataCellArray = fcn_TimeClean_loadMatDataFromDirectories(rootdirs, searchIdentifiers, (matQueryString), (fid), (plotFlags));

% Check the results
assert(iscell(rawDataCellArray));

%% Querying from storage directories

% List which directory/directories need to be loaded
DriveRoot = 'F:\Adrive';
rawBagRoot                  = cat(2,DriveRoot,'\MappingVanData\RawBags');
poseOnlyParsedBagRoot       = cat(2,DriveRoot,'\MappingVanData\ParsedBags_PoseOnly');
fullParsedBagRoot           = cat(2,DriveRoot,'\MappingVanData\ParsedBags');
parsedMATLAB_PoseOnly       = cat(2,DriveRoot,'\MappingVanData\ParsedMATLAB_PoseOnly\RawData');
parsedMATLAB_PoseOnlyMerged = cat(2,DriveRoot,'\MappingVanData\ParsedMATLAB_PoseOnly\RawDataMerged');
mergedTimeCleaned           = cat(2,DriveRoot,'\MappingVanData\ParsedMATLAB_PoseOnly\Merged_01_TimeCleaned');
mergedDataCleaned           = cat(2,DriveRoot,'\MappingVanData\ParsedMATLAB_PoseOnly\Merged_02_DataCleaned');
mergedKalmanFiltered        = cat(2,DriveRoot,'\MappingVanData\ParsedMATLAB_PoseOnly\Merged_03_KalmanFiltered');

% extensionFolder            = '\TestTrack\'; 
extensionFolder            = '\'; 

rawBagSearchDirectory                = cat(2,rawBagRoot,extensionFolder);
poseOnlyParsedBagDirectory           = cat(2,poseOnlyParsedBagRoot,extensionFolder);
fullParsedBagRootDirectory           = cat(2,fullParsedBagRoot,extensionFolder);
parsedMATLAB_PoseOnlyDirectory       = cat(2,parsedMATLAB_PoseOnly,extensionFolder);
parsedMATLAB_PoseOnlyMergedDirectory = cat(2,parsedMATLAB_PoseOnlyMerged,extensionFolder);
mergedTimeCleanedDirectory           = cat(2,mergedTimeCleaned,extensionFolder);
mergedDataCleanedDirectory           = cat(2,mergedDataCleaned,extensionFolder);
mergedKalmanFilteredDirectory        = cat(2,mergedKalmanFiltered,extensionFolder);


% Make sure folders exist!
fcn_INTERNAL_confirmDirectoryExists(rawBagSearchDirectory);
fcn_INTERNAL_confirmDirectoryExists(poseOnlyParsedBagDirectory);
fcn_INTERNAL_confirmDirectoryExists(fullParsedBagRootDirectory);
fcn_INTERNAL_confirmDirectoryExists(parsedMATLAB_PoseOnlyDirectory);
fcn_INTERNAL_confirmDirectoryExists(parsedMATLAB_PoseOnlyMergedDirectory);
fcn_INTERNAL_confirmDirectoryExists(mergedTimeCleanedDirectory);
fcn_INTERNAL_confirmDirectoryExists(mergedDataCleanedDirectory);
fcn_INTERNAL_confirmDirectoryExists(mergedKalmanFilteredDirectory);


%%%
% Query the raw bags available for parsing within rawBagSearchDirectory
fileQueryString = '*.bag'; % The more specific, the better to avoid accidental loading of wrong information
flag_fileOrDirectory = 0; % 0 --> file, 1 --> directory
directory_allRawBagFiles = fcn_DebugTools_listDirectoryContents({rawBagSearchDirectory}, (fileQueryString), (flag_fileOrDirectory), (-1));


% % % if 1==0
% % %     % Print the results?
% % %     fprintf(1,'ALL RAW BAG FILES FOUND IN FOLDER AND SUBFOLDERS OF: %s',rawBagSearchDirectory);
% % %     fcn_DebugTools_printDirectoryListing(directory_allRawBagFiles, ([]), ([]), (1));
% % % end
% % % 
% % % %%%
% % % % Summarize the file sizes
% % % totalBytes = fcn_DebugTools_countBytesInDirectoryListing(directory_allRawBagFiles, (1:length(directory_allRawBagFiles)));
% % % estimatedPoseOnlyParseTime = totalBytes/bytesPerSecondPoseOnly;
% % % estimatedFullParseTime = totalBytes/bytesPerSecondFull;
% % % 
% % % timeInSeconds = estimatedPoseOnlyParseTime;
% % % fprintf(1,'\nTotal estimated time to process these %.0f bags, pose only: %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));
% % % timeInSeconds = estimatedFullParseTime;
% % % fprintf(1,'Total estimated time to process these %.0f bags, full (no cameras): %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));
% % % 

% % % %%%
% % % % Extract all the bag file names
% % % bagFileNames = {directory_allRawBagFiles.name}';
% % % 
% % % % Pick only the ones we want
% % % filesToKeep = ~contains(bagFileNames,'Ouster') .* ~contains(bagFileNames,'velodyne') .* ~contains(bagFileNames,'cameras');
% % % goodFileindicies = find(filesToKeep);
% % % bagFileNamesSelected = bagFileNames(goodFileindicies);
% % % directory_selectedRawBagFiles = directory_allRawBagFiles(goodFileindicies);
% % % 
% % % %%%
% % % % Summarize the file sizes?
% % % 
% % % fprintf(1,'\n\nSELECTED FILES: \n');
% % % fcn_DebugTools_printDirectoryListing(directory_selectedRawBagFiles, ([]), ([]), (1));
% % % 
% % % totalBytes = fcn_DebugTools_countBytesInDirectoryListing(directory_selectedRawBagFiles, (1:length(directory_selectedRawBagFiles)));
% % % estimatedPoseOnlyParseTime = totalBytes/bytesPerSecondPoseOnly;
% % % estimatedFullParseTime = totalBytes/bytesPerSecondFull;
% % % 
% % % timeInSeconds = estimatedPoseOnlyParseTime;
% % % fprintf(1,'Total estimated time to process these %.0f bags, pose only: %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));
% % % timeInSeconds = estimatedFullParseTime;
% % % fprintf(1,'Total estimated time to process these %.0f bags, full (no cameras): %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));
% % % 
% % % 
% % % %%%%
% % % % Find which files were either Pose parsed, Full parsed, 
% % % flag_matchingType = 2; % file to folder
% % % typeExtension = '.bag';
% % % flags_fileWasPoseParsed = fcn_DebugTools_compareDirectoryListings(directory_selectedRawBagFiles, rawBagRoot, poseOnlyParsedBagRoot, (flag_matchingType), (typeExtension), (1));
% % % flags_fileWasFullParsed = fcn_DebugTools_compareDirectoryListings(directory_selectedRawBagFiles, rawBagRoot, fullParsedBagRoot,     (flag_matchingType), (typeExtension), (1));
% % % flag_matchingType = 1; % file to file
% % % typeExtension = '.m';
% % % flags_fileWasMATLABloaded = fcn_DebugTools_compareDirectoryListings(directory_selectedRawBagFiles, rawBagRoot, parsedMATLAB_PoseOnlyDirectory,     (flag_matchingType), (typeExtension), (1));
% % % typeExtension = 'merged.m';
% % % flags_fileWasMATLABmerged = fcn_DebugTools_compareDirectoryListings(directory_selectedRawBagFiles, rawBagRoot, parsedMATLAB_PoseOnlyMergedDirectory,     (flag_matchingType), (typeExtension), (1));
% % % 

%%%
% Query the merged mat files available for cleaning
fileQueryString = '*.mat'; % The more specific, the better to avoid accidental loading of wrong information
flag_fileOrDirectory = 0; % 0 --> file, 1 --> directory
directory_allMergedMatFiles = fcn_DebugTools_listDirectoryContents({parsedMATLAB_PoseOnlyMergedDirectory}, (fileQueryString), (flag_fileOrDirectory), (-1));


if 1==1
    % Print the results?
    fprintf(1,'ALL MERGED MAT FILES FOUND IN FOLDER AND SUBFOLDERS OF: %s',parsedMATLAB_PoseOnlyMergedDirectory);
    fcn_DebugTools_printDirectoryListing(directory_allMergedMatFiles, ([]), ([]), (1));
end


%%%
% Extract all the merged mat file names
mergedMatFileNames = {directory_allMergedMatFiles.name}';

% Pick only the ones we want
filesToKeep = ~contains(mergedMatFileNames,'Ouster') .* ~contains(mergedMatFileNames,'velodyne') .* ~contains(mergedMatFileNames,'cameras');
goodFileindicies = find(filesToKeep);
mergedMatFileNamesSelected = mergedMatFileNames(goodFileindicies);
directory_selectedMergedMatFiles = directory_allMergedMatFiles(goodFileindicies);

%%%
% Summarize the file sizes?

fprintf(1,'\n\nSELECTED FILES: \n');
fcn_DebugTools_printDirectoryListing(directory_selectedMergedMatFiles, ([]), ([]), (1));

% totalBytes = fcn_DebugTools_countBytesInDirectoryListing(directory_selectedRawBagFiles, (1:length(directory_selectedRawBagFiles)));
% estimatedPoseOnlyParseTime = totalBytes/bytesPerSecondPoseOnly;
% estimatedFullParseTime = totalBytes/bytesPerSecondFull;
% 
% timeInSeconds = estimatedPoseOnlyParseTime;
% fprintf(1,'Total estimated time to process these %.0f bags, pose only: %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));
% timeInSeconds = estimatedFullParseTime;
% fprintf(1,'Total estimated time to process these %.0f bags, full (no cameras): %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));


%%%%
% Find which files were either time cleaned, data cleaned, or KF cleaned 
flag_matchingType = 1; % same to same
typeExtension = 'merged.mat';
flags_mergedWasTimeCleaned    = fcn_DebugTools_compareDirectoryListings(directory_selectedMergedMatFiles, parsedMATLAB_PoseOnlyMerged, mergedTimeCleaned, (flag_matchingType), (typeExtension), (1));
flags_mergedWasDataCleaned    = fcn_DebugTools_compareDirectoryListings(directory_selectedMergedMatFiles, parsedMATLAB_PoseOnlyMerged, mergedDataCleaned, (flag_matchingType), (typeExtension), (1));
flags_mergedWasKalmanFiltered = fcn_DebugTools_compareDirectoryListings(directory_selectedMergedMatFiles, parsedMATLAB_PoseOnlyMerged, mergedKalmanFiltered, (flag_matchingType), (typeExtension), (1));


 

%%%%
% Print the results
NcolumnsToPrint = 4;
cellArrayHeaders = cell(NcolumnsToPrint,1);
cellArrayHeaders{1} = 'MERGED NAME                                   ';
cellArrayHeaders{2} = 'TIME Cleaned?';
cellArrayHeaders{3} = 'DATA Cleaned?';
cellArrayHeaders{4} = 'Kalman Filt? ';
cellArrayValues = [...
    mergedMatFileNamesSelected, ...
    fcn_DebugTools_convertBinaryToYesNoStrings(flags_mergedWasTimeCleaned), ...
    fcn_DebugTools_convertBinaryToYesNoStrings(flags_mergedWasDataCleaned), ...
    fcn_DebugTools_convertBinaryToYesNoStrings(flags_mergedWasKalmanFiltered)
    ];

fid = 1;
fcn_DebugTools_printNumeredDirectoryList(directory_selectedMergedMatFiles, cellArrayHeaders, cellArrayValues, (parsedMATLAB_PoseOnlyMerged), (fid))



%%
% Determine type of processing

% What type of processing to do?
flag_keepGoing = 1;
if 1==flag_keepGoing
    flag_keepGoing = 0;
    flag_goodReply = 0;
    while 0==flag_goodReply
        fprintf(1,'\nWhat type of processing should be done?\n')
        fprintf(1,'\t1. Time cleaning\n');
        fprintf(1,'\t2. Data cleaning.\n')
        fprintf(1,'\t3. Kalman filtering.\n')
        fprintf(1,'\tQ: Quit.\n')
        processingType = input('Selection? [default = 1]:','s');
        if isempty(processingType)
            processingType = '1';
            flag_goodReply = 1;
        else
            processingType = lower(processingType);
            if isscalar(processingType) && (strcmp(processingType,'1')||strcmp(processingType,'2')||strcmp(processingType,'3')||strcmp(processingType,'q'))
                flag_goodReply = 1;
            end
        end
    end
    fprintf(1,'Selection chosen: %s --> ',processingType);
    if strcmp(processingType,'1')
        fprintf(1,'Time cleaning\n');
        flags_toCheck = flags_mergedWasTimeCleaned;
        destinationRootFolder = mergedTimeCleaned;
        flag_keepGoing = 1;
    elseif strcmp(processingType,'2')
        fprintf(1,'Data cleaning\n');
        flags_toCheck = flags_mergedWasDataCleaned;
        destinationRootFolder = mergedDataCleaned;        
        flag_keepGoing = 1;
    elseif strcmp(processingType,'3')
        fprintf(1,'Kalman filtering\n');
        flags_toCheck = flags_mergedWasKalmanFiltered;
        destinationRootFolder = mergedKalmanFiltered;        
        flag_keepGoing = 1;
    else
        fprintf(1,'Quitting\n');
    end
end


%%% What numbers of files to parse?
if 1==flag_keepGoing
    [flag_keepGoing, startingIndex, endingIndex] = fcn_DebugTools_queryNumberRange(flags_toCheck, (' of the file(s) to parse'), (1), (directory_selectedMergedMatFiles), (1));
end

%%% Estimate the time it takes to process?
if 1==0  % 1==flag_keepGoing

    if strcmp(processingType,'1')
        bytesPerSecond = bytesPerSecondTimeClean;
    elseif strcmp(processingType,'2')
        bytesPerSecond = bytesPerSecondDataClean;
    elseif strcmp(processingType,'3')
        bytesPerSecond = bytesPerSecondKalmanFilter;
    end
    indexRange = (startingIndex:endingIndex);

    [flag_keepGoing, timeEstimateInSeconds] = fcn_DebugTools_confirmTimeToProcessDirectory(directory_selectedMergedMatFiles, bytesPerSecond, (indexRange),(1));
end



%%
% Process the files

if 1==flag_keepGoing

    alltstart = tic;
    Ndone = 0;
    NtoProcess = length(startingIndex:endingIndex);
    for ith_matFile = startingIndex:endingIndex
        Ndone = Ndone + 1;
        sourceFolderName     = directory_selectedMergedMatFiles(ith_matFile).folder;
        thisFolder           = extractAfter(sourceFolderName,parsedMATLAB_PoseOnlyMerged);
        thisBytes            = directory_selectedMergedMatFiles(ith_matFile).bytes;

        destinationFolder    = cat(2,destinationRootFolder,thisFolder);

        thisFileFullName = directory_selectedMergedMatFiles(ith_matFile).name;
        thisFile = extractBefore(thisFileFullName,'.mat');

        fprintf(1,'\n\nProcessing file: %d (file %d of %d)\n', ith_matFile, Ndone,NtoProcess);
        fprintf(1,'Initiating processing for file: %s\n',thisFile);
        fprintf(1,'Pulling from folder: %s\n',sourceFolderName);
        fprintf(1,'Pushing to folder:   %s\n',destinationFolder);

        tstart = tic;



        %%%%%%%%%%%%%%%%%%%%%%%
        % Location for Pittsburgh, site 1
        setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.44181017');
        setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.76090840');
        setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','327.428');


        % Specify the bagQueryString
        matQueryString = cat(2,thisFile,'*.mat'); % The more specific, the better to avoid accidental loading of wrong information

        % List what will be plotted, and the figure numbers
        plotFlags.fig_num_plotAllMatTogether = 1111;
        plotFlags.fig_num_plotAllMatIndividually = [];

        % Call the function
        sourceDataCellArray = fcn_TimeClean_loadMatDataFromDirectories({sourceFolderName}, [], (matQueryString), (1), (plotFlags));

        if strcmp(processingType,'1')
            fprintf(1,'Time cleaning\n');
            ref_baseStationLLA = [40.44181017, -79.76090840, 327.428]; % Pittsburgh (NOTE: not used)
            fig_num  = 1;
            cleanDataStruct = fcn_TimeClean_cleanData(sourceDataCellArray{1}.rawDataMerged, (ref_baseStationLLA), (fid), ([]), (fig_num));
        elseif strcmp(processingType,'2')
            fprintf(1,'Data cleaning\n');
            flags_toCheck = flags_mergedWasDataCleaned;
            destinationRootFolder = mergedDataCleaned;
            flag_keepGoing = 1;
        elseif strcmp(processingType,'3')
            fprintf(1,'Kalman filtering\n');
            flags_toCheck = flags_mergedWasKalmanFiltered;
            destinationRootFolder = mergedKalmanFiltered;
            flag_keepGoing = 1;
        else
            fprintf(1,'Quitting\n');
        end

        %%%%%%%

        
        telapsed = toc(tstart);

        totalBytes = directory_selectedMergedMatFiles(ith_matFile).bytes;
        predictedFileTime =  totalBytes/bytesPerSecond;
        fprintf(1,'Processing speed, predicted: %.0f seconds versus actual: %.0f seconds\n',predictedFileTime, telapsed);
        fprintf(1,'Actual bytes per second: %.0f \n',thisBytes/telapsed);
    end
    alltelapsed = toc(alltstart);

    % Check prediction
    fprintf(1,'\nTotal time to process: \n');
    if timeInSeconds<100
        fprintf(1,'\tEstimated: %.2f seconds \n', timeInSeconds)
        fprintf(1,'\tActual:    %.2f seconds \n', alltelapsed);
    elseif timeInSeconds>=100 && timeInSeconds<3600
        fprintf(1,'\tEstimated: %.2f seconds (e.g. %.2f minutes)\n',timeInSeconds, timeInSeconds/60);
        fprintf(1,'\tActual:    %.2f seconds (e.g. %.2f minutes)\n',alltelapsed, alltelapsed/60);
    else
        fprintf(1,'\tEstimated: %.2f seconds (e.g. %.2f minutes, or %.2f hours)\n',timeInSeconds, timeInSeconds/60, timeInSeconds/3600);
        fprintf(1,'\tActual:    %.2f seconds (e.g. %.2f minutes, or %.2f hours)\n',alltelapsed, alltelapsed/60, alltelapsed/3600);
    end

end

%% Conditional loading from the database

% NOT implemented yet

% % % % ======================= Load the raw data =========================
% % % % This data will have outliers, be unevenly sampled, have multiple and
% % % % inconsistent measurements of the same variable. In other words, it is the
% % % % raw data. It can be loaded either from a database or a file - details are
% % % % in the function below.
% % % 
% % % % For debugging, to force the if statement to be run
% % % clear dataset
% % % 
% % % flag.DBquery = false; %true; %set to true to query raw data from database 
% % % flag.DBinsert = false; %set to true to insert cleaned data to cleaned data database
% % % flag.SaveQueriedData = true; % 
% % % 
% % % % clear dataset
% % % if ~exist('dataset','var')
% % %     if flag.DBquery == true
% % %         % Load the raw data from the database
% % %         queryCondition = 'trip'; % Default: 'trip'. raw data can be queried by 'trip', 'date', or 'driver'
% % %         [rawData,trip_name,trip_id_cleaned,base_station,Hemisphere_gps_week] = fcn_TimeClean_queryRawDataFromDB(flag.DBquery,'mapping_van_raw',queryCondition); %#ok<ASGLU> % more query condition can be set in the function
% % %     else
% % %         % Load the raw data from file, and if a fig_num is given, save the
% % %         % image to a PNG file with same name as the bag file
% % %         [rawData, subPathStrings] = fcn_TimeClean_loadMappingVanDataFromFile(largeDataBagPath, bagName, fid,[],rawdata_fig_num);
% % % 
% % %         % Save the mat file to the Data folder
% % % 
% % % 
% % %         %%%%%
% % %         % Save the image file to the Data folder
% % % 
% % %         % Make sure bagName is good
% % %         if contains(bagName,'.')
% % %             bagName_clean = extractBefore(bagName,'.');
% % %         else
% % %             bagName_clean = bagName;
% % %         end
% % % 
% % %         % Save the image to file
% % %         Image = getframe(gcf);
% % %         image_fname = cat(2,char(bagName_clean),'.png');
% % %         imagePath = fullfile(pwd, 'ImageSummaries',image_fname);
% % %         if 2~=exist(imagePath,'file')
% % %             imwrite(Image.cdata, imagePath);
% % %         end
% % % 
% % % 
% % %         % Prepare the dataset for the "cleaning" process by loading rawData
% % %         % into the starting dataset variable
% % %         dataset{1} = rawData;
% % %     end
% % % else
% % %     if length(dataset)>1
% % %         % Keep just the first dataset
% % %         temp{1} = dataset{1};
% % %         dataset = temp;
% % %     end
% % % end

%% Main Cleaning Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  __  __       _          _____ _                  _               ______                _   _
% |  \/  |     (_)        / ____| |                (_)             |  ____|              | | (_)
% | \  / | __ _ _ _ __   | |    | | ___  __ _ _ __  _ _ __   __ _  | |__ _   _ _ __   ___| |_ _  ___  _ __
% | |\/| |/ _` | | '_ \  | |    | |/ _ \/ _` | '_ \| | '_ \ / _` | |  __| | | | '_ \ / __| __| |/ _ \| '_ \
% | |  | | (_| | | | | | | |____| |  __/ (_| | | | | | | | | (_| | | |  | |_| | | | | (__| |_| | (_) | | | |
% |_|  |_|\__,_|_|_| |_|  \_____|_|\___|\__,_|_| |_|_|_| |_|\__, | |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|
%                                                            __/ |
%                                                           |___/
% https://patorjk.com/software/taag/#p=display&f=Big&t=Main%20Cleaning%20Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_TimeClean_cleanNaming
% given a raw data structure, cleans field names to match expected
% standards for data cleaning methods
%
% FORMAT:
%
%      cleanDataStruct = fcn_TimeClean_cleanNaming(rawDataStruct, (fid), (Flags), (fig_num))
%
% INPUTS:
%
%      rawDataStruct: a  data structure containing data fields filled for
%      each ROS topic. If multiple bag files are specified, a cell array of
%      data structures is returned.
%
%      (OPTIONAL INPUTS)
%
%      fid: the fileID where to print. Default is 1, to print results to
%      the console.
%
%      Flags: a structure containing key flags to set the process. The
%      defaults, and explanation of each, are below:
%
%           Flags.flag_do_load_sick = 0; % Loads the SICK LIDAR data
%           Flags.flag_do_load_velodyne = 0; % Loads the Velodyne LIDAR
%           Flags.flag_do_load_cameras = 0; % Loads camera images
%           Flags.flag_select_scan_duration = 0; % Lets user specify scans from Velodyne
%           Flags.flag_do_load_GST = 0; % Loads the GST field from Sparkfun GPS Units          
%           Flags.flag_do_load_VTG = 0; % Loads the VTG field from Sparkfun GPS Units
%
%      fig_num: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
% OUTPUTS:
%
%      cleanDataStruct: a  data structure containing data fields filled for
%      each ROS topic, in name-cleaned form - e.g. all the field names are
%      compliant
%
%     subPathStrings: a string for each rawData load indicating the subpath
%     where the data was obtained

fig_num = 1;
if ~isempty(findobj('Number',fig_num))
    figure(fig_num);
    clf;
end


% fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData.mat');
fullExampleFilePath = fullfile(cd,'Data','ExampleData_cleanData2.mat');
load(fullExampleFilePath,'dataStructure')

%%%%%
% Run the command
fid = 1;
Flags = [];
dataStructure_cleanedNames = fcn_TimeClean_cleanNaming(dataStructure, (fid), (Flags), (fig_num));

% Check the data
assert(isstruct(dataStructure_cleanedNames))




%% Supporting Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              _   _               ______                _   _
%  / ____|                            | | (_)             |  ____|              | | (_)
% | (___  _   _ _ __  _ __   ___  _ __| |_ _ _ __   __ _  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  \___ \| | | | '_ \| '_ \ / _ \| '__| __| | '_ \ / _` | |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  ____) | |_| | |_) | |_) | (_) | |  | |_| | | | | (_| | | |  | |_| | | | | (__| |_| | (_) | | | \__ \
% |_____/ \__,_| .__/| .__/ \___/|_|   \__|_|_| |_|\__, | |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%              | |   | |                            __/ |
%              |_|   |_|                           |___/
% https://patorjk.com/software/taag/#p=display&f=Big&t=Supporting%20Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_TimeClean_pullDataFromFieldAcrossAllSensors
% Pulls a given field's data from all sensors. If the field does not exist,
% it returns an empty array for that field
%
% FORMAT:
%
%      dataArray = fcn_TimeClean_pullDataFromFieldAcrossAllSensors(dataStructure,field_string,(sensor_identifier_string), (entry_location), (fid), (fig_num))
%

% Grab example data
fid = 1;
date = '2024-07-10';
bagName = "mapping_van_2024-07-10-19-41-49_0";
largeDataBagPath = fullfile(pwd, 'LargeData',date, bagName);

[rawData, ~] = fcn_TimeClean_loadMappingVanDataFromFile(largeDataBagPath, bagName, fid,[], []);

dataStructure = rawData;
field_string = 'GPS_Time'; % Get the GPS_Time
sensor_identifier_string = 'GPS'; % Only keep sensors that have GPS in name
entry_location = 'first_row'; % Keep only the first sensor value
fid = 1;

% Call the function
[dataArray,sensorNames] = fcn_TimeClean_pullDataFromFieldAcrossAllSensors(dataStructure,field_string,(sensor_identifier_string), (entry_location), (fid));

% Check that results are all cell arrays
assert(iscell(dataArray))
assert(iscell(sensorNames))

% Assert they have same length
assert(length(dataArray)==length(sensorNames))

%% fcn_TimeClean_stichStructures
% given a cell array of structures, merges all the fields that are common
% among the structures, and lists also the fields that are not common
% across all. A "merge" consists of a vertical concatenation of data, e.g.
% the data rows from structure 1 are stacked above structure 2 which are
% stacked above structure 3, etc. If the data are scalars, the scalars must
% match for all the structures - otherwise they are considered not common.
%
% To merge structures, the following must be true:
%
%      all the merged fields must have the same field names
%
%      all the field entries must all be 1x1 scalars with the same scalar
%      value, OR all the field entries must be NxM vectors where M is the
%      same across structures, but N may be different across the structures
%      and/or across fields.
%
%      if the fields are themselves substructures, then the stitching
%      process is called with the substructures also.
%
%  The function returns an empty stitchedStructure ([]) if there is no
%  merged result. If substructures exist and partially agree, the parts
%  that disagree are indicated withthin uncommonFields using the dot
%  notation, for example: fieldName.disagreedSubFieldName. This is
%  recursive so sub-sub-fields would also be checked and similarly denoted
%  with two dots, etc.
%
% FORMAT:
%
%      [stitchedStructure, uncommonFields] = fcn_TimeClean_stichStructures(cellArrayOfStructures, (fig_num))
%


fig_num = [];

clear s1 s2 s3 cellArrayOfStructures

s1.a = 1*ones(3,1);
s1.b = 1*ones(3,1);
s1.c = 1*ones(3,1);
s1.sub1.a = 1*ones(3,1);

s2.a = 2*ones(3,1);
s2.c = 2*ones(3,1);
s2.d = 2*ones(3,1);
s2.sub1.a = 2*ones(3,1);
s2.sub1.b = 2*ones(3,1);

s3.a = 3*ones(3,1);
s3.c = 3*ones(3,1);
s3.e = 3*ones(3,1);
s3.f = 3*ones(3,1);
s3.sub1.a = 3*ones(3,1);
s3.sub1.c = 3*ones(3,1);
s3.sub2.a = 3*ones(3,1);

% Call the function
cellArrayOfStructures{1} = s1;
cellArrayOfStructures{2} = s2;
cellArrayOfStructures{3} = s3;
[stitchedStructure, uncommonFields] = fcn_TimeClean_stichStructures(cellArrayOfStructures, (fig_num));

% Check the output types
assert(isstruct(stitchedStructure))
assert(iscell(uncommonFields))

% Check their fields
temp = fieldnames(stitchedStructure);
assert(strcmp(temp{1},'a'));
assert(strcmp(temp{2},'c'));
assert(strcmp(temp{3},'sub1'));
temp2 = fieldnames(stitchedStructure.sub1);
assert(strcmp(temp2{1},'a'));

assert(strcmp(uncommonFields{1},'b'));
assert(strcmp(uncommonFields{2},'d'));
assert(strcmp(uncommonFields{3},'e'));
assert(strcmp(uncommonFields{4},'f'));
assert(strcmp(uncommonFields{5},'sub2'));
assert(strcmp(uncommonFields{6},'sub1.b'));
assert(strcmp(uncommonFields{7},'sub1.c'));

% Check field values
assert(isequal(stitchedStructure.a,[1*ones(1,3) 2*ones(1,3) 3*ones(1,3)]'))
assert(isequal(stitchedStructure.c,[1*ones(1,3) 2*ones(1,3) 3*ones(1,3)]'))
assert(isequal(stitchedStructure.sub1.a,[1*ones(1,3) 2*ones(1,3) 3*ones(1,3)]'))

%% fcn_TimeClean_fillTestDataStructure
% Creates five seconds of test data for testing functions
%
% FORMAT:
%
%      dataStructure =
%      fcn_TimeClean_fillTestDataStructure((time_time_corruption_type),(fid))

% Basic call in verbose mode
fprintf(1,'\n\nDemonstrating "verbose" mode by printing to console: \n');
error_type = [];
fid = 1;
testDataStructure = fcn_TimeClean_fillTestDataStructure(error_type,fid);

% Make sure its type is correct
assert(isstruct(testDataStructure));

fprintf(1,'The data structure for testDataStructure: \n')
disp(testDataStructure)


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

%% function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
% Clear out the variables
clear global flag* FLAG*
clear flag*
clear path

% Clear out any path directories under Utilities
if ispc
    path_dirs = regexp(path,'[;]','split');
elseif ismac
    path_dirs = regexp(path,'[:]','split');
elseif isunix
    path_dirs = regexp(path,'[;]','split');
else
    error('Unknown operating system. Unable to continue.');
end

utilities_dir = fullfile(pwd,filesep,'Utilities');
for ith_dir = 1:length(path_dirs)
    utility_flag = strfind(path_dirs{ith_dir},utilities_dir);
    if ~isempty(utility_flag)
        rmpath(path_dirs{ith_dir})
    end
end

% Delete the Utilities folder, to be extra clean!
if  exist(utilities_dir,'dir')
    [status,message,message_ID] = rmdir(utilities_dir,'s');
    if 0==status
        error('Unable remove directory: %s \nReason message: %s \nand message_ID: %s\n',utilities_dir, message,message_ID);
    end
end

end % Ends fcn_INTERNAL_clearUtilitiesFromPathAndFolders


%% fcn_INTERNAL_findTimeFromName
function timeNumber = fcn_INTERNAL_findTimeFromName(fileName) %#ok<DEFNU>

timeString = [];
if length(fileName)>4
    splitName = strsplit(fileName,{'_','.'});
    for ith_split = 1:length(splitName)
        if contains(splitName{ith_split},'-')
            timeString = splitName{ith_split};
        end
    end
end
timeNumber = datetime(timeString,'InputFormat','yyyy-MM-dd-HH-mm-ss');
end % Ends fcn_INTERNAL_findTimeFromName


%% fcn_INTERNAL_confirmDirectoryExists
function fcn_INTERNAL_confirmDirectoryExists(directoryName)
if 7~=exist(directoryName,'dir')
    warning('on','backtrace');
    warning('Unable to find folder: \n\t%s',directoryName);
    error('Desired directory: %s does not exist!',directoryName);
end
end % Ends fcn_INTERNAL_confirmDirectoryExists
