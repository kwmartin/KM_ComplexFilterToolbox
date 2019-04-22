#include <stdio.h>
#include "_cgo_export.h"
#include "fltrBnk.h"

double complex A[20][4];
double complex B[20][2];
double complex C[20][2];
double complex D[20];
double complex Xin[nmbInpts];
double complex frqShfts[nmbChnls];
double complex xinJ[nmbInpts][nmbChnls];
double complex x1[nmbInpts][nmbChnls];
double complex x2[nmbInpts][nmbChnls];
double complex xi1[nmbInpts][nmbChnls];
double complex xi2[nmbInpts][nmbChnls];
double complex Xout[nmbInpts][nmbChnls];

double TimeNow;
double startTime;
double finishTime;

double getTimeNow(void)
{
    struct timeval now;
    gettimeofday(&now, NULL);
    TimeNow = now.tv_sec + 1e-6*now.tv_usec;
    return TimeNow;
}

void cFltr(struct fltCoeffs *coeffs, int nInpts, int nChnls, double complex *fShfts) {
    Xin[0] = 1.0 + 0.0*I;

    // printf("\nnmbSctns: %d\n\n",coeffs->nmbSctns );

    for (int i=0; i < coeffs->nmbSctns; i++) {
        A[i][0] = coeffs->sctns[i].a11;
        A[i][1] = coeffs->sctns[i].a12;
        A[i][2] = coeffs->sctns[i].a21;
        A[i][3] = coeffs->sctns[i].a22;
        B[i][0] = coeffs->sctns[i].b1;
        B[i][1] = coeffs->sctns[i].b2;
        C[i][0] = coeffs->sctns[i].c1;
        C[i][1] = coeffs->sctns[i].c2;
        D[i] = coeffs->sctns[i].d;
    }

    int i, j, k;
    double complex chnlMltplr;

    startTime = getTimeNow();
    for ( i = 0; i < nInpts; i++ ) {
 
        chnlMltplr = 1.0 + 0.0*I;
        for ( k = 0; k < nChnls; k++ ) {
            chnlMltplr = chnlMltplr*(1.0*I);
            xinJ[i][k] = chnlMltplr*Xin[i];
        }

        for ( j = 0; j < coeffs->nmbSctns; j++ ) {
            if (coeffs->sctns[j].order == 2 ) {
                for ( k = 0; k < nChnls; k++ ) {
                    Xout[i][k] = C[j][0]*x1[j][k] + C[j][1]*x2[j][k] + D[j]*xinJ[i][k];
                    xi1[j][k] = A[j][0]*x1[j][k] + A[j][1]*x2[j][k] + B[j][0]*xinJ[i][k];
                    xi2[j][k] = A[j][2]*x1[j][k] + A[j][3]*x2[j][k] + B[j][1]*xinJ[i][k];
                    x1[j][k] = xi1[j][k] * fShfts[k];
                    x2[j][k] = xi2[j][k] * fShfts[k];
                }
            } else {
                for ( k = 0; k < nChnls; k++ ) {
                    Xout[i][k] = C[j][0]*x1[j][k] + D[j]*xinJ[i][k];
                    xi1[j][k] = A[j][0]*x1[j][k] + B[j][0]*xinJ[i][k];
                    x1[j][k] = xi1[j][k] * fShfts[k];
                 }
            }

            for ( k = 0; k < nChnls; k++ ) {
                xinJ[i][k] = Xout[i][k];
            }
        }
    }

    finishTime = getTimeNow();
    printf("\nSimulation time for C: %5.0fms\n\n", (finishTime - startTime)*1000);
    FILE *fp = fopen ("fltrc.dat", "w");
    for (i = 0; i < nInpts; i++) {
        for (j = 0; j < nChnls; j++) {
            fprintf(fp, "(%11.5e%+11.5ei) ", creal(Xout[i][j]), cimag(Xout[i][j]));
        }
        fprintf(fp, "\n");
    }
    fclose(fp);

    return;
}
