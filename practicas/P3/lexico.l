%option yylineno
%option noyywrap

%%

"{"                                                      { return INIBLOQUE; }
"}"                                                      { return FINBLOQUE; }
"["                                                      { return LCOR; }
"]"                                                      { return RCOR; }
"("                                                      { return LPAR; }
")"                                                      { return RPAR; }
";"                                                      { return PYC; }
","                                                      { return COMA; }
"="                                                      { return ASIGN; }
"@"                                                      { return OPAT; }
"cin"                                                    { return CIN; }
"cout"                                                   { return COUT; }
"return"                                                 { return RETURN; }
"local"                                                  { return LOCAL; }
"main"                                                   { return MAIN; }
"do"                                                     { return DO; }
"until"                                                  { return UNTIL; }
"int"                                                    { return TIPO; }
"float"                                                  { return TIPO; }
"char"                                                   { return TIPO; }
"bool"                                                   { return TIPO; }
"list_of"" "+"int"                                       { return TIPO; }
"list_of"" "+"float"                                     { return TIPO; }
"list_of"" "+"char"                                      { return TIPO; }
"list_of"" "+"bool"                                      { return TIPO; }
"if"                                                     { return IF; }
"while"                                                  { return WHILE; }
"else"                                                   { return ELSE; }
"||"                                                     { return OPOR; }
"&&"                                                     { return OPAND; }
"=="							 { return OPEQN; }
"!="                                                	 { return OPEQN; }
"<"							 { return OPCOMP; }
">"							 { return OPCOMP; }
"<="							 { return OPCOMP; }
">="                                        		 { return OPCOMP; }
"+"							 { return OPSUMRES; }
"-"                                                  	 { return OPSUMRES; }
"*"							 { return OPMULDIV; }
"/"                                                  	 { return OPMULDIV; }
"!"                                                      { return OPNOT; }
"**"                                                     { return OPPORPOR; }
"--"							 { return OPBORRLIST; }
"%"                                                 	 { return OPBORRLIST; }
"?"							 { return OPINTHASH; }
"#"                                                  	 { return OPINTHASH; }
"++"                                                     { return OPMASMAS; }
"$"                                                      { return OPDOLLAR; }
"<<"							 { return SHIFT; }
">>"                                                	 { return SHIFT; }
\"[^\"]*\"                                               { return CADENA; }
([0-9]+)						 { return CONSTANTS; }
([0-9]+\.[0-9]+)					 { return CONSTANTS; }
"true"							 { return CONSTANTS; }
"false"							 { return CONSTANTS; }
\'[^\']\'       					 { return CONSTANTS; }
[a-z|A-Z][a-z|A-Z|0-9|_]*                                { return ID; }
[ \t\n]                                                  { ; }
.	                                                 {printf("Error en la línea %d. Lexema %s no reconocible.\n", yylineno, yytext);}

%%
