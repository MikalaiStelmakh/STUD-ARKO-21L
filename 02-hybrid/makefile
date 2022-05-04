# executable output name
TARGET=image_viewer

# compiler
CC=gcc
# debug
DEBUG=-g
# optimisation
OPT=-O0
# warnings
WARN=-Wall

PTHREAD=-pthread

CCFLAGS=$(DEBUG) $(OPT) $(WARN) $(PTHREAD) -pipe

GTKLIB=`pkg-config --cflags --libs gtk+-3.0`

LDFLAGS=$(PTHREAD) $(GTKLIB) -export-dynamic

OBJS=main.o scale.o

all: $(OBJS)
	$(CC) -o $(TARGET) $(OBJS) $(LDFLAGS)

main.o: src/main.c
	$(CC) -c $(CCFLAGS) src/main.c $(GTKLIB) -o main.o

scale.o: src/scale.asm
	nasm -f elf64 src/scale.asm -o scale.o

clean:
	rm -f *.o $(TARGET)