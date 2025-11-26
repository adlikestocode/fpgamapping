%% generateGrid.m
% Generates a uniform grid of waypoints within the survey area
% Supports both 2D (flat) and 3D (DEM with elevation) modes
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Mapping & Survey Area Setup
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [gridX, gridY, waypoints] = generateGrid(surveyArea, params)
    %GENERATEGRID Generate uniform waypoint grid for survey area
    %
    % Syntax:
    %   [gridX, gridY, waypoints] = generateGrid(surveyArea, params)
    %
    % Inputs:
    %   surveyArea - struct from defineSurveyArea.m with area bounds
    %   params     - struct from parameters.m with grid spacing + DEM settings
    %
    % Outputs:
    %   gridX      - [MxN] matrix of X coordinates (Easting)
    %   gridY      - [MxN] matrix of Y coordinates (Northing)
    %   waypoints  - [P x2] or [P x3] matrix where each row is a waypoint
    %                If DEM disabled: [X, Y] (2D)
    %                If DEM enabled:  [X, Y, Z] (3D with elevation)
    %                P = total number of waypoints
    
    if nargin < 2 || ~isstruct(surveyArea) || ~isstruct(params)
        error('generateGrid:InvalidInput', ...
              'Inputs must be surveyArea and params structs');
    end
    
    %% Extract parameters
    xMin = surveyArea.xMin;
    xMax = surveyArea.xMax;
    yMin = surveyArea.yMin;
    yMax = surveyArea.yMax;
    gridSpacing = params.gridSpacing;
    
    %% Generate grid arrays
    % Create 1D arrays for each axis with specified spacing
    x = xMin : gridSpacing : xMax;
    y = yMin : gridSpacing : yMax;
    
    % Create 2D meshgrid (each point has coordinates from both axes)
    [gridX, gridY] = meshgrid(x, y);
    
    %% Convert to waypoint list format - initial 2D
    % Each row is [Easting, Northing] of one waypoint
    waypoints = [gridX(:), gridY(:)];
    
    %% Validate all waypoints are within survey area
    validIdx = (waypoints(:,1) >= xMin) & (waypoints(:,1) <= xMax) & ...
               (waypoints(:,2) >= yMin) & (waypoints(:,2) <= yMax);
    
    if ~all(validIdx)
        warning('generateGrid:OutOfBounds', ...
                'Some waypoints outside survey area. Removing invalid points.');
        waypoints = waypoints(validIdx, :);
    end
    
    %% Add elevation from DEM if enabled - NEW
    if params.useDEM
        waypoints = addElevationFromDEM(waypoints, surveyArea, params);
    else
        fprintf('  [2D Mode] Waypoints are 2D (X, Y) without elevation\n');
    end
    
    %% Display grid information
    numPointsX = length(x);
    numPointsY = length(y);
    totalWaypoints = size(waypoints, 1);
    
    fprintf('\n=== Grid Generation Summary ===\n');
    fprintf('Grid Spacing: %.0f meters\n', gridSpacing);
    fprintf('X-direction: %d points (%.0f to %.0f m)\n', numPointsX, xMin, xMax);
    fprintf('Y-direction: %d points (%.0f to %.0f m)\n', numPointsY, yMin, yMax);
    fprintf('Total Waypoints: %d\n', totalWaypoints);
    fprintf('Grid Density: %.4f waypoints/m²\n', totalWaypoints / (surveyArea.width * surveyArea.height));
    
    % Show waypoint dimensionality
    if size(waypoints, 2) == 3
        fprintf('Waypoint Format: [X, Y, Z] (3D with elevation)\n');
        fprintf('Elevation Range: %.1f to %.1f meters\n', min(waypoints(:,3)), max(waypoints(:,3)));
    else
        fprintf('Waypoint Format: [X, Y] (2D flat)\n');
    end
    
    fprintf('================================\n\n');
    
end

%% Helper Function: Add Elevation from DEM
function waypoints3D = addElevationFromDEM(waypoints2D, surveyArea, params)
    %ADDELEVATIONFROMDEM Query DEM and add Z coordinate to waypoints
    %
    % Inputs:
    %   waypoints2D - [N x 2] matrix of [X, Y] coordinates
    %   surveyArea  - struct with survey area bounds
    %   params      - struct with DEM configuration
    %
    % Output:
    %   waypoints3D - [N x 3] matrix of [X, Y, Z] coordinates
    
    fprintf('  [3D Mode] Loading DEM and adding elevation...\n');
    
    %% Step 1: Check if DEM file exists, generate if needed
    demFile = params.demFile;
    
    if ~isfile(demFile) && params.generateDEM
        fprintf('    • DEM file not found: %s\n', demFile);
        fprintf('    • Auto-generating synthetic DEM (%s terrain)...\n', params.demType);
        
        % Generate synthetic DEM
        demData = generateSyntheticDEM(surveyArea, params.demResolution, params.demType);
        fprintf('    ✓ DEM generated\n');
        
    elseif ~isfile(demFile)
        error('generateGrid:DEMNotFound', ...
              'DEM file not found: %s\nEnable params.generateDEM to auto-generate', demFile);
    else
        fprintf('    • Loading DEM from: %s\n', demFile);
    end
    
    %% Step 2: Load DEM
    demData = demImport(demFile);
    
    %% Step 3: Interpolate elevation at each waypoint
    X_waypoints = waypoints2D(:, 1);
    Y_waypoints = waypoints2D(:, 2);
    Z_waypoints = demInterpolate(demData, X_waypoints, Y_waypoints);
    
    %% Step 4: Combine into 3D waypoints
    waypoints3D = [waypoints2D, Z_waypoints];
    
    %% Step 5: Verify no NaN values
    nanCount = sum(isnan(Z_waypoints));
    if nanCount > 0
        warning('generateGrid:NaNElevation', ...
                '%d waypoints have NaN elevation (out of bounds)', nanCount);
    end
    
    fprintf('    ✓ Elevation added to %d waypoints\n', size(waypoints2D, 1));
    
end
