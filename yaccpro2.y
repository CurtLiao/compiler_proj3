%{  
#define Trace(t)        printf(t)
//#define Trace(t)
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "symbols.h"
#include<iostream>
#include<vector>
#include<string.h>
FILE *java_code;

extern "C" {							 //use C++
	int yyerror(const char *s);
	extern int yylex();
}

SymbolTables symt = SymbolTables();      //create symbol_table


int isconst = 0;
int islocal = 0;
%}

%union									//def struct for value passing
{
	struct
	{
		union
		{
			int ival;
			bool bval;
			char *sval;
			float fval;
		};
		int token_type;
	}Token;
}


/* tokens */
%token CONTINUE BREAK DO ELSE ENUM EXTERN FOR FN IF IN  LET LOOP MATCH MUT PRINT PRINTLN PUB RETURN SELF STATIC USE WHERE WHILE
%token STRUCT CHAR  
%token RIGHT_BRACE LEFT_BRACE RIGHT_BRACK LEFT_BRACK RIGHT_PARENT LEFT_PARENT COMMA COLON SEMICOLON            
%token DIVIDE MUTI MINUS PLUS MOD MMINUS ADD NOTEQ LARGEREQ LESSEQ LARGER LESS EQ
%token LOGICAL_AND LOGICAL_OR LOGICAL_NOT ASSIGN DIVIDE_ASSIGN PLUS_ASSIGN MINUS_ASSIGN TIMES_ASSIGN
 
%token<Token> IDENTIFIER
%token<Token> INTEGER
%token<Token> REAL
%token<Token> STRING

%token TRUE
%token FALSE
%token STR
%token INT
%token BOOL
%token FLOAT

%type<Token> exp arr_declared type interger_exp real_exp string_exp bool_exp func_invoke     //def grammar type for return






%start program							//start grammar
%left LOGICAL_OR						// precedence
%left LOGICAL_AND
%left LOGICAL_NOT
%left NOTEQ LARGEREQ LESSEQ LARGER LESS EQ
%left PLUS MINUS
%left MUTI DIVIDE MOD
%nonassoc UMINUS

 
%%
program:	
		normal_declared func_declared {						//from normal declare or function declare reduce to program and pop table stack and print
			Trace("Reducing to program\n");
			symt.popStack();
		} |
		func_declared{
			Trace("Reducing to program\n");
			symt.popStack();
		}
		;													
normal_declared:															
		declared normal_declared{															//from declare or normal declare reduce
			 Trace("Reducing to normal_declared\n");
		} |   
		declared{Trace("Reducing to normal_declared\n");}
		;
declared:																	
		const_declared{Trace("Reducing to declared\n");} |								//from variable constant or array declare reduce
		var_declared{Trace("Reducing to declared\n");} |
		arr_declared{Trace("Reducing to declared\n");}
		;
func_declared:																
			func_dec{Trace("Reducing to func_declared\n");} |									//from function declare reduce	
			func_dec func_declared{Trace("Reducing to func_declared\n");}
			;
func_dec:																		
			FN IDENTIFIER LEFT_PARENT { 													//declare function with formal_argu or not, and put function name into symbol table
										Trace("Reducing to func_dec\n");
										varentry v = func($2.sval,T_NO);
										if(!symt.addvar(v)){
											yyerror("Error: redefined");
										} 
										symt.pushStack($2.sval);
			}
			formal_argu RIGHT_PARENT func_type
			func_scope	{ 
				Trace("Reducing to func_dec\n");
				symt.popStack(); 
			}
			;
func_scope:																
		LEFT_BRACE content RIGHT_BRACE{																//declare code that write in the function
			Trace("Reducing to func scope\n");
		}
		;
func_type:																	
		MINUS LARGER type{													//def function type and return to symbol table
			Trace("Reducing to func type -> type\n");
			symt.funcIn($3.token_type);
		} |
		%empty{
			Trace("Reducing to func type nothing\n");
		}
		;
formal_argu:																
		%empty{																		//some argument in function, return its name,type,is initial or not
			Trace("Reducing to formal argu\n");
		} |
		IDENTIFIER COLON type COMMA formal_argu{
			Trace("Reducing to formal argu\n");
			//varentry v = varNormal($1.sval,$3.token_type,false);
			/*if(!symt.addvar(v)){
				yyerror("Error: redefined");
			}*/
		} |
		IDENTIFIER COLON type{
			Trace("Reducing to formal argu 1\n");
			//varentry v = varNormal($1.sval,$3.token_type,false);
			/*if(!symt.addvar(v)){
				yyerror("Error: redefined");
			}*/
		}
		;

