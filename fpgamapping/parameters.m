%% parameters.m
% Centralized parameter definitions for drone pathfinding project
% This struct is used by all mapping and survey area functions
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Mapping & Survey Area Setup
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function params = parameters()
    %% Survey Area Configuration (UTM Coordinates in meters)
    % Define the lower-left corner and dimensions of survey area
    
    params.x0 = 500000;           % UTM Easting origin (meters)
    params.y0 = 5400000;          % UTM Northing origin (meters)
    params.areaWidth = 1000;      % Survey area width (meters) - 1km
    params.areaHeight = 1000;     % Survey area height (meters) - 1km
    params.utmZone = '43N';       % UTM zone (e.g., for Delhi, India)
    
    %% Grid Configuration
    % Initial grid spacing - may be adjusted by computeCoverageGrid.m
    
    params.gridSpacing = 30;      % Distance between waypoints (meters)
    
    %% Camera Parameters
    % Based on typical drone camera specifications (e.g., DJI Mavic 3)
    
    params.focalLength = 20;      % Camera focal length (mm)
    params.sensorWidth = 24;      % Sensor width (mm)
    params.sensorHeight = 16;     % Sensor height (mm)
    params.imageWidth = 5280;     % Image resolution width (pixels)
    params.imageHeight = 3956;    % Image resolution height (pixels)
    params.altitude = 120;        % Drone flight altitude AGL (meters)
    
    %% Photogrammetry Requirements
    % Image overlap percentages for Structure-from-Motion
    
    params.frontalOverlap = 0.75; % 75% forward overlap (standard)
    params.sideOverlap = 0.65;    % 65% lateral overlap (standard)
    
    %% Coordinate System Settings
    
    params.useUTM = true;         % Use UTM coordinates (true) or lat/lon (false)
    
    %% DEM (Digital Elevation Model) Configuration
    % Enable 3D terrain awareness or use flat 2D mode
    
    params.useDEM = true;                    % ✓ Enable DEM (3D terrain) - RECOMMENDED
                                             % false = flat 2D mode
    
    params.demType = 'hills';                % Synthetic terrain type: 'flat', 'slope', 'hills', 'random'
    params.demResolution = 10;               % DEM grid resolution (meters)
    params.demFile = 'synthetic_dem_hills.mat'; % Path to DEM file (auto-generated if missing)
    params.generateDEM = true;               % Auto-generate DEM if file not found
    params.minAGL = 120;                     % Minimum altitude above ground level (meters)
                                             % Drone maintains this AGL over terrain
    
    %% Path Smoothing Configuration (Module 2 - Optional)
    params.smoothPath = true;                % Enable path smoothing
    params.smoothMethod = 'spline';          % 'linear', 'spline', 'bezier'
    params.smoothDensity = 15;               % Interpolation points per segment
    
    %% A* Pathfinding Configuration (Module 3)
    params.useAStar = true;                  % Enable A* pathfinding
    params.maxSlope = 30;                    % Max terrain slope (degrees)
    params.maxClimbAngle = 20;               % Max climb/descent angle (degrees)
    params.maxTurnAngle = 60;                % Max turn angle (degrees)
    params.obstacleBuffer = 30;              % Safety buffer around obstacles (meters)
    params.astarHeuristic = 'euclidean';     % 'euclidean', 'manhattan', 'diagonal'
    
    %% Mission Planning Configuration (Module 4)
    params.missionName = 'Terrain Survey Mission 001';
    params.missionType = 'coverage';         % 'coverage', 'point-to-point', 'custom'
    params.exportFormats = {'kml', 'csv'};   % Export file types: 'kml', 'csv', 'geojson'
    params.exportPath = './mission_output/'; % Output directory for exports
    params.saveFigures = true;               % Save visualization figures
    params.figureFormat = 'png';             % 'png', 'pdf', 'fig'
    params.droneSpeed = 15;                  % m/s cruise speed (for time estimation)
    params.batteryCapacity = 5400;           % mAh (for flight time calculation)
    params.takeoffAltitude = 5;              % Takeoff climb altitude (meters)
    params.landingAltitude = 0;              % Landing descent altitude (meters)
    
    %% Derived Parameters (Computed from above)
    % Ground Sample Distance (GSD) calculation
    
    params.GSD = (params.sensorWidth * params.altitude * 100) / ...
                 (params.focalLength * params.imageWidth);
    
    % Ground coverage per image (meters)
    params.groundWidth = (params.sensorWidth * params.altitude) / ...
                         params.focalLength;
    params.groundHeight = (params.sensorHeight * params.altitude) / ...
                          params.focalLength;
    
    %% Display Configuration Summary
    fprintf('\n=== Drone Survey Configuration ===\n');
    fprintf('Survey Area: %.0f x %.0f meters\n', params.areaWidth, params.areaHeight);
    fprintf('Grid Spacing: %.0f meters\n', params.gridSpacing);
    fprintf('Flight Altitude: %.0f meters AGL\n', params.altitude);
    fprintf('Ground Sample Distance (GSD): %.2f cm/pixel\n', params.GSD);
    fprintf('Ground Coverage: %.1f x %.1f meters per image\n', ...
            params.groundWidth, params.groundHeight);
    fprintf('Required Overlaps: %.0f%% frontal, %.0f%% side\n', ...
            params.frontalOverlap*100, params.sideOverlap*100);
    fprintf('==================================\n');
    
    %% DEM Configuration Display
    fprintf('\n=== DEM Configuration ===\n');
    if params.useDEM
        fprintf('Status: ✓ DEM ENABLED (3D terrain mode)\n');
        fprintf('Terrain Type: %s\n', params.demType);
        fprintf('DEM File: %s\n', params.demFile);
        fprintf('Resolution: %.0f meters\n', params.demResolution);
        fprintf('Min AGL: %.0f meters\n', params.minAGL);
        fprintf('Mode: Terrain-aware altitude (variable)\n');
    else
        fprintf('Status: ⊗ DEM DISABLED (2D flat mode)\n');
        fprintf('Mode: Fixed altitude (%.0f m AGL)\n', params.altitude);
        fprintf('Note: To enable DEM, set params.useDEM = true\n');
    end
    fprintf('==========================\n');
    
    %% Mission Planning Display
    fprintf('\n=== Mission Planning ===\n');
    fprintf('Mission: %s\n', params.missionName);
    fprintf('Type: %s\n', params.missionType);
    fprintf('Export: %s\n', strjoin(params.exportFormats, ', '));
    fprintf('Output: %s\n', params.exportPath);
    fprintf('Drone Speed: %.0f m/s\n', params.droneSpeed);
    fprintf('========================\n\n');
    
end
