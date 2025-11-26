%% computeCoverageGrid.m
% Calculates camera coverage footprint and validates grid overlap requirements
% Ensures grid spacing meets photogrammetry overlap standards
% Supports both flat (2D) and terrain-aware (3D with DEM) altitude modes
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Mapping & Survey Area Setup
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [coverageData, adjustedGrid, adjustedWaypoints] = computeCoverageGrid(waypoints, params, surveyArea)
    %COMPUTECOVERAGEGRID Calculate camera coverage and validate grid spacing
    %
    % Syntax:
    %   [coverageData, adjustedGrid, adjustedWaypoints] = computeCoverageGrid(waypoints, params, surveyArea)
    %
    % Inputs:
    %   waypoints    - [Nx2] for 2D mode OR [Nx3] for 3D mode with elevation
    %                  Format: [Easting, Northing] or [Easting, Northing, Elevation]
    %   params       - struct from parameters.m with camera, overlap, and DEM specs
    %   surveyArea   - struct from defineSurveyArea.m with boundary info
    %
    % Outputs:
    %   coverageData - struct with coverage statistics and validation results
    %   adjustedGrid - [Mx2] or [Mx3] adjusted waypoint matrix if grid was modified
    %   adjustedWaypoints - adjusted waypoint list with proper dimensionality
    
    if nargin < 3 || ~isnumeric(waypoints) || ~isstruct(params) || ~isstruct(surveyArea)
        error('computeCoverageGrid:InvalidInput', ...
              'Requires waypoints matrix, params struct, and surveyArea struct');
    end
    
    %% Determine if using 3D (DEM) or 2D mode
    waypointDim = size(waypoints, 2);
    useDEM = (waypointDim == 3) && params.useDEM;
    
    %% Extract camera and overlap parameters
    focalLength = params.focalLength;
    sensorWidth = params.sensorWidth;
    sensorHeight = params.sensorHeight;
    imageWidth = params.imageWidth;
    imageHeight = params.imageHeight;
    frontalOverlap = params.frontalOverlap;
    sideOverlap = params.sideOverlap;
    currentGridSpacing = params.gridSpacing;
    
    %% Calculate altitude (terrain-aware for DEM mode) - NEW
    if useDEM
        % 3D Mode: Variable altitude above terrain
        terrainElevations = waypoints(:, 3);
        minTerrainElev = min(terrainElevations);
        maxTerrainElev = max(terrainElevations);
        
        % Flight altitude must maintain minAGL above highest terrain
        flightAltitude = maxTerrainElev + params.minAGL;
        
        fprintf('  [Terrain-Aware Mode] Computing altitude relative to terrain...\n');
        fprintf('    Terrain elevation range: %.1f to %.1f m\n', minTerrainElev, maxTerrainElev);
        fprintf('    Min AGL: %.0f m\n', params.minAGL);
        fprintf('    Flight altitude: %.1f m (absolute)\n', flightAltitude);
    else
        % 2D Mode: Fixed altitude
        flightAltitude = params.altitude;
        fprintf('  [Flat Terrain Mode] Using fixed altitude: %.0f m AGL\n', flightAltitude);
    end
    
    %% Calculate ground coverage per image (in meters)
    groundWidth = (sensorWidth * flightAltitude) / focalLength;   % meters (East-West)
    groundHeight = (sensorHeight * flightAltitude) / focalLength;  % meters (North-South)
    gsd = (sensorWidth * flightAltitude * 100) / (focalLength * imageWidth); % cm/pixel
    
    %% Calculate required spacing from overlap requirements
    % Frontal overlap along flight direction (X/East)
    requiredSpacingFrontal = groundWidth * (1 - frontalOverlap);
    
    % Side overlap perpendicular to flight (Y/North)
    requiredSpacingSide = groundHeight * (1 - sideOverlap);
    
    %% Calculate total coverage per waypoint
    % Total area covered by single image (not considering overlap)
    imageCoverageArea = groundWidth * groundHeight;
    
    % With overlaps considered: effective coverage area
    effectiveCoverageWidth = groundWidth * (1 - frontalOverlap);
    effectiveCoverageHeight = groundHeight * (1 - sideOverlap);
    effectiveCoverageArea = effectiveCoverageWidth * effectiveCoverageHeight;
    
    %% Validate current grid spacing against overlap requirements
    isGridValid = (currentGridSpacing <= requiredSpacingFrontal) && ...
                  (currentGridSpacing <= requiredSpacingSide);
    
    %% Check if grid needs adjustment
    maxAllowedSpacing = min(requiredSpacingFrontal, requiredSpacingSide);
    gridAdjustmentNeeded = currentGridSpacing > maxAllowedSpacing;
    
    if gridAdjustmentNeeded
        % Calculate new spacing that satisfies both overlaps
        newGridSpacing = floor(maxAllowedSpacing / 5) * 5; % Round down to nearest 5m
        if newGridSpacing < 5
            newGridSpacing = 5; % Minimum practical spacing
        end
        adjustmentRatio = newGridSpacing / currentGridSpacing;
    else
        newGridSpacing = currentGridSpacing;
        adjustmentRatio = 1.0;
    end
    
    %% Generate adjusted grid if needed
    if gridAdjustmentNeeded
        x = surveyArea.xMin : newGridSpacing : surveyArea.xMax;
        y = surveyArea.yMin : newGridSpacing : surveyArea.yMax;
        [gridX, gridY] = meshgrid(x, y);
        
        if useDEM
            % 3D: Add elevation for adjusted waypoints
            wp_2d = [gridX(:), gridY(:)];
            Z = demInterpolate(demImport(params.demFile), wp_2d(:,1), wp_2d(:,2));
            adjustedGrid = [wp_2d, Z];
            adjustedWaypoints = adjustedGrid;
        else
            % 2D: No elevation
            adjustedGrid = [gridX(:), gridY(:)];
            adjustedWaypoints = adjustedGrid;
        end
    else
        adjustedGrid = waypoints;
        adjustedWaypoints = waypoints;
    end
    
    %% Calculate coverage statistics
    totalWaypoints = size(waypoints, 1);
    adjustedWaypoints_count = size(adjustedWaypoints, 1);
    
    % Coverage percentage of survey area
    surveyArea_total = surveyArea.width * surveyArea.height;
    coveragePerWaypoint = effectiveCoverageArea;
    totalCoverageIfOptimal = adjustedWaypoints_count * effectiveCoverageArea;
    coveragePercentage = min((totalCoverageIfOptimal / surveyArea_total) * 100, 100);
    
    %% Build output struct: coverageData - ENHANCED
    coverageData.altitude = flightAltitude;
    coverageData.altitudeMode = ifthenelse(useDEM, 'terrain-aware', 'fixed');
    if useDEM
        coverageData.minTerrainElev = minTerrainElev;
        coverageData.maxTerrainElev = maxTerrainElev;
        coverageData.minAGL = params.minAGL;
    end
    
    coverageData.focalLength = focalLength;
    coverageData.gsd = gsd;
    coverageData.groundWidth = groundWidth;
    coverageData.groundHeight = groundHeight;
    coverageData.imageCoverageArea = imageCoverageArea;
    
    coverageData.frontalOverlap = frontalOverlap;
    coverageData.sideOverlap = sideOverlap;
    coverageData.requiredSpacingFrontal = requiredSpacingFrontal;
    coverageData.requiredSpacingSide = requiredSpacingSide;
    coverageData.maxAllowedSpacing = maxAllowedSpacing;
    
    coverageData.currentGridSpacing = currentGridSpacing;
    coverageData.newGridSpacing = newGridSpacing;
    coverageData.gridAdjustmentNeeded = gridAdjustmentNeeded;
    coverageData.adjustmentRatio = adjustmentRatio;
    
    coverageData.totalWaypoints_original = totalWaypoints;
    coverageData.totalWaypoints_adjusted = adjustedWaypoints_count;
    coverageData.waypointCountChange = adjustedWaypoints_count - totalWaypoints;
    
    coverageData.effectiveCoverageArea = effectiveCoverageArea;
    coverageData.totalCoverageArea = totalCoverageIfOptimal;
    coverageData.surveyAreaTotal = surveyArea_total;
    coverageData.coveragePercentage = coveragePercentage;
    
    coverageData.isGridValid = isGridValid;
    
    %% Display coverage analysis
    fprintf('\n=== Coverage Analysis ===\n');
    fprintf('Altitude Mode: %s\n', upper(coverageData.altitudeMode));
    
    fprintf('\nCamera Parameters:\n');
    fprintf('  Altitude: %.1f m\n', flightAltitude);
    if useDEM
        fprintf('  (Terrain: %.1f-%.1f m, AGL: %.0f m)\n', ...
                minTerrainElev, maxTerrainElev, params.minAGL);
    end
    fprintf('  Focal Length: %.0f mm\n', focalLength);
    fprintf('  GSD: %.2f cm/pixel\n', gsd);
    fprintf('  Ground Coverage: %.1f x %.1f meters\n', groundWidth, groundHeight);
    
    fprintf('\nOverlap Requirements:\n');
    fprintf('  Frontal Overlap: %.0f%%  (requires spacing ≤ %.1f m)\n', ...
            frontalOverlap*100, requiredSpacingFrontal);
    fprintf('  Side Overlap: %.0f%%     (requires spacing ≤ %.1f m)\n', ...
            sideOverlap*100, requiredSpacingSide);
    fprintf('  Max Allowed Spacing: %.1f m\n', maxAllowedSpacing);
    
    fprintf('\nGrid Status:\n');
    fprintf('  Current Grid Spacing: %.0f m\n', currentGridSpacing);
    
    if isGridValid
        fprintf('  ✓ Grid VALID - satisfies all overlap requirements\n');
    else
        fprintf('  ✗ Grid INVALID - does not satisfy overlap requirements\n');
    end
    
    if gridAdjustmentNeeded
        fprintf('\nGrid Adjustment:\n');
        fprintf('  Recommended New Spacing: %.0f m\n', newGridSpacing);
        fprintf('  Original Waypoints: %d\n', totalWaypoints);
        fprintf('  Adjusted Waypoints: %d\n', adjustedWaypoints_count);
        fprintf('  Change: %+d waypoints\n', coverageData.waypointCountChange);
    else
        fprintf('\nNo Grid Adjustment Needed\n');
    end
    
    fprintf('  Estimated Coverage: %.1f%% of survey area\n', coveragePercentage);
    fprintf('=======================\n\n');
    
end

%% Helper: Conditional value (for MATLAB 2023b compatibility)
function result = ifthenelse(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
