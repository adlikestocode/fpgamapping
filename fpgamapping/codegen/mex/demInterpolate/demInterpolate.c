/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * demInterpolate.c
 *
 * Code generation for function 'demInterpolate'
 *
 */

/* Include files */
#include "demInterpolate.h"
#include "demInterpolate_types.h"
#include "rt_nonfinite.h"
#include "mwmathutil.h"

/* Variable Definitions */
static emlrtDCInfo emlrtDCI = {
    105,              /* lineNo */
    18,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

static emlrtDCInfo b_emlrtDCI = {
    105,              /* lineNo */
    23,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

static emlrtDCInfo c_emlrtDCI = {
    106,              /* lineNo */
    18,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

static emlrtDCInfo d_emlrtDCI = {
    106,              /* lineNo */
    23,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

static emlrtDCInfo e_emlrtDCI = {
    107,              /* lineNo */
    18,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

static emlrtDCInfo f_emlrtDCI = {
    107,              /* lineNo */
    23,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

static emlrtDCInfo g_emlrtDCI = {
    108,              /* lineNo */
    18,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

static emlrtDCInfo h_emlrtDCI = {
    108,              /* lineNo */
    23,               /* colNo */
    "demInterpolate", /* fName */
    "C:\\Users\\adity_6z2h70p\\Documents\\MATLAB\\fpgamapping\\demInterpolate."
    "m", /* pName */
    1    /* checkKind */
};

/* Function Definitions */
real_T demInterpolate(const emlrtStack *sp, const struct0_T *demData, real_T x,
                      real_T y)
{
  real_T dx;
  real_T i;
  real_T i_float;
  real_T j;
  real_T j_float;
  int32_T b_z_tmp;
  int32_T z_tmp;
  /*  demInterpolate.m */
  /*  UNIVERSAL DEM interpolation - works everywhere */
  /*  Drop-in replacement for Module 0 version */
  /*  Compatible with: Modules 0-4, HDL Coder, Fixed-Point Converter, AWS F1 */
  /*  */
  /*  Project: Drone Pathfinding - Module 0-5 Integration */
  /*  Date: 2025-11-12 */
  /*  Compatibility: MATLAB R2023b, HDL Coder, Fixed-Point Designer */
  /* DEMINTERPOLATE Bilinear interpolation for DEM elevation queries */
  /*  */
  /*  Universal implementation that works in: */
  /*    - Module 0: DEM system */
  /*    - Module 1: Mapping */
  /*    - Module 2: Coverage paths */
  /*    - Module 3: A* pathfinding */
  /*    - Module 4: Mission integration */
  /*    - Module 5: HDL generation for AWS F1 */
  /*  */
  /*  Syntax: */
  /*    z = demInterpolate(demData, x, y) */
  /*  */
  /*  Inputs: */
  /*    demData - DEM structure with fields: */
  /*              .X (101x101 grid of X coordinates) */
  /*              .Y (101x101 grid of Y coordinates) */
  /*              .Z (101x101 grid of elevations) */
  /*              .resolution (grid spacing, e.g., 10 meters) */
  /*    x - UTM X coordinate (scalar) */
  /*    y - UTM Y coordinate (scalar) */
  /*  */
  /*  Outputs: */
  /*    z - Interpolated elevation at (x,y) in meters */
  /*  */
  /*  Features: */
  /*    - HDL Coder compatible (no try-catch, bounded loops) */
  /*    - Fixed-Point Designer compatible (simple arithmetic) */
  /*    - Works with existing Modules 0-4 code */
  /*    - AWS F1 FPGA ready */
  /*  */
  /*  Example: */
  /*    demData = load('synthetic_dem_hills.mat').demData; */
  /*    z = demInterpolate(demData, 500500, 5400500); */
  /*     %% Input validation (removed for HDL compatibility) */
  /*  Note: For HDL, input validation happens at top level */
  /*  This function assumes valid inputs */
  /*     %% Extract grid data */
  /*     %% Grid bounds */
  /*     %% Calculate grid position */
  /*  Position in grid coordinates (floating-point) */
  i_float = (x - demData->X[0]) / demData->resolution;
  j_float = (y - demData->Y[0]) / demData->resolution;
  /*     %% Integer grid indices */
  i = muDoubleScalarFloor(i_float);
  j = muDoubleScalarFloor(j_float);
  /*     %% Bounds checking (clamp to valid range for 101x101 grid) */
  /*  This prevents out-of-bounds access and is HDL-compatible */
  if (i < 0.0) {
    i = 0.0;
  }
  if (j < 0.0) {
    j = 0.0;
  }
  if (i >= 100.0) {
    i = 99.0;
  }
  if (j >= 100.0) {
    j = 99.0;
  }
  /*     %% Calculate fractional offsets (interpolation weights) */
  dx = i_float - i;
  /*  X weight (0 to 1) */
  i_float = j_float - j;
  /*  Y weight (0 to 1) */
  /*     %% Clamp weights to valid range [0, 1] */
  /*  Handles edge cases and ensures valid interpolation */
  if (dx < 0.0) {
    dx = 0.0;
  }
  if (dx > 1.0) {
    dx = 1.0;
  }
  if (i_float < 0.0) {
    i_float = 0.0;
  }
  if (i_float > 1.0) {
    i_float = 1.0;
  }
  /*     %% Get four corner elevation values */
  /*  MATLAB uses 1-based indexing, so add 1 to C-style indices */
  if (j + 1.0 != (int32_T)(j + 1.0)) {
    emlrtIntegerCheckR2012b(j + 1.0, &emlrtDCI, (emlrtConstCTX)sp);
  }
  if (i + 1.0 != (int32_T)(i + 1.0)) {
    emlrtIntegerCheckR2012b(i + 1.0, &b_emlrtDCI, (emlrtConstCTX)sp);
  }
  /*  Bottom-left corner */
  if (j + 1.0 != (int32_T)(j + 1.0)) {
    emlrtIntegerCheckR2012b(j + 1.0, &c_emlrtDCI, (emlrtConstCTX)sp);
  }
  if (i + 2.0 != (int32_T)(i + 2.0)) {
    emlrtIntegerCheckR2012b(i + 2.0, &d_emlrtDCI, (emlrtConstCTX)sp);
  }
  /*  Bottom-right corner */
  if (j + 2.0 != (int32_T)(j + 2.0)) {
    emlrtIntegerCheckR2012b(j + 2.0, &e_emlrtDCI, (emlrtConstCTX)sp);
  }
  if (i + 1.0 != (int32_T)(i + 1.0)) {
    emlrtIntegerCheckR2012b(i + 1.0, &f_emlrtDCI, (emlrtConstCTX)sp);
  }
  /*  Top-left corner */
  if (j + 2.0 != (int32_T)(j + 2.0)) {
    emlrtIntegerCheckR2012b(j + 2.0, &g_emlrtDCI, (emlrtConstCTX)sp);
  }
  if (i + 2.0 != (int32_T)(i + 2.0)) {
    emlrtIntegerCheckR2012b(i + 2.0, &h_emlrtDCI, (emlrtConstCTX)sp);
  }
  /*  Top-right corner */
  /*     %% Bilinear interpolation */
  /*  Standard formula: z = z11*(1-dx)*(1-dy) + z21*dx*(1-dy) +  */
  /*                        z12*(1-dx)*dy + z22*dx*dy */
  /*  This is HDL-synthesizable and Fixed-Point compatible */
  z_tmp = 101 * ((int32_T)(i + 1.0) - 1);
  b_z_tmp = 101 * ((int32_T)(i + 2.0) - 1);
  return ((demData->Z[((int32_T)(j + 1.0) + z_tmp) - 1] * (1.0 - dx) *
               (1.0 - i_float) +
           demData->Z[((int32_T)(j + 1.0) + b_z_tmp) - 1] * dx *
               (1.0 - i_float)) +
          demData->Z[((int32_T)(j + 2.0) + z_tmp) - 1] * (1.0 - dx) * i_float) +
         demData->Z[((int32_T)(j + 2.0) + b_z_tmp) - 1] * dx * i_float;
}

/* End of code generation (demInterpolate.c) */