var_declared:																			
		LET MUT IDENTIFIER SEMICOLON{													//variable declare, return its name type value initial or not, put into symbol table
			Trace("Reducing to var_declared\n");										//if redefined,error
			varentry v = varNormal_n($3.sval,T_NO,false,symt.isGlobal());
			if(!symt.addvar(v))
				yyerror("Error : redefined");
		} |
		LET MUT IDENTIFIER COLON type SEMICOLON{
			Trace("Reducing to var_declared\n");
			varentry v = varNormal_n($3.sval,$5.token_type,false,symt.isGlobal());

			if(!symt.addvar(v))
				yyerror("Error : redefined");
		} |
		LET MUT IDENTIFIER ASSIGN exp SEMICOLON{    
			Trace("Reducing to var_declared\n");
			
			varentry v = varNormal($3.sval,$5.token_type,false,symt.isGlobal());
			if($5.token_type==T_INT){

				v.data.ival = $5.ival;
				
				if(symt.isGlobal()==1)
					fprintf(java_code,"\tfield static int %s = %d\n",$3.sval,$5.ival);
				else
					fprintf(java_code,"\t\tistore %d\n",v.javaStack_index);
			}
			else if($5.token_type==T_FLOAT){
				v.data.fval = $5.fval;
			}
			else if($5.token_type==T_STR){
				v.data.sval = $5.sval;
				
			}
			else if($5.token_type==T_BOOL){
				v.data.bval = $5.bval;
				
				if(symt.isGlobal()==1)
					fprintf(java_code,"\tfield static bool %s = %d\n",$3.sval,$5.bval);
				else
					fprintf(java_code,"\t\tistore %d\n",v.javaStack_index);
			}
			if(!symt.addvar(v))
				yyerror("Error: redefined");
		} |
		LET MUT IDENTIFIER COLON type ASSIGN exp SEMICOLON{
			Trace("Reducing to var_declared\n");
			varentry v = varNormal($3.sval,$5.token_type,false,symt.isGlobal());

			/*if($7.token_type==T_INT && $5.token_type==T_FLOAT){
				v.data.fval = $7.fval;
			}
			else if($5.token_type != $7.token_type){
				yyerror("Error : exp type not same");
			}*/
			if($7.token_type==T_INT){
				v.data.ival = $7.ival;
				
				if(symt.isGlobal()==1)
					fprintf(java_code,"\tfield static int %s = %d\n",$3.sval,$7.ival);
				else
					fprintf(java_code,"\t\tistore %d\n",v.javaStack_index);
			}
			else if($7.token_type==T_FLOAT){
				v.data.fval = $7.fval;
			}
			else if($7.token_type==T_STR){
				v.data.sval = $7.sval;
			}
			else if($7.token_type==T_BOOL){
				v.data.bval = $7.bval;
				
				if(symt.isGlobal()==1)
					fprintf(java_code,"\tfield static bool %s = %d\n",$3.sval,$7.bval);
				else
					fprintf(java_code,"\t\tistore %d\n",v.javaStack_index);
			}
			if(!symt.addvar(v))
				yyerror("Error: redefined");
		}
		;
