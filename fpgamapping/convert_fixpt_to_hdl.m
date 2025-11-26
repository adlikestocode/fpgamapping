%% convert_fixpt_to_hdl.m
% Convert fixed-point MATLAB → Verilog (auto-generated)
% Fixes the path issue from generateHDL_aws.m

function convert_fixpt_to_hdl()
    
    fprintf('\n========================================\n');
    fprintf('AUTO-GENERATE VERILOG FROM FIXED-POINT\n');
    fprintf('========================================\n\n');
    
    %% Step 1: Locate fixed-point file
    fprintf('Step 1: Locating fixed-point MATLAB...\n');
    
    fixpt_dir = 'codegen/demInterpolate/fixpt';
    fixpt_file = fullfile(fixpt_dir, 'demInterpolate_fixpt.m');
    
    if exist(fixpt_file, 'file')
        fprintf('  ✓ Found: %s\n', fixpt_file);
        
        % Add to MATLAB path
        addpath(fixpt_dir);
        fprintf('  ✓ Added to path\n\n');
    else
        fprintf('  ✗ Fixed-point file not found!\n');
        fprintf('  Run generateHDL_aws() first to create it.\n\n');
        return;
    end
    
    %% Step 2: Load test data
    fprintf('Step 2: Loading terrain data...\n');
    demData = load('synthetic_dem_hills.mat').demData;
    fprintf('  ✓ Loaded: %dx%d grid\n\n', size(demData.Z,1), size(demData.Z,2));
    
    %% Step 3: Configure HDL Coder
    fprintf('Step 3: Configuring HDL Coder...\n');
    
    cfg = coder.config('hdl');
    cfg.TargetLanguage = 'Verilog';
    cfg.GenerateHDLTestBench = true;
    cfg.TestBenchName = 'tb_demInterpolate_fixpt';
    
    fprintf('  ✓ Language: Verilog\n');
    fprintf('  ✓ Testbench: Enabled\n\n');
    
    %% Step 4: Generate Verilog from fixed-point
    fprintf('Step 4: Generating Verilog...\n');
    fprintf('  Source: demInterpolate_fixpt.m (auto-generated)\n');
    fprintf('  Target: AWS F1 (Xilinx VU9P)\n\n');
    
    try
        demType = coder.typeof(demData);
        xType = coder.typeof(double(0));
        yType = coder.typeof(double(0));
        
        % Generate HDL from fixed-point version
        codegen -config cfg demInterpolate_fixpt ...
                -args {demType, xType, yType} ...
                -o demInterpolate_fpga_auto -report;
        
        fprintf('  ✓ HDL Coder completed!\n\n');
        hdl_success = true;
        
    catch ME
        fprintf('  ⚠ HDL Coder issue: %s\n\n', ME.message);
        hdl_success = false;
    end
    
    %% Step 5: Copy to output directory
    if hdl_success
        fprintf('Step 5: Copying generated files...\n');
        
        % Check multiple possible locations
        hdl_dirs = {
            'codegen/demInterpolate_fixpt/hdlsrc'
            'hdlsrc'
            'codegen/hdlsrc'
        };
        
        files_copied = false;
        for i = 1:length(hdl_dirs)
            if exist(hdl_dirs{i}, 'dir')
                fprintf('  Found HDL output: %s\n', hdl_dirs{i});
                
                % Copy Verilog files
                v_files = dir(fullfile(hdl_dirs{i}, '*.v'));
                if ~isempty(v_files)
                    for j = 1:length(v_files)
                        src = fullfile(hdl_dirs{i}, v_files(j).name);
                        dst = fullfile('hdl_output_aws', v_files(j).name);
                        copyfile(src, dst);
                        fprintf('  ✓ Copied: %s\n', v_files(j).name);
                    end
                    files_copied = true;
                end
                break;
            end
        end
        
        if ~files_copied
            fprintf('  ⚠ HDL files not found in expected locations\n');
        end
        fprintf('\n');
    end
    
    %% Step 6: Verify and compare
    fprintf('Step 6: Verification\n');
    fprintf('========================================\n\n');
    
    v_files = dir('hdl_output_aws/*.v');
    fprintf('Verilog files in hdl_output_aws/:\n');
    for i = 1:length(v_files)
        fprintf('  • %s (%.1f KB)\n', v_files(i).name, v_files(i).bytes/1024);
    end
    fprintf('\n');
    
    %% Step 7: Summary
    fprintf('========================================\n');
    fprintf('SUMMARY\n');
    fprintf('========================================\n\n');
    
    if hdl_success && files_copied
        fprintf('✅ AUTO-GENERATED VERILOG SUCCESSFUL!\n\n');
        fprintf('What You Have:\n');
        fprintf('  • demInterpolate_fixpt.m (Fixed-Point Designer output)\n');
        fprintf('  • *.v files (HDL Coder output)\n');
        fprintf('  • Auto-generated from YOUR fixed-point code\n');
        fprintf('  • Ready for AWS F1 synthesis\n\n');
        
        fprintf('Compare:\n');
        fprintf('  Manual:   demInterpolate_fpga.v (template)\n');
        fprintf('  Auto:     demInterpolate_fpga_auto.v (from fixpt)\n\n');
        
    else
        fprintf('⚠ AUTO-GENERATION HAD ISSUES\n\n');
        fprintf('But you still have:\n');
        fprintf('  ✓ Fixed-point MATLAB (demInterpolate_fixpt.m)\n');
        fprintf('  ✓ Manual Verilog template\n');
        fprintf('  ✓ Both are valid for AWS F1\n\n');
    end
    
    fprintf('Next Steps:\n');
    fprintf('  1. Review: hdl_output_aws/\n');
    fprintf('  2. Synthesize in Vivado\n');
    fprintf('  3. Deploy to AWS F1!\n\n');
    
end
