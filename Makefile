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

# Lista de arquivos para distribuição.
# LEMBRE-SE DE ACRESCENTAR OS ARQUIVOS ADICIONAIS SOLICITADOS NO ENUNCIADO DO TRABALHO
DISTFILES = *.c *.h LEIAME* Makefile run_tests.sh *.gnu likwid-topology.txt *.csv
DISTDIR = tza23

.PHONY: all clean purge dist likwid

all: $(PROGS)

# Regras para programas sem LIKWID
ajustePol_v1: ajustePol_v1.c utils.c
	$(CC) -o $@ $(CFLAGS) $^ $(LFLAGS)

ajustePol_v2: ajustePol_v2.c utils.c
	$(CC) -o $@ $(CFLAGS) $^ $(LFLAGS)

gera_entrada: gera_entrada.c
	$(CC) gera_entrada.c -o gera_entrada

# Regra para compilar programas com suporte ao LIKWID
likwid: ajustePol_v1_likwid ajustePol_v2_likwid

ajustePol_v1_likwid: ajustePol_v1.c utils.c
	$(CC) -o ajustePol_v1 $(CFLAGS) $(LIKWID_INC) $^ $(LFLAGS) $(LIKWID_LIB)

ajustePol_v2_likwid: ajustePol_v2.c utils.c
	$(CC) -o ajustePol_v2 $(CFLAGS) $(LIKWID_INC) $^ $(LFLAGS) $(LIKWID_LIB)

clean:
	@echo "Limpando sujeira ..."
	@rm -f *~ *.bak *.o 

purge:  clean
	@echo "Limpando tudo ..."
	@rm -f $(PROGS) *.o a.out $(DISTDIR) $(DISTDIR).tar

dist: purge
	@echo "Gerando arquivo de distribuição ($(DISTDIR).tar) ..."
	@mkdir -p $(DISTDIR)/graficos
	@cp -r graficos/* $(DISTDIR)/graficos
	@cp $(DISTFILES) $(DISTDIR)
	@tar -chvf $(DISTDIR).tar $(addprefix ./$(DISTDIR)/, $(DISTFILES))
	@rm -f $(DISTDIR)
