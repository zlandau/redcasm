
YFLAGS        = -d
PROGRAM       = redcasm
SRCS          = parser.tab.o lexer.yy.o main.o
OBJS          = $(SRCS:.c=.o)

all:            $(PROGRAM)

.c.o:           $(SRCS)
		$(CC) -c $*.c -o $@ -O

parser.tab.c:   parser.y
		bison -v -t $(YFLAGS) parser.y

lexer.yy.c:       lexer.l
		flex -d -o lexer.yy.c lexer.l

redcasm:        $(OBJS)
		$(CC) $(OBJS)  -o $@ -lfl -lm

clean:          
		rm -f $(OBJS) core *~ \#* *.o $(PROGRAM) y.* lexer.yy.* parser.tab.*
