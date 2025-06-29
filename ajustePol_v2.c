#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <fenv.h>
#include <math.h>
#include <stdint.h>
#include <likwid.h>

#include "utils.h"

#define UNROLL 2

/////////////////////////////////////////////////////////////////////////////////////
//   AJUSTE DE CURVAS
/////////////////////////////////////////////////////////////////////////////////////

void montaSL(double **A, double *b, long long int n, long long int p, double *x, double *y) {
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
    }
    free(vetorPow);
}

void eliminacaoGauss(double **A, double *b, long long int n) {
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
            
           for (long long int j = i + 1; j <= n - UNROLL; j += UNROLL) {
                for (long long int u = 0; u < UNROLL; ++u) 
                    A[k][j + u] -= A[i][j + u] * m;
            }

            for (long long int j = n - ((n - i - 1) % UNROLL); j < n; ++j) 
                A[k][j] -= A[i][j] * m;

            b[k] -= b[i] * m;
        }
    }
}

void retrossubs(double **A, double *b, double *x, long long int n) {
    for (long long int i = n-1; i >= 0; --i) {
        x[i] = b[i];
        for (long long int j = i + 1; j <= n - UNROLL; j += UNROLL) {
            for (long long int u = 0; u < UNROLL; ++u) {
                x[i] -= A[i][j + u] * x[j + u];
            }
        }
        for (long long int j = n - ((n - i - 1) % UNROLL); j < n; ++j) 
            x[i] -= A[i][j] * x[j];
        x[i] /= A[i][i];
    }
}

double P(double x, long long int N, double *alpha) {
    double Px = alpha[0];
    double potX = x;
    for (long long int i = 1; i <= N; ++i) {
        Px += alpha[i]*potX;
        potX *= x;
    }
    return Px;
}

int main() {

  long long int N, n;
  long long int K, p;

  scanf("%lld %lld", &N, &K);
  p = K;   // quantidade de pontos
  n = N+1; // tamanho do SL (grau N + 1)

  double *x = (double *) malloc(sizeof(double)*p);
  double *y = (double *) malloc(sizeof(double)*p);

  // ler numeros
  for (long long int i = 0; i < p; ++i)
    scanf("%lf %lf", x+i, y+i);

  double **A = (double **) malloc(sizeof(double *)*n);
  for (long long int i = 0; i < n; ++i)
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
  for (long long int i = 0; i < n; ++i)
    printf("%1.15e ", alpha[i]);
  puts("");

  // Imprime resíduos
  for (long long int i = 0; i < p; ++i)
    printf("%1.15e ", fabs(y[i] - P(x[i],N,alpha)) );
  puts("");

  // Imprime os tempos
  printf("%lld %1.10e %1.10e\n", K, tSL, tEG);

  // Libera a memoria alocada
  for (long long int i = 0; i < n; ++i){
    free(A[i]);
  }
  free(A);
  free(b);
  free(alpha);
  free(x);
  free(y);

  return 0;
}
