function cfg = fixpt_config_aws()
%FIXPT_CONFIG_AWS AWS F1-optimized fixed-point type system for UAV pathfinding
%
% Target: AWS F1 xcvu9p-flgb2104-2-i (Xilinx UltraScale+ VU9P)
% Clock: 250 MHz
% Design: UAV autonomous navigation with A* pathfinding
%
% Type System Philosophy:
% - Maximize DSP48E2 utilization (6,840 available)
% - Use BRAM for DEM storage (75.9 Mb available)
% - Minimize LUT usage for control logic
% - Guard bits for numerical stability
% - Round-to-nearest for outputs

    cfg = struct();
    
    %% ========================================
    %% ELEVATION DATA (DEM Grid Values)
    %% ========================================
    % Purpose: Store terrain height in meters
    % Range: [0, 500] meters (with 20% headroom → 600m)
    % Precision: 0.01m required → use 0.0078125m (better)
    % Application: DEM grid storage and interpolation results
    
    cfg.elevation = numerictype(1, 18, 7);
    % Analysis:
    %   Signed: Yes (1 bit) - allows negative for future sea-level data
    %   Word: 18 bits total
    %   Fraction: 7 bits → precision = 2^-7 = 0.0078125m (< 0.01m ✓)
    %   Integer: 18-7-1 = 10 bits → range = [-1024, 1023.992] meters
    %   Covers [0, 600]m with margin ✓
    % 
    % Resource Impact:
    %   - 101×101 grid = 10,201 values × 18 bits = 183.6 Kb
    %   - 1024×1024 grid = 1,048,576 values × 18 bits = 18.9 Mb
    %   - Fits comfortably in 75.9 Mb BRAM ✓
    %   - DSP48E2 multiplier: 18×18 bit native support ✓
    
    cfg.elevation_info = struct(...
        'range_min', 0, ...
        'range_max', 600, ...
        'precision', 0.0078125, ...
        'bits_total', 18, ...
        'bits_frac', 7, ...
        'dsp_native', true);
    
    %% ========================================
    %% GRID COORDINATES (Normalized 0-100)
    %% ========================================
    % Purpose: Position within grid cell (floating grid coordinates)
    % Range: [0, 100] for 101×101 grid (up to 1024 for 1024×1024)
    % Precision: 0.001 grid cells required → use 0.00024 (better)
    % Application: Input to interpolation, supports sub-pixel positioning
    
    cfg.grid_coord = numerictype(0, 22, 12);
    % Analysis:
    %   Signed: No (unsigned, positions always positive)
    %   Word: 22 bits total  
    %   Fraction: 12 bits → precision = 2^-12 = 0.000244 grid cells
    %   Integer: 22-12 = 10 bits → range = [0, 1023.9998]
    %   Supports up to 1024×1024 grids ✓
    %
    % Resource Impact:
    %   - Arithmetic with elevation: 22×18 → uses DSP48E2 (27×18 mode)
    %   - No BRAM needed (scalar values)
    
    cfg.grid_coord_info = struct(...
        'range_min', 0, ...
        'range_max', 1024, ...
        'precision', 0.000244140625, ...
        'bits_total', 22, ...
        'bits_frac', 12);
    
    %% ========================================
    %% INTERPOLATION WEIGHTS [0, 1]
    %% ========================================
    % Purpose: Bilinear interpolation coefficients (dx, dy, 1-dx, 1-dy)
    % Range: [0, 1] exactly
    % Precision: 0.0001 required → use 0.0000305 (better)
    % Application: Multiply with corner elevation values
    
    cfg.weight = numerictype(0, 16, 15);
    % Analysis:
    %   Signed: No (weights always in [0,1])
    %   Word: 16 bits total
    %   Fraction: 15 bits → precision = 2^-15 = 0.0000305
    %   Integer: 16-15 = 1 bit → range = [0, 1.99997]
    %   Exact [0,1] representation ✓
    %
    % Resource Impact:
    %   - Multiplication: 16×18 (weight × elevation)
    %   - Uses DSP48E2 efficiently (18×18 or 27×18 mode)
    %   - High precision minimizes interpolation error
    
    cfg.weight_info = struct(...
        'range_min', 0, ...
        'range_max', 1, ...
        'precision', 3.0517578125e-05, ...
        'bits_total', 16, ...
        'bits_frac', 15);
    
    %% ========================================
    %% DISTANCE METRICS (Euclidean)
    %% ========================================
    % Purpose: Heuristic distance for A* (straight-line to goal)
    % Range: [0, 1500]m (diagonal of 1000m × 1000m grid, with margin)
    % Precision: 0.1m required → use 0.0625m (better)
    % Application: A* heuristic, neighbor costs
    
    cfg.distance = numerictype(0, 18, 4);
    % Analysis:
    %   Signed: No (distances always positive)
    %   Word: 18 bits total
    %   Fraction: 4 bits → precision = 2^-4 = 0.0625m
    %   Integer: 18-4 = 14 bits → range = [0, 16383.9375]m
    %   Covers [0, 1500]m easily ✓
    %
    % Resource Impact:
    %   - sqrt() operation: Requires CORDIC or approximation
    %   - Addition/comparison: Minimal LUT usage
    
    cfg.distance_info = struct(...
        'range_min', 0, ...
        'range_max', 1600, ...
        'precision', 0.0625, ...
        'bits_total', 18, ...
        'bits_frac', 4);
    
    %% ========================================
    %% GRID INDICES (Integer Array Access)
    %% ========================================
    % Purpose: Integer indices for array access (i, j in grid)
    % Range: [0, 1023] for up to 1024×1024 grids
    % Precision: 1 (integer)
    % Application: Memory addressing for BRAM access
    
    cfg.index = numerictype(0, 11, 0);
    % Analysis:
    %   Signed: No (indices always positive)
    %   Word: 11 bits total
    %   Fraction: 0 bits (pure integer)
    %   Range: [0, 2047]
    %   Supports up to 2048×2048 grids (future-proof) ✓
    %
    % Resource Impact:
    %   - BRAM addressing: Native 11-bit address support
    %   - Increment/compare: Minimal LUT usage
    
    cfg.index_info = struct(...
        'range_min', 0, ...
        'range_max', 2047, ...
        'precision', 1, ...
        'bits_total', 11, ...
        'bits_frac', 0);
    
    %% ========================================
    %% INTERMEDIATE CALCULATIONS (Guard Bits)
    %% ========================================
    % Purpose: Products and sums in bilinear interpolation
    % Prevent overflow: elevation(18) × weight(16) = 34 bits
    % Four-term sum needs 2 guard bits → 36 bits
    % Application: Internal DSP48E2 accumulator
    
    cfg.intermediate = numerictype(1, 36, 22);
    % Analysis:
    %   Signed: Yes (products can be signed)
    %   Word: 36 bits total
    %   Fraction: 22 bits (7 + 15 = elevation.frac + weight.frac)
    %   Integer: 36-22-1 = 13 bits
    %   Range: [-4096, 4095.999] - sufficient for 4× products
    %
    % Bit Growth Analysis:
    %   elevation × weight: (18,7) × (16,15) = (34,22)
    %   4-term sum: Need log2(4)=2 guard bits → (36,22) ✓
    %
    % Resource Impact:
    %   - DSP48E2 accumulator: 48-bit native (we use 36) ✓
    %   - Minimizes quantization noise in final result
    
    cfg.intermediate_info = struct(...
        'range_min', -4096, ...
        'range_max', 4095.999, ...
        'precision', 2.384185791015625e-07, ...
        'bits_total', 36, ...
        'bits_frac', 22, ...
        'guard_bits', 2);
    
    %% ========================================
    %% ROUNDING & OVERFLOW MODES
    %% ========================================
    
    cfg.rounding_mode = 'Nearest';
    cfg.overflow_mode = 'Saturate';
    
    %% ========================================
    %% FIMATH CONFIGURATION
    %% ========================================
    
    cfg.fimath = fimath(...
        'RoundingMethod', cfg.rounding_mode, ...
        'OverflowAction', cfg.overflow_mode, ...
        'ProductMode', 'FullPrecision', ...
        'SumMode', 'FullPrecision', ...
        'CastBeforeSum', true);
    
    %% ========================================
    %% RESOURCE ESTIMATES
    %% ========================================
    
    cfg.resources = struct();
    cfg.resources.bram_small = struct('total_mb', 0.175, 'utilization_pct', 0.23);
    cfg.resources.bram_large = struct('total_mb', 18.0, 'utilization_pct', 23.7);
    cfg.resources.dsp = struct('total_per_kernel', 4, 'utilization_pct', 0.06);
    
    cfg.performance = struct(...
        'clock_freq_mhz', 250, ...
        'latency_cycles', 6, ...
        'throughput_per_kernel', 41.67e6);
    
    cfg.version = '1.0';
    cfg.date = '2025-11-26';
    cfg.target = 'AWS F1 xcvu9p';
    
    fprintf('\n=== AWS F1 Fixed-Point Type System Loaded ===\n');
    fprintf('Target: %s @ %d MHz\n', cfg.target, cfg.performance.clock_freq_mhz);
    fprintf('Elevation: %d-bit, precision %.4f m\n', ...
        cfg.elevation.WordLength, cfg.elevation_info.precision);
    fprintf('============================================\n\n');
end
