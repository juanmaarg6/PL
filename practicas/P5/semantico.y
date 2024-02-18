%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


#define YYERROR_VERBOSE

FILE* yyout;

#define min(a, b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a < _b ? _a : _b; })
#define max(a, b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a > _b ? _a : _b; })

void yyerror( const char * msg );

#define MAX_TAM_TS 500

extern int yylineno;

char msgError[512];

// Esto elimina un Warning, no debería cambiar nada más.
int yylex();

/************************/
/* ESTRUCTURA DE LA TS */
/***********************/

// Para bucles if
typedef struct {
  char* etiquetaEntrada;
  char* etiquetaSalida;
  char* etiquetaElse;
} DescriptorDeInstrControl;

// Tipo de entrada
typedef enum {
  marca,
  funcion,
  variable,
  parametroFormal,
  descriptor
} TipoEntrada;

// Si TipoEntrada es función, variable, o parametro-formal; indica el tipo de dato
// No se usa en otro caso
typedef enum {
  entero,
  real,
  booleano,
  caracter,
  cadena, // Dato reservado a cadenas, no se puede declarar
  listaEntero,
  listaReal,
  listaBooleano,
  listaCaracter,
  error // Si da un error con expresiones
} TipoDato;

typedef struct {
  TipoEntrada tipoEntrada;    		// Tipo de entrada
  char* nombre;               		// Nombre del identificador (no se usa con marca)
  TipoDato tipoDato;          		// Tipo de dato
  int parametros;             		// Nº de parámetros formales (solo se usa con función)
  DescriptorDeInstrControl* descriptor; // Descriptor de control (bucles/if - intermedio)
} EntradaTS;

// Tabla de Símbolos
EntradaTS ts[MAX_TAM_TS];

// Última entrada de la TS usada.
long int tope = -1;

// Tipo auxiliar para declaración de variables
TipoDato tipoTmp;

// Si entramos en un bloque de un subprograma
// Si es 0 es un bloque de un subprograma; en caso contrario no
int subProg = 0;

// Variables usadas para pasar argumentos a una función
#define MAX_ARGS 50
TipoDato argumentos_tipo_datos[MAX_ARGS];
int n_argumentos = 0;

typedef struct {
  int atributo;
  char* lexema;
  TipoDato dtipo;
} Atributos;

char* tipoAString(TipoDato tipo_dato) {
  switch (tipo_dato) {
    case real:
      return "float";
    case entero:
      return "int";
    case booleano:
      return "bool";
    case caracter:
      return "char";
    case listaReal:
      return "list_of float";
    case listaEntero:
      return "list_of int";
    case listaCaracter:
      return "list_of char";
    case listaBooleano:
      return "list_of bool";
    case error:
      return "error";
    default:
      fprintf(stderr, "Error en tipoAString(), no se conoce el tipo dato\n");
      exit(EXIT_FAILURE);
  }
}

TipoDato tipoLista(TipoDato tipo_dato) {
  switch (tipo_dato) {
    case listaEntero:
      return entero;
    case listaCaracter:
      return caracter;
    case listaBooleano:
      return booleano;
    case listaReal:
      return real;
    case error:
      return error;
    default:
      fprintf(stderr, "Error en tipoLista(), tipo no es tipo de dato lista.\n");
      exit(EXIT_FAILURE);
  }
}

TipoDato aTipoLista(TipoDato td) {
  switch (td) {
    case entero:
      return listaEntero;
    case real:
      return listaReal;
    case caracter:
      return listaCaracter;
    case booleano:
      return listaBooleano;
    case error:
      return error;
    default:
      fprintf(stderr, "Error en atipoLista(), tipo no es un tipo elemental de dato.\n");
      exit(EXIT_FAILURE);
  }
}

TipoDato tipoOp(TipoDato td, char * op) {
  if ( !strcmp(op, "+") || !strcmp(op, "-") || !strcmp(op, "*") || !strcmp(op, "/") ||
       !strcmp(op, "**") || !strcmp(op, "--") || !strcmp(op, "%")
     )
     return td;

  if ( !strcmp(op, "!") || !strcmp(op, "&&") || !strcmp(op, "||") || !strcmp(op, ">") || 
       !strcmp(op, "<") || !strcmp(op, ">=") || !strcmp(op, "<=") || !strcmp(op, "!=") || !strcmp(op, "==")
     )
     return booleano;

  if ( !strcmp(op, "#") )
     return entero;

  if ( !strcmp(op, "?") || !strcmp(op, "@") )
     return tipoLista(td);
}

int esLista(TipoDato tipo_dato){
  return tipo_dato == listaEntero || tipo_dato == listaReal || tipo_dato == listaBooleano || tipo_dato == listaCaracter;
}

int esNumero(TipoDato tipo_dato){
  return tipo_dato == entero || tipo_dato == real;
}

