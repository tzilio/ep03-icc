#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <fenv.h>
#include <math.h>
#include <stdint.h>

#include "utils.h"

#define UNROLL 2

/////////////////////////////////////////////////////////////////////////////////////
//   AJUSTE DE CURVAS
/////////////////////////////////////////////////////////////////////////////////////

void montaSL(double **A, double *b, int n, long long int p, double *x, double *y) {
    for (long long int i = 0; i < n; ++i) {
        b[i] = 0.0;
        for (long long int j = 0; j < n; ++j) {
            A[i][j] = 0.0;
        }
    }

    double *vetorPow = (double*)malloc((2*n-1)*sizeof(double));
    vetorPow[0] = 1; // n^0 = 1

    for (long long int k = 0; k < p; ++k) {
        for (long long int i = 1; i < (2 * n) - 1; ++i) {
            vetorPow[i] = vetorPow[i - 1] * x[k];
        }

        for (long long int i = 0; i < n; i += UNROLL) {
            b[i] += vetorPow[i]*y[k];
            if (i+1< n) b[i+1] += vetorPow[i+1]*y[k];

            for (long long int j = 0; j < n; j += UNROLL){ 
                A[i][j] += vetorPow[i+j];
                if (j+1 < n) A[i][j+1] += vetorPow[i+j+1]; 
                if (i+1 < n){
                A[i+1][j] += vetorPow[i + 1 + j];
                if (j+1 < n) A[i+1][j+1] += vetorPow[i+1+j+1];
            }
        }
    }
    free(vetorPow);
}

void eliminacaoGauss(double **A, double *b, int n) {
    for (long long int i = 0; i < n; ++i) {
        long long int iMax = i;
        for (long long int k = i+1; k < n; ++k)
            if (A[k][i] > A[iMax][i])
	            iMax = k;

        if (iMax != i) {
            double *tmp, aux;
            tmp = A[i];
            A[i] = A[iMax];
            A[iMax] = tmp;

            aux = b[i];
            b[i] = b[iMax];
            b[iMax] = aux;
        }

        for (long long int k = i + 1; k < n; ++k) {
            double m = A[k][i] / A[i][i];
            A[k][i] = 0.0;
            
            for (long long int j = i + 1; j <= n - 1; j += UNROLL) {
                A[k][j] -= A[i][j]*m;
                A[k][j+1] -= A[i][j+1]*m;
            }
            if (n - i - 1) % 2 != 0)
                A[k][n-1] -= A[i][n-1]*m;

            b[k] -= b[i]*m;
        }
    }
}

void retrossubs(double **A, double *b, double *x, int n) {
    for (long long int i = n-1; i >= 0; --i) {
        x[i] = b[i];
        for (long long int j = i+1; j < n + 1; j += UNROLL) {
            x[i] -= A[i][j]*x[j];
            x[i + 1] -= A[i][j]*x[j + 1];
        }
        if ((n-i-1) % 2)
            x[i] -= A[i][n-1]*x[n-1];
        }
        x[i] /= A[i][i];
    }
}

double P(double x, int N, double *alpha) {
    double Px = alpha[0];
    double potX = x;
    for (long long int i = 1; i <= N; ++i) {
        Px += alpha[i]*potX;
        potX *= x;
    }
    return Px;
}

int main() {

  int N, n;
  long long int K, p;

  scanf("%d %lld", &N, &K);
  p = K;   // quantidade de pontos
  n = N+1; // tamanho do SL (grau N + 1)

  double *x = (double *) malloc(sizeof(double)*p);
  double *y = (double *) malloc(sizeof(double)*p);

  // ler numeros
  for (long long int i = 0; i < p; ++i)
    scanf("%lf %lf", x+i, y+i);

  double **A = (double **) malloc(sizeof(double *)*n);
  for (int i = 0; i < n; ++i)
    A[i] = (double *) malloc(sizeof(double)*n);
  
  double *b = (double *) malloc(sizeof(double)*n);
  double *alpha = (double *) malloc(sizeof(double)*n); // coeficientes ajuste

  LIKWID_MARKER_INIT;
  // (A) Gera SL
  double tSL = timestamp();
  LIKWID_MARKER_START("tSL");
  montaSL(A, b, n, p, x, y);
  LIKWID_MARKER_STOP("tSL");
  tSL = timestamp() - tSL;

  // (B) Resolve SL
  double tEG = timestamp();
  LIKWID_MARKER_START("tEG");
  eliminacaoGauss(A, b, n); 
  retrossubs(A, b, alpha, n); 
  LIKWID_MARKER_STOP("tEG");
  tEG = timestamp() - tEG;

  LIKWID_MARKER_CLOSE;

  // Imprime coeficientes
  for (int i = 0; i < n; ++i)
    printf("%1.15e ", alpha[i]);
  puts("");

  // Imprime resíduos
  for (long long int i = 0; i < p; ++i)
    printf("%1.15e ", fabs(y[i] - P(x[i],N,alpha)) );
  puts("");

  // Imprime os tempos
  printf("%lld %1.10e %1.10e\n", K, tSL, tEG);

  return 0;
}
