 /*
 * divider MEX-file for a digital clock divider.
 *            (see manual under Advanced Topics).
 *
 *            Syntax:  [sys, x0] = divider2(t,x,u,flag,div_rat,Ts)
 *	      The first  is the clock.
 *	      The state changes on the positive
 *	      edge of the clock. May sure no spurious edges occur.
 *	      The output is a single bit
 *
 */

/*
 * The following #define is used to specify the name of this S-Function.
 */

#define S_FUNCTION_NAME  divider2

#include <stdio.h>    /* needed for declaration of sprintf */
#include <math.h>

#ifdef MATLAB_MEX_FILE
#include "mex.h"      /* needed for declaration of mexErrMsgTxt */
#endif

/*
 * need to include simstruc.h for the definition of the SimStruct and
 * its associated macro definitions.
 */

#include "simstruc.h"

/*
 * Defines for easy access nbits which is passed in as a parameter
 */

#define Div_Rat_	ssGetArg(S,0)
#define Ts_			ssGetArg(S,1)

#define GetNumEl(m)  (mxGetM(m)*mxGetN(m))

/*
 * mdlInitializeSizes - initialize the sizes array
 *
 * The sizes array is used by SIMULINK to determine the S-function block's
 * characteristics (number of inputs, outputs, states, etc.).
 */

static void mdlInitializeSizes(S)
    SimStruct *S;
    {
    ssSetNumContStates(    S, 0);                  /* number of continuous states */
    ssSetNumDiscStates(    S, 2);		   /* number of discrete states */
    ssSetNumInputs(        S, 1);		   /* number of inputs */
    ssSetNumOutputs(       S, 1);  		   /* number of outputs */
    ssSetDirectFeedThrough(S, 0);                  /* direct feedthrough flag */
    ssSetNumSampleTimes(   S, 1);                  /* number of sample times */
    ssSetNumInputArgs(     S, 2);                  /* number of input arguments */
    ssSetNumRWork(         S, 0);		   /* number of real work vector elements */
    ssSetNumIWork(         S, 3);                  /* number of integer work vector elements */
    ssSetNumPWork(         S, 0);                  /* number of pointer work vector elements */

    /*
     * if there aren't two parameters, just return, simulink.c will
     * flag the error
     */

    if (ssGetNumArgs(S) != 2)
	return;
}

/*
 * mdlInitializeSampleTimes - initialize the sample times array
 *
 * This function is used to specify the sample time(s) for your S-function.
 * If your S-function is continuous, you must specify a sample time of 0.0.
 * Sample times must be registered in ascending order.
 */

static void mdlInitializeSampleTimes(S)
    SimStruct *S;
    {
    ssSetSampleTimeEvent(S, 0, mxGetPr(Ts_)[0]);
    ssSetOffsetTimeEvent (S, 0, 0.0);
    }

/*
 * mdlInitializeConditions - initialize the states
 *
 * In this function, you should initialize the continuous and discrete
 * states for your S-function block.  The initial states are placed
 * in the x0 variable.  You can also perform any other initialization
 * activities that your S-function may require.
 */

static void mdlInitializeConditions(x0, S)
    double *x0;
    SimStruct *S;
    {
    int *Ivar = ssGetIWork(S);
    int Div_Rat = mxGetPr(Div_Rat_)[0];

    Ivar[0] = 0;
    Ivar[2] = Div_Rat;
    Ivar[1] = Div_Rat/2;
    x0[0] = -1;
    x0[1] = 0;
    }

/*
 * mdlOutputs - compute the outputs
 *
 * In this function, you compute the outputs of your S-function
 * block.  The outputs are placed in the y variable.
 */

static void mdlOutputs(y, x, u, S, tid)
    double *y, *x, *u;
    SimStruct *S;
    int tid;
    {
    int *Ivar = ssGetIWork(S);

    // printf("In divider.c, mdlOutputs, x[0]: %lf\n",x[0]);
    y[0] = (Ivar[0] >= Ivar[1]) ? 0:1;
    // y[0] = x[1];
    }

/*
 * mdlUpdate - perform action at major sampling time step
 *
 * This function is called once for every sampling time step.
 * Discrete states are typically updated here, but this function is useful
 * for performing any tasks that should only take place once per sampling
 * step.
 */

static void mdlUpdate(x, u, S, tid)
    double *x, *u;
    SimStruct *S;
    int tid;
    {
    int *Ivar = ssGetIWork(S);
    if (ssIsSampleHitEvent(S,0,tid))
	{
	// printf("First: In divider, u[0]: %lf, x[0]: %lf\n",u[0],x[0]);
	if ((u[0] <= 0) && (x[0] > 0)) // A negative-going zero crossing
	    {
	    Ivar[0]++;
	    if (Ivar[0] >= Ivar[2]) Ivar[0] = 0;
	    // printf("Counter: %u\n",Ivar[0]);
	    x[1] = Ivar[0] - Ivar[1];
	    }
	x[0] = u[0];
	// printf("Second: In divider, u[0]: %lf, x[0]: %lf\n",u[0],x[0]);
	}
    }

/*
 * mdlDerivatives - compute the derivatives
 *
 * In this function, you compute the S-function block's derivatives.
 * The derivatives are placed in the dx variable.
 */

static void mdlDerivatives(dx, x, u, S, tid)
    double *dx, *x, *u;
    SimStruct *S;
    int tid;
{
}

/*
 * mdlTerminate - called when the simulation is terminated.
 *
 * In this function, you should perform any actions that are necessary
 * at the termination of a simulation.  For example, if memory was allocated
 * in mdlInitializeConditions, this is the place to free it.
 */

static void mdlTerminate(S)
    SimStruct *S;
{
}

#ifdef	MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