void imprimir() {
  for (int i = 0; i <= tope; ++i) {
    printf("[%i]: ", i);
    switch(ts[i].tipoEntrada) {
      case variable:
        printf("Variable %s, tipo: %s\n", ts[i].nombre,
            tipoAString(ts[i].tipoDato));
        break;
      case funcion:
        printf("Funcion %s, tipo: %s, nº parametros: %i\n", ts[i].nombre,
            tipoAString(ts[i].tipoDato), ts[i].parametros);
        break;
      case marca:
        printf("Marca\n");
        break;
      case parametroFormal:
        printf("Parametro formal %s, tipo: %s\n", ts[i].nombre,
            tipoAString(ts[i].tipoDato));
        break;
      default:
        fprintf(stderr, "Error en imprimir(), no debería salir\n");
        exit(EXIT_FAILURE);
    }
  }
}

void idRepetida(char* id) {
  // Miramos si id estaba declarado después de la última marca
  int repetida = 0;
  for (int i = tope; !repetida && ts[i].tipoEntrada != marca; --i) {
    if (ts[i].tipoEntrada != parametroFormal && !strcmp(ts[i].nombre, id)) {
      sprintf(msgError, "ERROR SEMÁNTICO: identificador %s ya declarado\n", id);
      yyerror(msgError);
      repetida = 1;
    }
  }
}

void insertarEntrada(TipoEntrada te, char* nombre, TipoDato tipo_dato, int nParam, DescriptorDeInstrControl* descp) {
  // Hacemos la entrada
  EntradaTS entrada = {
    te,
    strdup(nombre),
    tipo_dato,
    nParam,
    descp
  };

  // Si la tabla está llena da error
  if (tope + 1 >= MAX_TAM_TS) {
    sprintf(msgError, "ERROR SINTÁCTICO: La tabla de símbolos está llena\n");
    yyerror(msgError);
  }
  // Aumentamos el tope
  ++tope;
  // Añadimos la nueva entrada
  ts[tope] = entrada;
}

// Busca una entrada en la TS con el id especificado en el ámbito del programa
// actual. Si no lo encuentra, devuelve -1. No gestiona errores!
int buscarEntrada(char* id) {
  int i = tope;
  while(i >= 0 && (ts[i].tipoEntrada == parametroFormal || strcmp(id, ts[i].nombre)))
    --i;

  if (i < 0) {
    sprintf(msgError, "ERROR SEMÁNTICO: identificador %s no declarado\n", id);
    yyerror(msgError);
  }
  return i;
}

/****************/
/* FUNCIONES TS */
/****************/

void insertarMarca() {
  // Metemos la marca
  insertarEntrada(marca, "", -1, -1, NULL);
  // Si es subprograma añadimos las variables al bloque
  if (subProg) {
    for (int i = tope - 1; ts[i].tipoEntrada != funcion; --i) {
      insertarEntrada(variable, ts[i].nombre, ts[i].tipoDato, -1, NULL);
    }
    subProg = 0;
  }
}

void vaciarEntradas() {
  // Hasta la última marca borramos todo
  while (ts[tope].tipoEntrada != marca)
    --tope;
  // Elimina la última marca
  --tope;
}

void insertarVariable(char* id) {
  // Comprobamos que no esté repetida la id
  idRepetida(id);
  insertarEntrada(variable, id, tipoTmp, -1, NULL);
}

void insertarFuncion(TipoDato tipoDato, char* id) {
  // Comprobamos que el id no esté usado ya
  idRepetida(id);
  insertarEntrada(funcion, id, tipoDato, 0, NULL);
}

void insertarDescriptor(char* etqEntrada, char* etqSalida, char* etqElse) {
  DescriptorDeInstrControl* descp = (DescriptorDeInstrControl*) malloc(sizeof(DescriptorDeInstrControl));
  descp->etiquetaEntrada = strdup(etqEntrada);
  descp->etiquetaSalida = strdup(etqSalida);
  descp->etiquetaElse = strdup(etqElse);
  insertarEntrada(descriptor, "", -1, -1, descp);
}

void insertarParametro(TipoDato tipoDato, char* id) {
  // Comprobamos que no haya parámetros con nombres repetidos
  // Además guardamos el índice de la función
  int i;
  int parametroRepetido = 0;
  for (i = tope; !parametroRepetido && ts[i].tipoEntrada != funcion; --i) {
    if (!strcmp(ts[i].nombre, id)) {
      sprintf(msgError, "ERROR SEMÁNTICO: identificador del parámetro %s ya declarado\n", id);
      yyerror(msgError);
      parametroRepetido = 1;
    }
  }
  // Añadimos la entrada
  insertarEntrada(parametroFormal, id, tipoDato, -1, NULL);
  // Actualizamos el nº de parámetros de la función
  ++ts[i].parametros;
}

TipoDato buscarID(char* id) {
  int i = buscarEntrada(id);

  if (i < 0)
    return error;
  return ts[i].tipoDato;
}

