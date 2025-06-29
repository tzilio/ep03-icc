#!/bin/bash

# script de automatizacao de testes utilizado na maquina dinf
CPU=3
GRAUS=(10 1000)

PROGRAMAS=("ajustePol_v1" "ajustePol_v2") 

N1=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000 1000000 10000000 100000000)
N2=(64 128 200 256 512 600 800 1024 2000 3000 4096 6000 7000 10000 50000 100000)
make all

# iterando pelos programas (v1 e v2)
for PROGRAMA in "${PROGRAMAS[@]}"; do
    OUTPUT_TSL_FILE="results_${PROGRAMA}_tsl.csv"
    OUTPUT_TEG_FILE="results_${PROGRAMA}_teg.csv"

    # setando o csv dos resultados
    echo "GRAU,PONTOS,timeSL,L3MISSRATIO,ENERGY,FLOPS_DP,FLOPS_AVX_DP" > "$OUTPUT_TSL_FILE"
    echo "GRAU,PONTOS,timeEG,L3MISSRATIO,ENERGY,FLOPS_DP,FLOPS_AVX_DP" > "$OUTPUT_TEG_FILE"

    # funcao que executa os comandos e da grep no que precisa
    calcula(){
        local grau=$1
        local pontos=$2
        local SAIL3="temp_l3.out"
        local SAIENERGY="temp_energy.out"
        local SAIFLOPS="temp_flops.out"

        # gera a entrada com a metrica requisitada, da grep e coloca num arquivo .out
        echo "comecando a gerar proximo programa da fila..."
        ./gera_entrada "$pontos" "$grau" | likwid-perfctr -C $CPU -g FLOPS_DP -m ./"$PROGRAMA" > "$SAIFLOPS"
        local dp_tsl=$(cat "$SAIFLOPS" | grep "DP" | awk '{print $5}' | sed -n '2p')
        local dp_teg=$(cat "$SAIFLOPS" | grep "DP" | awk '{print $5}' | sed -n '5p')
        local AVX_dp_tsl=$(cat "$SAIFLOPS" | grep "DP" | awk '{print $6}' | sed -n '3p')
        local AVX_dp_teg=$(cat "$SAIFLOPS" | grep "DP" | awk '{print $6}' | sed -n '6p')
        ./gera_entrada "$pontos" "$grau" | likwid-perfctr -C $CPU -g L3CACHE -m ./"$PROGRAMA" > "$SAIL3"
        local l3_miss_ratio_tsl=$(grep "L3 miss ratio" "$SAIL3" | awk '{print $6}' | sed -n '1p')
        local l3_miss_ratio_teg=$(grep "L3 miss ratio" "$SAIL3" | awk '{print $6}' | sed -n '2p')
        ./gera_entrada "$pontos" "$grau" | likwid-perfctr -C $CPU -g ENERGY -m ./"$PROGRAMA" > "$SAIENERGY"
        local energy_tsl=$(grep "Energy" "$SAIENERGY" | sed -n '1p' | awk '{print $5}')
        local energy_teg=$(grep "Energy" "$SAIENERGY" | sed -n '5p' | awk '{print $5}')

        local tsl teg
        read -r _ tsl teg <<< $(grep "^$pontos" "$SAIL3")
        echo "$grau,$pontos,$tsl,$l3_miss_ratio_tsl,$energy_tsl,$dp_tsl,$AVX_dp_tsl" >> "$OUTPUT_TSL_FILE"
        echo "$grau,$pontos,$teg,$l3_miss_ratio_teg,$energy_teg,$dp_teg,$AVX_dp_teg" >> "$OUTPUT_TEG_FILE"
    } 
    # "main" do script
    for GRAU in "${GRAUS[@]}"; do
        if [ "$GRAU" -eq 10 ]; then
            PONTOS=("${N1[@]}")
        else
            PONTOS=("${N2[@]}")
        fi
        for PONTO in "${PONTOS[@]}"; do
            calcula "$GRAU" "$PONTO"
        done
    done
done
rm -f temp_*.out