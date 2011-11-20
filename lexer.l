%{
#include "parser.tab.h"
#include <stdio.h>

int lineno = 0;
%}

space 		[ \t\0\177]
newline 	\n

%option yylineno
%%

\;[^\n]*\n 		return TOK_COMMENT;
\n 		 	return TOK_NEWLINE;
[0-9]+ 		        return TOK_NUMBER;

equ 			return TOK_EQU;
end 			return TOK_END;
org 			return TOK_ORG;

dat 			return TOK_DAT;
mov 			return TOK_MOV;
add 			return TOK_ADD;
sub 			return TOK_SUB;
mul 			return TOK_MUL;
div 			return TOK_DIV;
mod 			return TOK_MOD;
jmp 			return TOK_JMP;
jmz 			return TOK_JMZ;
jmn 			return TOK_JMN;
djn 			return TOK_DJN;
cmp 			return TOK_CMP;
slt 			return TOK_SLT;
spl 			return TOK_SPL;

[a-zA-Z][a-zA-Z0-9]* 	return TOK_LABEL;
[\-+.*,=#:/<>&!()] 	return yytext[0];
[ \t\0\177] 		;
. 			printf("illegal character: '%c'\n", yytext[0]);
%%
