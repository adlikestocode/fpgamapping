%% pathSmoother.m
% Smooth path between waypoints for realistic drone trajectory
% Creates intermediate points with spline curves
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Coverage Path Planning - Module 2
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [smoothedPath, smoothStats] = pathSmoother(waypoints, params, method)
    %PATHSMOOTHER Smooth waypoint path for realistic drone flight
    %
    % Syntax:
    %   [smoothedPath, smoothStats] = pathSmoother(waypoints, params)
    %   [smoothedPath, smoothStats] = pathSmoother(waypoints, params, 'spline')
    %
    % Inputs:
    %   waypoints - [Nx2] or [Nx3] or [Nx4+] matrix of waypoints
    %   params    - struct with smoothing configuration
    %   method    - 'linear' (default), 'spline' interpolation
    %
    % Outputs:
    %   smoothedPath - densified waypoint matrix with smooth interpolation
    %   smoothStats  - struct with smoothing statistics
    %
    % Example:
    %   [smoothed, stats] = pathSmoother(waypoints, params);
    %   [smoothed, stats] = pathSmoother(waypoints, params, 'spline');
    
    %% Input validation
    if nargin < 2
        error('pathSmoother:MissingInput', 'Requires waypoints and params');
    end
    
    if nargin < 3
        method = 'spline';
    end
    
    if ~isnumeric(waypoints) || size(waypoints, 1) < 2
        error('pathSmoother:InvalidWaypoints', ...
              'waypoints must be Nx2+ matrix with N >= 2');
    end
    
    method = lower(char(method));
    validMethods = {'linear', 'spline'};
    if ~ismember(method, validMethods)
        error('pathSmoother:InvalidMethod', ...
              'method must be linear or spline (bezier in future)');
    end
    
    %% Determine dimensionality
    waypointDim = size(waypoints, 2);
    is3D = (waypointDim >= 3);
    
    fprintf('\n=== Path Smoothing ===\n');
    fprintf('Waypoints: %d\n', size(waypoints, 1));
    fprintf('Dimension: %d columns (%s)\n', waypointDim, ...
            ifthenelse(is3D, '3D [X,Y,Z]', '2D [X,Y]'));
    fprintf('Method: %s\n', method);
    
    %% Get smoothing parameters
    if isfield(params, 'smoothDensity')
        density = params.smoothDensity;
    else
        density = 10;  % Default: 10 points per segment
    end
    
    fprintf('Interpolation density: %d points per segment\n', density);
    
    %% Apply smoothing based on method
    tic;
    
    switch method
        case 'linear'
            smoothedPath = smoothLinear(waypoints, density);
        case 'spline'
            smoothedPath = smoothSpline(waypoints, density);
    end
    
    elapsed = toc;
    
    %% Calculate statistics
    smoothStats = calculateSmoothStats(waypoints, smoothedPath, elapsed, method);
    
    %% Display results
    fprintf('Results:\n');
    fprintf('  Original waypoints: %d\n', size(waypoints, 1));
    fprintf('  Smoothed points: %d\n', size(smoothedPath, 1));
    fprintf('  Densification: %.2fx\n', size(smoothedPath, 1) / size(waypoints, 1));
    fprintf('  Path length: %.1f m → %.1f m\n', ...
            smoothStats.originalLength, smoothStats.smoothedLength);
    fprintf('  Length change: %.2f%%\n', ...
            (smoothStats.smoothedLength - smoothStats.originalLength) / ...
            smoothStats.originalLength * 100);
    fprintf('  Max curvature: %.4f rad\n', smoothStats.maxCurvature);
    fprintf('  Compute time: %.4f seconds\n', elapsed);
    fprintf('====================\n\n');
    
end

%% Method 1: Linear interpolation
function smoothedPath = smoothLinear(waypoints, density)
    %SMOOTHLINEAR Create intermediate points with linear interpolation
    
    n = size(waypoints, 1);
    smoothedPath = [];
    
    for i = 1:n - 1
        % Current and next waypoint
        p1 = waypoints(i, :);
        p2 = waypoints(i+1, :);
        
        % Linear interpolation: t from 0 to 1
        t = linspace(0, 1, density + 1)';
        segment = zeros(density + 1, size(waypoints, 2));
        
        for d = 1:size(waypoints, 2)
            segment(:, d) = p1(d) + t * (p2(d) - p1(d));
        end
        
        % Append (skip last point to avoid duplication)
        if i < n - 1
            smoothedPath = [smoothedPath; segment(1:end-1, :)];
        else
            smoothedPath = [smoothedPath; segment];
        end
    end
end

%% Method 2: Spline interpolation (cubic)
function smoothedPath = smoothSpline(waypoints, density)
    %SMOOTHSPLINE Create intermediate points with cubic spline
    
    n = size(waypoints, 1);
    
    % Parameter for spline: 0 to n-1 (arc length approximation)
    t_orig = (0:n-1)';
    t_smooth = linspace(0, n-1, (n-1)*density + 1)';
    
    % Build smoothed path - interpolate each column
    smoothedPath = zeros(length(t_smooth), size(waypoints, 2));
    
    for col = 1:size(waypoints, 2)
        % Use MATLAB's spline function for cubic spline interpolation
        smoothedPath(:, col) = spline(t_orig, waypoints(:, col), t_smooth);
    end
end

%% Helper: Calculate smoothing statistics
function smoothStats = calculateSmoothStats(waypoints, smoothedPath, elapsed, method)
    %CALCULATESMOOOTHSTATS Compute smoothing quality metrics
    
    % Original path length
    originalLength = 0;
    for i = 1:size(waypoints, 1) - 1
        dx = waypoints(i+1, :) - waypoints(i, :);
        originalLength = originalLength + norm(dx);
    end
    
    % Smoothed path length
    smoothedLength = 0;
    for i = 1:size(smoothedPath, 1) - 1
        dx = smoothedPath(i+1, :) - smoothedPath(i, :);
        smoothedLength = smoothedLength + norm(dx);
    end
    
    % Calculate curvature at points (2D only)
    maxCurvature = 0;
    for i = 2:min(size(smoothedPath, 1) - 1, size(smoothedPath, 1) - 1)
        p1 = smoothedPath(i-1, 1:2);
        p2 = smoothedPath(i, 1:2);
        p3 = smoothedPath(i+1, 1:2);
        
        v1 = p2 - p1;
        v2 = p3 - p2;
        
        % Curvature angle
        if norm(v1) > 1e-6 && norm(v2) > 1e-6
            angle = atan2(v2(2), v2(1)) - atan2(v1(2), v1(1));
            curvature = abs(angle);
            if curvature > pi
                curvature = 2*pi - curvature;
            end
            maxCurvature = max(maxCurvature, curvature);
        end
    end
    
    smoothStats = struct(...
        'method', method, ...
        'originalWaypoints', size(waypoints, 1), ...
        'smoothedPoints', size(smoothedPath, 1), ...
        'densificationRatio', size(smoothedPath, 1) / size(waypoints, 1), ...
        'originalLength', originalLength, ...
        'smoothedLength', smoothedLength, ...
        'lengthChange', smoothedLength - originalLength, ...
        'maxCurvature', maxCurvature, ...
        'computeTime', elapsed ...
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
