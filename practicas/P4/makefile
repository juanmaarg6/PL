# Makefile para la práctica 4

.SUFFIXES:

# Compilación

lexico: lexico.l
	flex -l lexico.l

semantico: semantico.y lexico
	bison -d -v -o y.tab.c semantico.y

comp: y.tab.c
	gcc -o analizador_semantico y.tab.c

clean: 
	rm -f analizador_semantico y.tab.c lex.yy.c y.output y.tab.h

todo:
	make --no-print-directory clean
	make --no-print-directory semantico
	make --no-print-directory comp
	
# Ejecución

test_correcto_programa_1: todo
	./analizador_semantico < ../pruebas/programa_correcto_1.txt

test_correcto_guion: todo
	./analizador_semantico < ../pruebas/programa_correcto_guion.txt
	
test_errores_profe_guion_P3: todo
	./analizador_semantico < ../pruebas/programa_errores_profe_guion_P3.txt
	
test_errores_profe_guion_P4: todo
	./analizador_semantico < ../pruebas/programa_errores_profe_guion_P4.txt