void comprobarAsignacion(char* id, TipoDato td) {
  int i = buscarEntrada(id);
  if (i >= 0) {
    if (ts[i].tipoEntrada != variable) {
      sprintf(msgError, "ERROR SEMÁNTICO: se intenta asignar a %s, y no es una variable\n", id);
      yyerror(msgError);
    } else {
      if (td != error && td != ts[i].tipoDato) {
        sprintf(msgError, "ERROR SEMÁNTICO: asignación incorrecta, %s es tipo %s y se obtuvo %s\n",
            id, tipoAString(ts[i].tipoDato), tipoAString(td));
        yyerror(msgError);
      }
    }
  }
}

void expresionBooleana(TipoDato td) {
  if (td != error && td != booleano) {
    sprintf(msgError, "ERROR SEMÁNTICO: condición no es de tipo booleano, se tiene tipo %s",
        tipoAString(td));
    yyerror(msgError);
  }
}

void sentenciaLista(TipoDato td, char* sentencia) {
  if (td != error && !esLista(td)) {
    sprintf(msgError, "ERROR SEMÁNTICO: sentencia %s no aplicable al tipo %s\n",
        sentencia, tipoAString(td));
    yyerror(msgError);
  }
}

TipoDato mismoTipoLista(TipoDato t1, TipoDato t2) {

  if (t1 == error || t2 == error)
    return error;

  if (t1 != t2) {
    sprintf(msgError, "ERROR SEMÁNTICO: lista con dos tipos distintos %s y %s\n",
        tipoAString(t1), tipoAString(t2));
    yyerror(msgError);
    return error;
  }
  return t1;
}

TipoDato sumRes(int atr, TipoDato td) {
  if (td == error)
    return error;

  char* operador = atr ? "-" : "+";
  if (!esNumero(td)) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador %s no aplicable al tipo %s\n",
        operador, tipoAString(td));
    yyerror(msgError);
    return error;
  }
  return td;
}

TipoDato not(TipoDato td) {
  if (td == error)
    return error;
  if (td != booleano) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador ! no aplicable al tipo %s\n",
        tipoAString(td));
    yyerror(msgError);
    return error;
  }
  return booleano;
}

TipoDato intHash(int atr, TipoDato td) {
  if (td == error)
    return error;

  char* operador = atr ? "#" : "?";
  if (!esLista(td)) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador %s no aplicable al tipo %s\n",
        operador, tipoAString(td));
    yyerror(msgError);
    return error;
  }

  if (atr)
    return tipoLista(td);
  else
    return entero;
}

TipoDato at(TipoDato td1, TipoDato td2) {
  if (td1 == error || td2 == error)
    return error;

  if (!esLista(td1) || td2 != entero) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador @ no aplicable a los tipos %s, %s\n",
        tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }

  return tipoLista(td1);
}

TipoDato and(TipoDato td1, TipoDato td2) {
  if (td1 == error || td2 == error)
    return error;

  if (td1 != booleano || td2 != booleano) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador && no aplicable a los tipos %s, %s\n",
        tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }

  return booleano;
}

TipoDato or(TipoDato td1, TipoDato td2) {
  if (td1 == error || td2 == error)
    return error;

  if (td1 != booleano || td2 != booleano) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador || no aplicable a los tipos %s, %s\n",
        tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }

  return booleano;
}

TipoDato eqn(TipoDato td1, int atr, TipoDato td2) {
  if (td1 == error || td2 == error)
    return error;

  char* operador = atr ? "!=" : "==";
  if (td1 != td2) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador %s no aplicable a los tipos %s, %s\n",
        operador, tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }

  return booleano;
}

// Comprueba el tipo de la operación binaria realizada. En caso de error, lo
// gestiona. En caso contrario, devuelve el tipo tras la operación binaria.
// IMPORTANTE: Se asume que op1 esta asociado al valor 1 del atributo (atr)
// mientras que op2 está asociado al valor 0.
// IMPORTANE: Se asume que el op1 es simétrico y que el op2 no es simétrico y
// unicamente funciona de la forma "T op2 T" o bien "list_of T op2 T".
TipoDato op2Binario(TipoDato td1, int atr, TipoDato td2, char* op1, char* op2) {
  if (td1 == error || td2 == error)
    return error;

  char* operador = atr ? op1 : op2;
  int l1 = esLista(td1);
  int l2 = esLista(td2);
  TipoDato tipo1 = l1 ? tipoLista(td1) : td1;
  TipoDato tipo2 = l2 ? tipoLista(td2) : td2;

  int op_error = (l1 && l2) ||
              (tipo1 != tipo2) ||
              !esNumero(tipo1);

  TipoDato resultado = td1;

  if (!op_error && (l1 || l2) ) {
    // Llegado a este punto hay exactamente una lista. Vemos si el tipo de
    // la lista encaja con el tipo del otro atributo:
    if ( (operador == op2) || l1 ) {
      resultado = l1 ? td1 : td2;
    } else {
      op_error = 1;
    }
  }

  if (op_error) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador %s no aplicable a los tipos %s, %s\n",
        operador, tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }
  return resultado;
}

