#!/bin/bash

#automatizar testes

VERSIONS=(v1 v2)  # ./ajustePol_v1  ./ajustePol_v2
DEGREES=(10 1000)  # N1, N2

KBASE_N1=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000)
KBASE_N2=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000 1000000 10000000 100000000)

CORE=3       

make all

for versions in " "; do
    OUTPUT_TSL_FILE="results_${VERSIONS}_tsl.csv"
    OUTPUT_TEG_FILE="results_${VERSIONS}_teg.csv"

    # CSV
    echo >
    echo >

    # metricas
    metrics() {}

    for graus in " "; do
        if degree = 10
            points = KBASE_N1
        else 
            points = KBASE_N2
        fi
        for point in " "; do
            metrics
        done
    done
done
remover temps