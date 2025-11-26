%% exportMission.m
% Export mission data to KML, CSV, and GeoJSON formats
% Creates files compatible with Google Earth, Excel, and web mapping tools
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Integration & Mission Planning - Module 4
% Author: [Your Name]
% Date: 2025-11-12
% Compatibility: MATLAB 2023b+

function [exportedFiles] = exportMission(missionData, params, formats)
    %EXPORTMISSION Export mission path to multiple file formats
    %
    % Syntax:
    %   files = exportMission(missionData, params)
    %   files = exportMission(missionData, params, formats)
    %
    % Inputs:
    %   missionData - struct from runCompleteMission
    %   params      - struct from parameters()
    %   formats     - (optional) cell array {'kml', 'csv', 'geojson'}
    %
    % Outputs:
    %   exportedFiles - struct with paths to created files
    %
    % Example:
    %   [mission, ~] = runCompleteMission(params);
    %   files = exportMission(mission, params, {'kml', 'csv'});
    
    %% Input validation
    if nargin < 2
        error('exportMission:MissingInput', 'Requires missionData and params');
    end
    
    if nargin < 3
        formats = params.exportFormats;
    end
    
    % Create output directory
    if ~exist(params.exportPath, 'dir')
        mkdir(params.exportPath);
    end
    
    fprintf('\n=== Mission Export ===\n');
    fprintf('Output directory: %s\n', params.exportPath);
    fprintf('Formats: %s\n\n', strjoin(formats, ', '));
    
    exportedFiles = struct();
    exportedFiles.timestamp = datestr(now);
    
    %% Extract path data
    if isfield(missionData, 'finalPath') && ~isempty(missionData.finalPath)
        path = missionData.finalPath;
    elseif isfield(missionData, 'smoothedPath') && ~isempty(missionData.smoothedPath)
        path = missionData.smoothedPath;
    elseif isfield(missionData, 'coveragePath') && ~isempty(missionData.coveragePath)
        path = missionData.coveragePath;
    else
        error('exportMission:NoPath', 'No valid path found in missionData');
    end
    
    fprintf('Exporting %d waypoints...\n\n', size(path, 1));
    
    %% Export to each format
    for i = 1:length(formats)
        fmt = lower(formats{i});
        
        switch fmt
            case 'kml'
                fprintf('Exporting to KML...\n');
                tic;
                kmlFile = exportToKML(path, missionData, params);
                exportedFiles.kml = kmlFile;
                fprintf('  ✓ KML exported: %s (%.2f sec)\n\n', kmlFile, toc);
                
            case 'csv'
                fprintf('Exporting to CSV...\n');
                tic;
                csvFile = exportToCSV(path, missionData, params);
                exportedFiles.csv = csvFile;
                fprintf('  ✓ CSV exported: %s (%.2f sec)\n\n', csvFile, toc);
                
            case 'geojson'
                fprintf('Exporting to GeoJSON...\n');
                tic;
                jsonFile = exportToGeoJSON(path, missionData, params);
                exportedFiles.geojson = jsonFile;
                fprintf('  ✓ GeoJSON exported: %s (%.2f sec)\n\n', jsonFile, toc);
                
            otherwise
                warning('Unknown export format: %s', fmt);
        end
    end
    
    fprintf('=== Export Complete ===\n\n');
end

%% Helper: Export to KML
function kmlFile = exportToKML(path, missionData, params)
    %EXPORTTOKML Create KML file for Google Earth
    
    kmlFile = fullfile(params.exportPath, sprintf('%s.kml', params.missionName));
    
    % Convert UTM to Lat/Lon (simple approximation)
    [lat, lon] = utm2latlon(path(:,1), path(:,2), params.utmZone);
    
    % Open file
    fid = fopen(kmlFile, 'w');
    
    % Write KML header
    fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?>\n');
    fprintf(fid, '<kml xmlns="http://www.opengis.net/kml/2.2">\n');
    fprintf(fid, '  <Document>\n');
    fprintf(fid, '    <name>%s</name>\n', params.missionName);
    fprintf(fid, '    <description>Drone survey mission path</description>\n\n');
    
    % Define styles
    fprintf(fid, '    <Style id="pathStyle">\n');
    fprintf(fid, '      <LineStyle>\n');
    fprintf(fid, '        <color>ff0000ff</color>\n'); % Red line
    fprintf(fid, '        <width>3</width>\n');
    fprintf(fid, '      </LineStyle>\n');
    fprintf(fid, '    </Style>\n\n');
    
    fprintf(fid, '    <Style id="startStyle">\n');
    fprintf(fid, '      <IconStyle>\n');
    fprintf(fid, '        <color>ff00ff00</color>\n'); % Green
    fprintf(fid, '        <scale>1.2</scale>\n');
    fprintf(fid, '      </IconStyle>\n');
    fprintf(fid, '    </Style>\n\n');
    
    fprintf(fid, '    <Style id="goalStyle">\n');
    fprintf(fid, '      <IconStyle>\n');
    fprintf(fid, '        <color>ffff0000</color>\n'); % Blue
    fprintf(fid, '        <scale>1.2</scale>\n');
    fprintf(fid, '      </IconStyle>\n');
    fprintf(fid, '    </Style>\n\n');
    
    % Start marker
    fprintf(fid, '    <Placemark>\n');
    fprintf(fid, '      <name>Start</name>\n');
    fprintf(fid, '      <styleUrl>#startStyle</styleUrl>\n');
    fprintf(fid, '      <Point>\n');
    fprintf(fid, '        <coordinates>%.8f,%.8f,%.1f</coordinates>\n', lon(1), lat(1), path(1,3));
    fprintf(fid, '      </Point>\n');
    fprintf(fid, '    </Placemark>\n\n');
    
    % Goal marker
    fprintf(fid, '    <Placemark>\n');
    fprintf(fid, '      <name>Goal</name>\n');
    fprintf(fid, '      <styleUrl>#goalStyle</styleUrl>\n');
    fprintf(fid, '      <Point>\n');
    fprintf(fid, '        <coordinates>%.8f,%.8f,%.1f</coordinates>\n', lon(end), lat(end), path(end,3));
    fprintf(fid, '      </Point>\n');
    fprintf(fid, '    </Placemark>\n\n');
    
    % Flight path
    fprintf(fid, '    <Placemark>\n');
    fprintf(fid, '      <name>Flight Path</name>\n');
    fprintf(fid, '      <styleUrl>#pathStyle</styleUrl>\n');
    fprintf(fid, '      <LineString>\n');
    fprintf(fid, '        <extrude>1</extrude>\n');
    fprintf(fid, '        <tessellate>1</tessellate>\n');
    fprintf(fid, '        <altitudeMode>absolute</altitudeMode>\n');
    fprintf(fid, '        <coordinates>\n');
    
    % Write all coordinates
    for i = 1:size(path, 1)
        fprintf(fid, '          %.8f,%.8f,%.1f\n', lon(i), lat(i), path(i,3));
    end
    
    fprintf(fid, '        </coordinates>\n');
    fprintf(fid, '      </LineString>\n');
    fprintf(fid, '    </Placemark>\n\n');
    
    % Close document
    fprintf(fid, '  </Document>\n');
    fprintf(fid, '</kml>\n');
    
    fclose(fid);
