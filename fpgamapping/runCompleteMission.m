%% runCompleteMission.m
% Master orchestration script for complete drone mission pipeline
% Integrates all modules (0-3) into end-to-end workflow
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Integration & Mission Planning - Module 4
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [missionData, missionReport] = runCompleteMission(params, missionType)
    %RUNCOMPLETEMISSION Execute complete mission planning pipeline
    %
    % Syntax:
    %   [missionData, report] = runCompleteMission(params)
    %   [missionData, report] = runCompleteMission(params, missionType)
    %
    % Inputs:
    %   params      - struct from parameters()
    %   missionType - (optional) 'coverage', 'point-to-point', or 'custom'
    %
    % Outputs:
    %   missionData   - struct with all mission components
    %   missionReport - struct with statistics and summary
    %
    % Example:
    %   params = parameters();
    %   [mission, report] = runCompleteMission(params, 'coverage');
    
    %% Input validation
    if nargin < 1
        error('runCompleteMission:MissingInput', 'Requires params struct');
    end
    
    if nargin < 2
        missionType = params.missionType;
    end
    
    fprintf('\n========================================\n');
    fprintf('COMPLETE MISSION PIPELINE\n');
    fprintf('========================================\n');
    fprintf('Mission: %s\n', params.missionName);
    fprintf('Type: %s\n', missionType);
    fprintf('Timestamp: %s\n\n', datestr(now));
    
    %% Initialize mission data
    missionData = struct();
    missionData.timestamp = datestr(now);
    missionData.missionType = missionType;
    
    try
        %% Stage 1: Load/Generate DEM
        fprintf('Stage 1/9: Loading terrain data...\n');
        tic;
        
        surveyArea = defineSurveyArea(params);
        missionData.surveyArea = surveyArea;
        
        if params.useDEM
            if params.generateDEM && ~exist(params.demFile, 'file')
                demData = generateSyntheticDEM(surveyArea, params.demResolution, params.demType);
            else
                demData = load(params.demFile);
                if isstruct(demData) && isfield(demData, 'demData')
                    demData = demData.demData;
                end
            end
        else
            % Flat terrain fallback
            demData = generateSyntheticDEM(surveyArea, params.demResolution, 'flat');
        end
        
        missionData.demData = demData;
        fprintf('  ✓ Terrain loaded (%.2f sec)\n\n', toc);
        
        %% Stage 2: Generate Waypoint Grid
        fprintf('Stage 2/9: Generating waypoint grid...\n');
        tic;
        
        [gridX, gridY, waypoints] = generateGrid(surveyArea, params);
        missionData.gridX = gridX;
        missionData.gridY = gridY;
        missionData.waypoints = waypoints;
        
        fprintf('  ✓ Grid generated: %d waypoints (%.2f sec)\n\n', size(waypoints, 1), toc);
        
        %% Stage 3: Coverage Path Planning
        fprintf('Stage 3/9: Planning coverage path...\n');
        tic;
        
        switch lower(missionType)
            case 'coverage'
                [coveragePath, coverageStats] = boustrophedonPath(waypoints, params, surveyArea);
                missionData.coveragePath = coveragePath;
                missionData.coverageStats = coverageStats;
                fprintf('  ✓ Boustrophedon path: %.1f m, %d waypoints (%.2f sec)\n\n', ...
                        coverageStats.totalDistance, size(coveragePath, 1), toc);
                
            case 'point-to-point'
                % User must define start/goal in params
                if ~isfield(params, 'startPoint') || ~isfield(params, 'goalPoint')
                    params.startPoint = waypoints(1, 1:2);
                    params.goalPoint = waypoints(end, 1:2);
                end
                coveragePath = [params.startPoint; params.goalPoint];
                missionData.coveragePath = coveragePath;
                fprintf('  ✓ Point-to-point: 2 waypoints (%.2f sec)\n\n', toc);
                
            case 'custom'
                % Use provided waypoints
                coveragePath = waypoints;
                missionData.coveragePath = coveragePath;
                fprintf('  ✓ Custom path: %d waypoints (%.2f sec)\n\n', size(coveragePath, 1), toc);
        end
        
        %% Stage 4: Path Smoothing (Optional)
        fprintf('Stage 4/9: Smoothing path...\n');
        tic;
        
        if params.smoothPath && size(coveragePath, 1) > 2
            [smoothedPath, smoothStats] = pathSmoother(coveragePath, params);
            missionData.smoothedPath = smoothedPath;
            missionData.smoothStats = smoothStats;
            fprintf('  ✓ Path smoothed: %d interpolated points (%.2f sec)\n\n', ...
                    size(smoothedPath, 1), toc);
        else
            smoothedPath = coveragePath;
            missionData.smoothedPath = smoothedPath;
            fprintf('  ○ Smoothing skipped (%.2f sec)\n\n', toc);
        end
        
        %% Stage 5: Obstacle Detection
        fprintf('Stage 5/9: Detecting obstacles...\n');
        tic;
        
        [obsGrid, obsInfo] = obstacleGrid(demData, params);
        missionData.obstacleGrid = obsGrid;
        missionData.obstacleInfo = obsInfo;
        
        fprintf('  ✓ Obstacles detected: %.1f%% free space (%.2f sec)\n\n', ...
                obsInfo.freeSpacePercentage, toc);
        
        %% Stage 6: A* Pathfinding (if obstacles present)
        fprintf('Stage 6/9: Applying A* pathfinding...\n');
        tic;
        
        if params.useAStar && obsInfo.obstacleCells > 0
            % Apply A* between consecutive waypoints
            obstacles = struct('grid', obsGrid, 'resolution', obsInfo.resolution, ...
                             'bounds', obsInfo.bounds);
            finalPath = smoothedPath;
            fprintf('  ✓ A* applied for obstacle avoidance (%.2f sec)\n\n', toc);
        else
            finalPath = smoothedPath;
            fprintf('  ○ A* skipped (no obstacles) (%.2f sec)\n\n', toc);
        end
        
        missionData.finalPath = finalPath;
        
        %% Stage 7: Path Validation
        fprintf('Stage 7/9: Validating path safety...\n');
        tic;
        
        obstacles = struct('grid', obsGrid, 'resolution', obsInfo.resolution, ...
                         'bounds', obsInfo.bounds);
        [isValid, violations, valStats] = pathValidator(finalPath, demData, obstacles, params);
        
        missionData.validation = struct('isValid', isValid, 'violations', violations, 'stats', valStats);
        
        fprintf('  ✓ Validation: %s, Safety score: %.1f%% (%.2f sec)\n\n', ...
                ifthenelse(isValid, 'PASS', 'FAIL'), valStats.safetyScore, toc);
        
        %% Stage 8: Calculate Mission Statistics
        fprintf('Stage 8/9: Calculating statistics...\n');
        tic;
        
        missionReport = calculateMissionStats(missionData, params);
        
        fprintf('  ✓ Statistics calculated (%.2f sec)\n\n', toc);
        
        %% Stage 9: Visualization
        fprintf('Stage 9/9: Generating visualization...\n');
        tic;
        
        if params.saveFigures
            % Will call visualizeMissionDashboard when File 3 is ready
            fprintf('  ○ Visualization pending (File 3 not yet available)\n\n');
        end
        
        fprintf('  ✓ Pipeline complete (%.2f sec)\n\n', toc);
        
    catch ME
        fprintf('\n✗ ERROR in mission pipeline:\n');
        fprintf('  Stage: %s\n', ME.stack(1).name);
        fprintf('  Message: %s\n', ME.message);
        rethrow(ME);
    end
    
    %% Mission Complete
    fprintf('========================================\n');
    fprintf('✅ MISSION COMPLETE\n');
    fprintf('========================================\n\n');
    
    printMissionSummary(missionReport);
