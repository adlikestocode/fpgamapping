%% demImport.m
% Import Digital Elevation Model (DEM) from file
% Supports MATLAB MAT files and ESRI ASCII grid format
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: DEM (Digital Elevation Model) - Module 0
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function demData = demImport(filename, format)
    %DEMIMPORT Load DEM from MAT or ASCII file
    %
    % Syntax:
    %   demData = demImport(filename)
    %   demData = demImport(filename, format)
    %
    % Inputs:
    %   filename - char/string, path to DEM file
    %   format   - char/string (optional): 'mat', 'ascii', 'auto' (default: 'auto')
    %       'mat'   - MATLAB MAT file format
    %       'ascii' - ESRI ASCII grid format
    %       'auto'  - Auto-detect from file extension
    %
    % Outputs:
    %   demData - struct with standardized DEM data:
    %       .X, .Y - coordinate grids (meshgrid format)
    %       .Z - elevation grid (meters)
    %       .resolution - grid spacing (meters)
    %       .xMin, .xMax, .yMin, .yMax - UTM boundaries
    %       .type - DEM type/source
    %       .minElevation, .maxElevation, .meanElevation, .stdElevation
    %
    % Examples:
    %   demData = demImport('synthetic_dem_hills.mat');
    %   demData = demImport('terrain.asc', 'ascii');
    %   demData = demImport('dem.dat', 'auto');
    
    %% Input validation
    if nargin < 1
        error('demImport:MissingInput', 'filename is required');
    end
    
    if nargin < 2
        format = 'auto';
    end
    
    % Convert to char if string
    filename = char(filename);
    format = lower(char(format));
    
    % Validate format
    validFormats = {'mat', 'ascii', 'auto'};
    if ~ismember(format, validFormats)
        error('demImport:InvalidFormat', ...
              'format must be one of: mat, ascii, auto');
    end
    
    %% Auto-detect format from extension if needed
    if strcmp(format, 'auto')
        [~, ~, ext] = fileparts(filename);
        ext = lower(ext);
        
        switch ext
            case '.mat'
                format = 'mat';
            case '.asc'
                format = 'ascii';
            otherwise
                error('demImport:UnknownFormat', ...
                      'Cannot auto-detect format from extension: %s', ext);
        end
    end
    
    %% Check file exists
    if ~isfile(filename)
        error('demImport:FileNotFound', 'File not found: %s', filename);
    end
    
    fprintf('\n=== Importing DEM ===\n');
    fprintf('File: %s\n', filename);
    fprintf('Format: %s\n', format);
    
    %% Load based on format
    switch format
        case 'mat'
            demData = importMAT(filename);
        case 'ascii'
            demData = importASCII(filename);
    end
    
    %% Validate output structure
    try
        validateDEMStructure(demData);
        fprintf('Status: ✓ DEM loaded and validated\n');
    catch ME
        error('demImport:InvalidDEM', ...
              'Loaded DEM failed validation: %s', ME.message);
    end
    
    %% Display summary
    fprintf('Loaded DEM Information:\n');
    fprintf('  Type: %s\n', demData.type);
    fprintf('  Grid size: %d × %d points\n', size(demData.Z, 1), size(demData.Z, 2));
    fprintf('  Resolution: %.1f meters\n', demData.resolution);
    fprintf('  Bounds: (%.0f, %.0f) to (%.0f, %.0f)\n', ...
            demData.xMin, demData.yMin, demData.xMax, demData.yMax);
    fprintf('  Elevation: %.1f to %.1f m (μ=%.1f, σ=%.1f)\n', ...
            demData.minElevation, demData.maxElevation, ...
            demData.meanElevation, demData.stdElevation);
    fprintf('=== Import Complete ===\n\n');
    
end

%% Helper: Import MAT format
function demData = importMAT(filename)
    %IMPORTMAT Load DEM from MATLAB MAT file
    
    try
        loaded = load(filename);
        
        % Check if demData struct exists
        if isfield(loaded, 'demData')
            demData = loaded.demData;
        elseif isfield(loaded, 'Z')
            % Fallback: if only Z matrix exists, try to reconstruct
            demData = struct();
            demData.Z = loaded.Z;
            if isfield(loaded, 'X')
                demData.X = loaded.X;
            end
            if isfield(loaded, 'Y')
                demData.Y = loaded.Y;
            end
        else
            error('MAT file does not contain demData struct or Z matrix');
        end
        
    catch ME
        error('demImport:MATLoadError', ...
              'Failed to load MAT file: %s', ME.message);
    end
    
