#include <stdlib.h>
#include <complex.h>
#include <time.h>
#include <sys/time.h>

#define nmbChnls 65
#define nmbInpts 8192

struct sctn {
    int order;
    double complex a11;
    double complex a12;
    double complex a21;
    double complex a22;
    double complex b1;
    double complex b2;
    double complex c1;
    double complex c2;
    double complex d;
};

struct fltCoeffs {
    int nmbSctns;
    struct sctn sctns[20];
};

double complex xin1[nmbInpts];
double complex fShfts[nmbChnls];

double getTimeNow(void);
void cFltr(struct fltCoeffs *coeffs, int nInpts, int nChnls, double complex *fShfts);
