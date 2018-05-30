%{
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "y.tab.h"
#include "symbols.h"

#define MAX_LINE_LENG 256
#define LIST     strcat(buf,yytext)
#define token(t) {LIST;return(t);}
#define tokens(t) {LIST;return(t);}
#define tokenInteger(i) {LIST;}
#define tokenFloat(i) {LIST;}
#define tokenexp(i) {LIST;}
#define tokenString(t) {LIST;}
#define tokenStrings(t) {LIST;}

char c;
char strbuf[MAX_LINE_LENG];
int linenum = 1;
int j =0;
char buf[MAX_LINE_LENG];
char sbuf[MAX_LINE_LENG];
char *abuf;
char result[MAX_LINE_LENG];

extern "C"{
	int yywrap();
	int yylex();
}
%}

digit	[0-9_]+
letter	[A-Za-z_]
ident	[A-Za-z][0-9A-Za-z]*
Integer	[+-]?[1-9][0-9]*|0
Float	([+-]?[0-9]+"."[0-9]+["f"]?)|[0-9]["f"]?
exp	{digit}"."{digit}[Ee][+-]?{digit}

%x   COMMENT1  
%x   COMMENT2  
%x   COMMENT3  

%%
"("     {tokens(LEFT_PARENT);}
")"	{tokens(RIGHT_PARENT);}
"["	{tokens(LEFT_BRACK);}
"]"	{tokens(RIGHT_BRACK);}
"{"	{tokens(LEFT_BRACE);}
"}"	{tokens(RIGHT_BRACE);}

"++"	{tokens(ADD);}
"--"	{tokens(MMINUS);}
"=="	{tokens(EQ);}
"%"	{tokens(MOD);}
"<"	{tokens(LESS);}
">"	{tokens(LARGER);}
"<="	{tokens(LESSEQ);}
">="	{tokens(LARGEREQ);}
"!="	{tokens(NOTEQ);}

"&&"	{tokens(LOGICAL_AND);}
"||"	{tokens(LOGICAL_OR);}
"!"	{tokens(LOGICAL_NOT);}
"+="	{tokens(PLUS_ASSIGN);}
"-="	{tokens(MINUS_ASSIGN);}
"*="	{tokens(TIMES_ASSIGN);}
"/="	{tokens(DIVIDE_ASSIGN);}

"+"	{tokens(PLUS);}
"-"	{tokens(MINUS);}
"*"	{tokens(MUTI);}
"/"	{tokens(DIVIDE);}
","	{tokens(COMMA);}
";"	{tokens(SEMICOLON);}
":"	{tokens(COLON);}
"="	{tokens(ASSIGN);}

if	{token(IF)}
bool	{token(BOOL);}
break	{token(BREAK);}
char	{token(CHAR);}
continue	{token(CONTINUE);}
do	{token(DO);}
else	{token(ELSE);}
enum	{token(ENUM);}     
extern	{token(EXTERN);}
false	{yylval.Token.token_type=T_BOOL;yylval.Token.bval = false;token(FALSE);}
float	{token(FLOAT);}
for	{token(FOR);}
fn	{token(FN);}
in	{token(IN);}
int	{token(INT);}
let	{token(LET);}
loop	{token(LOOP);}
match	{token(MATCH);}
mut	{token(MUT);}
print	{token(PRINT);}
println	{token(PRINTLN);}
pub	{token(PUB);}
return	{token(RETURN);}
self	{token(SELF);}
static	{token(STATIC);}
str	{token(STR);}
struct	{token(STRUCT);}
true	{yylval.Token.token_type=T_BOOL;yylval.Token.bval = true;token(TRUE);}
use	{token(USE);}
where	{token(WHERE);}
while	{token(WHILE);}
{ident}	{
	tokenString(yytext);
	yylval.Token.sval = strdup(yytext);
	return(IDENTIFIER);
}

{Integer}	{
	tokenInteger(atoi(yytext));
	yylval.Token.token_type = T_INT;
	yylval.Token.ival = atoi(yytext);
	return(INTEGER);
}
{Float}	{
	tokenFloat(atof(yytext));
	yylval.Token.token_type = T_FLOAT;
	yylval.Token.fval = atof(yytext);
	return(REAL);
}

"//"	{LIST;BEGIN COMMENT1;}
<COMMENT1>[ \t]	{LIST;}
<COMMENT1>.	{LIST;}
<COMMENT1>\n	{
	LIST;
	printf("%d:%s", linenum, buf);
	linenum++;
	buf[0] = '\0';
	BEGIN 0;
}

"/*"	{LIST;BEGIN COMMENT2;}
<COMMENT2>[ \t]	{LIST;}
<COMMENT2>.	{LIST;}
<COMMENT2>\n	{
	LIST;
	printf("%d:%s", linenum, buf);  
	linenum++;
	buf[0] = '\0';
}
<COMMENT2>"*/"	{LIST;BEGIN 0;}
"\""	{LIST;BEGIN COMMENT3;}
<COMMENT3>[ \t]	{LIST;strcat(sbuf,yytext);}
<COMMENT3>"\""	{LIST;yytext = strdup(sbuf);yylval.Token.token_type = T_STR;yylval.Token.sval = strdup(yytext);memset(sbuf ,'\0',MAX_LINE_LENG);BEGIN 0;return(STRING);}
<COMMENT3>.	{LIST;strcat(sbuf,yytext);}


[ \t]	{LIST;}
\n      {
LIST;
printf("%d:%s", linenum, buf);
linenum++;
buf[0] = '\0';
}
.       {
LIST;
printf("%d:%s\n", linenum, buf);
printf("bad character:%s\n",yytext);
exit(-1);
}
%%
int yywrap(void){
return 1;
}
/*int main(){
yylex();
dump();
}*/
