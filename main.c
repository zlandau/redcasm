#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "parser.tab.h"
#include "lexer.yy.h"

extern int pass2_debug;
double yylval;
extern int yydebug;
extern char *symboldb[200];
extern int nsymbols;
extern int pass;
extern int push_buffer;
const char *parsefile;
int val=5;
extern int instno;

yyscan_t scanner;
int main(int argc, char **argv)
{
	/*yydebug=1;*/
	YYSTYPE type;

	pass2_lex_init(&scanner);
	parsefile = strdup(argv[1]);
	printf("parsefile is %s at %p, scanner is %p\n", parsefile, parsefile, scanner);
	/*yyin = fopen(parsefile, "r");*/
	if (argc > 2) {
		if (strcmp(argv[2], "lex") == 0)
			pass2_set_debug(1, scanner);
		else if (strcmp(argv[2], "yacc") == 0)
			pass2_debug = 1;
		else {
			pass2_set_debug(1, scanner);
			pass2_debug = 1;
		}

	}

	pass2_set_in(fopen(parsefile, "r"), scanner);
	pass = 1;
	fprintf(stderr, "parse 1...\n");
	assert(pass2_parse(scanner) == 0);
	fprintf(stderr, "parse 1 done\n");
	/*yylex(&type, scanner);*/

	printf("pass2: %p\n", pass2_get_in(scanner));
	rewind(pass2_get_in(scanner));
	instno = 0;
	push_buffer = 0;
	pass = 2;
	fprintf(stderr, "parse 2...\n");
	pass2_parse(scanner);
	fprintf(stderr, "parse 2 done\n");

	/*yylex(&type, scanner);*/
	/*yyparse();*/
	pass2_lex_destroy(scanner);
	return 0;
}

void pass2_error(char *s)
{
	fprintf(stderr, "%s (lineno=%d)\n", s, pass2_get_lineno(scanner));
}

#if 0
int yywrap(void)
{
	if (pass == 1) {
		printf("openining %s at %p\n", parsefile, parsefile);
		printf("val is %d\n", val);
		yyin = fopen(parsefile, "r");
		pass = 2;
		return 0;
	} else {
		return 1;
	}

}
#endif
