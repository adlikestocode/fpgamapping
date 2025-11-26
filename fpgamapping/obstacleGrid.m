%% obstacleGrid.m
% Create obstacle grid from DEM terrain and user-defined no-fly zones
% Detects steep terrain and custom obstacles
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: A* Pathfinding - Module 3
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [obsGrid, obstacleInfo] = obstacleGrid(demData, params, customObstacles)
    %OBSTACLEGRID Create obstacle grid from terrain slopes and custom zones
    %
    % Syntax:
    %   [obsGrid, obstacleInfo] = obstacleGrid(demData, params)
    %   [obsGrid, obstacleInfo] = obstacleGrid(demData, params, customObstacles)
    %
    % Inputs:
    %   demData          - struct from generateSyntheticDEM
    %   params           - struct with maxSlope and obstacleBuffer
    %   customObstacles  - (optional) struct with circles/rectangles/polygons
    %
    % Outputs:
    %   obsGrid      - [MxN] binary grid (0=free, 1=obstacle)
    %   obstacleInfo - struct with obstacle statistics
    
    if nargin < 2
        error('obstacleGrid:MissingInput', 'Requires demData and params');
    end
    
    if nargin < 3
        customObstacles = [];
    end
    
    fprintf('\n=== Obstacle Grid Generation ===\n');
    
    %% Initialize obstacle grid
    Z = demData.Z;
    [rows, cols] = size(Z);
    obsGrid = zeros(rows, cols);
    
    resolution = demData.resolution;
    maxSlope = params.maxSlope;
    buffer = ifthenelse(isfield(params, 'obstacleBuffer'), ...
                        params.obstacleBuffer, 30);
    
    fprintf('Grid size: %d × %d (%.0f m resolution)\n', rows, cols, resolution);
    fprintf('Max slope: %.0f degrees\n', maxSlope);
    fprintf('Buffer zone: %.0f m\n\n', buffer);
    
    %% Step 1: Detect steep terrain
    fprintf('Step 1: Detecting steep terrain...\n');
    slopeCount = 0;
    
    for i = 2:rows-1
        for j = 2:cols-1
            % Calculate slope (Sobel-like operator)
            dz_dx = (Z(i, j+1) - Z(i, j-1)) / (2 * resolution);
            dz_dy = (Z(i+1, j) - Z(i-1, j)) / (2 * resolution);
            
            % Slope in degrees
            slope = atan(sqrt(dz_dx^2 + dz_dy^2)) * 180 / pi;
            
            if slope > maxSlope
                obsGrid(i, j) = 1;
                slopeCount = slopeCount + 1;
            end
        end
    end
    
    fprintf('  ✓ Steep terrain cells: %d (%.1f%%)\n', ...
            slopeCount, slopeCount / (rows*cols) * 100);
    
    %% Step 2: Add buffer zones to steep areas
    fprintf('Step 2: Adding buffer zones...\n');
    obsGrid_buffered = obsGrid;
    bufferCells = round(buffer / resolution);
    
    for i = 1:rows
        for j = 1:cols
            if obsGrid(i, j) > 0
                % Add buffer around obstacle
                for di = -bufferCells:bufferCells
                    for dj = -bufferCells:bufferCells
                        ni = i + di;
                        nj = j + dj;
                        if ni >= 1 && ni <= rows && nj >= 1 && nj <= cols
                            obsGrid_buffered(ni, nj) = 1;
                        end
                    end
                end
            end
        end
    end
    
    obsGrid = obsGrid_buffered;
    bufferCount = sum(obsGrid(:)) - slopeCount;
    fprintf('  ✓ Buffer cells added: %d\n', bufferCount);
    
    %% Step 3: Add custom obstacles
    if ~isempty(customObstacles)
        fprintf('Step 3: Adding custom obstacles...\n');
        customCount = 0;
        
        % Circles
        if isfield(customObstacles, 'circles') && ~isempty(customObstacles.circles)
            for c = 1:size(customObstacles.circles, 1)
                cx = customObstacles.circles(c, 1);
                cy = customObstacles.circles(c, 2);
                cr = customObstacles.circles(c, 3);
                
                for i = 1:rows
                    for j = 1:cols
                        x = demData.xMin + (j-1) * resolution;
                        y = demData.yMin + (i-1) * resolution;
                        
                        dist = sqrt((x-cx)^2 + (y-cy)^2);
                        if dist < cr
                            obsGrid(i, j) = 1;
                            customCount = customCount + 1;
                        end
                    end
                end
            end
        end
        
        % Rectangles
        if isfield(customObstacles, 'rectangles') && ~isempty(customObstacles.rectangles)
            for r = 1:size(customObstacles.rectangles, 1)
                xMin = customObstacles.rectangles(r, 1);
                yMin = customObstacles.rectangles(r, 2);
                width = customObstacles.rectangles(r, 3);
                height = customObstacles.rectangles(r, 4);
                
                for i = 1:rows
                    for j = 1:cols
                        x = demData.xMin + (j-1) * resolution;
                        y = demData.yMin + (i-1) * resolution;
                        
                        if x >= xMin && x <= xMin+width && ...
                           y >= yMin && y <= yMin+height
                            obsGrid(i, j) = 1;
                            customCount = customCount + 1;
                        end
                    end
                end
            end
        end
        
        fprintf('  ✓ Custom obstacles added: %d cells\n', customCount);
    end
    
    %% Step 4: Calculate statistics
    fprintf('Step 4: Calculating statistics...\n');
    
    totalCells = rows * cols;
    obstacleCells = sum(obsGrid(:));
    freeCells = totalCells - obstacleCells;
    freePercentage = (freeCells / totalCells) * 100;
    obstacleArea = obstacleCells * resolution^2;
    
    fprintf('  Total cells: %d\n', totalCells);
    fprintf('  Obstacle cells: %d (%.1f%%)\n', obstacleCells, ...
            obstacleCells/totalCells*100);
    fprintf('  Free cells: %d (%.1f%%)\n', freeCells, freePercentage);
    fprintf('  Obstacle area: %.0f m²\n', obstacleArea);
    
    %% Build output struct
    obstacleInfo = struct(...
        'totalCells', totalCells, ...
        'obstacleCells', obstacleCells, ...
        'freeCells', freeCells, ...
        'freeSpacePercentage', freePercentage, ...
        'totalObstacleArea', obstacleArea, ...
        'resolution', resolution, ...
        'bounds', [demData.xMin, demData.xMax, demData.yMin, demData.yMax], ...
        'maxSlope', maxSlope, ...
        'bufferZone', buffer ...
    );
    
    fprintf('=================================\n\n');
end

%% Helper: Conditional value
function result = ifthenelse(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
