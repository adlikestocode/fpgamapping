%% demVisualize.m
% Create 3D visualization of Digital Elevation Model (DEM)
% Shows terrain surface, contours, and optional waypoint overlay
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: DEM (Digital Elevation Model) - Module 0
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function fig = demVisualize(demData, surveyArea, waypoints)
    %DEMVISUALIZE Create 3D terrain visualization from DEM
    %
    % Syntax:
    %   fig = demVisualize(demData)
    %   fig = demVisualize(demData, surveyArea)
    %   fig = demVisualize(demData, surveyArea, waypoints)
    %
    % Inputs:
    %   demData - struct from generateSyntheticDEM or demImport
    %   surveyArea - (optional) struct from defineSurveyArea (shows boundary)
    %   waypoints - (optional) [Nx3] waypoint matrix [X, Y, Z] for overlay
    %
    % Outputs:
    %   fig - figure handle for the created visualization
    %
    % Examples:
    %   demData = generateSyntheticDEM(surveyArea, 10, 'hills');
    %   fig = demVisualize(demData);
    %
    %   fig = demVisualize(demData, surveyArea, waypoints3D);
    
    %% Handle optional inputs
    if nargin < 2
        surveyArea = [];
    end
    if nargin < 3
        waypoints = [];
    end
    
    %% Validate inputs
    if ~isstruct(demData)
        error('demVisualize:InvalidInput', 'demData must be a struct');
    end
    
    requiredFields = {'X', 'Y', 'Z'};
    for i = 1:length(requiredFields)
        if ~isfield(demData, requiredFields{i})
            error('demVisualize:InvalidDEM', ...
                  'demData missing field: %s', requiredFields{i});
        end
    end
    
    %% Create figure
    fig = figure('Name', 'DEM Visualization', 'NumberTitle', 'off', ...
                 'Position', [100 100 1400 600]);
    
    %% Plot 1: 3D Surface
    subplot(1, 2, 1);
    surf(demData.X, demData.Y, demData.Z, 'EdgeColor', 'none', 'FaceColor', 'interp');
    colormap(gca, 'parula');
    colorbar;
    
    hold on;
    
    % Add survey boundary if provided
    if ~isempty(surveyArea) && isstruct(surveyArea)
        plotSurveyBoundary(demData, surveyArea);
    end
    
    % Add waypoints if provided
    if ~isempty(waypoints) && size(waypoints, 2) >= 3
        plotWaypoints(waypoints);
    end
    
    xlabel('UTM Easting (m)');
    ylabel('UTM Northing (m)');
    zlabel('Elevation (m)');
    title('3D Terrain Surface');
    view(45, 30);
    grid on;
    axis equal tight;
    
    %% Plot 2: Contour Map
    subplot(1, 2, 2);
    contourf(demData.X, demData.Y, demData.Z, 25, 'LineColor', 'none');
    colormap(gca, 'parula');
    colorbar;
    
    hold on;
    
    % Add survey boundary if provided
    if ~isempty(surveyArea) && isstruct(surveyArea)
        plotSurveyBoundaryContour(demData, surveyArea);
    end
    
    % Add waypoints if provided
    if ~isempty(waypoints) && size(waypoints, 2) >= 2
        plot(waypoints(:,1), waypoints(:,2), 'r.', 'MarkerSize', 6);
    end
    
    xlabel('UTM Easting (m)');
    ylabel('UTM Northing (m)');
    title('Elevation Contours');
    axis equal tight;
    grid on;
    
    %% Display information
    fprintf('\n=== DEM Visualization ===\n');
    fprintf('Type: %s\n', demData.type);
    fprintf('Bounds: (%.0f, %.0f) to (%.0f, %.0f)\n', ...
            demData.xMin, demData.yMin, demData.xMax, demData.yMax);
    fprintf('Elevation: %.1f to %.1f m (μ=%.1f)\n', ...
            demData.minElevation, demData.maxElevation, demData.meanElevation);
    
    if ~isempty(waypoints)
        fprintf('Waypoints: %d points overlaid\n', size(waypoints, 1));
    end
    fprintf('=== Visualization Complete ===\n\n');
    
end

%% Helper: Plot survey boundary on 3D surface
function plotSurveyBoundary(demData, surveyArea)
    %PLOTSURVEYB OUNDARY Draw survey area boundary on 3D plot
    
    % Get boundary elevation (approximate)
    boundaryZ = demData.minElevation + (demData.maxElevation - demData.minElevation) * 0.95;
    
    % Define boundary corners
    corners_x = [surveyArea.xMin, surveyArea.xMax, surveyArea.xMax, surveyArea.xMin, surveyArea.xMin];
    corners_y = [surveyArea.yMin, surveyArea.yMin, surveyArea.yMax, surveyArea.yMax, surveyArea.yMin];
    corners_z = ones(size(corners_x)) * boundaryZ;
    
    % Plot boundary
    plot3(corners_x, corners_y, corners_z, 'r-', 'LineWidth', 2.5);
    
end

%% Helper: Plot survey boundary on contour map
function plotSurveyBoundaryContour(demData, surveyArea)
    %PLOTSURVEYB OUNDARYCONTOUR Draw survey area boundary on contour plot
    
    % Define boundary corners
    corners_x = [surveyArea.xMin, surveyArea.xMax, surveyArea.xMax, surveyArea.xMin, surveyArea.xMin];
    corners_y = [surveyArea.yMin, surveyArea.yMin, surveyArea.yMax, surveyArea.yMax, surveyArea.yMin];
    
    % Plot boundary
    plot(corners_x, corners_y, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Survey Boundary');
    
end

%% Helper: Plot waypoints on 3D surface
function plotWaypoints(waypoints)
    %PLOTWAYPOINTS Add waypoint markers on 3D surface
    
    % Plot waypoints as red dots
    plot3(waypoints(:,1), waypoints(:,2), waypoints(:,3), ...
          'r.', 'MarkerSize', 8, 'DisplayName', 'Waypoints');
    
end
