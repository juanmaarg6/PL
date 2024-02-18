%option yylineno
%option noyywrap

char* msgError[256];

%%

"{"                         { return INIBLOQUE; }
"}"                         { return FINBLOQUE; }
"["                         { return LCOR; }
"]"                         { return RCOR; }
"("                         { return LPAR; }
")"                         { return RPAR; }
";"                         { return PYC; }
","                         { return COMA; }
"="                         { return ASIGN; }
"@"                         { return OPAT; }
"cin"                       { return CIN; }
"cout"                      { return COUT; }
"return"                    { return RETURN; }
"local"                     { return LOCAL; }
"main"                      { return MAIN; }
"do"                        { return DO; }
"until"                     { return UNTIL; }
"int"                       { yylval.atributo = 0; yylval.dtipo = entero; return TIPO; }
"float"                     { yylval.atributo = 1; yylval.dtipo = real; return TIPO; }
"char"                      { yylval.atributo = 2; yylval.dtipo = caracter; return TIPO; }
"bool"                      { yylval.atributo = 3; yylval.dtipo = booleano; return TIPO; }
"list_of"" "+"int"          { yylval.atributo = 4; yylval.dtipo = listaEntero; return TIPO; }
"list_of"" "+"float"        { yylval.atributo = 5; yylval.dtipo = listaReal; return TIPO; }
"list_of"" "+"char"         { yylval.atributo = 6; yylval.dtipo = listaCaracter; return TIPO; }
"list_of"" "+"bool"         { yylval.atributo = 7; yylval.dtipo = listaBooleano; return TIPO; }
"if"                        { return IF; }
"while"                     { return WHILE; }
"else"                      { return ELSE; }
"||"                        { return OPOR; }
"&&"                        { return OPAND; }
"=="                        { yylval.atributo = 0; return OPEQN; }
"!="                        { yylval.atributo = 1; return OPEQN;}
"<"                         { yylval.atributo = 0; return OPCOMP; }
">"                         { yylval.atributo = 1; return OPCOMP; }
"<="                        { yylval.atributo = 2; return OPCOMP; }
">="                        { yylval.atributo = 3; return OPCOMP; }
"+"                         { yylval.atributo = 0; return OPSUMRES; }
"-"                         { yylval.atributo = 1; return OPSUMRES; }
"*"                         { yylval.atributo = 0; return OPMULDIV;}
"/"                         { yylval.atributo = 1; return OPMULDIV; }
"!"                         { return OPNOT; }
"**"                        { return OPPORPOR; }
"--"                        { yylval.atributo = 0; return OPBORRLIST; }
"%"                         { yylval.atributo = 1; return OPBORRLIST; }
"?"                         { yylval.atributo = 0; return OPINTHASH; }
"#"                         { yylval.atributo = 1; return OPINTHASH; }
"++"                        { return OPMASMAS; }
"$"                         { return OPDOLLAR; }
"<<"                        { yylval.atributo = 0; return SHIFT; }
">>"                        { yylval.atributo = 1; return SHIFT; }
\"[^\"]*\"                  { return CADENA; }
[0-9]+                      { yylval.atributo = 0; yylval.dtipo = entero; return CONSTANTS; }
[0-9]+\.[0-9]+              { yylval.atributo = 1; yylval.dtipo = real; return CONSTANTS; }
\'[^\']\'                   { yylval.atributo = 2; yylval.dtipo = caracter; return CONSTANTS; }
"true"|"false"              { yylval.atributo = 3; yylval.dtipo = booleano; return CONSTANTS; }
[a-z|A-Z][a-z|A-Z|0-9|_]*   { yylval.lexema = strdup(yytext); return ID; }
[ \t\n]                     { ; }
.                     	    { sprintf(msgError, "ERROR LÉXICO: Lexema %s no reconocible.\n", yytext); yyerror(msgError); }

%%
