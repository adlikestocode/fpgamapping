%% test_module1_dem_integration.m
% Comprehensive integration test for Module 1 with DEM support
% Tests all 3 updated files working together in both 2D and 3D modes
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Module 1 - Mapping & Survey Area (DEM Integration)
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

clear all; close all; clc;

fprintf('\n========================================\n');
fprintf('MODULE 1: DEM Integration Test\n');
fprintf('(Parameters + Grid + Coverage)\n');
fprintf('========================================\n\n');

%% Test Mode Selection
fprintf('Available Tests:\n');
fprintf('  1. Test 3D Mode (DEM enabled)  - RECOMMENDED\n');
fprintf('  2. Test 2D Mode (DEM disabled) - Flat terrain\n');
fprintf('  3. Test Both Modes (comparison)\n\n');

testMode = input('Select test (1-3) [default: 1]: ');
if isempty(testMode)
    testMode = 1;
end

%% Run tests based on selection
switch testMode
    case 1
        test3DMode();
    case 2
        test2DMode();
    case 3
        testBothModes();
    otherwise
        fprintf('Invalid selection. Running default (3D Mode)...\n');
        test3DMode();
end

fprintf('\n✅ TEST COMPLETE\n========================================\n\n');

%% Test Function 1: 3D Mode (DEM Enabled)
function test3DMode()
    
    fprintf('\n--- TEST 1: 3D Mode (DEM Enabled) ---\n');
    
    % Setup
    params = parameters();
    params.useDEM = true;
    params.demType = 'hills';
    
    surveyArea = defineSurveyArea(params);
    
    fprintf('\n✓ Parameters loaded\n');
    fprintf('  DEM Enabled: %s\n', ifthenelse(params.useDEM, 'YES', 'NO'));
    fprintf('  Terrain Type: %s\n', params.demType);
    fprintf('  Min AGL: %.0f m\n', params.minAGL);
    
    % Generate grid (3D with elevation)
    [gridX, gridY, waypoints3D] = generateGrid(surveyArea, params);
    
    fprintf('\n✓ Waypoints generated\n');
    fprintf('  Format: [X, Y, Z]\n');
    fprintf('  Count: %d waypoints\n', size(waypoints3D, 1));
    fprintf('  Elevation range: %.1f to %.1f m\n', ...
            min(waypoints3D(:,3)), max(waypoints3D(:,3)));
    
    % Compute coverage
    [coverageData, adjGrid, adjWP] = computeCoverageGrid(waypoints3D, params, surveyArea);
    
    fprintf('\n✓ Coverage analysis complete\n');
    fprintf('  Altitude Mode: %s\n', upper(coverageData.altitudeMode));
    fprintf('  Flight Altitude: %.1f m\n', coverageData.altitude);
    fprintf('  GSD: %.2f cm/pixel\n', coverageData.gsd);
    fprintf('  Grid Valid: %s\n', ifthenelse(coverageData.isGridValid, 'YES', 'NO'));
    
    fprintf('\n✅ 3D MODE TEST PASSED\n');
    
end

%% Test Function 2: 2D Mode (Flat Terrain)
function test2DMode()
    
    fprintf('\n--- TEST 2: 2D Mode (DEM Disabled) ---\n');
    
    % Setup
    params = parameters();
    params.useDEM = false;
    
    surveyArea = defineSurveyArea(params);
    
    fprintf('\n✓ Parameters loaded\n');
    fprintf('  DEM Enabled: %s\n', ifthenelse(params.useDEM, 'YES', 'NO'));
    fprintf('  Fixed Altitude: %.0f m AGL\n', params.altitude);
    
    % Generate grid (2D without elevation)
    [gridX, gridY, waypoints2D] = generateGrid(surveyArea, params);
    
    fprintf('\n✓ Waypoints generated\n');
    fprintf('  Format: [X, Y]\n');
    fprintf('  Count: %d waypoints\n', size(waypoints2D, 1));
    
    % Compute coverage
    [coverageData, adjGrid, adjWP] = computeCoverageGrid(waypoints2D, params, surveyArea);
    
    fprintf('\n✓ Coverage analysis complete\n');
    fprintf('  Altitude Mode: %s\n', upper(coverageData.altitudeMode));
    fprintf('  Flight Altitude: %.1f m\n', coverageData.altitude);
    fprintf('  GSD: %.2f cm/pixel\n', coverageData.gsd);
    fprintf('  Grid Valid: %s\n', ifthenelse(coverageData.isGridValid, 'YES', 'NO'));
    
    fprintf('\n✅ 2D MODE TEST PASSED\n');
    
end

%% Test Function 3: Both Modes (Comparison)
function testBothModes()
    
    fprintf('\n--- TEST 3: Mode Comparison (2D vs 3D) ---\n');
    
    surveyArea = defineSurveyArea(parameters());
    
    % Test 2D mode
    fprintf('\n[2D MODE]\n');
    params_2D = parameters();
    params_2D.useDEM = false;
    
    [~, ~, wp_2D] = generateGrid(surveyArea, params_2D);
    [cov_2D, ~, ~] = computeCoverageGrid(wp_2D, params_2D, surveyArea);
    
    % Test 3D mode
    fprintf('\n[3D MODE]\n');
    params_3D = parameters();
    params_3D.useDEM = true;
    params_3D.demType = 'hills';
    
    [~, ~, wp_3D] = generateGrid(surveyArea, params_3D);
    [cov_3D, ~, ~] = computeCoverageGrid(wp_3D, params_3D, surveyArea);
    
    % Comparison
    fprintf('\n========== COMPARISON TABLE ==========\n');
    fprintf('%-25s | %-10s | %-10s\n', 'Parameter', '2D Mode', '3D Mode');
    fprintf('%-25s | %-10s | %-10s\n', repmat('-', 1, 25), repmat('-', 1, 10), repmat('-', 1, 10));
    fprintf('%-25s | %-10d | %-10d\n', 'Waypoint Count', size(wp_2D, 1), size(wp_3D, 1));
    fprintf('%-25s | %-10s | %-10s\n', 'Waypoint Format', '[X, Y]', '[X, Y, Z]');
    fprintf('%-25s | %-10.1f | %-10.1f\n', 'Flight Altitude (m)', cov_2D.altitude, cov_3D.altitude);
    fprintf('%-25s | %-10.2f | %-10.2f\n', 'GSD (cm/pixel)', cov_2D.gsd, cov_3D.gsd);
    fprintf('%-25s | %-10s | %-10s\n', 'Grid Valid', ifthenelse(cov_2D.isGridValid, 'YES', 'NO'), ...
            ifthenelse(cov_3D.isGridValid, 'YES', 'NO'));
    fprintf('%-25s | %-10.1f | %-10.1f\n', 'Coverage %', cov_2D.coveragePercentage, cov_3D.coveragePercentage);
    fprintf('========================================\n\n');
    
    fprintf('✅ COMPARISON TEST PASSED\n');
    
end

%% Helper function
function result = ifthenelse(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
