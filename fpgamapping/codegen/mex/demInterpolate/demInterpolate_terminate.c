/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * demInterpolate_terminate.c
 *
 * Code generation for function 'demInterpolate_terminate'
 *
 */

/* Include files */
#include "demInterpolate_terminate.h"
#include "_coder_demInterpolate_mex.h"
#include "demInterpolate_data.h"
#include "rt_nonfinite.h"

/* Function Definitions */
void demInterpolate_atexit(void)
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexFunctionCreateRootTLS();
  st.tls = emlrtRootTLSGlobal;
  emlrtEnterRtStackR2012b(&st);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
  emlrtExitTimeCleanup(&emlrtContextGlobal);
}

void demInterpolate_terminate(void)
{
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (demInterpolate_terminate.c) */