TipoDato sumRes2(TipoDato td1, int atr, TipoDato td2) {
  return op2Binario(td1, atr, td2, "-", "+");
}

TipoDato mulDiv(TipoDato td1, int atr, TipoDato td2) {
  return op2Binario(td1, atr, td2, "/", "*");
}

TipoDato porPor(TipoDato td1, TipoDato td2) {
  if (td1 == error || td2 == error)
    return error;

  if (td1 != td2 || !esLista(td1) || !esLista(td2)) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador ** no aplicable a los tipos %s, %s\n",
        tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }

  return td1;
}

TipoDato borrList(TipoDato td1, int atr, TipoDato td2) {
  if (td1 == error || td2 == error)
    return error;

  char* operador = atr ? "%" : "--";
  if (!esLista(td1) || td2 != entero) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador %s no aplicable a los tipos %s, %s\n",
        operador, tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }

  return td1;
}

TipoDato comp(TipoDato td1, int atr, TipoDato td2) {
  if (td1 == error || td2 == error)
    return error;

  char* operador;
  switch (atr) {
    case 0:
      operador = "<";
      break;
    case 1:
      operador = ">";
      break;
    case 2:
      operador = "<=";
      break;
    case 3:
      operador = ">=";
      break;
  }

  if (td1 != td2 || !esNumero(td1) || !esNumero(td2)) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador %s no aplicable a los tipos %s, %s\n",
        operador, tipoAString(td1), tipoAString(td2));
    yyerror(msgError);
    return error;
  }

  return booleano;
}

TipoDato ternario(TipoDato td1, TipoDato td2, TipoDato td3) {
  if (td1 == error || td2 == error || td3 == error)
    return error;

  if (!esLista(td1) || tipoLista(td1) != td2 || td3 != entero) {
    sprintf(msgError, "ERROR SEMÁNTICO: operador ++ @ no aplicable a los tipos %s, %s, %s\n",
            tipoAString(td1), tipoAString(td2), tipoAString(td3));
    yyerror(msgError);
    return error;
  }
  return td1;
}

void comprobarReturn(TipoDato td) {
  int i = tope;
  int marcaEncontrada = 0;
  int funcionEncontrada = 0;

  while (i >= 1 && !funcionEncontrada) {
    funcionEncontrada = marcaEncontrada && ts[i].tipoEntrada == funcion;
    marcaEncontrada = (!marcaEncontrada && ts[i].tipoEntrada == marca) ||
                      (marcaEncontrada && ts[i].tipoEntrada == parametroFormal);
    --i;
  }

  if (funcionEncontrada) ++i;

  if (i <= 0) {
    sprintf(msgError, "ERROR SEMÁNTICO: return no asignado a ninguna función\n");
    yyerror(msgError);
  } else if (td != error && td != ts[i].tipoDato) {
    sprintf(msgError, "ERROR SEMÁNTICO: return devuelve tipo %s, y función es de tipo %s\n",
        tipoAString(td), tipoAString(ts[i].tipoDato));
    yyerror(msgError);
  }
}

TipoDato comprobarFuncion(char* id) {
  int iFuncion = buscarEntrada(id);

  if (iFuncion < 0)
    return error;

  if (ts[iFuncion].tipoEntrada != funcion) {
    sprintf(msgError, "ERROR SEMÁNTICO: %s no es una función y no puede ser llamada\n", id);
    yyerror(msgError);
    return error;
  }

  int n_argumentos_esperados = ts[iFuncion].parametros;

  if ( n_argumentos != n_argumentos_esperados ) {
    sprintf(msgError, "ERROR SEMÁNTICO: número de argumentos errónea al llamar a la función %s. Esperados: %d, encontrados: %d\n",
        id, n_argumentos_esperados, n_argumentos);
    yyerror(msgError);
  }

  n_argumentos = min(n_argumentos, n_argumentos_esperados);

  for (int i = 0; i < n_argumentos; i++){
    TipoDato tipoEsperado = ts[iFuncion + i + 1].tipoDato;
    TipoDato tipoObtenido = argumentos_tipo_datos[i];
    if (tipoObtenido != error && tipoEsperado != tipoObtenido){
      sprintf(msgError, "ERROR SEMÁNTICO: argumento número %d de tipo erróneo al llamar a la función %s. Esperado: %s, encontrado: %s\n",
          i+1, id, tipoAString(tipoEsperado), tipoAString(tipoObtenido));
      yyerror(msgError);
    }
  }

  // De esta forma mostramos el máximo número de errores posibles.

  // Borramos los argumentos recibidos.
  n_argumentos = 0;

  // Devolvemos el tipo de la función.
  return ts[iFuncion].tipoDato;
}

/***********************************/
/* GENERACIÓN DE CÓDIGO INTERMEDIO */
/***********************************/

int hayError = 0;
int deep = 0;
FILE * fMain;
FILE * fFunc;

