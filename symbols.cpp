
#include<iostream>
#include<string>
#include<vector>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include"symbols.h"


using namespace std;

int stackCount = 0;
varentry varNormal(string name, int type, bool isconst,int isg){
	varentry v;
	v.name = name;
	v.type = type;
	v.isconst = isconst;
	v.isArr = false;
	v.isInit = true;
	v.isfunc = false;
	v.arrSize = 1;
	v.global = isg;  
	if(isg != 1){
		v.javaStack_index = stackCount;
		stackCount++;
	}
	if(type == T_STR){
		v.data.sval = new char[1];
		v.data.sval[0] = '0';
	}
	return v;
}
varentry varNormal_n(string name, int type, bool isconst,int isg){
	varentry v;
	v.name = name;
	v.type = type;
	v.isconst = isconst;
	v.isArr = false;
	v.isInit = false;
	v.isfunc = false;
	v.arrSize = 1;
	v.global = isg;
	if(isg != 1){
		v.javaStack_index = stackCount;
		stackCount++;
	}
	if(type == T_STR){
		v.data.sval = new char[1];
		v.data.sval[0] = '0';
	}
	return v;
}
varentry argu(string name, int type,int isg){
	varentry v;
	v.name = name;
	v.type = type;
	v.isArr = false;
	v.isInit = false;
	v.isfunc = false;
	v.arrSize = 1;
	v.global = 0;
	if(isg != 1){
		v.javaStack_index = stackCount;
		stackCount++;
	}
	return v;
}
varentry varArr(string name, int type, bool isconst, int arrSize){
	varentry v;
	v.name = name;
	v.type = type;
	v.data.ival = 0;
	v.isconst = isconst;
	v.isArr = true;
	v.isInit = true;
	v.isfunc = false;
	v.arrSize = arrSize;
	if(type == T_STR){
		v.data.sval = new char[1];
		v.data.sval[0] = '0';
	}
	return v;
}

varentry func(string name,int type,string content){
	varentry v;
	v.name = name;
	v.type = type;
	v.data.ival = 0;
	v.isArr = false;
	v.isInit = true;
	v.isconst = false;
	v.isfunc = true;
	v.arguname = content;
	v.arrSize = 1;
	
	
	if(type == T_STR){
		v.data.sval = new char[1];
		v.data.sval[0] = '0';
	}
	return v;
}

SymbolTables::SymbolTables(){

	SymbolTable symboltable;
	symboltable.scopeName = "global";
	Table.push_back(symboltable);
}
int SymbolTables::pushStack(string name){
	
	SymbolTable symboltable;
	symboltable.scopeName = name;
	Table.push_back(symboltable);
}

int SymbolTables::popStack(){
	dumpTable();
	Table.pop_back();
}
int SymbolTables::dumpTable(){
	cout<<"------------------------------------------"<< endl;
	cout<<"Scope: "<<Table.back().scopeName << endl<<"SymbolTable:"<<endl;
	cout<<"conORvarORfun"<<'\t'<<"type"<<'\t'<<"name"<<'\t'<<"value:"<<endl;
	for(int i = 0;i < Table.back().varentrys.size();i++){
		varentry v = Table.back().varentrys[i];
		for(int k = 0;k < v.arrSize;k++){
			if(k!=0){
				cout<<"ARRAY:"<< k <<'\t'<<'\t';
			}
			else{
				if(v.isfunc==true)
					cout<<"function"<<'\t';
				else{
					if(v.isconst==true)
						cout<<"constant"<<'\t';
					else
						cout<<"variable"<<'\t';
				}
			}
			if(v.type==T_NO){
				cout<< "Notype"<<'\t';
				cout<<v.name<<'\t';
				cout<<"null"<<endl;
			}
			else if(v.type==T_INT){
				cout<<"int"<<'\t';
				if(v.isArr){
					cout<<v.name<<'['<< k << ']'<<'\t';
					if(v.isInit)
						cout<< v.data.inArr[k]<<endl;
					else
						cout<<"null"<<endl;
				}
				else{
					cout<<v.name<<'\t';
					if(v.isInit)
						cout<<v.data.ival<<endl;
					else
						cout<<"null"<<endl;
				}
			}
			else if(v.type==T_FLOAT){
				cout<<"float"<<'\t';
				if(v.isArr){
					cout<<v.name<<'['<< k << ']'<<'\t';
					if(v.isInit)
						cout<< v.data.flArr[k]<<endl;
					else
						cout<<"null"<<endl;
				}
				else{
					cout<<v.name<<'\t';
					if(v.isInit)
						cout<<v.data.fval<<endl;
					else
						cout<<"null"<<endl;
				}
			}
			else if(v.type==T_BOOL){
				cout<<"bool"<<'\t';
				if(v.isArr){
					cout<<v.name<<'['<< k << ']'<<'\t';
					if(v.isInit)
						cout<< v.data.boArr[k]<<endl;
					else 
						cout<<"null"<<endl;
				}
				else{
					cout<<v.name<<'\t';
					if(v.isInit)
						cout<<v.data.bval<<endl;
					else
						cout<<"null"<<endl;
				}
			}
			else if(v.type==T_STR){
				cout<<"string"<<'\t';
				if(v.isArr){
					cout<<v.name<<'['<< k << ']'<<'\t';
					if(v.isInit);
					else
						cout<<"null"<<endl;
				}
				else{
					cout<<v.name<<'\t';
					if(v.isInit)
						cout<<v.data.sval<<endl;
					else
						cout<<"null"<<endl;
				}
			}
		}
	}
	cout<<"------------------------------------------"<<endl;
	stackCount = 0;
}

int SymbolTables::addvar(varentry var){
	if(lookupscope(var.name).type == T_WRONG){
		Table.back().varentrys.push_back(var);
	}
	else{
		return 0;
	}
	return 1;
}

int SymbolTables::revVar(varentry var){
	for(int i =Table.size();i>=0;i--){
		for(int k=0;k<Table.size();k++){
			varentry v = Table[k].varentrys[i];
			if(v.name==var.name){
				if(!v.isconst){
					Table[k].varentrys[i]=var;
				}
			}
		}
	}
	return 0;
}

int SymbolTables::funcIn(int type){
	Table[Table.size()-2].varentrys.back().type = type;
	if(type == T_STR){
		Table[Table.size()-2].varentrys.back().data.sval = new char[1];
		Table[Table.size()-2].varentrys.back().data.sval[0]='0';
	}
}

int SymbolTables::funcAR(string content){
	Table[Table.size()-2].varentrys.back().arguname = content;
}

int SymbolTables::isGlobal(){
	
	if(Table.size()==1)
		return 1;
	return 0;
}


varentry SymbolTables::lookup(string name){
	for(int i =Table.size()-1;i>=0;i--){
		for(int k=0;k<Table[i].varentrys.size();k++){
			varentry v = Table[i].varentrys[k];
			if(v.name==name){
				return v;
			}
		}
	}
	varentry notexist;
	notexist.type = T_WRONG;
	notexist.name = " ";
	return notexist;
}

varentry SymbolTables::lookupscope(string name){
	for(int i=0;i<Table.back().varentrys.size();i++){
		varentry v = Table.back().varentrys[i];
		if(v.name==name)
			return v;
	}
	varentry notexist;
	notexist.type = T_WRONG;
	return notexist;
}
varentry SymbolTables::lookupargu(int a){
	
		varentry v = Table.back().varentrys[a-1];
			return v;
	
}
