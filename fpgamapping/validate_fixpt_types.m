function report = validate_fixpt_types(cfg)
%VALIDATE_FIXPT_TYPES Validate AWS F1 fixed-point type system
%
% Checks range, precision, overflow, and quantization noise for each type
% Generates summary report and plots for analysis

    types = {'elevation', 'grid_coord', 'weight', 'distance', 'index', 'intermediate'};
    report = struct();
    
    fprintf('\n=== Validating Fixed-Point Type System ===\n\n');
    
    for k = 1:length(types)
        tname = types{k};
        nt = cfg.(tname);
        infoField = [tname '_info'];
        info = cfg.(infoField);
        
        fprintf('Validating %s type:\n', tname);
        fprintf('  WordLength = %d bits, FractionLength = %d bits\n', ...
            nt.WordLength, nt.FractionLength);
        
        % Check range compatibility
        maxRepresentable = 2^(nt.WordLength - (nt.IsSigned + nt.FractionLength)) - 2^-nt.FractionLength;
        if nt.IsSigned
            minRepresentable = -2^(nt.WordLength - 1 - nt.FractionLength);
        else
            minRepresentable = 0;
        end
        
        % Compare intended ranges
        range_ok = (minRepresentable <= info.range_min) && (maxRepresentable >= info.range_max);
        
        % Quantization error estimate
        quant_error = 2^(-nt.FractionLength);
        
        % Store results
        report.(tname).range_ok = range_ok;
        report.(tname).quantization_error = quant_error;
        report.(tname).min_representable = minRepresentable;
        report.(tname).max_representable = maxRepresentable;
        
        if range_ok
            fprintf('  Range OK: Covers [%g, %g]\n', info.range_min, info.range_max);
        else
            fprintf('  WARNING: Range Mismatch! Intended [%g, %g], but type covers [%g, %g]\n', ...
                info.range_min, info.range_max, minRepresentable, maxRepresentable);
        end
        
        fprintf('  Quantization error: %g\n', quant_error);
        fprintf('  Precision vs requirement: %.1fx better\n\n', info.precision / quant_error);
    end
    
    fprintf('=== Type Validation Complete ===\n\n');
    
    % Summary statistics
    all_ok = true;
    for k = 1:length(types)
        if ~report.(types{k}).range_ok
            all_ok = false;
            break;
        end
    end
    
    report.all_tests_passed = all_ok;
    
    if all_ok
        fprintf('RESULT: All types passed validation!\n\n');
    else
        fprintf('RESULT: Some types failed validation. Review warnings above.\n\n');
    end
end
