# DEM Configuration & Mode Switching Guide

## Quick Reference: How to Change Settings

### File Location & Quick Edit Lines

#### 1. **Enable/Disable DEM**
**File:** `parameters.m`  
**Line:** Find and edit this line:
```
params.useDEM = true;   % Change to: true (3D) or false (2D)
```

---

#### 2. **Change Terrain Type** (DEM mode only)
**File:** `parameters.m`  
**Line:** Find and edit this line:
```
params.demType = 'hills';  % Options: 'flat', 'slope', 'hills', 'random'
```

---

#### 3. **Adjust Minimum AGL (Above Ground Level)**
**File:** `parameters.m`  
**Line:** Find and edit this line:
```
params.minAGL = 120;  % Drone altitude above terrain (meters)
```

---

#### 4. **Change DEM Resolution**
**File:** `parameters.m`  
**Line:** Find and edit this line:
```
params.demResolution = 10;  % Grid spacing in meters (10 = 10m resolution)
```

---

#### 5. **Specify DEM File**
**File:** `parameters.m`  
**Line:** Find and edit this line:
```
params.demFile = 'synthetic_dem_hills.mat';  % Path to DEM file
```

---

## Mode Switching Recipes

### Recipe 1: Switch to 3D (DEM Enabled) - RECOMMENDED
```
% In parameters.m, set:
params.useDEM = true;
params.demType = 'hills';
params.minAGL = 120;
```

### Recipe 2: Switch to 2D (Flat Terrain)
```
% In parameters.m, set:
params.useDEM = false;
```

### Recipe 3: Test Different Terrain Types (3D Mode)
```
% In parameters.m, set:
params.useDEM = true;

% Then try each type:
params.demType = 'flat';    % No variation
params.demType = 'slope';   % Linear gradient
params.demType = 'hills';   % Rolling hills (realistic)
params.demType = 'random';  % Random features
```

### Recipe 4: Ultra-Smooth Terrain Flight (Very High AGL)
```
% In parameters.m, set:
params.useDEM = true;
params.demType = 'hills';
params.minAGL = 200;  % Keep 200m above terrain
```

### Recipe 5: Low Altitude Survey (High Resolution Imagery)
```
% In parameters.m, set:
params.useDEM = true;
params.demType = 'flat';   % Use flat for lower altitudes
params.minAGL = 50;        % 50m AGL for high resolution
```

---

## Full Parameters.m DEM Section Reference

```
%% DEM Configuration
params.useDEM = true;                        % Enable/disable DEM
params.demType = 'hills';                    % Terrain: 'flat', 'slope', 'hills', 'random'
params.demResolution = 10;                   % DEM resolution (meters)
params.demFile = 'synthetic_dem_hills.mat';  % DEM file path
params.generateDEM = true;                   % Auto-generate if missing
params.minAGL = 120;                         % Min altitude above ground (meters)
```

---

## How to Test Mode Switching

### Quick Test Script
```
clear all;

% Test 1: 3D Mode
fprintf('=== Testing 3D Mode ===\n');
params = parameters();
params.useDEM = true;

surveyArea = defineSurveyArea(params);
[~, ~, wp3D] = generateGrid(surveyArea, params);
fprintf('3D Waypoints: %d × %d\n', size(wp3D, 1), size(wp3D, 2));

% Test 2: 2D Mode
fprintf('\n=== Testing 2D Mode ===\n');
params.useDEM = false;

[~, ~, wp2D] = generateGrid(surveyArea, params);
fprintf('2D Waypoints: %d × %d\n', size(wp2D, 1), size(wp2D, 2));
```

---

## Output Comparison

### 3D Mode Output
```
=== DEM Configuration ===
Status: ✓ DEM ENABLED (3D terrain mode)
Terrain Type: hills
DEM File: synthetic_dem_hills.mat
Resolution: 10 meters
Min AGL: 120 meters
Mode: Terrain-aware altitude (variable)
```

### 2D Mode Output
```
=== DEM Configuration ===
Status: ⊗ DEM DISABLED (2D flat mode)
Mode: Fixed altitude (120 m AGL)
Note: To enable DEM, set params.useDEM = true
```

---

## Common Workflows

### Workflow 1: Development (Fast Testing)
```
params.useDEM = true;
params.demType = 'flat';  % Simplest case, easiest to debug
```

### Workflow 2: Realistic Mission Planning
```
params.useDEM = true;
params.demType = 'hills';  % Realistic rolling terrain
params.minAGL = 120;
```

### Workflow 3: Academic Comparison (2D vs 3D)
```
% First test 2D
params.useDEM = false;
[~, ~, wp_2d] = generateGrid(surveyArea, params);

% Then test 3D
params.useDEM = true;
[~, ~, wp_3d] = generateGrid(surveyArea, params);

% Compare results
```

### Workflow 4: FPGA/HDL Testing (Minimal Complexity)
```
params.useDEM = true;
params.demType = 'flat';  % Use flat but keep 3D structure
params.demResolution = 20;  % Coarser grid = fewer waypoints
```

---

## Troubleshooting

### "DEM file not found" error
**Solution:** Make sure `params.generateDEM = true` is set in parameters.m

### Elevation values look wrong (all same or NaN)
**Solution:** 
- Check `params.demType` is one of: 'flat', 'slope', 'hills', 'random'
- Verify DEM file exists: `isfile(params.demFile)`

### Too many or too few waypoints
**Solution:** Adjust `params.gridSpacing` in parameters.m

### Flight altitude too high/low
**Solution:** Adjust `params.minAGL` to maintain desired clearance above terrain

---

## Files Modified for DEM Integration

| File | Changes | Key Lines |
|------|---------|-----------|
| `parameters.m` | Added DEM config section | Lines 53-60 |
| `generateGrid.m` | Added DEM elevation loading | Lines 48-50 |
| `computeCoverageGrid.m` | Added terrain-aware altitude | Lines 32-50 |

---

```

***

## **PART 3: test_module1_dem_integration.m - Instructions**

### **How to Run:**

1. **Copy the test script** into your project folder
2. **Run in MATLAB:**
   ```matlab
   test_module1_dem_integration
   ```
3. **Select test mode** (1, 2, or 3) when prompted
4. **Review output** showing which mode is active and results

### **Test Options:**

- **Option 1:** Test 3D mode only (DEM enabled) - **RECOMMENDED**
- **Option 2:** Test 2D mode only (flat terrain)
- **Option 3:** Compare both modes side-by-side

***


