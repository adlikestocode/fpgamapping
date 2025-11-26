function run_hdl_workflow()
% Runs fixed-point conversion, test bench, and HDL generation

    fprintf('Starting HDL workflow...\n');

    % Load DEM to define test variables
    load('synthetic_dem_hills.mat', 'demData');

    % Define fixed-point test input argument types
    Z_grid = fi(zeros(101,101), 1, 16, 8);
    x_norm = fi(0, 0, 16, 8);
    y_norm = fi(0, 0, 16, 8);

    % Run test bench first
    test_demInterpolate_hdl();
    
    % Setup HDL Coder config for Verilog generation
    hdlcfg = coder.config('hdl');
    hdlcfg.TargetLanguage = 'Verilog';
    hdlcfg.GenerateHDLTestBench = true;
    hdlcfg.SynthesisTool = 'Xilinx Vivado';
    hdlcfg.TargetFrequency = 250; % MHz

    fprintf('Generating HDL code...\n');
    codegen -config hdlcfg demInterpolate_hdl -args {Z_grid, x_norm, y_norm} -report

    fprintf('HDL code generation complete. See codegen/demInterpolate_hdl/hdlsrc/\n');
end
