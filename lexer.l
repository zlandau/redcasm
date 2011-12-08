%{
#include "parser.tab.h"
#include <stdio.h>

int lineno = 0;
extern int pass;
extern char *buffer_text;

int start_replacing = 0;

/*YY_BUFFER_STATE main_buffer;
YY_BUFFER_STATE expansion_buffer;*/

YY_BUFFER_STATE buffer_stack[10];
int bufferpos = 0;
int for_nest = 0;

YY_BUFFER_STATE for_stack[10];
int forpos = 0;

%}

space 		[ \t\0\177]
newline 	\n
label           [a-zA-Z][a-zA-Z0-9_]*
%option yylineno reentrant noyywrap bison-bridge debug stack
%option prefix="pass2_"
%option header-file="lexer.yy.h"

%x GOBBLE
%x GOBBLE_SPACE
%x GOBBLE_FOR
%x FOR_TERM
%x FOR_GOBBLE

%%

\;[^\n]*\n 		yylval->string = yyget_text(yyscanner); return TOK_COMMENT;
\n 		 	return TOK_NEWLINE;
<INITIAL,FOR_TERM>[0-9]+ 		        { yylval->number = atoi(yyget_text(yyscanner)); return TOK_NUMBER; }
org 			{ return TOK_ORG; }
end 			{ return TOK_END; }
<INITIAL>for		{ BEGIN(FOR_TERM); printf("here?!\n"); for_nest++; return TOK_FOR; }
<FOR_TERM>\n 		{ BEGIN(FOR_GOBBLE); }
<FOR_TERM>{space}* 	;
<FOR_GOBBLE>for 	{ for_nest++; yylval->string = yyget_text(yyscanner); return TOK_FOR_GOBBLE; }
<FOR_GOBBLE>rof         { if ((--for_nest) == 0) {
				fprintf(stderr, "blah! %s", buffer_text);
				BEGIN(INITIAL);
				if (buffer_text) {
					for_stack[++forpos] = YY_CURRENT_BUFFER;
					printf("going to push %s\n", buffer_text);
					yy_switch_to_buffer(yy_scan_string(strdup(buffer_text), yyscanner), yyscanner);
				}
				return TOK_ROF;
			} else {
				yylval->string = yyget_text(yyscanner);
				return TOK_FOR_GOBBLE;
			} }
<FOR_GOBBLE>(.|\n)     { yylval->string = yyget_text(yyscanner); return TOK_FOR_GOBBLE; }
equ 			{ BEGIN(GOBBLE_SPACE); return TOK_EQU; }
<GOBBLE_SPACE>{space}*  { BEGIN(GOBBLE); }
<GOBBLE>[^\n;]* 	{ yylval->string = yyget_text(yyscanner); BEGIN(INITIAL); return TOK_GOBBLE; }
(dat|mov|add|sub|mul|div|mod|jmp|jmz|jmn|djn|cmp|slt|spl|end|org)(\.(a|b|ab|ba|f|x|i))? {
			char *modpos = index(yyget_text(yyscanner), '.');
			if (modpos) {
				*modpos = '\0';
				++modpos;
			}
			yylval->inst = generate_inst(yyget_text(yyscanner), modpos);
			return TOK_OPCODE;
			}
{label} 	        {
			char *macro = NULL;
			macro = lookup_macro(yyget_text(yyscanner));
			/* XXX: should be able to use buffer stack, but it's crashing */
			if (macro) {
				buffer_stack[++bufferpos] = YY_CURRENT_BUFFER;
				yy_switch_to_buffer(yy_scan_string(strdup(macro), yyscanner), yyscanner);
			} else {
				yylval->string = yyget_text(yyscanner);
				return TOK_LABEL;
			}
			}
<INITIAL,FOR_TERM>[\-+.*,=#:/<>&!()@$] 	return yyget_text(yyscanner)[0];
<INITIAL,FOR_TERM>[ \t\0\177] 		;
. 			printf("illegal character: '%c'\n", yyget_text(yyscanner)[0]);
<<EOF>> {
	if (bufferpos > 0) {
		yy_delete_buffer(YY_CURRENT_BUFFER, yyscanner);
		yy_switch_to_buffer(buffer_stack[bufferpos--], yyscanner);
	} else if (forpos > 0) {
		printf("and here?!\n");
		yy_delete_buffer(YY_CURRENT_BUFFER, yyscanner);
		yy_switch_to_buffer(buffer_stack[forpos--], yyscanner);
	} else {
		yyterminate();
	}
}
%%
