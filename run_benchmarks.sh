#!/bin/bash

# script de automatizacao de testes utilizado na maquina dinf
CORE=3
DEGREES=(10 1000)

VERSIONS=("ajustePol_v1" "ajustePol_v2") 

BASE_N1=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000 1000000 10000000 100000000)
BASE_N2=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000)

echo "gerando executaveis"
make likwid
make gera_entrada


for PROGRAM in "${VERSIONS[@]}"; do
    OUTPUT_SL_FILE="results_${PROGRAM}_sl.csv"
    OUTPUT_EG_FILE="results_${PROGRAM}_eg.csv"

    # CSV headers
    echo 'DEGREE,POINTS,TSL,L3MISSRATIO,ENERGY,FLOPS_DP,FLOPS_AVX_DP' > "$OUTPUT_SL_FILE"
    echo 'DEGREE,POINTS,TEG,L3MISSRATIO,ENERGY,FLOPS_DP,FLOPS_AVX_DP' > "$OUTPUT_EG_FILE"

    metrics() {
        local degree=$1
        local points=$2
        local OUT_L3='temp_l3.out'
        local OUT_ENERGY='temp_energy.out'
        local OUT_FLOPS='temp_flops.out'

        echo 'starting next program in queue...'
        ./gera_entrada "$points" "$degree" | likwid-perfctr -C $CORE -g FLOPS_DP -m ./"$PROGRAM" > "$OUT_FLOPS"
        local dp_sl=$(grep 'DP' "$OUT_FLOPS" | awk '{print $5}' | sed -n '2p')
        local dp_eg=$(grep 'DP' "$OUT_FLOPS" | awk '{print $5}' | sed -n '5p')
        local avx_dp_sl=$(grep 'DP' "$OUT_FLOPS" | awk '{print $6}' | sed -n '3p')
        local avx_dp_eg=$(grep 'DP' "$OUT_FLOPS" | awk '{print $6}' | sed -n '6p')

        ./gera_entrada "$points" "$degree" | likwid-perfctr -C $CORE -g L3CACHE -m ./"$PROGRAM" > "$OUT_L3"
        local l3_miss_ratio_sl=$(grep 'L3 miss ratio' "$OUT_L3" | awk '{print $6}' | sed -n '1p')
        local l3_miss_ratio_eg=$(grep 'L3 miss ratio' "$OUT_L3" | awk '{print $6}' | sed -n '2p')

        ./gera_entrada "$points" "$degree" | likwid-perfctr -C $CORE -g ENERGY -m ./"$PROGRAM" > "$OUT_ENERGY"
        local energy_sl=$(grep 'Energy' "$OUT_ENERGY" | sed -n '1p' | awk '{print $5}')
        local energy_eg=$(grep 'Energy' "$OUT_ENERGY" | sed -n '5p' | awk '{print $5}')

        local time_sl time_eg
        read -r _ time_sl time_eg <<< "$(grep "^$points" "$OUT_L3")"

        echo "${degree},${points},${time_sl},${l3_miss_ratio_sl},${energy_sl},${dp_sl},${avx_dp_sl}" >> "$OUTPUT_SL_FILE"
        echo "${degree},${points},${time_eg},${l3_miss_ratio_eg},${energy_eg},${dp_eg},${avx_dp_eg}" >> "$OUTPUT_EG_FILE"
    }

    # main loop
    for DEGREE in "${DEGREES[@]}"; do
        if [ "$DEGREE" -eq 10 ]; then
            POINTS_LIST=("${POINTS_N1[@]}")
        else
            POINTS_LIST=("${POINTS_N2[@]}")
        fi
        for POINTS in "${POINTS_LIST[@]}"; do
            metrics "$DEGREE" "$POINTS"
        done
    done
done
rm -f temp_*.out