end

%% Helper: Import ASCII Grid format
function demData = importASCII(filename)
    %IMPORTASCII Load DEM from ESRI ASCII grid file
    
    try
        fid = fopen(filename, 'r');
        if fid == -1
            error('Cannot open file');
        end
        
        % Read header
        header = struct();
        headerLines = {};
        
        % Expected ESRI ASCII header fields
        expectedHeaders = {'ncols', 'nrows', 'xllcorner', 'yllcorner', 'cellsize'};
        
        for i = 1:10  % Read up to 10 header lines
            line = fgetl(fid);
            if ischar(line) && ~iseof(fid)
                parts = strsplit(line);
                if length(parts) >= 2
                    key = lower(parts{1});
                    value = str2double(parts{2});
                    
                    if ismember(key, expectedHeaders) || strcmp(key, 'nodata_value')
                        header.(key) = value;
                        headerLines{end+1} = line;
                    else
                        % End of header
                        break;
                    end
                end
            else
                break;
            end
        end
        
        % Validate required header fields
        requiredFields = {'ncols', 'nrows', 'xllcorner', 'yllcorner', 'cellsize'};
        for i = 1:length(requiredFields)
            if ~isfield(header, requiredFields{i})
                error('Missing required header field: %s', requiredFields{i});
            end
        end
        
        ncols = header.ncols;
        nrows = header.nrows;
        xllcorner = header.xllcorner;
        yllcorner = header.yllcorner;
        cellsize = header.cellsize;
        
        % Read elevation data
        Z_flipped = zeros(nrows, ncols);
        for i = 1:nrows
            line = fgetl(fid);
            values = str2num(line);
            if length(values) ~= ncols
                error('Row %d has %d columns, expected %d', i, length(values), ncols);
            end
            Z_flipped(i, :) = values;
        end
        
        fclose(fid);
        
        % Flip Z back to original orientation (ESRI stores bottom-to-top)
        Z = flipud(Z_flipped);
        
        % Create coordinate grids
        x = xllcorner : cellsize : (xllcorner + (ncols-1)*cellsize);
        y = yllcorner : cellsize : (yllcorner + (nrows-1)*cellsize);
        [X, Y] = meshgrid(x, y);
        
        % Build demData struct
        demData = struct();
        demData.X = X;
        demData.Y = Y;
        demData.Z = Z;
        demData.resolution = cellsize;
        demData.xMin = xllcorner;
        demData.xMax = xllcorner + (ncols-1)*cellsize;
        demData.yMin = yllcorner;
        demData.yMax = yllcorner + (nrows-1)*cellsize;
        demData.type = 'imported_ascii';
        demData.minElevation = min(Z(:));
        demData.maxElevation = max(Z(:));
        demData.meanElevation = mean(Z(:));
        demData.stdElevation = std(Z(:));
        
    catch ME
        fclose(fid);
        error('demImport:ASCIILoadError', ...
              'Failed to load ASCII grid file: %s', ME.message);
    end
    
end

%% Helper: Validate DEM structure
function validateDEMStructure(demData)
    %VALIDATEDEMSTRUCTURE Check demData has all required fields and proper format
    
    requiredFields = {'X', 'Y', 'Z', 'resolution', 'xMin', 'xMax', 'yMin', 'yMax', 'type'};
    
    for i = 1:length(requiredFields)
        if ~isfield(demData, requiredFields{i})
            error('Missing required field: %s', requiredFields{i});
        end
    end
    
    % Check matrix dimensions
    if ~(size(demData.X, 1) == size(demData.Y, 1) && ...
         size(demData.X, 1) == size(demData.Z, 1) && ...
         size(demData.X, 2) == size(demData.Y, 2) && ...
         size(demData.X, 2) == size(demData.Z, 2))
        error('X, Y, Z matrices have inconsistent dimensions');
    end
    
    % Check numeric fields
    if ~isnumeric(demData.resolution) || demData.resolution <= 0
        error('resolution must be positive number');
    end
    
    if ~isnumeric(demData.xMin) || ~isnumeric(demData.xMax) || ...
       ~isnumeric(demData.yMin) || ~isnumeric(demData.yMax)
        error('Boundary values must be numeric');
    end
    
end

%% Helper: Split string function (for compatibility)
function parts = strsplit(str)
    %STRSPLIT Simple string split (compatibility for older MATLAB)
    parts = regexp(char(str), '\s+', 'split');
end