#define addTab() { for (int i = 0; i < deep - (yyout != fMain); ++i) fprintf(yyout, "\t"); }
#define gen(f_, ...) { if (!hayError) {addTab(); fprintf(yyout, f_, ##__VA_ARGS__); fflush(yyout);} }

char* temporal() {
  static int indice = 1;
  char* temp = malloc(sizeof(char) * 10);
  sprintf(temp, "temp%i", indice++);
  return temp;
}

char* etiqueta() {
  static int indice = 1;
  char* etiqueta = malloc(sizeof(char) * 14);
  sprintf(etiqueta, "etiqueta%i", indice++);
  return etiqueta;
}

char* tipoIntermedio(TipoDato td) {
  if (esLista(td))
    return "Lista";
  else if (td == booleano)
    return "int";
  else
    return tipoAString(td);
}

char* leerOp(TipoDato td1, char* exp1, char* op, char* exp2, TipoDato td2) {
  char* etiqueta = temporal();
  TipoDato tdPrimario = td1;
  char* expPrimaria = exp1;
  char* expSecundaria = exp2;
  if (esLista(td2) && (!strcmp("+", op) || !strcmp("*", op))) {
    tdPrimario = td2;
    expPrimaria = exp2;
    expSecundaria = exp1;
  }

  gen("%s %s;\n", tipoIntermedio(tipoOp(tdPrimario, op)), etiqueta);

  if (!strcmp("#", op)) {
    gen("%s = getTam(%s);\n", etiqueta, exp1);
  } else if (!strcmp("?", op)) {
    gen("%s = *(%s*)getActual(%s);\n", etiqueta, tipoIntermedio(tipoLista(td1)), exp1);
  } else if (!strcmp("@", op)) {
    gen("%s = *(%s*)get(%s, %s);\n", etiqueta, tipoIntermedio(tipoLista(td1)), exp1, exp2);
  } else if (!strcmp("--", op)) {
    gen("%s = borrarEn(%s, %s);\n", etiqueta, exp1, exp2);
  } else if (!strcmp("%", op)) {
    gen("%s = borrarAPartirDe(%s, %s);\n", etiqueta, exp1, exp2);
  } else if (!strcmp("**", op)) {
    gen("%s = concatenar(%s, %s);\n", etiqueta, exp1, exp2);
  } else if (esLista(tdPrimario)) {
    if (!strcmp("+", op)) {
      gen("%s = sumarLista(%s, %s);\n", etiqueta, expPrimaria, expSecundaria)
    } else if (!strcmp("-", op)) {
        gen("%s = restarLista(%s, %s);\n", etiqueta, expPrimaria, expSecundaria);
    } else if (!strcmp("*", op)) {
      gen("%s = multiplicarLista(%s, %s);\n", etiqueta, expPrimaria, expSecundaria);
    } else if (!strcmp("/", op)) {
      gen("%s = dividirLista(%s, %s);\n", etiqueta, expPrimaria, expSecundaria);
    }
  } else if (!strcmp("", exp2)) {
    gen("%s = %s %s;\n", etiqueta, op, exp1);
  } else {
    gen("%s = %s %s %s;\n", etiqueta, exp1, op, exp2);
  }
  return etiqueta;
}

char* leerCte(char* cte, TipoDato td) {
  if (td == booleano) {
    if (!strcmp("true", cte))
      return "1";
    else
      return "0";
  }
  return cte;
}

char* insertarDato(char* id, TipoDato td) {
  char* buffer = malloc(sizeof(char) * 100);
  switch (td) {
    case entero:
    case booleano:
      sprintf(buffer, "pInt(%s)", id);
      return buffer;
    case real:
      sprintf(buffer, "pFloat(%s)", id);
      return buffer;
    case caracter:
      sprintf(buffer, "pChar(%s)", id);
      return buffer;
    default:
      if (!hayError) {
        sprintf(msgError, "ERROR INTERMEDIO: tipo no básico en insertarDato().\n");
        yyerror(msgError);
        exit(EXIT_FAILURE);
      }
  }
}

char* tipoImprimir(TipoDato tipo) {
  if (tipo == entero)
    return "%d";
  else if (tipo == real)
    return "%f";
  else if (esLista(tipo) || tipo == booleano || tipo == cadena)
    return "%s";
  else if (tipo == caracter)
    return "%c";
  else {
    if (!hayError) {
      sprintf(msgError, "ERROR INTERMEDIO: tipoImprimir() tipo no válido.\n");
      yyerror(msgError);
      exit(EXIT_FAILURE);
    }
  }
}

char* inicializaTipoLista(TipoDato tipo) {
  if (tipo == entero)
    return "tInt";
  else if (tipo == real)
    return "tFloat";
  else if (tipo == caracter)
    return "tChar";
  else if (tipo == booleano)
    return "tBool";
  else {
    if (!hayError) {
      sprintf(msgError, "ERROR INTERMEDIO: tipo no válido en inicializaTipoLista().\n");
      yyerror(msgError);
      exit(EXIT_FAILURE);
    }
  }
}

