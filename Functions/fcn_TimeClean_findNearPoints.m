function [nearbyIndicies, Nnearby] = fcn_TimeClean_findNearPoints(ENU_data, searchRadiusAndAngles, varargin)
%fcn_TimeClean_findNearPoints  for each point, lists nearby indicies
%
% FORMAT:
%
%       nearbyIndicies = fcn_TimeClean_findNearPoints(fcn_TimeClean_findNearPoints, searchRadiusAndAngles, (figNum))
%
% INPUTS:
%
%      fcn_TimeClean_findNearPoints: the [East North Up] data as an [Nx3]
%      vector, using the origin as set in the main demo script
%
%      searchRadiusAndAngles: a [1x1] or [1x2] vector of [searchRadius] or
%      [searchRadius angleRange] where searchRadius is the query distance
%      that determines search criteria for "nearby", in meters and
%      angleRange specifies the absolute difference in angle allowable (in
%      radians) for this position to be considered for calculations, e.g
%      all angles that are within [-angleRange, angleRange] are considered
%      for the search
%
%      (OPTIONAL INPUTS)
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
% OUTPUTS:
%
%      nearbyIndicies: an N-length cell array, with each cell corresponding
%      to the nth point in the fcn_TimeClean_findNearPoints input. The cell
%      array contains, in each element, a vector [kx1] that lists the k
%      indicies near to the given point. If no point is within the
%      searchRadius, an empty matrix is given.
%
%      Nnearby: an Nx1 array listing the number of points nearby
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script:
%
%       script_test_fcn_TimeClean_findNearPoints
%
% This function was written on 2024_10_27 by Sean Brennan
% Questions or comments? sbrennan@psu.edu

% Revision History

% REVISION HISTORY:
%
% 2024_10_27 by S. Brennan, sbrennan@psu.edu
% - started function by modifying fcn _ DataClean _ findNearPoints
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Added rev history
% - Added TO+_DO list

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)