const_declared:
		LET IDENTIFIER ASSIGN {isconst = 1;}
		exp SEMICOLON{													
			Trace("Reducing to const_declared\n");									//constant declare, return its name type value initial or not, put into symbol table
			varentry v = varNormal($2.sval,$5.token_type,true,symt.isGlobal());						//if redefined,error
			if($5.token_type ==T_INT){
				v.data.ival = $5.ival;
			}
			else if($5.token_type ==T_FLOAT){
				v.data.fval = $5.fval;
			}
			else if($5.token_type ==T_STR){
				v.data.sval = $5.sval;
			}
			else if($5.token_type ==T_BOOL){
				v.data.bval = $5.bval;
			}
			if(!symt.addvar(v))
				yyerror("Error: redefined");
			isconst = 0;
		}
		|
		LET IDENTIFIER COLON type ASSIGN {isconst = 1;}
		exp SEMICOLON{
			Trace("Reducing to const_declared\n");
			varentry v = varNormal($2.sval,$4.token_type,true,symt.isGlobal());

			if($7.token_type==T_INT && $4.token_type==T_FLOAT){
				v.data.fval = $7.ival;
			}
			else if($4.token_type != $7.token_type){
				yyerror("Error : exp type not same");
			}
			else if($7.token_type==T_INT){
				v.data.ival = $7.ival;
			}
			else if($7.token_type==T_FLOAT){
				v.data.fval = $7.fval;
			}
			else if($7.token_type==T_STR){
				v.data.sval = $7.sval;
			}
			else if($7.token_type==T_BOOL){
				v.data.bval = $7.bval;
			}
			if(!symt.addvar(v))
				yyerror("Error: redefined");
			isconst = 0;
		}
		;
arr_declared:
		LET MUT IDENTIFIER LEFT_BRACK type COMMA interger_exp RIGHT_BRACK SEMICOLON{	//array declare, return its name type value initial or not,array index, put into symbol table
			Trace("Reducing to arr_declared\n");
			varentry v = varArr($3.sval,$5.token_type,false,$7.ival);
			int arrIndex = $7.ival;
			if($7.token_type!=T_INT){
				yyerror("Error array index type error");
			}
			if($5.token_type==T_INT){
				v.data.inArr = new int[arrIndex];
			}
			else if($5.token_type==T_FLOAT){
				v.data.flArr = new float[arrIndex];
			}
			else if($5.token_type==T_STR){
				v.data.stArr = new char*[arrIndex];
				for(int i =0;i<arrIndex;i++){
					v.data.stArr[i][0] = '0';
				}
			}
			else if($5.token_type==T_BOOL){
				v.data.boArr = new bool[arrIndex];
			}

			if(!symt.addvar(v))
				yyerror("Error: redefined");
		}
		;
content:															
		declared content{
			Trace("Reducing to content declared content\n");
		}
		|
		statements content{
			Trace("Reducing to content statements  content\n");
		}
		|
		declared{
			Trace("Reducing to content declared\n");
		}
		|
		statements{
			Trace("Reducing to content statements\n");
		}
		|
		%empty{
			Trace("Reducing to content empty\n");
		}
		;
statements:
			statement statements{
				Trace("Reducing to statements\n");
			}
			|
			statement{
				Trace("Reducing to statements\n");
			}
			;
statement:																	
		IDENTIFIER ASSIGN exp SEMICOLON{							//statement include identifier reassign, print/println expression, return, block, if else,while loop, function invoke
			varentry vcheck = symt.lookup($1.sval);
			Trace("Reducing to statement vcheck\n");
			
			if(vcheck.name!=" "){
				if(vcheck.isconst!=1){
					if(vcheck.global==1)
						fprintf(java_code,"\t\tputstatic int proj3.%s\n",$1.sval);
					else
						fprintf(java_code,"\t\tistore %d\n",vcheck.javaStack_index);
				}
				else{
					yyerror("this is constant");
				}
			}
			else{
				yyerror("not define");
			}
		} |
		IDENTIFIER LEFT_BRACK interger_exp RIGHT_BRACK ASSIGN exp SEMICOLON{
			Trace("Reducing to statement\n");
		} |
		PRINT{
			fprintf(java_code,"\t\tgetstatic java.io.PrintStream java.lang.System.out\n");
		}exp SEMICOLON{
			if($3.token_type==T_INT||$3.token_type==T_BOOL)
				fprintf(java_code,"\t\tinvokevirtual void java.io.PrintStream.println(int)\n");
			else
				fprintf(java_code,"\t\tinvokevirtual void java.io.PrintStream.println(java.lang.String)\n");
			Trace("Reducing to statement print\n");
		} |
		PRINTLN{
			
			fprintf(java_code,"\t\tgetstatic java.io.PrintStream java.lang.System.out\n");
		}exp SEMICOLON{
			if($3.token_type==T_INT||$3.token_type==T_BOOL)
				fprintf(java_code,"\t\tinvokevirtual void java.io.PrintStream.println(int)\n");
			else
				fprintf(java_code,"\t\tinvokevirtual void java.io.PrintStream.println(java.lang.String)\n");
			
			Trace("Reducing to statement println\n");	
		} |
		RETURN exp SEMICOLON{
			Trace("Reducing to statement return\n");
		} |
		RETURN SEMICOLON{
			Trace("Reducing to statement return\n");
		} |
		block{
			Trace("Reducing to statement\n");
		} |
		conditionl{
			Trace("Reducing to statement conditional\n");
		} |
		loop{
			Trace("Reducing to statement loop\n");
		} |
		func_invoke{
			Trace("Reducing to statement func_invoke\n");
		}
		;
