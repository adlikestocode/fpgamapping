%% tspNearestNeighbor.m
% Optimize waypoint visiting order using Nearest Neighbor TSP approximation
% Reduces total path length by reordering waypoints intelligently
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Coverage Path Planning - Module 2
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [optimizedWaypoints, tspStats] = tspNearestNeighbor(waypoints, startIdx)
    %TSPNEARESTNEIGHBOR Optimize waypoint order using greedy TSP algorithm
    %
    % Syntax:
    %   [optimizedWaypoints, tspStats] = tspNearestNeighbor(waypoints)
    %   [optimizedWaypoints, tspStats] = tspNearestNeighbor(waypoints, startIdx)
    %
    % Inputs:
    %   waypoints - [Nx2] or [Nx3] or [Nx4+] matrix
    %              Must include [X, Y] in first 2 columns
    %              Additional columns (Z, order, etc.) preserved
    %   startIdx  - (optional) Starting waypoint index (default: 1)
    %
    % Outputs:
    %   optimizedWaypoints - Same format as input, reordered by TSP
    %   tspStats - struct with optimization statistics
    %
    % Example:
    %   [optimized, stats] = tspNearestNeighbor(waypoints);
    %   [optimized, stats] = tspNearestNeighbor(waypoints, 100);
    
    %% Input validation
    if nargin < 1
        error('tspNearestNeighbor:MissingInput', 'waypoints required');
    end
    
    if nargin < 2
        startIdx = 1;
    end
    
    if ~isnumeric(waypoints) || size(waypoints, 1) < 2
        error('tspNearestNeighbor:InvalidWaypoints', ...
              'waypoints must be Nx2+ matrix with N >= 2');
    end
    
    if size(waypoints, 2) < 2
        error('tspNearestNeighbor:InvalidWaypoints', ...
              'waypoints must have at least 2 columns [X, Y, ...]');
    end
    
    if startIdx < 1 || startIdx > size(waypoints, 1)
        error('tspNearestNeighbor:InvalidStart', ...
              'startIdx must be between 1 and %d', size(waypoints, 1));
    end
    
    %% Calculate original path distance
    tic;
    originalDistance = calculatePathDistance(waypoints);
    
    fprintf('\n=== TSP Nearest Neighbor Optimization ===\n');
    fprintf('Waypoints: %d\n', size(waypoints, 1));
    fprintf('Dimensions: %d columns\n', size(waypoints, 2));
    fprintf('Starting waypoint: %d\n', startIdx);
    fprintf('Original path distance: %.1f m\n', originalDistance);
    
    %% Run nearest neighbor algorithm
    [orderedIdx, visitOrder] = nearestNeighborTSP(waypoints, startIdx);
    
    %% Build optimized waypoints with new order
    optimizedWaypoints = waypoints(orderedIdx, :);
    
    %% Calculate optimized distance
    optimizedDistance = calculatePathDistance(optimizedWaypoints);
    
    %% Calculate statistics
    improvement = (originalDistance - optimizedDistance) / originalDistance * 100;
    computeTime = toc;
    
    fprintf('Optimized path distance: %.1f m\n', optimizedDistance);
    fprintf('Distance reduction: %.1f m (%.2f%%)\n', ...
            originalDistance - optimizedDistance, improvement);
    fprintf('Compute time: %.4f seconds\n', computeTime);
    fprintf('========================================\n\n');
    
    %% Build output struct
    tspStats = struct(...
        'originalDistance', originalDistance, ...
        'optimizedDistance', optimizedDistance, ...
        'distanceReduction', originalDistance - optimizedDistance, ...
        'improvement', improvement, ...
        'computeTime', computeTime, ...
        'startIdx', startIdx, ...
        'numWaypoints', size(waypoints, 1), ...
        'algorithm', 'nearest_neighbor' ...
    );
    
end

%% Helper: Nearest Neighbor TSP
function [orderedIdx, visitOrder] = nearestNeighborTSP(waypoints, startIdx)
    %NEARESTNEIGHBORTSP Greedy TSP using nearest unvisited neighbor
    
    n = size(waypoints, 1);
    visited = false(n, 1);
    orderedIdx = zeros(n, 1);
    visitOrder = zeros(n, 1);
    
    % Start at specified waypoint
    currentIdx = startIdx;
    visited(currentIdx) = true;
    orderedIdx(1) = currentIdx;
    visitOrder(currentIdx) = 1;
    
    % Iteratively visit nearest unvisited neighbor
    for step = 2:n
        nearestIdx = findNearestUnvisited(waypoints, currentIdx, visited);
        visited(nearestIdx) = true;
        orderedIdx(step) = nearestIdx;
        visitOrder(nearestIdx) = step;
        currentIdx = nearestIdx;
    end
    
end

%% Helper: Find nearest unvisited waypoint
function nearestIdx = findNearestUnvisited(waypoints, currentIdx, visited)
    %FINDNEARESTUNVISITED Find closest unvisited waypoint
    
    current = waypoints(currentIdx, 1:2);
    
    % Calculate distances to all unvisited waypoints
    distances = zeros(size(waypoints, 1), 1);
    
    for i = 1:size(waypoints, 1)
        if ~visited(i)
            dx = waypoints(i, 1) - current(1);
            dy = waypoints(i, 2) - current(2);
            
            % For 3D: include elevation in distance
            if size(waypoints, 2) >= 3
                dz = waypoints(i, 3) - current(1)*0;  % Z from destination
                if i > 1
                    dz = waypoints(i, 3) - waypoints(currentIdx, 3);
                end
                distances(i) = sqrt(dx^2 + dy^2 + dz^2);
            else
                distances(i) = sqrt(dx^2 + dy^2);
            end
        else
            distances(i) = inf;  % Mark visited as unreachable
        end
    end
    
    % Return index of nearest unvisited
    [~, nearestIdx] = min(distances);
end

%% Helper: Calculate total path distance
function totalDistance = calculatePathDistance(waypoints)
    %CALCULATEPATHDISTANCE Sum of distances between consecutive waypoints
    
    totalDistance = 0;
    n = size(waypoints, 1);
    
    for i = 1:n - 1
        if size(waypoints, 2) >= 3
            % 3D distance including elevation
            dx = waypoints(i+1, 1) - waypoints(i, 1);
            dy = waypoints(i+1, 2) - waypoints(i, 2);
            dz = waypoints(i+1, 3) - waypoints(i, 3);
            totalDistance = totalDistance + sqrt(dx^2 + dy^2 + dz^2);
        else
            % 2D distance
            dx = waypoints(i+1, 1) - waypoints(i, 1);
            dy = waypoints(i+1, 2) - waypoints(i, 2);
            totalDistance = totalDistance + sqrt(dx^2 + dy^2);
        end
    end
end
