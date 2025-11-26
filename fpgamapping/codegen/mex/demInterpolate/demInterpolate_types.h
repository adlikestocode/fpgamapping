/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * demInterpolate_types.h
 *
 * Code generation for function 'demInterpolate'
 *
 */

#pragma once

/* Include files */
#include "rtwtypes.h"
#include "emlrt.h"

/* Type Definitions */
#ifndef typedef_struct0_T
#define typedef_struct0_T
typedef struct {
  real_T X[10201];
  real_T Y[10201];
  real_T Z[10201];
  real_T resolution;
  real_T xMin;
  real_T xMax;
  real_T yMin;
  real_T yMax;
  char_T type[5];
  real_T minElevation;
  real_T maxElevation;
  real_T meanElevation;
  real_T stdElevation;
} struct0_T;
#endif /* typedef_struct0_T */

#ifndef typedef_b_demInterpolate_api
#define typedef_b_demInterpolate_api
typedef struct {
  struct0_T demData;
} b_demInterpolate_api;
#endif /* typedef_b_demInterpolate_api */

#ifndef typedef_demInterpolateStackData
#define typedef_demInterpolateStackData
typedef struct {
  b_demInterpolate_api f0;
} demInterpolateStackData;
#endif /* typedef_demInterpolateStackData */

/* End of code generation (demInterpolate_types.h) */
