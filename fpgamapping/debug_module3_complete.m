%% debug_module3_complete.m
% Complete Module 3 integration test
% Tests A* → Obstacles → Validation full workflow

clear all; close all; clc;

fprintf('\n========================================\n');
fprintf('MODULE 3: Complete A* Pathfinding\n');
fprintf('========================================\n\n');

%% Setup
params = parameters();
params.maxSlope = 30;
params.useAStar = true;
params.minAGL = 120;
params.maxClimbAngle = 20;

surveyArea = defineSurveyArea(params);
demData = generateSyntheticDEM(surveyArea, 10, 'hills');

fprintf('Setup complete\n\n');

%% Section 1: A* Pathfinding
fprintf('=== Section 1: A* Pathfinding ===\n');

start = [500100, 5400100];
goal = [500900, 5400900];

[path, astarStats] = astarPathfinding(start, goal, demData, [], params);

fprintf('Path generated: %d waypoints, %.1f m\n\n', ...
        size(path, 1), astarStats.pathLength);

%% Section 2: Obstacle Grid
fprintf('=== Section 2: Obstacle Detection ===\n');

[obsGrid, obsInfo] = obstacleGrid(demData, params);

fprintf('Obstacle grid: %.1f%% free space\n\n', obsInfo.freeSpacePercentage);

%% Section 3: Path Validation
fprintf('=== Section 3: Path Validation ===\n');

obstacles = struct('grid', obsGrid, 'resolution', obsInfo.resolution, ...
                   'bounds', obsInfo.bounds);

[isValid, violations, valStats] = pathValidator(path, demData, obstacles, params);

fprintf('Validation: %s\n', ifthenelse(isValid, 'PASS', 'FAIL'));
fprintf('Safety score: %.1f%%\n\n', valStats.safetyScore);

%% Section 1: A* Pathfinding
fprintf('=== Section 1: A* Pathfinding ===\n');

start = [500100, 5400100];
goal = [500900, 5400900];

[path, astarStats] = astarPathfinding(start, goal, demData, [], params);

% ADD ELEVATION TO 2D PATH
if size(path, 2) == 2
    Z = [];
    for i = 1:size(path, 1)
        Z = [Z; demInterpolate(demData, path(i,1), path(i,2))];
    end
    path = [path, Z];
end

fprintf('Path generated: %d waypoints, %.1f m\n\n', ...
        size(path, 1), astarStats.pathLength);

%% Section 2: Obstacle Grid
fprintf('=== Section 2: Obstacle Detection ===\n');

[obsGrid, obsInfo] = obstacleGrid(demData, params);

fprintf('Obstacle grid: %.1f%% free space\n\n', obsInfo.freeSpacePercentage);

%% Section 3: Path Validation
fprintf('=== Section 3: Path Validation ===\n');

obstacles = struct('grid', obsGrid, 'resolution', obsInfo.resolution, ...
                   'bounds', obsInfo.bounds);

[isValid, violations, valStats] = pathValidator(path, demData, obstacles, params);

fprintf('Validation: %s\n', ifthenelse(isValid, 'PASS', 'FAIL'));
fprintf('Safety score: %.1f%%\n\n', valStats.safetyScore);
%% Section 1: A* Pathfinding
fprintf('=== Section 1: A* Pathfinding ===\n');

start = [500100, 5400100];
goal = [500900, 5400900];

[path, astarStats] = astarPathfinding(start, goal, demData, [], params);

% ADD ELEVATION TO 2D PATH
if size(path, 2) == 2
    Z = [];
    for i = 1:size(path, 1)
        Z = [Z; demInterpolate(demData, path(i,1), path(i,2))];
    end
    path = [path, Z];
end

fprintf('Path generated: %d waypoints, %.1f m\n\n', ...
        size(path, 1), astarStats.pathLength);

%% Section 2: Obstacle Grid
fprintf('=== Section 2: Obstacle Detection ===\n');

[obsGrid, obsInfo] = obstacleGrid(demData, params);

fprintf('Obstacle grid: %.1f%% free space\n\n', obsInfo.freeSpacePercentage);

%% Section 3: Path Validation
fprintf('=== Section 3: Path Validation ===\n');

obstacles = struct('grid', obsGrid, 'resolution', obsInfo.resolution, ...
                   'bounds', obsInfo.bounds);

[isValid, violations, valStats] = pathValidator(path, demData, obstacles, params);

fprintf('Validation: %s\n', ifthenelse(isValid, 'PASS', 'FAIL'));
fprintf('Safety score: %.1f%%\n\n', valStats.safetyScore);

