%% plotResults.m
% Comprehensive visualization and results plotting for drone survey
% Creates detailed plots of survey area, grid, coverage, and export options
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Mapping & Survey Area Setup
% Author: [Your Name]
% Date: 2025-11-11
% Compatibility: MATLAB 2023+

function plotResults(surveyArea, waypoints, params, coverageData, varargin)
    %PLOTRESULTS Create comprehensive visualization of survey results
    %
    % Syntax:
    %   plotResults(surveyArea, waypoints, params, coverageData)
    %   plotResults(surveyArea, waypoints, params, coverageData, 'basemap', true)
    %
    % Inputs:
    %   surveyArea   - struct from defineSurveyArea.m
    %   waypoints    - [Nx2] waypoint matrix
    %   params       - struct from parameters.m
    %   coverageData - struct from computeCoverageGrid.m
    %   Optional Name-Value pairs:
    %       'basemap' - true/false for satellite basemap (default: false)
    %       'export'  - true/false for CSV export (default: true)
    %
    % Output: Figures and optional files
    
    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'basemap', false, @islogical);
    addParameter(p, 'export', true, @islogical);
    parse(p, varargin{:});
    
    useBasemap = p.Results.basemap;
    doExport = p.Results.export;
    
    fprintf('\n=== Plotting Survey Results ===\n\n');
    
    %% Figure 1: Complete Survey Overview
    fprintf('Creating Figure 1: Survey Overview...\n');
    fig1 = figure('Name', 'Survey Overview', 'NumberTitle', 'off', 'Position', [100 100 1200 800]);
    
    % Subplot 1.1: Survey Area with Waypoints
    subplot(2, 3, 1);
    plot(surveyArea.corners(:,1), surveyArea.corners(:,2), 'b-', 'LineWidth', 2.5);
    hold on;
    plot(waypoints(:,1), waypoints(:,2), 'r.', 'MarkerSize', 6);
    plot(surveyArea.centerX, surveyArea.centerY, 'g*', 'MarkerSize', 15);
    axis equal; grid on;
    xlabel('UTM Easting (m)'); ylabel('UTM Northing (m)');
    title('Survey Area with Waypoints');
    legend('Boundary', 'Waypoints', 'Center', 'Location', 'best');
    
    % Subplot 1.2: Waypoint Density
    subplot(2, 3, 2);
    histogram(waypoints(:,1), 20, 'FaceColor', 'b', 'EdgeColor', 'k');
    xlabel('UTM Easting (m)');
    ylabel('Count');
    title('Easting Distribution');
    grid on;
    
    % Subplot 1.3: Northing Distribution
    subplot(2, 3, 3);
    histogram(waypoints(:,2), 20, 'FaceColor', 'r', 'EdgeColor', 'k');
    xlabel('UTM Northing (m)');
    ylabel('Count');
    title('Northing Distribution');
    grid on;
    
    % Subplot 1.4: Survey Area Statistics (Text)
    subplot(2, 3, 4);
    axis off;
    stats_text = sprintf(['Survey Area Information:\n\n', ...
                         'UTM Zone: %s\n', ...
                         'Area Bounds:\n', ...
                         '  E: %.0f - %.0f m\n', ...
                         '  N: %.0f - %.0f m\n\n', ...
                         'Dimensions: %.0f × %.0f m\n', ...
                         'Area: %.2f km²\n', ...
                         'Center: (%.0f, %.0f)\n'], ...
                         surveyArea.utmZone, ...
                         surveyArea.xMin, surveyArea.xMax, ...
                         surveyArea.yMin, surveyArea.yMax, ...
                         surveyArea.width, surveyArea.height, ...
                         (surveyArea.width * surveyArea.height) / 1e6, ...
                         surveyArea.centerX, surveyArea.centerY);
    text(0.1, 0.5, stats_text, 'FontSize', 9, 'VerticalAlignment', 'middle');
    
    % Subplot 1.5: Waypoint Statistics
    subplot(2, 3, 5);
    axis off;
    waypoint_stats = sprintf(['Waypoint Statistics:\n\n', ...
                             'Total Waypoints: %d\n', ...
                             'Grid Spacing: %.0f m\n\n', ...
                             'X Range: %.0f - %.0f m\n', ...
                             'Y Range: %.0f - %.0f m\n\n', ...
                             'Density: %.4f pts/m²\n', ...
                             'Area per Point: %.1f m²\n'], ...
                             size(waypoints, 1), ...
                             params.gridSpacing, ...
                             min(waypoints(:,1)), max(waypoints(:,1)), ...
                             min(waypoints(:,2)), max(waypoints(:,2)), ...
                             size(waypoints, 1) / (surveyArea.width * surveyArea.height), ...
                             (surveyArea.width * surveyArea.height) / size(waypoints, 1));
    text(0.1, 0.5, waypoint_stats, 'FontSize', 9, 'VerticalAlignment', 'middle');
    
    % Subplot 1.6: Coverage Information
    subplot(2, 3, 6);
    axis off;
    coverage_stats = sprintf(['Coverage Analysis:\n\n', ...
                             'GSD: %.2f cm/pixel\n', ...
                             'Ground Coverage:\n', ...
                             '  %.1f × %.1f m/image\n\n', ...
                             'Frontal Overlap: %.0f%%\n', ...
                             'Side Overlap: %.0f%%\n\n', ...
                             'Grid Status: %s\n', ...
                             'Coverage: %.1f%%\n'], ...
                             coverageData.gsd, ...
                             coverageData.groundWidth, coverageData.groundHeight, ...
                             params.frontalOverlap*100, ...
                             params.sideOverlap*100, ...
                             ifthenelse(coverageData.isGridValid, 'VALID ✓', 'INVALID ✗'), ...
                             coverageData.coveragePercentage);
    text(0.1, 0.5, coverage_stats, 'FontSize', 9, 'VerticalAlignment', 'middle');
    
    fprintf('  ✓ Figure 1 created\n');
    
    %% Figure 2: Detailed Grid Analysis
    fprintf('Creating Figure 2: Grid Analysis...\n');
    fig2 = figure('Name', 'Grid Analysis', 'NumberTitle', 'off', 'Position', [100 100 1200 500]);
    
    % Subplot 2.1: Grid with boundary
    subplot(1, 3, 1);
    plot(surveyArea.corners(:,1), surveyArea.corners(:,2), 'b-', 'LineWidth', 2);
    hold on;
    plot(waypoints(:,1), waypoints(:,2), 'r.', 'MarkerSize', 5);
    
    % Plot a sample of grid lines
    sample_idx = 1:3:size(waypoints, 1);
    for i = sample_idx(1:min(10, length(sample_idx)))
        plot([waypoints(i,1), waypoints(i,1)], ...
             [surveyArea.yMin, surveyArea.yMax], 'g-', 'LineWidth', 0.5);
    end
    
    axis equal; grid on;
    xlabel('Easting (m)'); ylabel('Northing (m)');
    title('Waypoint Grid Layout');
    
    % Subplot 2.2: Spacing uniformity
    subplot(1, 3, 2);
    % Calculate nearest-neighbor distances
    distances = zeros(size(waypoints, 1), 1);
    for i = 1:min(size(waypoints, 1), 100) % Sample first 100 for speed
        dists = sqrt(sum((waypoints - waypoints(i,:)).^2, 2));
        dists(i) = Inf;
        distances(i) = min(dists);
    end
    
    plot(distances(distances > 0), 'bo-', 'LineWidth', 1);
    hold on;
    yline(params.gridSpacing, 'r--', 'LineWidth', 1.5);
    xlabel('Waypoint Index');
    ylabel('Distance to Nearest Neighbor (m)');
    title('Spacing Uniformity Check');
    grid on;
    legend('NN Distance', sprintf('Expected: %.0f m', params.gridSpacing));
    
    % Subplot 2.3: Grid statistics
    subplot(1, 3, 3);
    axis off;
    grid_stats = sprintf(['Grid Statistics:\n\n', ...
                         'Waypoint Count: %d\n', ...
                         'Grid Spacing: %.0f m\n\n', ...
                         'Required Spacing:\n', ...
                         '  Frontal: %.1f m\n', ...
                         '  Side: %.1f m\n', ...
                         '  Max: %.1f m\n\n', ...
                         'Status: %s\n', ...
                         'Adjustment: %s'], ...
                         size(waypoints, 1), ...
                         params.gridSpacing, ...
                         coverageData.requiredSpacingFrontal, ...
                         coverageData.requiredSpacingSide, ...
                         coverageData.maxAllowedSpacing, ...
                         ifthenelse(coverageData.isGridValid, 'VALID', 'INVALID'), ...
                         ifthenelse(coverageData.gridAdjustmentNeeded, 'NEEDED', 'NOT NEEDED'));
    text(0.1, 0.5, grid_stats, 'FontSize', 9, 'VerticalAlignment', 'middle');
    
    fprintf('  ✓ Figure 2 created\n');
    
    %% Figure 3: Camera Coverage
    fprintf('Creating Figure 3: Camera Coverage...\n');
    fig3 = figure('Name', 'Camera Coverage Analysis', 'NumberTitle', 'off', 'Position', [100 100 1200 600]);
    
    % Subplot 3.1: Coverage footprint
    subplot(1, 2, 1);
    plot(surveyArea.corners(:,1), surveyArea.corners(:,2), 'b-', 'LineWidth', 2);
    hold on;
    
    % Draw sample coverage footprints
    sample_waypoints = round(linspace(1, size(waypoints, 1), 9));
    for idx = sample_waypoints
        cx = waypoints(idx, 1);
        cy = waypoints(idx, 2);
        hw = coverageData.groundWidth / 2;
        hh = coverageData.groundHeight / 2;
        
        rect_x = [cx - hw, cx + hw, cx + hw, cx - hw, cx - hw];
        rect_y = [cy - hh, cy - hh, cy + hh, cy + hh, cy - hh];
        
        plot(rect_x, rect_y, 'g-', 'LineWidth', 0.5);
    end
    
    plot(waypoints(:,1), waypoints(:,2), 'r.', 'MarkerSize', 4);
    
    axis equal; grid on;
    xlabel('Easting (m)'); ylabel('Northing (m)');
    title('Sample Camera Coverage Footprints');
    
    % Subplot 3.2: Coverage parameters
    subplot(1, 2, 2);
    axis off;
    coverage_params = sprintf(['Camera Coverage Parameters:\n\n', ...
                              'Altitude: %.0f m AGL\n', ...
                              'Focal Length: %.0f mm\n', ...
                              'GSD: %.2f cm/pixel\n\n', ...
                              'Single Image Coverage:\n', ...
                              '  Width: %.1f m\n', ...
                              '  Height: %.1f m\n', ...
                              '  Area: %.0f m²\n\n', ...
                              'Effective Coverage (with overlap):\n', ...
                              '  Width: %.1f m\n', ...
                              '  Height: %.1f m\n', ...
                              '  Area: %.0f m²\n'], ...
                              params.altitude, ...
                              params.focalLength, ...
                              coverageData.gsd, ...
                              coverageData.groundWidth, ...
                              coverageData.groundHeight, ...
                              coverageData.imageCoverageArea, ...
                              coverageData.groundWidth * (1 - params.frontalOverlap), ...
                              coverageData.groundHeight * (1 - params.sideOverlap), ...
                              coverageData.effectiveCoverageArea);
    text(0.1, 0.5, coverage_params, 'FontSize', 9, 'VerticalAlignment', 'middle');
    
    fprintf('  ✓ Figure 3 created\n');
