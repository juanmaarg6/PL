%option yylineno
%option noyywrap
%{
	#include "tabla.h"
%}

%%

"{"                                                                                          { return INIBLOQUE; }
"}"                                                                                          { return FINBLOQUE; }
"["                                                                                          { return LCOR; }
"]"                                                                                          { return RCOR; }
"("                                                                                          { return LPAR; }
")"                                                                                          { return RPAR; }
";"                                                                                          { return PYC; }
","                                                                                          { return COMA; }
"="                                                                                          { return ASIGN; }
"@"                                                                                          { return AT; }
"cin"                                                                                        { return CIN; }
"cout"                                                                                       { return COUT; }
"return"                                                                                     { return RETURN; }
"local"                                                                                      { return LOCAL; }
"main"                                                                                       { return MAIN; }
"do"                                                                                         { return DO; }
"until"                                                                                      { return UNTIL; }
"int"											     { return TIPO; }
"float"											     { return TIPO; }
"char"											     { return TIPO; }
"bool"											     { return TIPO; }
"list_of"" "+"int"                                       				     { return TIPO; }
"list_of"" "+"float"                                     				     { return TIPO; }
"list_of"" "+"char"                                      				     { return TIPO; }
"list_of"" "+"bool" 									     { return TIPO; }
"if"                                                                                         { return IF; }
"while"                                                                                      { return WHILE; }
"else"                                                                                       { return ELSE; }
"+"|"-"                                                                                      { return BINYUN; }
"<<"                                                                                         { return SHIFTL; }
">>"											     { return SHIFTR; }
"$"                                                                                          { return DOLLAR; }
"++"                                                                                         { return MASMAS; }
"*"										             { return OPBIN; }
"/"										             { return OPBIN; }
"%"										             { return OPBIN; }
"**"										             { return OPBIN; }
"=="										             { return OPBIN; }
"!="										             { return OPBIN; }
"&&"										             { return OPBIN; }
"||"										             { return OPBIN; }
"<"										             { return OPBIN; }
">"										             { return OPBIN; }
"<="										             { return OPBIN; }
">="										             { return OPBIN; }
"--"										             { return OPBIN; }
"!"	                                                                       	             { return OPUNARIO; }
"#"                                                                       	     	     { return OPUNARIO; }
"?"                                                                       	     	     { return OPUNARIO; }
\"[^\"]*\"                                                                                   { return CADENA; }
[0-9]+										             { return CONSTANTS; }
[0-9]+(\.[0-9]+)?                                               			     { return CONSTANTS; }
'[^']'                                              					     { return CONSTANTS; }
"true"|"false"                                             				     { return CONSTANTS; }
[a-z|A-Z][a-z|A-Z|0-9]*                                                                      { return ID; }
[ \t\n]                                                                                      { ; }
.                                                                                            { printf("Error en la línea %d. Lexema %s no reconocible.\n", yylineno, yytext); }

%%

int main() {
	int val;
	val = yylex();

	while (val != 0){
		printf("%d\n", val);
		val = yylex();
	}

	return(0);
}
