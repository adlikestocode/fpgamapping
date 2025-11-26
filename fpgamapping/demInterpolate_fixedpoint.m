%% demInterpolate_hdl.m
% HDL-compatible version - DEM data is INSIDE the function (as constants)
% For HDL Coder to convert to Block RAM

function z = demInterpolate_hdl(x, y)
    %DEMINTERPOLATE_HDL HDL-only version for FPGA
    %
    % DEM grid is embedded as constants (becomes Block RAM in hardware)
    % Only coordinates are inputs
    %
    % Inputs:
    %   x, y - UTM coordinates (doubles)
    % Outputs:
    %   z - Elevation (double)
    
    %#codegen
    
    %% Grid parameters (constants)
    persistent DEM_Z
    
    if isempty(DEM_Z)
        % Load DEM data ONCE (at compile time)
        demData = coder.load('synthetic_dem_hills.mat');
        DEM_Z = demData.demData.Z;
    end
    
    % Constants
    X_MIN = 500000;
    Y_MIN = 5400000;
    RESOLUTION = 10;
    
    %% Calculate grid position
    i_float = (x - X_MIN) / RESOLUTION;
    j_float = (y - Y_MIN) / RESOLUTION;
    
    %% Integer indices
    i = floor(i_float);
    j = floor(j_float);
    
    %% Bounds checking
    if i < 0, i = 0; end
    if j < 0, j = 0; end
    if i >= 100, i = 99; end
    if j >= 100, j = 99; end
    
    %% Fractional offsets
    dx = i_float - i;
    dy = j_float - j;
    
    % Clamp weights
    if dx < 0, dx = 0; end
    if dx > 1, dx = 1; end
    if dy < 0, dy = 0; end
    if dy > 1, dy = 1; end
    
    %% Get corner elevations (1-based indexing)
    z11 = DEM_Z(j+1, i+1);
    z21 = DEM_Z(j+1, i+2);
    z12 = DEM_Z(j+2, i+1);
    z22 = DEM_Z(j+2, i+2);
    
    %% Bilinear interpolation
    z = z11 * (1 - dx) * (1 - dy) + ...
        z21 * dx * (1 - dy) + ...
        z12 * (1 - dx) * dy + ...
        z22 * dx * dy;
    
end
