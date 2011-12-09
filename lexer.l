%{
#include "parser.tab.h"
#include <stdio.h>

int lineno = 0;
extern int pass;
//extern char *buffer_text[10];
extern char *buffer_text;
extern int nbuffers;
extern int push_buffer;

int start_replacing = 0;

/*YY_BUFFER_STATE main_buffer;
YY_BUFFER_STATE expansion_buffer;*/

YY_BUFFER_STATE buffer_stack[10];
int bufferpos = 0;
int for_nest = 0;

YY_BUFFER_STATE for_stack[10];
int forpos = 0;


/* XXX: the normal scan string also switches to that buffer, so we can't use
 * push_state, how annoying */
YY_BUFFER_STATE pass2_scan_buffer  (char * base, yy_size_t  size , yyscan_t yyscanner)
{
	YY_BUFFER_STATE b;

	if ( size < 2 ||
	     base[size-2] != YY_END_OF_BUFFER_CHAR ||
	     base[size-1] != YY_END_OF_BUFFER_CHAR )
		/* They forgot to leave room for the EOB's. */
		return 0;

	b = (YY_BUFFER_STATE) pass2_alloc(sizeof( struct yy_buffer_state ) ,yyscanner );
	if ( ! b )
		fprintf(stderr, ( "out of dynamic memory in pass2__scan_buffer()" ));

	b->yy_buf_size = size - 2;	/* "- 2" to take care of EOB's */
	b->yy_buf_pos = b->yy_ch_buf = base;
	b->yy_is_our_buffer = 0;
	b->yy_input_file = 0;
	b->yy_n_chars = b->yy_buf_size;
	b->yy_is_interactive = 0;
	b->yy_at_bol = 1;
	b->yy_fill_buffer = 0;
	b->yy_buffer_status = YY_BUFFER_NEW;

	return b;
}

YY_BUFFER_STATE pass2_create_string  (yyconst char * str, yyscan_t yyscanner)
{
	YY_BUFFER_STATE b;
	char *buf;
	yy_size_t n;
	int i;
	char *yybytes = str;
	int _yybytes_len = strlen(str);

	/* Get memory for full buffer, including space for trailing EOB's. */
	n = _yybytes_len + 2;
	buf = (char *) pass2_alloc(n ,yyscanner );
	if ( ! buf )
		fprintf(stderr, ( "out of dynamic memory in pass2__scan_bytes()" ));

	for ( i = 0; i < _yybytes_len; ++i )
		buf[i] = yybytes[i];

	buf[_yybytes_len] = buf[_yybytes_len+1] = YY_END_OF_BUFFER_CHAR;

	b = pass2_scan_buffer(buf,n ,yyscanner);
	if ( ! b )
		fprintf(stderr, ( "bad buffer in pass2__scan_bytes()" ));

	/* It's okay to grow etc. this buffer, and we should throw it
	 * away when we're done.
	 */
	b->yy_is_our_buffer = 1;

	return b;
}
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
<INITIAL>for		{ BEGIN(FOR_TERM); for_nest++; return TOK_FOR; }
<FOR_TERM>\n 		{ BEGIN(FOR_GOBBLE); }
<FOR_TERM>{space}* 	;
<FOR_GOBBLE>for 	{ for_nest++; yylval->string = yyget_text(yyscanner); return TOK_FOR_GOBBLE; }
<FOR_GOBBLE>rof         { if ((--for_nest) == 0) {
				BEGIN(INITIAL);
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
<INITIAL,FOR_TERM>{label} 	        {
			char *macro = NULL;
			macro = lookup_macro(yyget_text(yyscanner));
			/* XXX: should be able to use buffer stack, but it's crashing */
			if (macro) {
				/*buffer_stack[++bufferpos] = YY_CURRENT_BUFFER;*/
				/*yy_switch_to_buffer(yy_scan_string(strdup(macro), yyscanner), yyscanner);*/
				++bufferpos;
				yypush_buffer_state(pass2_create_string(strdup(macro), yyscanner), yyscanner);
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
		/*yy_delete_buffer(YY_CURRENT_BUFFER, yyscanner);
		yy_switch_to_buffer(buffer_stack[bufferpos--], yyscanner);*/
		yypop_buffer_state(yyscanner);
		bufferpos--;
	} else if (push_buffer > 0) {
		if (pass == 2) {
			yypop_buffer_state(yyscanner);
			push_buffer--;
		}
	} else {
		yyterminate();
	}
}
%%