%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
MAX_NARGIN = 3; % The largest Number of argument inputs to the function
flag_max_speed = 0;
if (nargin==3 && isequal(varargin{end},-1))
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS");
    MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG = getenv("MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 0 == flag_max_speed
    if flag_check_inputs == 1
        % Are there the right number of inputs?
        narginchk(2,MAX_NARGIN);

    end
end

% Does user want to specify figNum?
flag_do_plots = 0;
figNum = []; % Initialize the figure number to be empty
if (0==flag_max_speed) && (MAX_NARGIN == nargin)
    temp = varargin{end};
    if ~isempty(temp)
        figNum = temp;
        flag_do_plots = 1;
    end
end


%% Write main code for plotting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the output
Ndata = length(ENU_data(:,1));
nearbyIndicies{Ndata} = [];

% Check the inputs in searchRadiusAndAngles
flag_check_angles = 0;
if length(searchRadiusAndAngles)==2
    searchRadius = searchRadiusAndAngles(1);
    searchAngles = searchRadiusAndAngles(2);
    flag_check_angles = 1;
elseif length(searchRadiusAndAngles)==1
    searchRadius = searchRadiusAndAngles(1);
else
    warning('on','backtrace');
    warning('A poorly defined searchRadiusAndAngles was encountered. Expecting a [1x2] vector - throwing an error.')
    error('Error in searchRadiusAndAngles encountered. Cannot continue.');
end


% Precalculate items
if 1==flag_check_angles
    error('Not coded yet');
    % % Grab the time values
    % [modeIndex, ~, offsetCentisecondsToMode] = fcn_TimeClean_assessTime([], ENU_data, (-1));
    % 
    % % Calculate the velocities, angles, and heading
    % [~, angleENUradians, ~]  = fcn_TimeClean_calcVelocity([], ENU_data, modeIndex, offsetCentisecondsToMode, -1); 
end

% Loop through all the points, finding qualifying agreement indicies
allXY = ENU_data(:,1:2);
Nnearby = nan(Ndata,1);
for ith_point = 1:Ndata
    this_pointXY = ENU_data(ith_point,1:2);
    closeDistanceIndiciesWithSelfPoint = fcn_geometry_pointsNearPoint(this_pointXY, allXY, searchRadius, -1);
    closeDistanceIndicies = closeDistanceIndiciesWithSelfPoint(closeDistanceIndiciesWithSelfPoint~=ith_point);

    if 1==flag_check_angles
        error('Not coded yet');
        % current_angle = angleENUradians(ith_point);
        % closeAngleIndiciesWithSelfPoint = fcn_geometry_anglesNearAngle(current_angle, angleENUradians, searchAngles, -1);
        % closeAngleIndicies = closeAngleIndiciesWithSelfPoint(closeAngleIndiciesWithSelfPoint~=ith_point);
    else
        closeAngleIndicies = closeDistanceIndicies;
    end

    % Merge the results together by keeping only indicies that are in both
    nearbyIndicies{ith_point} = intersect(closeDistanceIndicies,closeAngleIndicies);
    Nnearby(ith_point,1) = length(nearbyIndicies{ith_point});
end

%% Any debugging?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% before opeaning up a figure, lets start to capture the frames for an
% animation if the user has entered a name for the mov file
if flag_do_plots == 1

    figure(figNum);

    % Pick a random value to plot
    randomIndex = round(rand*(Ndata-1))+1;
    ith_point = min(Ndata,max(1,randomIndex));

    
    % Plot the input data
    clear plotFormat
    plotFormat.Color = [0 0 0];
    plotFormat.Marker = '.';
    plotFormat.MarkerSize = 10;
    plotFormat.LineStyle = 'none';
    plotFormat.LineWidth = 3;

    testPointFormat = plotFormat;
    testPointFormat.Color = [0 0 1];
    testPointFormat.MarkerSize = 50;

    circleFormat = plotFormat;
    circleFormat.Marker = 'none';
    circleFormat.Color = [1 0 1];
    circleFormat.MarkerSize = 10;
    circleFormat.LineStyle = '-';
    circleFormat.LineWidth = 3;

    pointsInside = plotFormat;
    pointsInside.Color = [1 0 1];
    pointsInside.Marker = 'o';
    pointsInside.MarkerSize = 10;
    pointsInside.LineStyle = 'none';
    pointsInside.LineWidth = 1;

    % Plot the input data
    fcn_plotRoad_plotXY((ENU_data(:,1:2)), (plotFormat), (figNum));

    % Plot the test point
    h1 = fcn_plotRoad_plotXY((ENU_data(ith_point,1:2)), (testPointFormat), (figNum));

    % Plot the bounding circle
    Nangles = 45;
    theta = linspace(0, 2*pi, Nangles)'; 
    CircleXData = ones(Nangles,1)*ENU_data(ith_point,1) + searchRadius*cos(theta);
    CircleYData = ones(Nangles,1)*ENU_data(ith_point,2) + searchRadius*sin(theta);
    h2 = fcn_plotRoad_plotXY([CircleXData CircleYData], (circleFormat), (figNum));

    % Plot the points inside the bounding circle
    indicesNearby = nearbyIndicies{ith_point};
    if ~isempty(indicesNearby)
        h3 = fcn_plotRoad_plotXY((ENU_data(indicesNearby,1:2)), (pointsInside), (figNum));
    end


    for ith_point = 1:Ndata
        set(h1,'XData',ENU_data(ith_point,1),'YData',ENU_data(ith_point,2));
        CircleXData = ones(Nangles,1)*ENU_data(ith_point,1) + searchRadius*cos(theta);
        CircleYData = ones(Nangles,1)*ENU_data(ith_point,2) + searchRadius*sin(theta);  
        set(h2,'XData',CircleXData,'YData',CircleYData);
        indicesNearby = nearbyIndicies{ith_point};
        set(h3,'XData',ENU_data(indicesNearby,1),'YData',ENU_data(indicesNearby,2));
        pause(0.02);
    end
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

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