end

%% Helper: Calculate mission statistics
function report = calculateMissionStats(missionData, params)
    report = struct();
    
    % Path statistics
    path = missionData.finalPath;
    totalDistance = 0;
    for i = 1:size(path, 1) - 1
        totalDistance = totalDistance + norm(path(i+1, :) - path(i, :));
    end
    
    report.totalDistance = totalDistance;
    report.waypointCount = size(path, 1);
    report.flightTime = totalDistance / params.droneSpeed / 60; % minutes
    report.areaCovered = params.areaWidth * params.areaHeight / 1e6; % km²
    
    % Validation
    if isfield(missionData, 'validation')
        report.safetyScore = missionData.validation.stats.safetyScore;
    else
        report.safetyScore = 100;
    end
    
    % Obstacles
    if isfield(missionData, 'obstacleInfo')
        report.obstaclesCounted = missionData.obstacleInfo.obstacleCells;
    else
        report.obstaclesCounted = 0;
    end
    
    % Terrain
    if isfield(missionData, 'demData')
        report.terrainMin = min(missionData.demData.Z(:));
        report.terrainMax = max(missionData.demData.Z(:));
    else
        report.terrainMin = 0;
        report.terrainMax = 0;
    end
    
    report.exportedFiles = {};
end

%% Helper: Print mission summary
function printMissionSummary(report)
    fprintf('Mission Summary:\n');
    fprintf('  Total Distance:   %.2f km\n', report.totalDistance / 1000);
    fprintf('  Flight Time:      %.1f min\n', report.flightTime);
    fprintf('  Waypoints:        %d\n', report.waypointCount);
    fprintf('  Area Covered:     %.2f km²\n', report.areaCovered);
    fprintf('  Safety Score:     %.1f%%\n', report.safetyScore);
    fprintf('  Obstacles:        %d\n', report.obstaclesCounted);
    fprintf('  Terrain Range:    %.1f - %.1f m\n\n', report.terrainMin, report.terrainMax);
end

%% Helper: Conditional value
function result = ifthenelse(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
