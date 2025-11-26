%% OPTIONAL: GPS to UTM Conversion Helper Function
% Uncomment and use if working with real-world latitude/longitude coordinates

function surveyArea = defineSurveyAreaFromGPS(params, lat_center, lon_center)
    % Alternative initialization using GPS coordinates
    %
    % Input:
    %   params - struct from parameters.m
    %   lat_center - center latitude (decimal degrees)
    %   lon_center - center longitude (decimal degrees)
    %
    % Uses MATLAB Mapping Toolbox to convert GPS to UTM
    
    if ~license('test', 'Mapping_Toolbox')
        error('Mapping Toolbox required for GPS conversion');
    end
    
    % Convert center point to UTM
    [x_center, y_center, utmZone] = deg2utm(lat_center, lon_center);
    
    % Adjust x0, y0 to center at the GPS point
    params.x0 = x_center - params.areaWidth / 2;
    params.y0 = y_center - params.areaHeight / 2;
    params.utmZone = utmZone;
    
    % Use standard function with adjusted params
    surveyArea = defineSurveyArea(params);
end
