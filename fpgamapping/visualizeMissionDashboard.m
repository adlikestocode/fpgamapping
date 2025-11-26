%% visualizeMissionDashboard.m
% Create comprehensive 6-panel mission visualization dashboard
% Professional publication-quality output with statistics and analysis
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Integration & Mission Planning - Module 4
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function figHandle = visualizeMissionDashboard(missionData, params, saveToFile)
    %VISUALIZEMISSIONDASHBOARD Create comprehensive mission visualization
    %
    % Syntax:
    %   visualizeMissionDashboard(missionData, params)
    %   visualizeMissionDashboard(missionData, params, saveToFile)
    %   figHandle = visualizeMissionDashboard(...)
    %
    % Inputs:
    %   missionData - struct from runCompleteMission
    %   params      - struct from parameters()
    %   saveToFile  - (optional) true to save figure
    %
    % Outputs:
    %   figHandle - handle to created figure
    %
    % Example:
    %   [mission, ~] = runCompleteMission(params);
    %   visualizeMissionDashboard(mission, params, true);
    
    %% Input validation
    if nargin < 2
        error('visualizeMissionDashboard:MissingInput', 'Requires missionData and params');
    end
    
    if nargin < 3
        saveToFile = params.saveFigures;
    end
    
    fprintf('\n=== Mission Dashboard ===\n');
    fprintf('Generating visualization...\n');
    
    %% Extract data
    demData = missionData.demData;
    path = missionData.finalPath;
    
    %% Create figure
    figHandle = figure('Name', 'Mission Dashboard', 'NumberTitle', 'off', ...
                       'Position', [50 50 1600 900], 'Color', 'white');
    
    %% Panel 1: 3D Mission Overview (subplot 1)
    subplot(2, 3, 1);
    surf(demData.X, demData.Y, demData.Z, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    hold on;
    
    % Flight path
    if size(path, 2) >= 3
        plot3(path(:,1), path(:,2), path(:,3), 'r-', 'LineWidth', 2, ...
              'DisplayName', 'Flight Path');
    end
    
    % Start and goal markers
    plot3(path(1,1), path(1,2), path(1,3), 'g*', 'MarkerSize', 15, ...
          'LineWidth', 2, 'DisplayName', 'Start');
    plot3(path(end,1), path(end,2), path(end,3), 'bs', 'MarkerSize', 10, ...
          'LineWidth', 2, 'DisplayName', 'Goal');
    
    xlabel('UTM Easting (m)');
    ylabel('UTM Northing (m)');
    zlabel('Elevation (m)');
    title('3D Mission Overview');
    legend('Location', 'best');
    view(45, 30);
    grid on;
    colormap(gca, parula);
    colorbar;
    
    %% Panel 2: 2D Top-Down View (subplot 2)
    subplot(2, 3, 2);
    contourf(demData.X, demData.Y, demData.Z, 20, 'LineColor', 'none');
    hold on;
    
    % Flight path
    plot(path(:,1), path(:,2), 'r-', 'LineWidth', 2, 'DisplayName', 'Path');
    plot(path(1,1), path(1,2), 'g*', 'MarkerSize', 15, 'LineWidth', 2, ...
         'DisplayName', 'Start');
    plot(path(end,1), path(end,2), 'bs', 'MarkerSize', 10, 'LineWidth', 2, ...
         'DisplayName', 'Goal');
    
    % Survey area boundary
    rectangle('Position', [params.x0, params.y0, params.areaWidth, params.areaHeight], ...
              'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--');
    
    xlabel('UTM Easting (m)');
    ylabel('UTM Northing (m)');
    title('2D Top-Down View');
    legend('Location', 'best');
    axis equal tight;
    colorbar;
    grid on;
    
    %% Panel 3: Elevation Profile (subplot 3)
    subplot(2, 3, 3);
    
    % Calculate distance along path
    pathDist = zeros(size(path, 1), 1);
    for i = 2:size(path, 1)
        pathDist(i) = pathDist(i-1) + norm(path(i,1:2) - path(i-1,1:2));
    end
    
    % Get terrain elevation along path
    terrainZ = zeros(size(path, 1), 1);
    for i = 1:size(path, 1)
        terrainZ(i) = demInterpolate(demData, path(i,1), path(i,2));
    end
    
    % Plot
    plot(pathDist, path(:,3), 'b-', 'LineWidth', 2, 'DisplayName', 'Drone');
    hold on;
    plot(pathDist, terrainZ, 'g--', 'LineWidth', 1.5, 'DisplayName', 'Terrain');
    plot(pathDist, terrainZ + params.minAGL, 'r:', 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Min AGL (%.0fm)', params.minAGL));
    
    % Shaded safe zone
    fill([pathDist; flipud(pathDist)], ...
         [terrainZ + params.minAGL; flipud(path(:,3))], ...
         [0.8 1 0.8], 'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
         'DisplayName', 'Safe Zone');
    
    xlabel('Distance along path (m)');
    ylabel('Elevation (m)');
    title('Elevation Profile');
    legend('Location', 'best');
    grid on;
    
    %% Panel 4: Speed/Heading Profile (subplot 4)
    subplot(2, 3, 4);
    
    % Calculate ground speed (assuming constant time between waypoints)
    speeds = zeros(size(path, 1)-1, 1);
    for i = 1:size(path, 1)-1
        dist = norm(path(i+1,:) - path(i,:));
        speeds(i) = params.droneSpeed; % Constant for now
    end
    
    % Calculate heading
    headings = zeros(size(path, 1)-1, 1);
    for i = 1:size(path, 1)-1
        dx = path(i+1,1) - path(i,1);
        dy = path(i+1,2) - path(i,2);
        headings(i) = atan2d(dy, dx);
    end
    
    yyaxis left
    plot(1:length(speeds), speeds, 'b-', 'LineWidth', 2);
    ylabel('Ground Speed (m/s)');
    ylim([0 max(speeds)*1.2]);
    
    yyaxis right
    plot(1:length(headings), headings, 'r-', 'LineWidth', 2);
    ylabel('Heading (degrees)');
    ylim([-180 180]);
    
    xlabel('Waypoint Index');
    title('Speed & Heading Profile');
    grid on;
    legend('Speed', 'Heading', 'Location', 'best');
    
    %% Panel 5: Statistics Table (subplot 5)
    subplot(2, 3, 5);
    axis off;
    
    % Calculate statistics
    totalDist = 0;
    for i = 1:size(path, 1) - 1
        totalDist = totalDist + norm(path(i+1,:) - path(i,:));
    end
    
    flightTime = totalDist / params.droneSpeed / 60; % minutes
    
    if isfield(missionData, 'validation')
        safetyScore = missionData.validation.stats.safetyScore;
    else
        safetyScore = 100;
    end
    
    stats_text = sprintf([...
        'Mission Summary\n' ...
        '━━━━━━━━━━━━━━━━━━━━\n\n' ...
        'Coverage Area:    %.2f km²\n' ...
        'Total Distance:   %.2f km\n' ...
        'Flight Time:      %.1f min\n' ...
        'Waypoints:        %d\n' ...
        'Avg Altitude:     %.1f m\n' ...
        'Max Slope:        %.1f°\n' ...
        'Safety Score:     %.1f%%\n' ...
        'Obstacles:        %d\n\n' ...
        'Export Format:    %s\n' ...
        'Timestamp:        %s'], ...
        params.areaWidth * params.areaHeight / 1e6, ...
        totalDist / 1000, ...
        flightTime, ...
        size(path, 1), ...
        mean(path(:,3)), ...
        0, ...
        safetyScore, ...
        0, ...
        strjoin(params.exportFormats, ', '), ...
        datestr(now));
    
    text(0.1, 0.5, stats_text, 'FontSize', 11, 'FontName', 'FixedWidth', ...
         'VerticalAlignment', 'middle', 'Interpreter', 'none');
    
    %% Panel 6: Terrain Analysis (subplot 6)
    subplot(2, 3, 6);
    
    % Elevation distribution
    histogram(demData.Z(:), 20, 'FaceColor', [0.3 0.7 0.3], 'EdgeColor', 'k');
    xlabel('Elevation (m)');
    ylabel('Frequency');
    title('Terrain Elevation Distribution');
    grid on;
    
    % Add statistics
    hold on;
    meanZ = mean(demData.Z(:));
    xline(meanZ, 'r--', 'LineWidth', 2, 'Label', sprintf('Mean: %.1fm', meanZ));
    
    %% Save figure
    if saveToFile
        % Create filename
        filename = fullfile(params.exportPath, ...
                           sprintf('%s_dashboard', params.missionName));
        
        % Save in specified format
        switch lower(params.figureFormat)
            case 'png'
                print(figHandle, filename, '-dpng', '-r300');
                fprintf('  ✓ Dashboard saved: %s.png\n', filename);
            case 'pdf'
                print(figHandle, filename, '-dpdf', '-bestfit');
                fprintf('  ✓ Dashboard saved: %s.pdf\n', filename);
            case 'fig'
                savefig(figHandle, [filename '.fig']);
                fprintf('  ✓ Dashboard saved: %s.fig\n', filename);
        end
    end
    
    fprintf('=== Dashboard Complete ===\n\n');
end
