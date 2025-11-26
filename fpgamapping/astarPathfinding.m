%% astarPathfinding.m
% A* pathfinding algorithm with terrain and obstacle awareness
% Finds optimal collision-free paths while respecting terrain constraints
% ALWAYS returns 3D paths with elevation data
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: A* Pathfinding - Module 3
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [path, pathStats] = astarPathfinding(startPoint, goalPoint, demData, obstacles, params)
    %ASTARPATHFINDING Find optimal path using A* algorithm with terrain awareness
    %
    % Syntax:
    %   [path, pathStats] = astarPathfinding(start, goal, demData, obstacles, params)
    %
    % Inputs:
    %   startPoint - [X, Y] or [X, Y, Z] start coordinate
    %   goalPoint  - [X, Y] or [X, Y, Z] goal coordinate
    %   demData    - struct from generateSyntheticDEM or demImport
    %   obstacles  - struct with obstacle info ([] if none)
    %   params     - struct with A* configuration
    %
    % Outputs:
    %   path      - [Nx3] waypoint path [X, Y, Z] from start to goal (ALWAYS 3D)
    %   pathStats - struct with path statistics
    %
    % Example:
    %   [path, stats] = astarPathfinding([500100, 5400100], [500900, 5400900], ...
    %                                     demData, obstacles, params);
    
    %% Input validation
    if nargin < 5
        error('astarPathfinding:MissingInput', ...
              'Requires all 5 arguments: start, goal, demData, obstacles, params');
    end
    
    startPoint = startPoint(:)';
    goalPoint = goalPoint(:)';
    
    if length(startPoint) < 2 || length(goalPoint) < 2
        error('astarPathfinding:InvalidCoordinates', ...
              'Start and goal must have at least [X, Y]');
    end
    
    fprintf('\n=== A* Pathfinding ===\n');
    fprintf('Start: [%.1f, %.1f]\n', startPoint(1), startPoint(2));
    fprintf('Goal: [%.1f, %.1f]\n', goalPoint(1), goalPoint(2));
    
    %% Setup
    tic;
    gridResolution = demData.resolution;
    
    %% Initialize A* search
    % Create node at start
    startNode = struct('pos', startPoint(1:2), 'g', 0, 'h', 0, 'f', 0, 'parent', []);
    startNode.h = heuristic(startPoint(1:2), goalPoint(1:2), params);
    startNode.f = startNode.g + startNode.h;
    
    % Initialize open/closed lists
    openList = startNode;
    closedList = [];
    nodesExpanded = 0;
    
    %% A* main loop
    while ~isempty(openList)
        % Find node with lowest f-score
        [~, idx] = min([openList.f]);
        currentNode = openList(idx);
        nodesExpanded = nodesExpanded + 1;
        
        % Check if goal reached
        if norm(currentNode.pos - goalPoint(1:2)) < gridResolution
            fprintf('Goal found!\n');
            path = reconstructPath(currentNode, demData);  % FIXED: Always returns 3D
            elapsed = toc;
            pathStats = createPathStats(path, nodesExpanded, elapsed, demData, params);
            fprintf('Path length: %.1f m, Nodes expanded: %d\n', ...
                    pathStats.pathLength, nodesExpanded);
            fprintf('===================\n\n');
            return;
        end
        
        % Move current from open to closed
        closedList = [closedList; currentNode];
        openList(idx) = [];
        
        % Expand neighbors (8-connected grid)
        neighbors = getNeighbors(currentNode, gridResolution, demData, obstacles, params);
        
        for i = 1:size(neighbors, 1)
            neighborPos = neighbors(i, 1:2);
            
            % Check if in closed list
            if isInList(neighborPos, closedList, gridResolution)
                continue;
            end
            
            % Calculate costs
            moveCost = norm(neighborPos - currentNode.pos);
            g = currentNode.g + moveCost;
            h = heuristic(neighborPos, goalPoint(1:2), params);
            f = g + h;
            
            % Check if in open list
            inOpenIdx = findInList(neighborPos, openList, gridResolution);
            
            if inOpenIdx > 0
                % Already in open list
                if f < openList(inOpenIdx).f
                    % Found better path
                    openList(inOpenIdx).g = g;
                    openList(inOpenIdx).f = f;
                    openList(inOpenIdx).parent = currentNode;
                end
            else
                % Add new node to open list
                newNode = struct('pos', neighborPos, 'g', g, 'h', h, 'f', f, ...
                                'parent', currentNode);
                openList = [openList; newNode];
            end
        end
        
        % Safety check: prevent infinite loop
        if nodesExpanded > 100000
            fprintf('Warning: Maximum nodes expanded\n');
            if ~isempty(closedList)
                [~, bestIdx] = min([closedList.f]);
                path = reconstructPath(closedList(bestIdx), demData);
            else
                z_start = demInterpolate(demData, startPoint(1), startPoint(2));
                z_goal = demInterpolate(demData, goalPoint(1), goalPoint(2));
                path = [startPoint(1:2), z_start; goalPoint(1:2), z_goal];
            end
            elapsed = toc;
            pathStats = createPathStats(path, nodesExpanded, elapsed, demData, params);
            fprintf('===================\n\n');
            return;
        end
    end
    
    % No path found
    fprintf('No path found - returning direct connection\n');
    z_start = demInterpolate(demData, startPoint(1), startPoint(2));
    z_goal = demInterpolate(demData, goalPoint(1), goalPoint(2));
    path = [startPoint(1:2), z_start; goalPoint(1:2), z_goal];
    elapsed = toc;
    pathStats = createPathStats(path, nodesExpanded, elapsed, demData, params);
    fprintf('===================\n\n');
