#include <stdio.h>

double yylval;
extern int yydebug;

int main(int argc, char **argv)
{
	/*yydebug=1;*/
	yyparse();
	return 0;
}

extern int yylineno;
void yyerror(char *s)
{
	fprintf(stderr, "%s (lineno=%d)\n", s, yylineno);
}

