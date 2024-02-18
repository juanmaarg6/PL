# Makefile para la práctica 5

.SUFFIXES:

# Compilación

lexico: lexico.l
	flex -l lexico.l

semantico: semantico.y lexico
	bison -d -v -o y.tab.c semantico.y

comp: y.tab.c
	gcc -o traductor y.tab.c

clean: 
	echo "" >  dec_fun.h
	rm -f traductor y.tab.c lex.yy.c y.output y.tab.h a.out prog.c programa_correcto_1 programa_correcto_guion programa_errores_profe_guion_P3 programa_errores_profe_guion_P4 programa_codigo_intermedio_1_P5 programa_codigo_intermedio_2_P5 programa_codigo_intermedio_anidamiento_P5 programa_codigo_intermedio_listas_P5

todo:
	make --no-print-directory clean
	make --no-print-directory semantico
	make --no-print-directory comp
	
# Ejecución

test_correcto_programa_1: todo
	./traductor < ../pruebas/programa_correcto_1.txt
	gcc prog.c -o programa_correcto_1
	./programa_correcto_1

test_correcto_guion: todo
	./traductor < ../pruebas/programa_correcto_guion.txt
	gcc prog.c -o programa_correcto_guion
	./programa_correcto_guion
	
test_errores_profe_guion_P3: todo
	./traductor < ../pruebas/programa_errores_profe_guion_P3.txt
	gcc prog.c -o programa_errores_profe_guion_P3
	./programa_errores_profe_guion_P3
	
test_errores_profe_guion_P4: todo
	./traductor < ../pruebas/programa_errores_profe_guion_P4.txt
	gcc prog.c -o programa_errores_profe_guion_P4
	./programa_errores_profe_guion_P4
	
test_codigo_intermedio_1_P5: todo
	./traductor < ../pruebas/programa_codigo_intermedio_1_P5.txt
	gcc prog.c -o programa_codigo_intermedio_1_P5
	./programa_codigo_intermedio_1_P5

test_codigo_intermedio_2_P5: todo
	./traductor < ../pruebas/programa_codigo_intermedio_2_P5.txt
	gcc prog.c -o programa_codigo_intermedio_2_P5
	./programa_codigo_intermedio_2_P5
	
test_codigo_intermedio_anidamiento_P5: todo
	./traductor < ../pruebas/programa_codigo_intermedio_anidamiento_P5.txt
	gcc prog.c -o programa_codigo_intermedio_anidamiento_P5
	./programa_codigo_intermedio_anidamiento_P5

test_codigo_intermedio_listas_P5: todo
	./traductor < ../pruebas/programa_codigo_intermedio_listas_P5.txt
	gcc prog.c -o programa_codigo_intermedio_listas_P5
	./programa_codigo_intermedio_listas_P5