end

%% Helper: Export to CSV
function csvFile = exportToCSV(path, missionData, params)
    %EXPORTTOCSV Create CSV file with waypoint data
    
    csvFile = fullfile(params.exportPath, sprintf('%s_waypoints.csv', params.missionName));
    
    % Convert UTM to Lat/Lon
    [lat, lon] = utm2latlon(path(:,1), path(:,2), params.utmZone);
    
    % Open file
    fid = fopen(csvFile, 'w');
    
    % Write header
    fprintf(fid, 'WaypointID,Easting_UTM,Northing_UTM,Elevation_m,Latitude,Longitude,Action\n');
    
    % Write waypoints
    for i = 1:size(path, 1)
        if i == 1
            action = 'TAKEOFF';
        elseif i == size(path, 1)
            action = 'LAND';
        else
            action = 'WAYPOINT';
        end
        
        fprintf(fid, '%d,%.2f,%.2f,%.2f,%.8f,%.8f,%s\n', ...
                i, path(i,1), path(i,2), path(i,3), lat(i), lon(i), action);
    end
    
    fclose(fid);
end

%% Helper: Export to GeoJSON
function jsonFile = exportToGeoJSON(path, missionData, params)
    %EXPORTTOGEOJSON Create GeoJSON file for web mapping
    
    jsonFile = fullfile(params.exportPath, sprintf('%s.geojson', params.missionName));
    
    % Convert UTM to Lat/Lon
    [lat, lon] = utm2latlon(path(:,1), path(:,2), params.utmZone);
    
    % Open file
    fid = fopen(jsonFile, 'w');
    
    % Write GeoJSON structure
    fprintf(fid, '{\n');
    fprintf(fid, '  "type": "FeatureCollection",\n');
    fprintf(fid, '  "features": [\n');
    fprintf(fid, '    {\n');
    fprintf(fid, '      "type": "Feature",\n');
    fprintf(fid, '      "properties": {\n');
    fprintf(fid, '        "name": "%s",\n', params.missionName);
    fprintf(fid, '        "waypoints": %d,\n', size(path, 1));
    fprintf(fid, '        "mission_type": "%s"\n', params.missionType);
    fprintf(fid, '      },\n');
    fprintf(fid, '      "geometry": {\n');
    fprintf(fid, '        "type": "LineString",\n');
    fprintf(fid, '        "coordinates": [\n');
    
    % Write coordinates
    for i = 1:size(path, 1)
        if i == size(path, 1)
            fprintf(fid, '          [%.8f, %.8f, %.1f]\n', lon(i), lat(i), path(i,3));
        else
            fprintf(fid, '          [%.8f, %.8f, %.1f],\n', lon(i), lat(i), path(i,3));
        end
    end
    
    fprintf(fid, '        ]\n');
    fprintf(fid, '      }\n');
    fprintf(fid, '    }\n');
    fprintf(fid, '  ]\n');
    fprintf(fid, '}\n');
    
    fclose(fid);
end

%% Helper: UTM to Lat/Lon conversion
function [lat, lon] = utm2latlon(x, y, zone)
    %UTM2LATLON Simple UTM to Lat/Lon approximation
    %
    % NOTE: This is a simplified conversion suitable for visualization.
    % For high-accuracy applications, use proper geodetic library.
    
    % Extract zone number
    zoneNum = str2double(zone(1:end-1));
    
    % Central meridian
    lon0 = (zoneNum - 1) * 6 - 180 + 3;
    
    % Simple approximation (Mercator-like)
    % More accurate methods require geodetic libraries
    k0 = 0.9996; % UTM scale factor
    a = 6378137.0; % WGS84 equatorial radius
    
    lat = (y / k0) / (a * pi / 180);
    lon = lon0 + (x - 500000) / (k0 * a * pi / 180 * cos(lat * pi / 180));
end
