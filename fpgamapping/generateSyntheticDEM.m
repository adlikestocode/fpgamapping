%% generateSyntheticDEM.m
% Generate synthetic Digital Elevation Model (DEM) for drone survey testing
% Creates realistic terrain profiles with configurable elevation characteristics
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: DEM (Digital Elevation Model) - Module 0
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function demData = generateSyntheticDEM(surveyArea, resolution, demType)
    %GENERATESYNTHETICDEM Create synthetic terrain elevation model
    %
    % Syntax:
    %   demData = generateSyntheticDEM(surveyArea, resolution, demType)
    %
    % Inputs:
    %   surveyArea - struct from defineSurveyArea.m with fields:
    %       .xMin, .xMax, .yMin, .yMax (UTM coordinates)
    %   resolution - grid spacing in meters (e.g., 10)
    %   demType    - char array: 'flat', 'slope', 'hills', 'random'
    %
    % Outputs:
    %   demData - struct containing:
    %       .X, .Y - coordinate grids (meshgrid format)
    %       .Z - elevation grid (meters)
    %       .resolution - grid spacing used
    %       .xMin, .xMax, .yMin, .yMax - boundaries
    %       .type - DEM type generated
    %
    % Examples:
    %   params = parameters();
    %   surveyArea = defineSurveyArea(params);
    %   demData = generateSyntheticDEM(surveyArea, 10, 'hills');
    %
    %   demData = generateSyntheticDEM(surveyArea, 20, 'slope');
    
    %% Input validation
    if nargin < 3
        demType = 'hills';
    end
    if nargin < 2
        resolution = 10;
    end
    
    if ~isstruct(surveyArea)
        error('generateSyntheticDEM:InvalidInput', 'surveyArea must be a struct');
    end
    
    if ~ischar(demType) && ~isstring(demType)
        error('generateSyntheticDEM:InvalidInput', 'demType must be char or string');
    end
    demType = lower(char(demType));
    
    %% Validate DEM type
    validTypes = {'flat', 'slope', 'hills', 'random'};
    if ~ismember(demType, validTypes)
        error('generateSyntheticDEM:InvalidDEMType', ...
              'demType must be one of: flat, slope, hills, random');
    end
    
    fprintf('\n=== Generating Synthetic DEM ===\n');
    fprintf('DEM Type: %s\n', demType);
    fprintf('Resolution: %d meters\n', resolution);
    fprintf('Survey Area: (%.0f, %.0f) to (%.0f, %.0f)\n', ...
            surveyArea.xMin, surveyArea.yMin, surveyArea.xMax, surveyArea.yMax);
    
    %% Create coordinate grids
    x = surveyArea.xMin : resolution : surveyArea.xMax;
    y = surveyArea.yMin : resolution : surveyArea.yMax;
    [X, Y] = meshgrid(x, y);
    
    fprintf('Grid size: %d × %d points\n', size(X, 2), size(X, 1));
    
    %% Generate elevation based on terrain type
    switch demType
        case 'flat'
            % Constant elevation terrain
            baseElevation = 100;  % meters
            Z = zeros(size(X)) + baseElevation;
            fprintf('  Elevation: %.1f m (constant)\n', baseElevation);
            
        case 'slope'
            % Linear slope in east-west direction
            baseElevation = 100;
            slope = 0.1;  % 0.1 m/m slope (10% grade)
            xNorm = (X - surveyArea.xMin) / (surveyArea.xMax - surveyArea.xMin);
            Z = baseElevation + (slope * 100 * xNorm);  % 10m total rise
            fprintf('  Slope: %.3f m/m (%.1f m total rise)\n', slope, slope * 100);
            
        case 'hills'
            % Smooth rolling hills using sine/cosine waves
            baseElevation = 100;
            amplitude1 = 20;  % Primary wave amplitude
            amplitude2 = 15;  % Secondary wave amplitude
            
            % Normalize coordinates to [0, 1] for wave generation
            xNorm = (X - surveyArea.xMin) / (surveyArea.xMax - surveyArea.xMin);
            yNorm = (Y - surveyArea.yMin) / (surveyArea.yMax - surveyArea.yMin);
            
            % Create smooth hills using sinusoidal waves
            wave1 = amplitude1 * sin(2*pi*xNorm) .* cos(2*pi*yNorm);
            wave2 = amplitude2 * cos(3*pi*xNorm) .* sin(3*pi*yNorm);
            
            Z = baseElevation + wave1 + wave2;
            fprintf('  Base elevation: %.1f m\n', baseElevation);
            fprintf('  Wave amplitudes: %.1f m, %.1f m\n', amplitude1, amplitude2);
            
        case 'random'
            % Random terrain with smoothing
            baseElevation = 100;
            elevation_variation = 30;  % ±30m variation
            
            % Generate random elevation
            Z = baseElevation + elevation_variation * (2*rand(size(X)) - 1);
            
            % Apply Gaussian smoothing for realistic terrain
            smoothingFactor = 5;
            Z = imgaussfilt(Z, smoothingFactor);
            
            fprintf('  Base elevation: %.1f m\n', baseElevation);
            fprintf('  Variation: ±%.1f m\n', elevation_variation);
            fprintf('  Smoothing factor: %.1f\n', smoothingFactor);
    end
    
    %% Calculate elevation statistics
    minElevation = min(Z(:));
    maxElevation = max(Z(:));
    meanElevation = mean(Z(:));
    stdElevation = std(Z(:));
    
    fprintf('Elevation Statistics:\n');
    fprintf('  Min: %.1f m\n', minElevation);
    fprintf('  Max: %.1f m\n', maxElevation);
    fprintf('  Mean: %.1f m\n', meanElevation);
    fprintf('  Std Dev: %.1f m\n', stdElevation);
    
    %% Build output structure
    demData = struct(...
        'X', X, ...
        'Y', Y, ...
        'Z', Z, ...
        'resolution', resolution, ...
        'xMin', surveyArea.xMin, ...
        'xMax', surveyArea.xMax, ...
        'yMin', surveyArea.yMin, ...
        'yMax', surveyArea.yMax, ...
        'type', demType, ...
        'minElevation', minElevation, ...
        'maxElevation', maxElevation, ...
        'meanElevation', meanElevation, ...
        'stdElevation', stdElevation ...
    );
    
    %% Save to MAT file
    matFilename = sprintf('synthetic_dem_%s.mat', demType);
    save(matFilename, 'demData');
    fprintf('\nSaved: %s\n', matFilename);
    
    %% Save to ASCII grid (ESRI format)
    ascFilename = sprintf('synthetic_dem_%s.asc', demType);
    exportToASCIIGrid(demData, ascFilename);
    
    %% Create visualization
    fprintf('Generating visualization...\n');
    figure('Name', sprintf('Synthetic DEM: %s', demType), 'NumberTitle', 'off', ...
           'Position', [100 100 1000 700]);
    
    % 3D surface plot
    subplot(1, 2, 1);
    surf(X, Y, Z, 'EdgeColor', 'none', 'FaceColor', 'interp');
    colorbar;
    colormap(gca, 'parula');
    xlabel('UTM Easting (m)');
    ylabel('UTM Northing (m)');
    zlabel('Elevation (m)');
    title(sprintf('Synthetic DEM: %s', demType));
    view(45, 30);
    axis equal tight;
    grid on;
    
    % Contour plot
    subplot(1, 2, 2);
    contourf(X, Y, Z, 20, 'LineColor', 'none');
    colorbar;
    colormap(gca, 'parula');
    xlabel('UTM Easting (m)');
    ylabel('UTM Northing (m)');
    title('Elevation Contours');
    axis equal tight;
    grid on;
    
    fprintf('  ✓ Visualization created\n');
    fprintf('=== DEM Generation Complete ===\n\n');
    
end

%% Helper function: Export to ASCII Grid
function exportToASCIIGrid(demData, filename)
    %EXPORTTOASCIGRID Export DEM to ESRI ASCII grid format
    
    fid = fopen(filename, 'w');
    if fid == -1
        error('generateSyntheticDEM:FileError', 'Cannot create ASCII grid file: %s', filename);
    end
    
    % Write ESRI ASCII grid header
    fprintf(fid, 'ncols         %d\n', size(demData.Z, 2));
    fprintf(fid, 'nrows         %d\n', size(demData.Z, 1));
    fprintf(fid, 'xllcorner     %.6f\n', demData.xMin);
    fprintf(fid, 'yllcorner     %.6f\n', demData.yMin);
    fprintf(fid, 'cellsize      %.6f\n', demData.resolution);
    fprintf(fid, 'NODATA_value  -9999\n');
    
    % Write elevation data (flip for proper row-major order)
    Z_flipped = flipud(demData.Z);
    for i = 1:size(Z_flipped, 1)
        fprintf(fid, '%f ', Z_flipped(i, :));
        fprintf(fid, '\n');
    end
    
    fclose(fid);
    fprintf('  ✓ Saved ASCII grid: %s\n', filename);
    
end