%% Export Results
if doExport
    fprintf('\nExporting results...\n');
    
    % Export waypoints to CSV (MATLAB 2023 compatible)
    csvFilename = 'waypoints_export.csv';
    
    % Create table for easier export
    waypointTable = table(waypoints(:,1), waypoints(:,2), ...
                          repmat(params.altitude, size(waypoints, 1), 1), ...
                          'VariableNames', {'Easting_m', 'Northing_m', 'Altitude_m'});
    
    writetable(waypointTable, csvFilename);
    fprintf('  ✓ Exported: %s (%d waypoints)\n', csvFilename, size(waypoints, 1));
    
    % Export coverage data to text file
    reportFilename = 'survey_report.txt';
    fid = fopen(reportFilename, 'w');
    fprintf(fid, 'DRONE SURVEY REPORT\n');
    fprintf(fid, '==================\n\n');
    fprintf(fid, 'Survey Area:\n');
    fprintf(fid, '  UTM Zone: %s\n', surveyArea.utmZone);
    fprintf(fid, '  Bounds: (%.0f, %.0f) to (%.0f, %.0f)\n', ...
            surveyArea.xMin, surveyArea.yMin, surveyArea.xMax, surveyArea.yMax);
    fprintf(fid, '  Area: %.2f km²\n\n', (surveyArea.width * surveyArea.height) / 1e6);
    
    fprintf(fid, 'Camera Parameters:\n');
    fprintf(fid, '  Altitude: %.0f m\n', params.altitude);
    fprintf(fid, '  GSD: %.2f cm/pixel\n', coverageData.gsd);
    fprintf(fid, '  Ground Coverage: %.1f x %.1f m\n\n', ...
            coverageData.groundWidth, coverageData.groundHeight);
    
    fprintf(fid, 'Waypoints:\n');
    fprintf(fid, '  Count: %d\n', size(waypoints, 1));
    fprintf(fid, '  Spacing: %.0f m\n\n', params.gridSpacing);
    
    fprintf(fid, 'Coverage Analysis:\n');
    fprintf(fid, '  Grid Valid: %s\n', ifthenelse(coverageData.isGridValid, 'YES', 'NO'));
    fprintf(fid, '  Coverage: %.1f%%\n', coverageData.coveragePercentage);
    
    fclose(fid);
    fprintf('  ✓ Exported: %s\n', reportFilename);
end

    
end

%% Helper Function
function result = ifthenelse(condition, trueStr, falseStr)
    if condition
        result = trueStr;
    else
        result = falseStr;
    end
end