%% Section 4: Visualization
fprintf('=== Section 4: Visualization ===\n');

figure('Name', 'Module 3: Complete A* System', 'NumberTitle', 'off', ...
       'Position', [100 100 1400 600]);

% Terrain with path
subplot(2, 2, 1);
surf(demData.X, demData.Y, demData.Z, 'EdgeColor', 'none');
hold on;
if size(path, 2) >= 3
    plot3(path(:,1), path(:,2), path(:,3), 'r-', 'LineWidth', 2, ...
          'DisplayName', 'A* Path');
else
    plot(path(:,1), path(:,2), 'r-', 'LineWidth', 2, 'DisplayName', 'A* Path');
end
plot3(start(1), start(2), 105, 'g*', 'MarkerSize', 15, 'DisplayName', 'Start');
plot3(goal(1), goal(2), 105, 'bs', 'MarkerSize', 10, 'DisplayName', 'Goal');
xlabel('UTM Easting');
ylabel('UTM Northing');
zlabel('Elevation (m)');
title('3D Path on Terrain');
legend();
view(45, 45);

% 2D path with obstacles
subplot(2, 2, 2);
imagesc(demData.X(1,:), demData.Y(:,1), obsGrid);
colormap(gca, 'gray');
hold on;
plot(path(:,1), path(:,2), 'r-', 'LineWidth', 2, 'DisplayName', 'Path');
plot(start(1), start(2), 'g*', 'MarkerSize', 15, 'DisplayName', 'Start');
plot(goal(1), goal(2), 'bs', 'MarkerSize', 10, 'DisplayName', 'Goal');
xlabel('UTM Easting');
ylabel('UTM Northing');
title('Path with Obstacle Grid');
legend();
axis equal;

% Elevation profile
subplot(2, 2, 3);
pathDist = zeros(size(path, 1), 1);
for i = 2:size(path, 1)
    pathDist(i) = pathDist(i-1) + norm(path(i,1:2) - path(i-1,1:2));
end

if size(path, 2) >= 3
    plot(pathDist, path(:,3), 'b-', 'LineWidth', 2, 'DisplayName', 'Drone');
    hold on;
    terrainZ = [];
    for i = 1:size(path, 1)
        terrainZ = [terrainZ; demInterpolate(demData, path(i,1), path(i,2))];
    end
    plot(pathDist, terrainZ, 'g--', 'LineWidth', 1.5, 'DisplayName', 'Terrain');
    plot(pathDist, terrainZ + params.minAGL, 'r:', 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Min AGL (%.0fm)', params.minAGL));
else
    plot(pathDist, ones(size(pathDist))*100, 'b-', 'LineWidth', 2);
end
xlabel('Distance along path (m)');
ylabel('Elevation (m)');
title('Elevation Profile');
legend();
grid on;

% Statistics
subplot(2, 2, 4);
axis off;
stats_text = sprintf(...
    ['A* Pathfinding Results\n\n' ...
     'Path Length: %.1f m\n' ...
     'Waypoints: %d\n' ...
     'Valid: %s\n' ...
     'Safety Score: %.1f%%\n\n' ...
     'Obstacle Grid\n' ...
     'Free Space: %.1f%%\n' ...
     'Obstacle Area: %.0f m2\n\n' ...
     'Validation\n' ...
     'Collisions: %d\n' ...
     'Altitude Violations: %d\n' ...
     'Slope Violations: %d\n'], ...
    astarStats.pathLength, size(path, 1), ...
    ifthenelse(isValid, 'PASS', 'FAIL'), valStats.safetyScore, ...
    obsInfo.freeSpacePercentage, obsInfo.totalObstacleArea, ...
    length(violations.obstacleCollisions), ...
    size(violations.altitudeTooLow, 1), ...
    size(violations.slopeTooSteep, 1));

text(0.1, 0.5, stats_text, 'FontSize', 11, 'FontName', 'FixedWidth', ...
     'VerticalAlignment', 'middle');

fprintf('✓ Visualization created\n\n');

%% Summary
fprintf('========================================\n');
fprintf('✅ MODULE 3 COMPLETE\n');
fprintf('========================================\n\n');

fprintf('System Status:\n');
fprintf('  ✓ A* Pathfinding: Working\n');
fprintf('  ✓ Obstacle Detection: Working\n');
fprintf('  ✓ Path Validation: Working\n');
fprintf('  ✓ Visualization: Complete\n\n');

%% Helper
function result = ifthenelse(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end

