function demData_fixed = convertDEMtoFixedPoint(demData)
    %CONVERTDEMTOFIXEDPOINT Convert Module 0 DEM to fixed-point
    %
    % Syntax:
    %   demData_fixed = convertDEMtoFixedPoint(demData)
    %
    % Inputs:
    %   demData - Original DEM from Module 0 (floating-point)
    %
    % Outputs:
    %   demData_fixed - DEM with fixed-point arrays
    
    % Fixed-point type definitions
    coord_Type = numerictype(1, 32, 16);
    coord_F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
    
    elev_Type = numerictype(1, 16, 12);
    elev_F = fimath('RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');
    
    % Convert X grid
    demData_fixed.X = fi(demData.X, coord_Type, coord_F);
    
    % Convert Y grid
    demData_fixed.Y = fi(demData.Y, coord_Type, coord_F);
    
    % Convert Z elevation
    demData_fixed.Z = fi(demData.Z, elev_Type, elev_F);
    
    % Preserve metadata
    demData_fixed.resolution = demData.resolution;
    demData_fixed.type = demData.type;
    
    % Store bounds
    demData_fixed.bounds.xMin = demData.X(1, 1);
    demData_fixed.bounds.xMax = demData.X(1, end);
    demData_fixed.bounds.yMin = demData.Y(1, 1);
    demData_fixed.bounds.yMax = demData.Y(end, 1);
    
    fprintf('✓ DEM converted to fixed-point:\n');
    fprintf('  X range: %.1f to %.1f\n', demData_fixed.bounds.xMin, demData_fixed.bounds.xMax);
    fprintf('  Y range: %.1f to %.1f\n', demData_fixed.bounds.yMin, demData_fixed.bounds.yMax);
    fprintf('  Z range: %.1f to %.1f m\n', min(demData.Z(:)), max(demData.Z(:)));
    fprintf('  Grid: %dx%d (%.0f m resolution)\n\n', ...
            size(demData_fixed.Z, 1), size(demData_fixed.Z, 2), demData.resolution);
end
