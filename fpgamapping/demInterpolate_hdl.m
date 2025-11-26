function z = demInterpolate_hdl(Z_grid, x_norm, y_norm)
%DEMINTERPOLATE_HDL HDL-compatible bilinear interpolation kernel
%
% Inputs:
%   Z_grid  - [101x101] fixed-point elevation grid (fi)
%   x_norm  - normalized X position in [0,100], fixed-point fi
%   y_norm  - normalized Y position in [0,100], fixed-point fi
%
% Output:
%   z       - interpolated elevation (fixed-point fi)
%
% This function follows HDL Coder constraints (fixed size, no dynamic arrays)

%#codegen

    % Integer indices
    i = fi(floor(x_norm), 0, 8, 0);
    j = fi(floor(y_norm), 0, 8, 0);

    % Clamp indices
    if i > 99
        i = fi(99, 0, 8, 0);
    end
    if j > 99
        j = fi(99, 0, 8, 0);
    end

    % Fractional weights
    dx = x_norm - i;
    dy = y_norm - j;

    % Corner values (note MATLAB indexing 1-based)
    z11 = Z_grid(j+1, i+1);
    z21 = Z_grid(j+1, i+2);
    z12 = Z_grid(j+2, i+1);
    z22 = Z_grid(j+2, i+2);

    % Precompute complements
    one_minus_dx = fi(1.0, 0, 16, 8) - dx;
    one_minus_dy = fi(1.0, 0, 16, 8) - dy;

    % Bilinear interpolation formula
    z = z11 * one_minus_dx * one_minus_dy + ...
        z21 * dx * one_minus_dy + ...
        z12 * one_minus_dx * dy + ...
        z22 * dx * dy;

end
