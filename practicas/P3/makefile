# Makefile para la práctica 3

.SUFFIXES:

# Compilación

lexico: lexico.l
	flex -l lexico.l

sintactico: sintactico.y lexico
	#yacc -d -v -o y.tab.c sintactico.y
	bison -d -v -o y.tab.c sintactico.y

comp: y.tab.c
	gcc -o analizador_sintactico y.tab.c

clean: 
	rm -f analizador_sintactico y.tab.c lex.yy.c y.output y.tab.h

todo:
	make --no-print-directory clean
	make --no-print-directory sintactico
	make --no-print-directory comp
	
# Ejecución

test_correcto_programa_1: todo
	./analizador_sintactico < ../pruebas/programa_correcto_1.txt

test_correcto_guion_P3: todo
	./analizador_sintactico < ../pruebas/programa_correcto_guion_P3.txt
	
test_errores_guion_P3: todo
	./analizador_sintactico < ../pruebas/programa_errores_guion_P3.txt
	
test_errores_profe_guion_P3: todo
	./analizador_sintactico < ../pruebas/programa_errores_profe_guion_P3.txt
