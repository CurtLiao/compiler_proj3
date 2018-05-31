#ifndef SYMBOLS_H
#define SYMBOLS_H
#include<stdio.h>
#include<stdlib.h>
#include<iostream>
#include<string.h>
#include<vector>
using namespace std;

enum TYPE{
	T_NO,T_BOOL,T_STR,T_INT,T_FLOAT,T_WRONG
};

typedef union{
	int ival;
	float fval;
	bool bval;
	char *sval;
	char *fun;

	int* inArr;
	float* flArr;
	bool* boArr;
	char** stArr;
}varData;

typedef struct varentry{
	string name;
	int type;
	bool isInit;
	bool isconst;    //1 const,0 variable
	bool isArr;
	bool isfunc;
	int arrSize;
	int javaStack_index;
	int global;      //1 global,0 local
	string funcC;
	union{
		varData data;
	};
}varentry;

varentry varNormal(string name, int type, bool isconst,int isg);
varentry varNormal_n(string name, int type, bool isconst,int isg);
varentry func(string name, int type);
varentry varArr(string name, int type, bool isconst, int arrSize);
varentry argu(string name,int type,int isg);


typedef struct{
	string scopeName;
	vector<varentry> varentrys;
} SymbolTable;

class SymbolTables
{
private:
	vector<SymbolTable> Table;
public:
	SymbolTables();

	int pushStack(string name);
	
	int popStack();
	int dumpTable();

	int addvar(varentry var);
	int revVar(varentry var);
	int funcIn(int type);
	int isGlobal();
	
	varentry lookupargu();
	//varentry lookupfunc();
	varentry lookup(string name);
	varentry lookupscope(string name);
	
};
#endif