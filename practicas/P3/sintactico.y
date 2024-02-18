%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

void yyerror( const char * msg );

#define YYERROR_VERBOSE
%}

%error-verbose

%start programa
%token MAIN
%token LOCAL
%token TIPO
%token PYC
%token CIN COUT
%token CADENA
%token RETURN
%token IF ELSE
%token DO UNTIL
%token WHILE
%token SHIFT
%token CONSTANTS
%token INIBLOQUE FINBLOQUE
%token LCOR RCOR
%token COMA
%token ASIGN
%token LPAR RPAR
%token OPDOLLAR
%token ID

/* Operador Ternario (Asociatividad por la Derecha) */
%right OPMASMAS OPAT

/* Operador Lógico OR (Asociatividad por la Izquierda) */
%left OPOR

/* Operador Lógico AND (Asociatividad por la Izquierda) */
%left OPAND

/* Operadores de Igualdad (Asociatividad por la Izquierda) */
%left OPEQN

/* Operadores de Comparación (Asociatividad por la Izquierda) */
%left OPCOMP

/* Operadores Binarios para Listas (Asociatividad por la Izquierda) */
%left OPPORPOR OPBORRLIST

/* Operadores Aditivos (Asociatividad por la Izquierda) */
%left OPSUMRES

/* Operadores Multiplicativos (Asociatividad por la Izquierda) */
%left OPMULDIV

/* Operadores Unarios (OPINTHASH mayor preferencia que OPNOT */
%precedence OPINTHASH OPNOT
%%

programa : MAIN bloque ;

bloque : INIBLOQUE declaracion_variables_locales declaracion_subprogramas sentencias FINBLOQUE ;

declaracion_variables_locales : LOCAL INIBLOQUE variables_locales FINBLOQUE
                              | %empty ;

variables_locales : variables_locales cuerpo_variables_locales
                  | cuerpo_variables_locales ;

cuerpo_variables_locales : TIPO lista_variables PYC
                         | error ;

lista_variables : lista_variables COMA ID 
                | ID ;

declaracion_subprogramas : declaracion_subprogramas declaracion_subprog
                         | %empty ;

declaracion_subprog : cabecera_subprog bloque ;

cabecera_subprog : TIPO ID LPAR cabecera_argumentos RPAR ;

cabecera_argumentos : parametros
                    | %empty
                    | error ;

parametros : parametros COMA parametro
           | parametro ;

parametro : TIPO ID ;

sentencias : sentencias sentencia
           | %empty ;

sentencia : bloque
          | expresion PYC
          | sentencia_asignacion PYC
          | sentencia_lista PYC
          | sentencia_if
          | sentencia_while
          | sentencia_entrada PYC
          | sentencia_salida PYC
          | sentencia_do_until PYC
          | sentencia_return PYC;

sentencia_asignacion : ID ASIGN expresion ;

sentencia_if : IF LPAR expresion RPAR sentencia sentencia_else ;

sentencia_else : ELSE sentencia
               | %empty ;
             
sentencia_while : WHILE LPAR expresion RPAR sentencia ;

sentencia_entrada : CIN lista_variables ;

sentencia_salida : COUT lista_expresiones_cadenas ;

lista_expresiones_cadenas : lista_expresiones_cadenas COMA expresion_cadena
                          | expresion_cadena ;

expresion_cadena : expresion
                 | CADENA ;

sentencia_return : RETURN expresion ;
        
sentencia_lista : expresion SHIFT
                | OPDOLLAR expresion ;

sentencia_do_until : DO sentencia UNTIL LPAR expresion RPAR ;

expresion : LPAR expresion RPAR
          | OPSUMRES expresion %prec OPNOT
          | OPNOT expresion
          | OPINTHASH expresion
          | expresion OPAND expresion
          | expresion OPOR expresion
          | expresion OPEQN expresion
          | expresion OPCOMP expresion
          | expresion OPSUMRES expresion
          | expresion OPMULDIV expresion
          | expresion OPPORPOR expresion
          | expresion OPAT expresion
          | expresion OPBORRLIST expresion
          | expresion OPMASMAS expresion OPAT expresion
          | ID
          | constante
          | llamada_funcion
          | error ;

llamada_funcion : ID LPAR argumentos RPAR ;

argumentos : lista_expresiones
           | %empty ;
           
lista_expresiones : lista_expresiones COMA expresion
                  | expresion ;
                  
constante : CONSTANTS
          | lista ;

lista : LCOR lista_expresiones RCOR
      | LCOR RCOR ;

%%

#include "lex.yy.c"

void yyerror(const char *msg){
  fprintf(stderr, "[Linea %d]: %s\n", yylineno, msg);
}

int main(){
  yyparse();

  return(0);
}
