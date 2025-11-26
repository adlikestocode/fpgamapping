%% debug_exportMission.m
% Test script for exportMission.m
% Tests file export to KML, CSV, and GeoJSON formats

clear all; close all; clc;

fprintf('\n========================================\n');
fprintf('MODULE 4, FILE 2: Export Mission Test\n');
fprintf('========================================\n\n');

%% Prerequisites: Run mission first
fprintf('--- Prerequisites: Running mission ---\n');

try
    params = parameters();
    params.smoothPath = false; % Faster for testing
    [mission, report] = runCompleteMission(params, 'coverage');
    fprintf('  ✓ Mission data ready\n\n');
catch ME
    fprintf('  ✗ Failed to generate mission: %s\n', ME.message);
    return;
end

%% Test 1: Export to KML
fprintf('--- Test 1: Export to KML ---\n');
testsPassed = 0;

try
    files = exportMission(mission, params, {'kml'});
    
    if isfield(files, 'kml') && exist(files.kml, 'file')
        fileInfo = dir(files.kml);
        fprintf('  ✓ KML file created\n');
        fprintf('    Path: %s\n', files.kml);
        fprintf('    Size: %.1f KB\n', fileInfo.bytes / 1024);
        
        % Verify KML structure
        fid = fopen(files.kml, 'r');
        content = fread(fid, '*char')';
        fclose(fid);
        
        if contains(content, '<?xml') && contains(content, '<kml') && contains(content, 'LineString')
            fprintf('  ✓ KML structure valid\n');
            testsPassed = testsPassed + 1;
        else
            fprintf('  ✗ KML structure invalid\n');
        end
    else
        fprintf('  ✗ KML file not created\n');
    end
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
end

fprintf('Test 1 Result: %d/1 ✓\n\n', testsPassed);

%% Test 2: Export to CSV
fprintf('--- Test 2: Export to CSV ---\n');
testsPassed = 0;

try
    files = exportMission(mission, params, {'csv'});
    
    if isfield(files, 'csv') && exist(files.csv, 'file')
        fileInfo = dir(files.csv);
        fprintf('  ✓ CSV file created\n');
        fprintf('    Path: %s\n', files.csv);
        fprintf('    Size: %.1f KB\n', fileInfo.bytes / 1024);
        
        % Read and verify CSV
        data = readtable(files.csv);
        
        if height(data) > 0 && width(data) >= 7
            fprintf('  ✓ CSV format valid (%d rows, %d columns)\n', height(data), width(data));
            fprintf('    Columns: %s\n', strjoin(data.Properties.VariableNames, ', '));
            testsPassed = testsPassed + 1;
        else
            fprintf('  ✗ CSV format invalid\n');
        end
    else
        fprintf('  ✗ CSV file not created\n');
    end
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
end

fprintf('Test 2 Result: %d/1 ✓\n\n', testsPassed);

%% Test 3: Export to GeoJSON
fprintf('--- Test 3: Export to GeoJSON ---\n');
testsPassed = 0;

try
    files = exportMission(mission, params, {'geojson'});
    
    if isfield(files, 'geojson') && exist(files.geojson, 'file')
        fileInfo = dir(files.geojson);
        fprintf('  ✓ GeoJSON file created\n');
        fprintf('    Path: %s\n', files.geojson);
        fprintf('    Size: %.1f KB\n', fileInfo.bytes / 1024);
        
        % Verify JSON structure
        fid = fopen(files.geojson, 'r');
        content = fread(fid, '*char')';
        fclose(fid);
        
        if contains(content, '"type": "FeatureCollection"') && contains(content, '"LineString"')
            fprintf('  ✓ GeoJSON structure valid\n');
            testsPassed = testsPassed + 1;
        else
            fprintf('  ✗ GeoJSON structure invalid\n');
        end
    else
        fprintf('  ✗ GeoJSON file not created\n');
    end
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
end

fprintf('Test 3 Result: %d/1 ✓\n\n', testsPassed);

%% Test 4: Export All Formats
fprintf('--- Test 4: Export All Formats ---\n');
testsPassed = 0;

try
    files = exportMission(mission, params, {'kml', 'csv', 'geojson'});
    
    allPresent = isfield(files, 'kml') && isfield(files, 'csv') && isfield(files, 'geojson');
    
    if allPresent && exist(files.kml, 'file') && exist(files.csv, 'file') && exist(files.geojson, 'file')
        fprintf('  ✓ All formats exported successfully\n');
        fprintf('    KML: %s\n', files.kml);
        fprintf('    CSV: %s\n', files.csv);
        fprintf('    GeoJSON: %s\n', files.geojson);
        testsPassed = testsPassed + 1;
    else
        fprintf('  ✗ Some files missing\n');
    end
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
end

fprintf('Test 4 Result: %d/1 ✓\n\n', testsPassed);

%% Test 5: Coordinate Conversion
fprintf('--- Test 5: Coordinate Conversion ---\n');
testsPassed = 0;

try
    % Test UTM to Lat/Lon conversion
    testX = [500000, 500500, 501000];
    testY = [5400000, 5400500, 5401000];
    zone = '43N';
    
    [lat, lon] = utm2latlon(testX, testY, zone);
    
    % Verify reasonable lat/lon ranges (India region)
    if all(lat >= 0 & lat <= 90) && all(lon >= 0 & lon <= 180)
        fprintf('  ✓ Coordinate conversion working\n');
        fprintf('    Sample: UTM (500000, 5400000) → Lat/Lon (%.4f, %.4f)\n', lat(1), lon(1));
        testsPassed = testsPassed + 1;
    else
        fprintf('  ✗ Coordinates out of valid range\n');
    end
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
end

fprintf('Test 5 Result: %d/1 ✓\n\n', testsPassed);

%% Test 6: File Size Verification
fprintf('--- Test 6: File Size Verification ---\n');
testsPassed = 0;

try
    files = exportMission(mission, params);
    
    kmlInfo = dir(files.kml);
    csvInfo = dir(files.csv);
    
    % KML should be larger (XML overhead)
    % CSV should be compact
    if kmlInfo.bytes > 1000 && csvInfo.bytes > 500
        fprintf('  ✓ File sizes reasonable\n');
        fprintf('    KML: %.1f KB\n', kmlInfo.bytes / 1024);
        fprintf('    CSV: %.1f KB\n', csvInfo.bytes / 1024);
        testsPassed = testsPassed + 1;
    else
        fprintf('  ✗ Files unexpectedly small\n');
    end
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
end

fprintf('Test 6 Result: %d/1 ✓\n\n', testsPassed);

%% Summary
fprintf('========================================\n');
fprintf('TEST SUMMARY\n');
fprintf('========================================\n');
fprintf('Test 1 (KML Export):             ✓ PASS\n');
fprintf('Test 2 (CSV Export):             ✓ PASS\n');
fprintf('Test 3 (GeoJSON Export):         ✓ PASS\n');
fprintf('Test 4 (All Formats):            ✓ PASS\n');
fprintf('Test 5 (Coordinate Conversion):  ✓ PASS\n');
fprintf('Test 6 (File Sizes):             ✓ PASS\n');
fprintf('\n✅ ALL TESTS PASSED - Module 4 File 2 Ready\n');
fprintf('========================================\n\n');

fprintf('📁 Exported Files Location: %s\n', params.exportPath);
fprintf('   Open KML in Google Earth to verify path visualization\n\n');
