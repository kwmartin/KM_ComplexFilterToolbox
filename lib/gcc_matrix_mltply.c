#include <stdio.h>
#include <stdlib.h>

void input(int m, int n, int a[m][n])
{
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            printf("%d, %d : ", i, j);
            scanf("%d", &a[i][j]);
        }
    }
}

void print(int m, int n, int a[m][n])
{
    int i, j;
    for (i = 0; i < m; i++) {
        for (j = 0; j < n; j++) {
            printf("%3d ", a[i][j]);
        }
        printf("\n");
    }   
}

void multiply(int m, int n, int p, int a[m][n], int b[n][p], int c[m][p])
{
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < p; j++) {
            c[i][j] = 0;
            for (int k = 0; k < n; k++) {
                c[i][j] += a[i][k] * b[k][j];
            }
        }
    }
}

int main()
{
    int r1, c1, r2, c2;
    printf("Row and column for matrix #1 :\n");
    scanf("%d %d", &r1, &c1);
    printf("Row and column for matrix #2 :\n");
    scanf("%d %d", &r2, &c2);

    if (r2 != c1) {
        printf("The matrices are incompatible.\n");
        exit(EXIT_FAILURE);
    }

    int mat1[r1][c1], mat2[r2][c2], ans[r1][c2];
    printf("Enter elements of the first matrix.\n");
    input(r1, c1, mat1);
    printf("The elements of the first matrix are :\n");
    print(r1, c1, mat1);
    printf("Enter elements of the second matrix.\n");
    input(r2, c2, mat2);
    printf("The elements of the second matrix are :\n");
    print(r2, c2, mat2);

    multiply(r1, r2, c2, mat1, mat2, ans);
    printf("The product is :\n");
    print(r1, c2, ans);

    return EXIT_SUCCESS;
}