#define YYSTYPE Atributos
%}

%define parse.error verbose

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

/* Operadores Unarios (OPINTHASH mayor preferencia que OPNOT) */
%precedence OPINTHASH OPNOT

%%

/************* PROGRAMA PRINCIPAL *****************/

programa : MAIN {
              gen("#include <stdlib.h>\n");
              gen("#include <stdio.h>\n");
              gen("#include \"dec_fun.h\"\n");
              gen("#include \"dec_dat.h\"\n\n");
            }
          bloque ;

/************* BLOQUE *****************/

bloque : INIBLOQUE { insertarMarca(); if (yyout != fMain || (yyout == fMain && deep > 0)) { gen("{\n"); ++deep; } }
            declaracion_variables_locales { if (deep == 0) yyout = fFunc; }
            declaracion_subprogramas { if (deep == 0) { yyout = fMain; gen("int main()\n{\n"); ++deep; } }
            sentencias
         FINBLOQUE { vaciarEntradas(); --deep; gen("}\n\n"); } ;

/************* VARIABLES LOCALES *****************/

declaracion_variables_locales : LOCAL INIBLOQUE variables_locales FINBLOQUE { gen("\n"); }
                              | LOCAL INIBLOQUE FINBLOQUE { gen("\n"); }
                              | %empty ;

variables_locales : variables_locales cuerpo_variables_locales
                  | cuerpo_variables_locales ;

cuerpo_variables_locales : TIPO { tipoTmp = $1.dtipo; } lista_variables PYC { gen("%s %s;\n", tipoIntermedio($1.dtipo), $3.lexema); }
                         | error ;


lista_variables : lista_variables COMA ID {
                     insertarVariable($3.lexema);
                     $$.lexema = malloc(sizeof(char) * (strlen($3.lexema) + strlen($1.lexema) + 3));
                     sprintf($$.lexema, "%s, %s", $3.lexema, $1.lexema);
                  }
                | ID { insertarVariable($1.lexema); $$.lexema = $1.lexema; } ;

/************* SUBPROGRAMAS (FUNCIONES) *****************/

declaracion_subprogramas : declaracion_subprogramas declaracion_subprog
                   	 | %empty ;

declaracion_subprog : cabecera_subprog { subProg = 1; } bloque ;

cabecera_subprog : TIPO ID { insertarFuncion($1.dtipo, $2.lexema); }
                   LPAR cabecera_argumentos RPAR { gen("%s %s(%s)\n", tipoIntermedio($1.dtipo), $2.lexema, $5.lexema); } ;

cabecera_argumentos : parametros { $$.lexema = $1.lexema; }
                    | %empty     { $$.lexema = ""; }
                    | error ;


parametros : parametros COMA parametro {
                $$.lexema = malloc(strlen($1.lexema) + strlen($3.lexema) + 3);
                sprintf($$.lexema, "%s, %s", $1.lexema, $3.lexema);
             }
           | parametro { $$.lexema = $1.lexema; } ;

parametro : TIPO ID {
               insertarParametro($1.dtipo, $2.lexema);
               $$.lexema = malloc(strlen($1.lexema) + strlen($2.lexema) + 2);
               sprintf($$.lexema, "%s %s", tipoIntermedio($1.dtipo), $2.lexema);
            } ;

/************* SENTENCIAS *****************/

sentencias : sentencias {gen("{\n"); ++deep; } sentencia { --deep; gen("}\n"); }
           | %empty ;

sentencia : bloque
          | expresion PYC { gen("%s;\n", $1.lexema); }
          | sentencia_asignacion PYC
          | sentencia_lista PYC
          | sentencia_if
          | sentencia_while
          | sentencia_entrada PYC
          | sentencia_salida PYC
          | sentencia_do_until PYC
          | sentencia_return PYC ;

/************* ASIGNACIÓN *****************/

sentencia_asignacion : ID ASIGN expresion {
                          comprobarAsignacion($1.lexema, $3.dtipo);
                          gen("%s = %s;\n", $1.lexema, $3.lexema);
                       } ;

/************* LISTAS *****************/

sentencia_lista : expresion SHIFT {
                     sentenciaLista($1.dtipo, $2.lexema);
                     if (!strcmp(">>", $2.lexema)) {
                        gen("avanza(%s);\n", $1.lexema);
                     } 
                     else {
                        gen("retrocede(%s);\n", $1.lexema);
                     }
                  }
                | OPDOLLAR expresion {
                     sentenciaLista($2.dtipo, $1.lexema);
                     gen("inicio(%s);\n", $2.lexema);
                  } ;

/************* CONDICIONAL IF-ELSE *****************/