exp:                                                                       //for expression action include +-*/% and integer,real,string,bool
	MINUS exp %prec UMINUS{
		if($2.token_type==T_INT){                           //negative
			$$.token_type=T_INT;
			$$.ival = -$2.ival;
			fprintf(java_code,"\t\tineg\n");
		}							
		Trace("Reducing to exp\n");
	} |
	exp PLUS exp{                                             //plus
		if($1.token_type==T_INT&&$3.token_type==T_INT){
			$$.token_type=T_INT;
			$$.ival = $1.ival + $3.ival;
			fprintf(java_code,"\t\tiadd\n");
		}
		Trace("Reducing to exp\n");
	} |
	exp MINUS exp{                                            //minus
		if($1.token_type==T_INT&&$3.token_type==T_INT){
			$$.token_type=T_INT;
			$$.ival = $1.ival - $3.ival;
			fprintf(java_code,"\t\tisub\n");
		}
		Trace("Reducing to exp\n");
	} |
	exp MUTI exp{                                              //muti
		if($1.token_type==T_INT&&$3.token_type==T_INT){
			$$.token_type=T_INT;
			$$.ival = $1.ival * $3.ival;
			fprintf(java_code,"\t\timul\n");
		}
		Trace("Reducing to exp\n");
	} |
	exp DIVIDE exp{                                             //div
		if($1.token_type==T_INT&&$3.token_type==T_INT){
			$$.token_type=T_INT;
			$$.ival = $1.ival / $3.ival;
			fprintf(java_code,"\t\tidiv\n");
		}
		Trace("Reducing to exp\n");
	} |
	exp MOD exp{                                                //mod
		if($1.token_type==T_INT&&$3.token_type==T_INT){
			$$.token_type=T_INT;
			$$.ival = $1.ival % $3.ival;
			fprintf(java_code,"\t\tirem\n");
		}
		Trace("Reducing to exp\n");
	} |
	LEFT_PARENT exp RIGHT_PARENT{
		Trace("Reducing to exp\n");
	} |
	INTEGER{
		$$.ival = $1.ival;
		$$.token_type = T_INT;
		if(islocal = 1)
			if(isconst!=1)
				fprintf(java_code,"\t\tsipush %d\n",$1.ival);
		Trace("Reducing to exp\n");
	} |
	real_exp{
		Trace("Reducing to exp\n");
	} |
	bool_exp{
		$$.token_type = T_BOOL;
		$$.bval = $1.bval;
		Trace("Reducing to exp\n");
	} |
	string_exp{
		Trace("Reducing to exp\n");
		if(isconst!=1)
			fprintf(java_code,"\t\tldc \"%s\"\n",$1.sval);
		$$.token_type=T_STR;
		strcpy($$.sval,$1.sval);
	} |
	func_invoke{
		Trace("Reducing to exp\n");
	} |
	IDENTIFIER{
		varentry vcheck = symt.lookup($1.sval);
		if(vcheck.name!=" "){
			$$.token_type = vcheck.type;
			if(vcheck.type==T_INT){                                                 //int assign
				$$.ival = vcheck.data.ival;
				if(vcheck.global==1){
					fprintf(java_code,"\t\tgetstatic int proj3.%s\n",$1.sval);
				}
				else{
					if(vcheck.isconst==0)
						fprintf(java_code,"\t\tiload %d\n",vcheck.javaStack_index);
					else
						fprintf(java_code,"\t\tsipush %d\n",vcheck.data.ival);
				}
			}
			else if(vcheck.type==T_BOOL){                                            //bool assign
				if(vcheck.global==1){
					fprintf(java_code,"\t\tgetstatic bool proj3.%s\n",$1.sval);
				}
				else{
					if(vcheck.isconst==0)
						fprintf(java_code,"\t\tiload %d\n",vcheck.javaStack_index);
					else
						fprintf(java_code,"\t\ticonst_ %d\n",vcheck.data.bval);
				}
			}
		}
		else{
				yyerror("not define");
		}
		Trace("Reducing to exp\n");
	} |
	IDENTIFIER LEFT_BRACK interger_exp RIGHT_BRACK{
		Trace("Reducing to exp\n");
	}
	;
