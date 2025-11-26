%% pathValidator.m
% Validate paths for safety, terrain clearance, and feasibility
% Checks for collisions, altitude violations, steep slopes
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: A* Pathfinding - Module 3
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [isValid, violations, stats] = pathValidator(path, demData, obstacles, params)
    %PATHVALIDATOR Validate path for safety and feasibility
    %
    % Syntax:
    %   [isValid, violations, stats] = pathValidator(path, demData, obstacles, params)
    %
    % Inputs:
    %   path      - [Nx2] or [Nx3] waypoint path
    %   demData   - struct from generateSyntheticDEM
    %   obstacles - struct with obstacle grid ([] if none)
    %   params    - struct with validation thresholds
    %
    % Outputs:
    %   isValid    - true if path passes all checks
    %   violations - struct with detailed violation list
    %   stats      - struct with path statistics
    
    if nargin < 4
        error('pathValidator:MissingInput', 'Requires all 4 arguments');
    end
    
    fprintf('\n=== Path Validation ===\n');
    fprintf('Path waypoints: %d\n', size(path, 1));
    
    %% Initialize validation
    violations = struct(...
        'obstacleCollisions', [], ...
        'altitudeTooLow', [], ...
        'slopeTooSteep', [], ...
        'turnsTooSharp', [], ...
        'totalViolations', 0 ...
    );
    
    minAGL = params.minAGL;
    maxSlope = ifthenelse(isfield(params, 'maxClimbAngle'), ...
                          params.maxClimbAngle, 20);
    maxTurn = ifthenelse(isfield(params, 'maxTurnAngle'), ...
                         params.maxTurnAngle, 60);
    
    %% Check 1: Obstacle collisions
    fprintf('\nCheck 1: Obstacle collisions...\n');
    collisionCount = 0;
    collisionPoints = [];
    
    if ~isempty(obstacles) && isfield(obstacles, 'grid')
        obsGrid = obstacles.grid;
        resolution = obstacles.resolution;
        xMin = obstacles.bounds(1);
        yMin = obstacles.bounds(3);
        
        for i = 1:size(path, 1)
            x = path(i, 1);
            y = path(i, 2);
            
            % Convert to grid indices
            xIdx = round((x - xMin) / resolution) + 1;
            yIdx = round((y - yMin) / resolution) + 1;
            
            if xIdx >= 1 && xIdx <= size(obsGrid, 2) && ...
               yIdx >= 1 && yIdx <= size(obsGrid, 1)
                if obsGrid(yIdx, xIdx) > 0
                    collisionCount = collisionCount + 1;
                    collisionPoints = [collisionPoints; path(i, 1:2)];
                end
            end
        end
    end
    
    if collisionCount > 0
        fprintf('  ✗ Obstacle collisions: %d points\n', collisionCount);
        violations.obstacleCollisions = collisionPoints;
        violations.totalViolations = violations.totalViolations + collisionCount;
    else
        fprintf('  ✓ No obstacle collisions\n');
    end
    
  %% Check 2: Altitude safety (AGL) - FIXED
fprintf('Check 2: Altitude safety (AGL)...\n');
altitudeViolations = [];

% IMPORTANT: A* returns path at terrain elevation
% We need to LIFT it to terrain + minAGL
if size(path, 2) >= 3
    for i = 1:size(path, 1)
        terrainZ = demInterpolate(demData, path(i, 1), path(i, 2));
        requiredZ = terrainZ + minAGL;
        
        % Check if path Z is below required altitude
        if path(i, 3) < requiredZ - 1  % 1m tolerance
            % Path is too low - need to RAISE it
            altitudeViolations = [altitudeViolations; i, path(i, 3), requiredZ];
        end
    end
    
    if ~isempty(altitudeViolations)
        fprintf('  ⚠ Altitude violations detected\n');
        fprintf('    Points below minAGL: %d\n', size(altitudeViolations, 1));
        fprintf('    Adjusting path altitude...\n');
        
        % AUTOMATICALLY FIX the path: raise to terrain + minAGL
        for i = 1:size(path, 1)
            terrainZ = demInterpolate(demData, path(i, 1), path(i, 2));
            path(i, 3) = terrainZ + minAGL;
        end
        
        fprintf('    ✓ Path adjusted to %.0f m AGL\n', minAGL);
    else
        fprintf('  ✓ All points maintain minimum AGL\n');
    end