sentencia_if : IF LPAR { insertarDescriptor("", etiqueta(), etiqueta()); }
               expresion {
                  expresionBooleana($4.dtipo);
                  gen("\n");
                  gen("if (!%s) goto %s;\n", $4.lexema, ts[tope].descriptor->etiquetaElse);
               }
               RPAR { gen("{\n"); ++deep; }
               sentencia {
                  { --deep; gen("}\n"); }
                  DescriptorDeInstrControl* ds = ts[tope].descriptor;
                  gen("goto %s;\n\n", ds->etiquetaSalida);
                  gen("%s:", ds->etiquetaElse);
               }
               bloque_else {
                  gen("\n");
                  gen("%s: {} \n", ts[tope].descriptor->etiquetaSalida);
                  --tope;
               } ;

bloque_else : ELSE { gen("\n"); gen("{\n"); ++deep; } sentencia { --deep; gen("}\n"); }
            | %empty { int aux = deep; deep = 0; gen(" {}\n"); deep = aux; } ;

/************* BUCLE WHILE *****************/
sentencia_while : WHILE LPAR {
                     insertarDescriptor(etiqueta(), etiqueta(), "");
                     gen("%s:\n", ts[tope].descriptor->etiquetaEntrada);
                     gen("{\n");
                     ++deep;
                     gen("{\n");
                     ++deep;
                  }
                  expresion {
                     expresionBooleana($4.dtipo);
                     gen("\n");
                     gen("if (!%s) goto %s;\n", $4.lexema, ts[tope].descriptor->etiquetaSalida);
                     --deep;
                     gen("}\n\n");
                  }
                  RPAR sentencia {
                     gen("goto %s;\n\n", ts[tope].descriptor->etiquetaEntrada);
                     --deep;
                     gen("}\n");
                     gen("%s: {}\n", ts[tope].descriptor->etiquetaSalida);
                     --tope;
                  } ;

/************* ENTRADA *****************/

sentencia_entrada : CIN lista_id ;

lista_id : lista_id COMA id_cin
         | id_cin ;

id_cin : ID {
            TipoDato td = buscarID($1.lexema);
            if (td == booleano) {
               gen("char aux[32];\n");
               gen("scanf(\"%s\", aux);\n", "%s");
               gen("%s = aInt(aux);\n", $1.lexema);
            } 
            else if (esLista(td)) {
               gen("%s = leerLista(%s);\n", $1.lexema, inicializaTipoLista(tipoLista(td)));
            } 
            else {
               gen("scanf(\"%s\", &%s);\n", tipoImprimir(td), $1.lexema);
            }
         } ;

/************* SALIDA *****************/

sentencia_salida : COUT lista_expresiones_cadenas { gen("printf(\"\\n\");\n"); } ;

lista_expresiones_cadenas : lista_expresiones_cadenas COMA expresion_cout
                          | expresion_cout ;

expresion_cout: expresion_cadena { gen("printf(\"%s\", %s);\n", tipoImprimir($1.dtipo), $1.lexema); gen("fflush(stdout);\n"); } ;

expresion_cadena : expresion {
                      if (esLista($1.dtipo)) {
                         $$.lexema = malloc(sizeof(char) * (15 + strlen($1.lexema)));
                         sprintf($$.lexema, "listaAString(%s)", $1.lexema);
                      } 
                      else if ($1.dtipo == booleano) {
                         $$.lexema = malloc(sizeof(char) * (8 + strlen($1.lexema)));
                         sprintf($$.lexema, "aBool(%s)", $1.lexema);
                      } 
                      else
                         $$.lexema = $1.lexema;
                      $$.dtipo = $1.dtipo;
                   }
                 | CADENA { $$.lexema = $1.lexema; $$.dtipo = $1.dtipo; } ;

/************* BUCLE DO-UNTIL *****************/

sentencia_do_until : DO {
                        insertarDescriptor(etiqueta(), "", "");
                        gen("%s:\n", ts[tope].descriptor->etiquetaEntrada);
                        gen("{\n");
                        ++deep;
                        gen("{\n");
                        ++deep;
                      }
                      sentencia { --deep; gen("}\n"); }
                      UNTIL LPAR expresion {
                         expresionBooleana($7.dtipo);
                         gen("\n");
                         gen("if (%s) goto %s;\n", $7.lexema, ts[tope].descriptor->etiquetaEntrada);
                         --deep;
                         gen("}\n");
                         --tope;
                      }
                      RPAR ;

/************* RETURN *****************/

sentencia_return : RETURN expresion { comprobarReturn($2.dtipo); gen("return %s;\n", $2.lexema); } ;

/************* EXPRESIÓN *****************/

