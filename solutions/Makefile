SOLUTIONS+=example
SOLUTIONS+=mnbvmar

all: ${SOLUTIONS}

example: example.c
	gcc -O3 $< -o $@

mnbvmar: mnbvmar.cpp
	g++ -std=c++11 -O3 $< -o $@