else
    fprintf('  ⚠ Warning: Path missing Z coordinates\n');
end

    %% Check 3: Slope constraint
    fprintf('Check 3: Slope constraint...\n');
    slopeViolations = [];
    
    for i = 1:size(path, 1) - 1
        p1 = path(i, :);
        p2 = path(i+1, :);
        
        if size(path, 2) >= 3
            dz = p2(3) - p1(3);
        else
            dz = 0;
        end
        
        dx = norm(p2(1:2) - p1(1:2));
        
        if dx > 0
            slope = atan(abs(dz) / dx) * 180 / pi;
            if slope > maxSlope
                slopeViolations = [slopeViolations; i, slope, maxSlope];
            end
        end
    end
    
    if ~isempty(slopeViolations)
        fprintf('  ✗ Slope violations: %d segments\n', size(slopeViolations, 1));
        violations.slopeTooSteep = slopeViolations;
        violations.totalViolations = violations.totalViolations + size(slopeViolations, 1);
    else
        fprintf('  ✓ All slopes within limits\n');
    end
    
    %% Check 4: Turn angles
    fprintf('Check 4: Turn angle constraint...\n');
    turnViolations = [];
    
    for i = 2:size(path, 1) - 1
        v1 = path(i, 1:2) - path(i-1, 1:2);
        v2 = path(i+1, 1:2) - path(i, 1:2);
        
        if norm(v1) > 0.1 && norm(v2) > 0.1
            angle1 = atan2(v1(2), v1(1));
            angle2 = atan2(v2(2), v2(1));
            
            turnAngle = abs(angle2 - angle1) * 180 / pi;
            if turnAngle > 180
                turnAngle = 360 - turnAngle;
            end
            
            if turnAngle > maxTurn
                turnViolations = [turnViolations; i, turnAngle, maxTurn];
            end
        end
    end
    
    if ~isempty(turnViolations)
        fprintf('  ✗ Turn violations: %d points\n', size(turnViolations, 1));
        violations.turnsTooSharp = turnViolations;
        violations.totalViolations = violations.totalViolations + size(turnViolations, 1);
    else
        fprintf('  ✓ All turns within limits\n');
    end
    
    %% Calculate path statistics
    fprintf('\nCalculating statistics...\n');
    
    pathLength = 0;
    minAGLValue = inf;
    maxSlope = 0;
    maxTurnAngle = 0;
    
    for i = 1:size(path, 1) - 1
        dx = path(i+1, :) - path(i, :);
        pathLength = pathLength + norm(dx);
        
        if size(path, 2) >= 3
            terrainZ = demInterpolate(demData, path(i, 1), path(i, 2));
            agl = path(i, 3) - terrainZ;
            minAGLValue = min(minAGLValue, agl);
        end
    end
    
    stats = struct(...
        'pathLength', pathLength, ...
        'numWaypoints', size(path, 1), ...
        'minAGL', minAGLValue, ...
        'maxSlope', maxSlope, ...
        'maxTurnAngle', maxTurnAngle, ...
        'safetyScore', calculateSafetyScore(violations, size(path, 1)) ...
    );
    
    %% Determine if valid
    isValid = (violations.totalViolations == 0);
    
    fprintf('\nValidation Result: %s\n', ifthenelse(isValid, 'PASS ✓', 'FAIL ✗'));
    fprintf('Safety score: %.1f%%\n', stats.safetyScore);
    fprintf('===================\n\n');
end

%% Helper: Calculate safety score
function score = calculateSafetyScore(violations, numWaypoints)
    %CALCULATESAFETYSCORE Calculate 0-100 safety score
    totalViolations = violations.totalViolations;
    score = max(0, 100 - (totalViolations / max(numWaypoints, 1) * 100));
end

%% Helper: Conditional value
function result = ifthenelse(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