expresion : LPAR expresion RPAR                  	{ $$.lexema = $2.lexema; $$.dtipo = $2.dtipo; }
          | OPSUMRES expresion %prec OPNOT              { $$.lexema = leerOp($2.dtipo, $2.lexema, $1.lexema, "", -1); $$.dtipo = sumRes($1.atributo, $2.dtipo); }
          | OPNOT expresion                             { $$.lexema = leerOp($2.dtipo, $2.lexema, $1.lexema, "", -1); $$.dtipo = not($2.dtipo); }
          | OPINTHASH expresion                         { $$.lexema = leerOp($2.dtipo, $2.lexema, $1.lexema, "", -1); $$.dtipo = intHash($1.atributo, $2.dtipo); }
          | expresion OPAT expresion                    { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = at($1.dtipo, $3.dtipo); }
          | expresion OPAND expresion                   { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = and($1.dtipo, $3.dtipo); }
          | expresion OPOR expresion                    { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = or($1.dtipo, $3.dtipo); }
          | expresion OPEQN expresion                   { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = eqn($1.dtipo, $2.atributo, $3.dtipo); }
          | expresion OPSUMRES expresion                { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = sumRes2($1.dtipo, $2.atributo, $3.dtipo); }
          | expresion OPMULDIV expresion                { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = mulDiv($1.dtipo, $2.atributo, $3.dtipo); }
          | expresion OPPORPOR expresion                { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = porPor($1.dtipo, $3.dtipo); }
          | expresion OPBORRLIST expresion              { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = borrList($1.dtipo, $2.atributo, $3.dtipo); }
          | expresion OPCOMP expresion                  { $$.lexema = leerOp($1.dtipo, $1.lexema, $2.lexema, $3.lexema, $3.dtipo); $$.dtipo = comp($1.dtipo, $2.atributo, $3.dtipo); }
          | expresion OPMASMAS expresion OPAT expresion { $$.dtipo = ternario($1.dtipo, $3.dtipo, $5.dtipo);
              						  $$.lexema = temporal();
              						  gen("Lista %s;\n", $$.lexema);
              						  gen("%s = insertarEn(%s, %s, %s);\n", $$.lexema, $1.lexema, insertarDato($3.lexema, $3.dtipo), $5.lexema);
            						}
          | llamada_funcion                          	{ $$.lexema = $1.lexema; $$.dtipo = $1.dtipo; }
          | ID                                       	{ $$.lexema = $1.lexema; $$.dtipo = buscarID($1.lexema); }
          | constante                                	{ $$.lexema = $1.lexema; $$.dtipo = $1.dtipo; }
          | error ;

/************* LLAMADA FUNCIÓN *****************/

llamada_funcion : ID LPAR argumentos RPAR {
                     $$.dtipo = comprobarFuncion($1.lexema);
                     $$.lexema = malloc(sizeof(char) * (strlen($1.lexema) + strlen($3.lexema) + 3));
                     sprintf($$.lexema, "%s(%s)", $1.lexema, $3.lexema);
                  } ;

argumentos : lista_argumentos { $$.lexema = $1.lexema; }
           | %empty { $$.lexema = ""; } ;

lista_argumentos : lista_argumentos COMA expresion {
                      $$.lexema = malloc(sizeof(char) * (strlen($1.lexema) + strlen($3.lexema) + 3));
                      sprintf($$.lexema, "%s, %s", $1.lexema, $3.lexema);
                      argumentos_tipo_datos[n_argumentos] = $3.dtipo;
                      n_argumentos++;
                   }
                 | expresion {
                      $$.lexema = $1.lexema;
                      argumentos_tipo_datos[n_argumentos] = $1.dtipo;
                      n_argumentos++;
                   } ;

/************* CONSTANTES *****************/

constante : CONSTANTS { $$.lexema = leerCte($1.lexema, $1.dtipo); $$.dtipo = $1.dtipo; }
          | lista 	{ $$.lexema = $1.lexema; $$.dtipo = $1.dtipo; } ;

lista : LCOR lista_expresiones RCOR { $$.lexema = $2.lexema; $$.dtipo = aTipoLista($2.dtipo); } ;

lista_expresiones : lista_expresiones COMA expresion {
                       $$.lexema = $1.lexema;
                       $$.dtipo = mismoTipoLista($1.dtipo, $3.dtipo);
                       gen("insertar(%s, %s);\n", $$.lexema, insertarDato($3.lexema, $3.dtipo));
                    }
                  | expresion {
                       $$.lexema = temporal();
                       $$.dtipo = $1.dtipo;
                       gen("Lista %s;\n", $$.lexema);
                       gen("%s = inicializar(%s);\n", $$.lexema, inicializaTipoLista($$.dtipo));
                       gen("insertar(%s, %s);\n", $$.lexema, insertarDato($1.lexema, $1.dtipo));
                    } ;
                    
%%

#include "lex.yy.c"

void yyerror(const char *msg){
  fprintf(stderr, "[Linea %d] %s\n", yylineno, msg);
  fflush(stderr);
  hayError = 1;
}

int main(){
  fMain = fopen("prog.c", "w");
  fFunc = fopen("dec_fun.h", "w");

  yyout = fMain ;
  yyparse();

  fclose(fMain);
  fclose(fFunc);

  if (hayError) {
    remove("prog.c");
    remove("dec_fun.h");
  }

  return(0);
}
