%% boustrophedonPath.m
% Generate boustrophedon (zigzag/lawnmower) coverage path from waypoint grid
% Creates efficient sweep pattern for complete area coverage
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Coverage Path Planning - Module 2
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [orderedWaypoints, pathStats] = boustrophedonPath(waypoints, params, surveyArea)
    %BOUSTROPHEDONPATH Generate zigzag coverage path from waypoint grid
    %
    % Syntax:
    %   [orderedWaypoints, pathStats] = boustrophedonPath(waypoints, params, surveyArea)
    %
    % Inputs:
    %   waypoints   - [Nx2] or [Nx3] matrix [X,Y] or [X,Y,Z]
    %   params      - struct with gridSpacing and sweep direction
    %   surveyArea  - struct with xMin, xMax, yMin, yMax (bounds)
    %
    % Outputs:
    %   orderedWaypoints - [Nx4] or [Nx5] matrix with visit order added
    %                      Format: [X, Y, Z(if 3D), order, (reserved)]
    %   pathStats   - struct with path statistics and efficiency metrics
    %
    % Example:
    %   params = parameters();
    %   surveyArea = defineSurveyArea(params);
    %   [gridX, gridY, wp] = generateGrid(surveyArea, params);
    %   [orderedWP, stats] = boustrophedonPath(wp, params, surveyArea);
    
    %% Input validation
    if nargin < 3
        error('boustrophedonPath:MissingInput', ...
              'Requires waypoints, params, and surveyArea');
    end
    
    if ~isnumeric(waypoints) || size(waypoints, 1) < 2
        error('boustrophedonPath:InvalidWaypoints', ...
              'waypoints must be Nx2 or Nx3 matrix with N >= 2');
    end
    
    %% Determine dimensionality
    waypointDim = size(waypoints, 2);
    if waypointDim == 2
        is3D = false;
        waypoints = [waypoints, zeros(size(waypoints, 1), 1)];  % Add dummy Z
    elseif waypointDim == 3
        is3D = true;
    else
        error('boustrophedonPath:InvalidDimension', ...
              'waypoints must have 2 or 3 columns');
    end
    
    fprintf('\n=== Boustrophedon Path Generation ===\n');
    fprintf('Waypoints: %d (dimension: %s)\n', size(waypoints, 1), ...
            ifthenelse(is3D, '3D [X,Y,Z]', '2D [X,Y]'));
    
    %% Detect grid structure
    gridSpacing = params.gridSpacing;
    xMin = surveyArea.xMin;
    xMax = surveyArea.xMax;
    yMin = surveyArea.yMin;
    yMax = surveyArea.yMax;
    
    % Unique X and Y coordinates (with tolerance for floating point)
    uniqueX = unique(round(waypoints(:, 1) / gridSpacing) * gridSpacing);
    uniqueY = unique(round(waypoints(:, 2) / gridSpacing) * gridSpacing);
    
    numX = length(uniqueX);
    numY = length(uniqueY);
    
    fprintf('Grid structure: %d × %d (%d unique X, %d unique Y)\n', ...
            numX, numY, numX, numY);
    
    %% Determine sweep direction (which way to zigzag)
    sweepDir = determineDirection(waypoints, gridSpacing);
    fprintf('Sweep direction: %s\n', sweepDir);
    
    %% Create boustrophedon order
    orderedWaypoints = createBoustrophedon(waypoints, sweepDir, gridSpacing);
    
    %% Calculate path statistics
    pathStats = calculatePathStats(orderedWaypoints, is3D);
    pathStats.sweepDirection = sweepDir;
    
    %% Add order column
    orderedWaypoints = [orderedWaypoints, (1:size(orderedWaypoints, 1))'];
    
    %% Display results
    fprintf('Path Statistics:\n');
    fprintf('  Total distance: %.1f m\n', pathStats.totalDistance);
    fprintf('  Number of waypoints: %d\n', pathStats.numWaypoints);
    fprintf('  Number of segments: %d\n', pathStats.numSegments);
    fprintf('  Number of turns: %d\n', pathStats.numTurns);
    fprintf('  Path efficiency: %.2f%%\n', pathStats.pathEfficiency * 100);
    fprintf('===================================\n\n');
    
end

%% Helper: Determine sweep direction
function sweepDir = determineDirection(waypoints, gridSpacing)
    %DETERMINEDIRECTION Choose sweep direction (EW or NS)
    
    xRange = max(waypoints(:, 1)) - min(waypoints(:, 1));
    yRange = max(waypoints(:, 2)) - min(waypoints(:, 2));
    
    % Sweep along longer dimension
    if xRange >= yRange
        sweepDir = 'EW';  % East-West (sweep along X)
    else
        sweepDir = 'NS';  % North-South (sweep along Y)
    end
end

%% Helper: Create boustrophedon pattern
function orderedWaypoints = createBoustrophedon(waypoints, sweepDir, gridSpacing)
    %CREATEBOUSTROPHEDON Generate zigzag ordering of waypoints
    
    tolerance = gridSpacing * 0.1;
    
    if strcmp(sweepDir, 'EW')
        % Sweep East-West (along X), rows in Y direction
        [~, sortIdx] = sort(waypoints(:, 2));  % Sort by Y first
        waypoints = waypoints(sortIdx, :);
        
        % Group into rows (constant Y)
        rowIdx = 1;
        rows = cell(100, 1);
        currentY = waypoints(1, 2);
        
        for i = 1:size(waypoints, 1)
            if abs(waypoints(i, 2) - currentY) > tolerance
                rowIdx = rowIdx + 1;
                currentY = waypoints(i, 2);
            end
            if rowIdx > size(rows, 1)
                rows = [rows; cell(100, 1)];
            end
            rows{rowIdx} = [rows{rowIdx}; i];
        end
        
        rows = rows(1:rowIdx);
        
        % Create zigzag: alternate direction each row
        orderedIdx = [];
        for i = 1:length(rows)
            rowIndices = rows{i};
            if mod(i, 2) == 1
                % Odd rows: left to right (ascending X)
                [~, order] = sort(waypoints(rowIndices, 1));
            else
                % Even rows: right to left (descending X)
                [~, order] = sort(waypoints(rowIndices, 1), 'descend');
            end
            orderedIdx = [orderedIdx; rowIndices(order)];
        end
        
    else  % 'NS'
        % Sweep North-South (along Y), rows in X direction
        [~, sortIdx] = sort(waypoints(:, 1));  % Sort by X first
        waypoints = waypoints(sortIdx, :);
        
        % Group into rows (constant X)
        rowIdx = 1;
        rows = cell(100, 1);
        currentX = waypoints(1, 1);
        
        for i = 1:size(waypoints, 1)
            if abs(waypoints(i, 1) - currentX) > tolerance
                rowIdx = rowIdx + 1;
                currentX = waypoints(i, 1);
            end
            if rowIdx > size(rows, 1)
                rows = [rows; cell(100, 1)];
            end
            rows{rowIdx} = [rows{rowIdx}; i];
        end
        
        rows = rows(1:rowIdx);
        
        % Create zigzag: alternate direction each row
        orderedIdx = [];
        for i = 1:length(rows)
            rowIndices = rows{i};
            if mod(i, 2) == 1
                % Odd rows: bottom to top (ascending Y)
                [~, order] = sort(waypoints(rowIndices, 2));
            else
                % Even rows: top to bottom (descending Y)
                [~, order] = sort(waypoints(rowIndices, 2), 'descend');
            end
            orderedIdx = [orderedIdx; rowIndices(order)];
        end
    end
    
    orderedWaypoints = waypoints(orderedIdx, :);
end

%% Helper: Calculate path statistics
function pathStats = calculatePathStats(waypoints, is3D)
    %CALCULATEPATHSTATS Compute metrics for generated path
    
    numPoints = size(waypoints, 1);
    
    % Calculate distances between consecutive waypoints
    distances = zeros(numPoints - 1, 1);
    for i = 1:numPoints - 1
        if is3D
            dx = waypoints(i+1, 1) - waypoints(i, 1);
            dy = waypoints(i+1, 2) - waypoints(i, 2);
            dz = waypoints(i+1, 3) - waypoints(i, 3);
            distances(i) = sqrt(dx^2 + dy^2 + dz^2);
        else
            dx = waypoints(i+1, 1) - waypoints(i, 1);
            dy = waypoints(i+1, 2) - waypoints(i, 2);
            distances(i) = sqrt(dx^2 + dy^2);
        end
    end
    
    totalDistance = sum(distances);
    
    % Count turns (changes in direction)
    numTurns = 0;
    if numPoints > 2
        for i = 2:numPoints - 1
            dir1 = [waypoints(i, 1) - waypoints(i-1, 1), ...
                    waypoints(i, 2) - waypoints(i-1, 2)];
            dir2 = [waypoints(i+1, 1) - waypoints(i, 1), ...
                    waypoints(i+1, 2) - waypoints(i, 2)];
            
            % Check if direction change (dot product < 0.99 means turn)
            dot = (dir1(1)*dir2(1) + dir1(2)*dir2(2)) / ...
                  (norm(dir1) * norm(dir2) + eps);
            if dot < 0.99
                numTurns = numTurns + 1;
            end
        end
    end
    
    % Efficiency: straight line distance / actual path
    minX = min(waypoints(:, 1));
    maxX = max(waypoints(:, 1));
    minY = min(waypoints(:, 2));
    maxY = max(waypoints(:, 2));
    
    if is3D
        minZ = min(waypoints(:, 3));
        maxZ = max(waypoints(:, 3));
        straightLine = sqrt((maxX-minX)^2 + (maxY-minY)^2 + (maxZ-minZ)^2);
    else
        straightLine = sqrt((maxX-minX)^2 + (maxY-minY)^2);
    end
    
    efficiency = straightLine / (totalDistance + eps);
    
    % Build output struct
    pathStats = struct(...
        'totalDistance', totalDistance, ...
        'numWaypoints', numPoints, ...
        'numSegments', numPoints - 1, ...
        'numTurns', numTurns, ...
        'pathEfficiency', efficiency, ...
        'minDistance', min(distances), ...
        'maxDistance', max(distances), ...
        'meanDistance', mean(distances) ...
    );
end

%% Helper: Conditional value
function result = ifthenelse(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
