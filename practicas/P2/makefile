# Makefile para la práctica 2

# Compilación

lexico: lexico.l
	flex -l lexico.l

comp: lex.yy.c
	gcc -o analizador_lexico lex.yy.c

clean: 
	rm -f analizador_lexico lex.yy.c

todo:
	make --no-print-directory clean
	make --no-print-directory lexico
	make --no-print-directory comp
	
# Ejecución

test_correcto: todo
	./analizador_lexico < ../pruebas/programa_correcto.prog
