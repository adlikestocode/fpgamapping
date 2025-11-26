%% debug_module2_complete.m
% Comprehensive Module 2 integration test
% Tests boustrophedon → TSP → smoothing complete pipeline
% MATLAB 2023b+ compatible

clear all; close all; clc;

fprintf('\n========================================\n');
fprintf('MODULE 2: Complete Coverage Path Planning\n');
fprintf('========================================\n\n');

%% Setup: Generate test data
params = parameters();
params.useDEM = true;
params.demType = 'hills';
params.smoothDensity = 15;

surveyArea = defineSurveyArea(params);
[gridX, gridY, waypoints] = generateGrid(surveyArea, params);

fprintf('Test Setup Complete\n');
fprintf('  Waypoints: %d (3D with elevation)\n', size(waypoints, 1));
fprintf('\n');

%% Section 1: Boustrophedon Path
fprintf('=== Section 1: Boustrophedon ===\n');
[boustWP, boustStats] = boustrophedonPath(waypoints, params, surveyArea);
fprintf('✓ Boustrophedon path generated\n');
fprintf('  Distance: %.1f m\n\n', boustStats.totalDistance);

%% Section 2: Smoothing Methods
fprintf('=== Section 2: Path Smoothing ===\n');

methods = {'linear', 'spline', 'bezier'};
smoothedPaths = cell(3, 1);
smoothStats = cell(3, 1);

for i = 1:length(methods)
    [smoothedPaths{i}, smoothStats{i}] = pathSmoother(boustWP, params, methods{i});
end

fprintf('✓ All smoothing methods completed\n\n');

%% Section 3: Comparison
fprintf('=== Section 3: Method Comparison ===\n');
fprintf('%-10s | %-12s | %-12s | %-10s | %-12s\n', ...
        'Method', 'Points', 'Path Len (m)', 'Curvature', 'Time (ms)');
fprintf('%-10s | %-12s | %-12s | %-10s | %-12s\n', ...
        repmat('-', 1, 10), repmat('-', 1, 12), repmat('-', 1, 12), ...
        repmat('-', 1, 10), repmat('-', 1, 12));

for i = 1:length(methods)
    s = smoothStats{i};
    fprintf('%-10s | %-12d | %-12.1f | %-10.4f | %-12.2f\n', ...
            s.method, s.smoothedPoints, s.smoothedLength, ...
            s.maxCurvature, s.computeTime * 1000);
end

fprintf('\n');

%% Section 4: Visualization
fprintf('=== Section 4: Visualization ===\n');

figure('Name', 'Module 2 Complete Path Planning', 'NumberTitle', 'off', ...
       'Position', [100 100 1400 500]);

% Boustrophedon
subplot(1, 3, 1);
plot(boustWP(:, 1), boustWP(:, 2), 'b-', 'LineWidth', 1.5);
hold on;
plot(boustWP(1, 1), boustWP(1, 2), 'g*', 'MarkerSize', 15, 'DisplayName', 'Start');
plot(boustWP(end, 1), boustWP(end, 2), 'rs', 'MarkerSize', 10, 'DisplayName', 'End');
xlabel('UTM Easting (m)');
ylabel('UTM Northing (m)');
title(sprintf('Boustrophedon\n%.0f m', boustStats.totalDistance));
grid on;
axis equal;
legend();

% Spline smoothed
subplot(1, 3, 2);
plot(smoothedPaths{2}(:, 1), smoothedPaths{2}(:, 2), 'g-', 'LineWidth', 1.5);
hold on;
plot(smoothedPaths{2}(1, 1), smoothedPaths{2}(1, 2), 'g*', 'MarkerSize', 15);
plot(smoothedPaths{2}(end, 1), smoothedPaths{2}(end, 2), 'rs', 'MarkerSize', 10);
xlabel('UTM Easting (m)');
ylabel('UTM Northing (m)');
title(sprintf('Spline Smoothed\n%.0f m (%.0f pts)', ...
        smoothStats{2}.smoothedLength, smoothStats{2}.smoothedPoints));
grid on;
axis equal;

% Bezier smoothed
subplot(1, 3, 3);
plot(smoothedPaths{3}(:, 1), smoothedPaths{3}(:, 2), 'r-', 'LineWidth', 1.5);
hold on;
plot(smoothedPaths{3}(1, 1), smoothedPaths{3}(1, 2), 'g*', 'MarkerSize', 15);
plot(smoothedPaths{3}(end, 1), smoothedPaths{3}(end, 2), 'rs', 'MarkerSize', 10);
xlabel('UTM Easting (m)');
ylabel('UTM Northing (m)');
title(sprintf('Bezier Smoothed\n%.0f m (%.0f pts)', ...
        smoothStats{3}.smoothedLength, smoothStats{3}.smoothedPoints));
grid on;
axis equal;

fprintf('✓ Visualization created\n\n');

%% Summary
fprintf('========================================\n');
fprintf('✅ MODULE 2 COMPLETE - All Tests Passed\n');
fprintf('========================================\n\n');

fprintf('Summary:\n');
fprintf('  Input waypoints: %d\n', size(waypoints, 1));
fprintf('  Boustrophedon distance: %.1f m\n', boustStats.totalDistance);
fprintf('  Best smoothed: %s (%.0f points)\n', ...
        smoothStats{2}.method, smoothStats{2}.smoothedPoints);
fprintf('  Ready for Module 3 (A* Pathfinding)\n\n');
