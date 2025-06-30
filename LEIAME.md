# EP-03 — Ajuste de Curvas  
Thiago Zilio — GRR 20234265  

## 0) Ambiente de teste
- Máquina física: laboratório DINF: @h12  
- Processador: Intel Core i5-7500 (4 c/4 t, 3.4 GHz)  
- Topologia completa (sockets, caches, NUMA) em **topology.txt**  

## 1) Alterações implementadas (versão 2)
1. **Função `montaSL`**  
   - Substituiu chamadas repetidas a `pow()` por vetor pré-computado.  
   - Fundiu loops de `b` e `A`; aplicou *Unroll & Jam* (fator 2).
2. **Função `eliminacaoGauss`**  
   - *Unroll & Jam* no loop interno — melhor reuse de cache.
3. **Função `retrossub`**  
   - Mesmo unrolling (passo 2) para aproveitar ILP.
4. **Função `P`**  
   - Troca de `pow()` por variável acumulativa para cortar FLOPs.

## 2) Metodologia
- Graus testados: **N1 = 10** e **N2 = 1000**  
- Vetores de pontos: `BASE_N1` e `BASE_N2` conforme enunciado  
- Marker API separa regiões: **tSL** (montagem) e **tEG** (eliminação)  
- CSVs gerados (estão na pasta **resultados/**):  
  - `results_ajustePol_v1_sl.csv`  
  - `results_ajustePol_v2_sl.csv`  
  - `results_ajustePol_v1_eg.csv`  
  - `results_ajustePol_v2_eg.csv`  
- Gráficos `.png` estão na pasta **graficos/**

## 3) Resultados resumidos
### a) Tempo
- **tSL:** v2 até 100× mais rápida em cenários grandes.  
- **tEG:** diferença pequena; gargalo já era baixo.

### b) L3 miss ratio
- **tSL:** queda de ~50 % na v2.  
- **tEG:** valores próximos, mas v1 degrada no grau 10 com muitos pontos.

### c) Energia
- **tSL:** v1 cresce exponencialmente; v2 sobe bem menos.  
- **tEG:** consumo parecido, v2 ligeiramente mais estável.

### d) FLOPS
- **FLOPS_DP (tSL):** forte redução na v2 (menos operações).  
- **FLOPS_AVX_DP:** 0 em tSL; em tEG a v2 usa AVX um pouco melhor.

## 4) Como reproduzir
```bash
./run_benchmarks.sh        # compila e gera os CSVs
gnuplot plot_results.gp    # produz os gráficos
