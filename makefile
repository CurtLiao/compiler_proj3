CC = g++
LEX = flex
YACC = bison
LEX_FILENAME = scanner.l
YACC_FILENAME = yaccpro2.y
OUTPUT_FILENAME = output.exe
TEST_FILENAME = ./testData/fib.rust
OTHER_SOURCE = symbols.cpp

$(OUTPUT_FILENAME): clean lex.yy.o y.tab.o
	$(CC) lex.yy.o y.tab.o $(OTHER_SOURCE) -o $(OUTPUT_FILENAME)

lex.yy.o: lex.yy.cpp y.tab.h
	$(CC) -c lex.yy.cpp

y.tab.o: y.tab.cpp
	$(CC) -c y.tab.cpp

y.tab.cpp y.tab.h: $(YACC_FILENAME)
	$(YACC) -y -d $(YACC_FILENAME)
	mv y.tab.c y.tab.cpp

lex.yy.cpp: $(LEX_FILENAME)
	$(LEX) -o lex.yy.cpp $(LEX_FILENAME)

clean:
	rm -f lex.yy.cpp y.tab.cpp y.tab.h  *.o *.exe 

run: 
	./$(OUTPUT_FILENAME) < $(TEST_FILENAME)
