%% demInterpolate.m
% UNIVERSAL DEM interpolation - works everywhere
% Drop-in replacement for Module 0 version
% Compatible with: Modules 0-4, HDL Coder, Fixed-Point Converter, AWS F1
%
% Project: Drone Pathfinding - Module 0-5 Integration
% Date: 2025-11-12
% Compatibility: MATLAB R2023b, HDL Coder, Fixed-Point Designer

function z = demInterpolate(demData, x, y)
    %DEMINTERPOLATE Bilinear interpolation for DEM elevation queries
    %
    % Universal implementation that works in:
    %   - Module 0: DEM system
    %   - Module 1: Mapping
    %   - Module 2: Coverage paths
    %   - Module 3: A* pathfinding
    %   - Module 4: Mission integration
    %   - Module 5: HDL generation for AWS F1
    %
    % Syntax:
    %   z = demInterpolate(demData, x, y)
    %
    % Inputs:
    %   demData - DEM structure with fields:
    %             .X (101x101 grid of X coordinates)
    %             .Y (101x101 grid of Y coordinates)
    %             .Z (101x101 grid of elevations)
    %             .resolution (grid spacing, e.g., 10 meters)
    %   x - UTM X coordinate (scalar)
    %   y - UTM Y coordinate (scalar)
    %
    % Outputs:
    %   z - Interpolated elevation at (x,y) in meters
    %
    % Features:
    %   - HDL Coder compatible (no try-catch, bounded loops)
    %   - Fixed-Point Designer compatible (simple arithmetic)
    %   - Works with existing Modules 0-4 code
    %   - AWS F1 FPGA ready
    %
    % Example:
    %   demData = load('synthetic_dem_hills.mat').demData;
    %   z = demInterpolate(demData, 500500, 5400500);
    
    %% Input validation (removed for HDL compatibility)
    % Note: For HDL, input validation happens at top level
    % This function assumes valid inputs
    
    %% Extract grid data
    X_grid = demData.X;
    Y_grid = demData.Y;
    Z_grid = demData.Z;
    resolution = demData.resolution;
    
    %% Grid bounds
    x_min = X_grid(1, 1);
    y_min = Y_grid(1, 1);
    
    %% Calculate grid position
    % Position in grid coordinates (floating-point)
    i_float = (x - x_min) / resolution;
    j_float = (y - y_min) / resolution;
    
    %% Integer grid indices
    i = floor(i_float);
    j = floor(j_float);
    
    %% Bounds checking (clamp to valid range for 101x101 grid)
    % This prevents out-of-bounds access and is HDL-compatible
    if i < 0
        i = 0;
    end
    if j < 0
        j = 0;
    end
    if i >= 100
        i = 99;
    end
    if j >= 100
        j = 99;
    end
    
    %% Calculate fractional offsets (interpolation weights)
    dx = i_float - i;  % X weight (0 to 1)
    dy = j_float - j;  % Y weight (0 to 1)
    
    %% Clamp weights to valid range [0, 1]
    % Handles edge cases and ensures valid interpolation
    if dx < 0
        dx = 0;
    end
    if dx > 1
        dx = 1;
    end
    if dy < 0
        dy = 0;
    end
    if dy > 1
        dy = 1;
    end
    
    %% Get four corner elevation values
    % MATLAB uses 1-based indexing, so add 1 to C-style indices
    z11 = Z_grid(j+1, i+1);    % Bottom-left corner
    z21 = Z_grid(j+1, i+2);    % Bottom-right corner
    z12 = Z_grid(j+2, i+1);    % Top-left corner
    z22 = Z_grid(j+2, i+2);    % Top-right corner
    
    %% Bilinear interpolation
    % Standard formula: z = z11*(1-dx)*(1-dy) + z21*dx*(1-dy) + 
    %                       z12*(1-dx)*dy + z22*dx*dy
    % This is HDL-synthesizable and Fixed-Point compatible
    z = z11 * (1 - dx) * (1 - dy) + ...
        z21 * dx * (1 - dy) + ...
        z12 * (1 - dx) * dy + ...
        z22 * dx * dy;
    
end
