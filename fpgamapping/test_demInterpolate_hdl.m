function test_demInterpolate_hdl()
% Test bench for demInterpolate_hdl fixed-point kernel

    fprintf('Running demInterpolate_hdl tests...\n');

    % Load DEM data
    load('synthetic_dem_hills.mat', 'demData');
    Z_double = demData.Z;

    % Convert DEM grid to fixed-point
    Z_grid_fi = fi(Z_double, 1, 16, 8);

    % Test points normalized in grid coords
    testPoints = [
        50.5, 50.5;
        0.0, 0.0;
        99.9, 99.9;
        25.3, 75.7;
        88.1, 12.4;
    ];

    for k = 1:size(testPoints,1)
        x_norm = fi(testPoints(k,1), 0, 16, 8);
        y_norm = fi(testPoints(k,2), 0, 16, 8);

        % Call HDL kernel
        z_hdl = demInterpolate_hdl(Z_grid_fi, x_norm, y_norm);

        % Reference value from full demInterpolate()
        x_actual = demData.X(1,1) + double(testPoints(k,1)) * demData.resolution;
        y_actual = demData.Y(1,1) + double(testPoints(k,2)) * demData.resolution;
        z_ref = demInterpolate(demData, x_actual, y_actual);

        % Display errors
        fprintf('Test point (%.1f, %.1f)\n', testPoints(k,1), testPoints(k,2));
        fprintf('  HDL Kernel:      %.3f\n', double(z_hdl));
        fprintf('  Reference interp: %.3f\n', z_ref);
        fprintf('  Error:           %.3f\n\n', abs(double(z_hdl) - z_ref));
    end
    fprintf('Test complete.\n');
end