interger_exp:	
		INTEGER{
			$$.ival = $1.ival;
			$$.token_type = T_INT;
																	//for integer
			Trace("Reducing to interger_exp\n");
		}
		;
real_exp:
		REAL{														//for real
			Trace("Reducing to real_exp\n");
		}
		;
bool_exp:	
		TRUE{														//for boolean true,false, logical and/or/not, >, =, <, >=, <=, !=, ! 
			Trace("Reducing to bool_exp\n");
			$$.token_type = T_BOOL;
			$$.bval = true;
			fprintf(java_code,"\t\ticonst_1\n");
		} |
		FALSE{
			Trace("Reducing to bool_exp\n");
			$$.token_type = T_BOOL;
			$$.bval = false;
			fprintf(java_code,"\t\ticonst_0\n");
		} |
		LOGICAL_NOT exp{
			Trace("Reducing to bool_exp not\n");
		} |
		exp LESS exp{
			Trace("Reducing to bool_exp less\n");
		} |
		exp LARGER exp{
			Trace("Reducing to bool_exp larger\n");
		} |
		exp LOGICAL_AND exp{
			Trace("Reducing to bool_exp and\n");
		} |
		exp LOGICAL_OR exp{
			Trace("Reducing to bool_exp or\n");
		} |
		exp LOGICAL_NOT exp{
			Trace("Reducing to bool_exp not\n");
		} |
		exp LARGEREQ exp{
			Trace("Reducing to bool_exp larger eq\n");
		} |
		exp LESSEQ exp{
			Trace("Reducing to  less eq\n");
		} |
		exp NOTEQ exp{
			Trace("Reducing to bool_exp not eq\n");
		} 
		;
string_exp:			
		STRING{																		//for string
			$$.token_type = T_STR;
			strcpy($$.sval,$1.sval);
			Trace("Reducing to string_exp\n");
		}
		;
func_invoke:
		IDENTIFIER LEFT_PARENT parameters RIGHT_PARENT{											
			Trace("Reducing to func_invoke\n");
		}
		;
parameters:
		exp COMMA parameters{							//function invoke's parameters
			Trace("Reducing to parameter\n");
		}
		|
		exp{
			Trace("Reducing to parameter\n");
		}
		;
block:												
	 LEFT_BRACE{																			//when see the { push table to stack and pop it when see }
				Trace("Reducing to block\n");
				symt.pushStack("nowScope");
	 			} 
	 content RIGHT_BRACE{
				Trace("Reducing to block\n");
				symt.popStack();
	 }
	 ;
conditionl:
	IF LEFT_PARENT bool_exp RIGHT_PARENT block{												//if else
		Trace("Reducing to conditionl\n");
	}
	|
	IF LEFT_PARENT bool_exp RIGHT_PARENT block ELSE block{
		Trace("Reducing to conditionl\n");
	}
	;
loop:
	WHILE LEFT_PARENT bool_exp RIGHT_PARENT block{									//while loop
		Trace("Reducing to loop\n");
	}
	;
type:						
		BOOL{																	//for type, def int,float ,bool,string
			Trace("Reducing to type bool\n");
			$$.token_type =T_BOOL;
		} |
		INT{
			Trace("Reducing to type int\n");
			$$.token_type =T_INT;
		} |
		STR{
			Trace("Reducing to type string\n");
			$$.token_type =T_STR;
		} |
		FLOAT{
			Trace("Reducing to type float\n");
			$$.token_type =T_FLOAT;
		}
		;
%%


int yyerror(const char *s){                     							//when error print error
	//fprintf("%s\n",yytext);
    fprintf(stderr, "Error: %s\n", s);
	exit(0);
	return 0;
}

int main(void)
{
	java_code = fopen("b10415031.jasm","w");
	fprintf(java_code,"class proj3\n{\n");

    yyparse();

	fprintf(java_code,"}");
	fclose(java_code);

	return 0;
}