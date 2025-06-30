# PROGRAMA
PROGS = ajustePol_v1 ajustePol_v2 gera_entrada

# PATH LIKWID
LIKWID_HOME = /home/soft/likwid

# LIKWID
LIKWID_INC = -I${LIKWID_HOME}/include -DLIKWID_PERFMON
LIKWID_LIB = -L${LIKWID_HOME}/lib -llikwid

# Compilador
CC     = gcc
CFLAGS = -O3 -mavx -march=native -Wall -Wextra
LFLAGS = -lm

# Arquivos para distribuição (somente na raiz)
DISTFILES = *.c *.h LEIAME* Makefile run_benchmarks.sh topology.txt
DISTDIR   = tza23

.PHONY: all clean purge dist likwid

all: $(PROGS)

# --------- Compilação sem LIKWID ----------
ajustePol_v1: ajustePol_v1.c utils.c
	$(CC) -o $@ $(CFLAGS) $^ $(LFLAGS)

ajustePol_v2: ajustePol_v2.c utils.c
	$(CC) -o $@ $(CFLAGS) $^ $(LFLAGS)

gera_entrada: gera_entrada.c
	$(CC) $^ -o $@

# --------- Compilação com LIKWID ----------
likwid: ajustePol_v1_likwid ajustePol_v2_likwid

ajustePol_v1_likwid: ajustePol_v1.c utils.c
	$(CC) -o ajustePol_v1 $(CFLAGS) $(LIKWID_INC) $^ $(LFLAGS) $(LIKWID_LIB)

ajustePol_v2_likwid: ajustePol_v2.c utils.c
	$(CC) -o ajustePol_v2 $(CFLAGS) $(LIKWID_INC) $^ $(LFLAGS) $(LIKWID_LIB)

# --------- Limpeza ----------
clean:
	@echo "Limpando sujeira ..."
	@rm -f *~ *.bak *.o

purge: clean
	@echo "Limpando tudo ..."
	@rm -f $(PROGS) a.out $(DISTDIR).tgz
	@rm -rf $(DISTDIR)

# --------- Distribuição ----------
dist: purge
	@echo "Gerando arquivo de distribuição ($(DISTDIR).tgz) ..."
	@mkdir -p $(DISTDIR)/graficos
	@mkdir -p $(DISTDIR)/resultados
	@cp -r graficos/*   $(DISTDIR)/graficos
	@cp -r resultados/* $(DISTDIR)/resultados
	@cp $(DISTFILES)    $(DISTDIR)
	@tar -czf $(DISTDIR).tgz $(DISTDIR)
	@rm -rf $(DISTDIR)