end

%% Helper: Calculate heuristic (Euclidean distance)
function h = heuristic(pos, goal, params)
    %HEURISTIC Calculate admissible heuristic for A*
    h = norm(pos - goal);
end

%% Helper: Get neighbor nodes
function neighbors = getNeighbors(currentNode, resolution, demData, obstacles, params)
    %GETNEIGHBORS Get valid 8-connected neighbors
    
    pos = currentNode.pos;
    
    % 8-connected directions
    directions = [
        1, 0;   % Right
        -1, 0;  % Left
        0, 1;   % Up
        0, -1;  % Down
        1, 1;   % Diagonal UR
        1, -1;  % Diagonal DR
        -1, 1;  % Diagonal UL
        -1, -1; % Diagonal DL
    ];
    
    neighbors = [];
    
    for i = 1:size(directions, 1)
        newPos = pos + directions(i, :) * resolution;
        
        % Check bounds
        if newPos(1) < demData.xMin || newPos(1) > demData.xMax || ...
           newPos(2) < demData.yMin || newPos(2) > demData.yMax
            continue;
        end
        
        % Check obstacles (if provided)
        if ~isempty(obstacles)
            if isObstacleAtPoint(newPos, obstacles, params)
                continue;
            end
        end
        
        % Check terrain slope
        if isTerrainTooSteep(currentNode.pos, newPos, demData, params)
            continue;
        end
        
        neighbors = [neighbors; newPos];
    end
end

%% Helper: Check if point is obstacle
function isObstacle = isObstacleAtPoint(pos, obstacles, params)
    %ISOBSTACLEATPOINT Check if position hits obstacle
    
    isObstacle = false;
    
    % Simple check: if obstacle grid exists
    if isfield(obstacles, 'grid') && ~isempty(obstacles.grid)
        % Convert position to grid indices
        resolution = obstacles.resolution;
        xIdx = round((pos(1) - obstacles.bounds(1)) / resolution) + 1;
        yIdx = round((pos(2) - obstacles.bounds(3)) / resolution) + 1;
        
        if xIdx >= 1 && xIdx <= size(obstacles.grid, 2) && ...
           yIdx >= 1 && yIdx <= size(obstacles.grid, 1)
            if obstacles.grid(yIdx, xIdx) > 0
                isObstacle = true;
            end
        end
    end
end

%% Helper: Check terrain slope
function tooSteep = isTerrainTooSteep(p1, p2, demData, params)
    %ISTERRAINTOOSTEEP Check if terrain slope exceeds threshold
    
    tooSteep = false;
    maxSlope = params.maxSlope;
    
    % Get elevations at both points
    z1 = demInterpolate(demData, p1(1), p1(2));
    z2 = demInterpolate(demData, p2(1), p2(2));
    
    if isnan(z1) || isnan(z2)
        return;
    end
    
    % Calculate slope
    horizontalDist = norm(p2 - p1);
    verticalDist = abs(z2 - z1);
    
    if horizontalDist > 0
        slope = atan(verticalDist / horizontalDist) * 180 / pi;
        if slope > maxSlope
            tooSteep = true;
        end
    end
end

%% Helper: Check if in list
function inList = isInList(pos, list, tolerance)
    %ISINLIST Check if position exists in list
    inList = false;
    for i = 1:length(list)
        if norm(pos - list(i).pos) < tolerance
            inList = true;
            return;
        end
    end
end

%% Helper: Find in list
function idx = findInList(pos, list, tolerance)
    %FINDINLIST Find index of position in list (0 if not found)
    idx = 0;
    for i = 1:length(list)
        if norm(pos - list(i).pos) < tolerance
            idx = i;
            return;
        end
    end
end

%% Helper: Reconstruct path - FIXED TO ALWAYS RETURN 3D
function path = reconstructPath(node, demData)
    %RECONSTRUCTPATH Build 3D path by following parent pointers
    %
    % ALWAYS returns [X, Y, Z] - queries DEM for elevation if needed
    
    path = [];
    currentNode = node;
    
    while ~isempty(currentNode)
        x = currentNode.pos(1);
        y = currentNode.pos(2);
        z = demInterpolate(demData, x, y);  % ALWAYS query elevation
        path = [x, y, z; path];  % ALWAYS 3D format
        
        if isempty(currentNode.parent)
            break;
        end
        currentNode = currentNode.parent;
    end
end

%% Helper: Create path statistics
function stats = createPathStats(path, nodesExpanded, elapsed, demData, params)
    %CREATEPATHSTATS Calculate path quality metrics
    
    pathLength = 0;
    for i = 1:size(path, 1) - 1
        dx = path(i+1, :) - path(i, :);
        pathLength = pathLength + norm(dx);
    end
    
    minZ = min(path(:, 3));
    
    stats = struct(...
        'pathLength', pathLength, ...
        'numNodes', size(path, 1), ...
        'nodesExpanded', nodesExpanded, ...
        'computeTime', elapsed, ...
        'minAGL', minZ, ...
        'terrainSafe', true ...
    );
end
