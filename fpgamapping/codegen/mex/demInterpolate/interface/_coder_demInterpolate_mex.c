/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_demInterpolate_mex.c
 *
 * Code generation for function '_coder_demInterpolate_mex'
 *
 */

/* Include files */
#include "_coder_demInterpolate_mex.h"
#include "_coder_demInterpolate_api.h"
#include "demInterpolate_data.h"
#include "demInterpolate_initialize.h"
#include "demInterpolate_terminate.h"
#include "demInterpolate_types.h"
#include "rt_nonfinite.h"

/* Function Definitions */
void demInterpolate_mexFunction(demInterpolateStackData *SD, int32_T nlhs,
                                mxArray *plhs[1], int32_T nrhs,
                                const mxArray *prhs[3])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  const mxArray *outputs;
  st.tls = emlrtRootTLSGlobal;
  /* Check for proper number of arguments. */
  if (nrhs != 3) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 3, 4,
                        14, "demInterpolate");
  }
  if (nlhs > 1) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 14,
                        "demInterpolate");
  }
  /* Call the function. */
  demInterpolate_api(SD, prhs, &outputs);
  /* Copy over outputs to the caller. */
  emlrtReturnArrays(1, &plhs[0], &outputs);
}

void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs,
                 const mxArray *prhs[])
{
  demInterpolateStackData *demInterpolateStackDataGlobal = NULL;
  demInterpolateStackDataGlobal = (demInterpolateStackData *)emlrtMxCalloc(
      (size_t)1, (size_t)1U * sizeof(demInterpolateStackData));
  mexAtExit(&demInterpolate_atexit);
  /* Module initialization. */
  demInterpolate_initialize();
  /* Dispatch the entry-point. */
  demInterpolate_mexFunction(demInterpolateStackDataGlobal, nlhs, plhs, nrhs,
                             prhs);
  /* Module termination. */
  demInterpolate_terminate();
  emlrtMxFree(demInterpolateStackDataGlobal);
}

emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLSR2022a(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1,
                           NULL, "windows-1252", true);
  return emlrtRootTLSGlobal;
}

/* End of code generation (_coder_demInterpolate_mex.c) */
