%% defineSurveyArea.m
% Defines the survey area boundaries and handles coordinate conversions
% Uses parameters from parameters.m to establish the rectangular survey region
%
% Project: Drone Pathfinding with Coverage Path Planning
% Module: Mapping & Survey Area Setup
% Author: [Your Name]
% Date: 2025-11-11

function surveyArea = defineSurveyArea(params)
    %DEFINESURVEYAREA Define and validate survey area boundaries
    %
    % Syntax:
    %   surveyArea = defineSurveyArea(params)
    %
    % Input:
    %   params - struct from parameters.m containing area dimensions and origin
    %
    % Output:
    %   surveyArea - struct with fields:
    %       .xMin, .xMax, .yMin, .yMax - UTM bounds (meters)
    %       .utmZone - UTM zone designation
    %       .width, .height - area dimensions (meters)
    %       .centerX, .centerY - area center coordinates
    %       .corners - [4x2] array of corner coordinates (clockwise)
    
    if nargin < 1 || ~isstruct(params)
        error('defineSurveyArea:InvalidInput', ...
              'Input must be params struct from parameters.m');
    end
    
    %% Extract parameters
    x0 = params.x0;
    y0 = params.y0;
    width = params.areaWidth;
    height = params.areaHeight;
    utmZone = params.utmZone;
    
    %% Define rectangular survey area (lower-left origin)
    % Rectangle corners in counter-clockwise order starting from lower-left
    
    surveyArea.xMin = x0;
    surveyArea.xMax = x0 + width;
    surveyArea.yMin = y0;
    surveyArea.yMax = y0 + height;
    
    surveyArea.width = width;
    surveyArea.height = height;
    
    %% Calculate center point
    surveyArea.centerX = (surveyArea.xMin + surveyArea.xMax) / 2;
    surveyArea.centerY = (surveyArea.yMin + surveyArea.yMax) / 2;
    
    %% Define corner coordinates (clockwise from lower-left)
    surveyArea.corners = [
        surveyArea.xMin, surveyArea.yMin;  % Lower-left
        surveyArea.xMax, surveyArea.yMin;  % Lower-right
        surveyArea.xMax, surveyArea.yMax;  % Upper-right
        surveyArea.xMin, surveyArea.yMax   % Upper-left
    ];
    
    %% UTM zone information
    surveyArea.utmZone = utmZone;
    
    %% Display survey area information
    fprintf('\n=== Survey Area Definition ===\n');
    fprintf('UTM Zone: %s\n', surveyArea.utmZone);
    fprintf('Easting (X): %.0f to %.0f meters\n', surveyArea.xMin, surveyArea.xMax);
    fprintf('Northing (Y): %.0f to %.0f meters\n', surveyArea.yMin, surveyArea.yMax);
    fprintf('Area Dimensions: %.0f x %.0f meters\n', surveyArea.width, surveyArea.height);
    fprintf('Area Center: (%.0f, %.0f)\n', surveyArea.centerX, surveyArea.centerY);
    fprintf('Area Size: %.2f km²\n', (surveyArea.width * surveyArea.height) / 1e6);
    fprintf('==============================\n\n');
    
end
