%{
#define YYPARSE_PARAM scanner
#define YYLEX_PARAM scanner
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "parser.tab.h"
#define YYDEBUG 1

#define MAXSYMLIST 200
#define MAXEQULIST 200
#define MAXLOCALLIST 10

/* Fix this dependency mess */
#define PARSE_EQU 1

struct symbol_t {
	char *name;
	char *text;
	int address;
};

struct symbol_t *symboldb[MAXSYMLIST];
int nsymbols = 0;
struct symbol_t *symboldb_local[MAXLOCALLIST];
int pass = 1;
int origin = 0;

struct label_list_t {
	char *labels[10];
	int nlabels;
};

enum opcode_t {
	DAT,
	MOV,
	ADD,
	SUB,
	MUL,
	DIV,
	MOD,
	JMP,
	JMZ,
	JMN,
	DJN,
	CMP,
	SLT,
	SPL,
	EQU,
	END,
	ORG,
	UNKNOWN
};

char *inst_to_str[] = {
	"dat",
	"mov",
	"add",
	"sub",
	"mul",
	"div",
	"mod",
	"jmp",
	"jmz",
	"jmn",
	"djn",
	"cmp",
	"slt",
	"spl",
	"equ",
	"end",
	"org",
	"unknown"
};

enum mode_t {
	IMMEDIATE,
	DIRECT,
	INDIRECT,
	DECREMENT,
	INCREMENT
};

char mode_to_str[] = {
	'#',
	'$',
	'@',
	'<',
	'>'
};

enum modifier_t {
	MOD_A,
	MOD_B,
	MOD_AB,
	MOD_BA,
	MOD_F,
	MOD_X,
	MOD_I,
	MOD_UNDEFINED
};

char *mod_to_str[] = {
	"a",
	"b",
	"ab",
	"ba",
	"f",
	"x",
	"i",
	"?",
};

typedef short address_t;

struct instruction_t {
	enum opcode_t opcode;
	enum modifier_t modifier;
	enum mode_t a_mode;
	address_t a_addr;
	enum mode_t b_mode;
	address_t b_addr;
};

struct equ_t {
	char *name;
	struct instruction_t *inst;
};

struct equ_t *equdb[MAXEQULIST];
int nequs = 0;

address_t org = 0;

struct equ_t *find_equ(const char *str)
{
	int i = 0;
	for (i = 0; i < nequs; i++) {
		if (strcmp(str, equdb[i]->name) == 0)
			return equdb[i];
	}
	return NULL;
}

struct instruction_t *generate_inst(const char *str, const char *mod) {
	struct instruction_t *inst = malloc(sizeof(struct instruction_t));
	int i = 0;
	inst->opcode = UNKNOWN;
	for (i = 0; i <= ORG; i++) {
		if (strcmp(str, inst_to_str[i]) == 0) {
			inst->opcode = i;
			break;
		}
	}
	if (inst->opcode == UNKNOWN)
		printf("Could not find opcode %s\n", str);

	inst->modifier = MOD_UNDEFINED;
	if (mod) {
		for (i = 0; i <= MOD_I; i++) {
			if (strcmp(mod, mod_to_str[i]) == 0) {
				inst->modifier = i;
				break;
			}
		}
	}

	return inst;
}

int instno;

enum modifier_t get_default_modifier(struct instruction_t *inst)
{
	switch (inst->opcode) {
		case DAT:
			return MOD_F;
		case MOV:
		case CMP:
		/* case SEQ: */
		/* case SNE: */
			if (inst->a_mode == IMMEDIATE)
				return MOD_AB;
			else if (inst->b_mode == IMMEDIATE)
				return MOD_B;
			else
				return MOD_I;
		case ADD:
		case SUB:
		case MUL:
		case DIV:
		case MOD:
			if (inst->a_mode == IMMEDIATE)
				return MOD_AB;
			else if (inst->b_mode == IMMEDIATE)
				return MOD_B;
			else
				return MOD_F;
		case SLT:
			if (inst->a_mode == IMMEDIATE)
				return MOD_AB;
			else
				return MOD_B;
		case JMP:
		case JMZ:
		case JMN:
		case DJN:
		case SPL:
		/*case NOP:*/
			return MOD_B;
		default:
			return MOD_UNDEFINED;

	}
}

void set_fields(struct instruction_t *inst, int a, enum mode_t a_mode, int b, enum mode_t b_mode)
{
	inst->a_addr = a;
	inst->a_mode = a_mode;
	inst->b_addr = b;
	inst->b_mode = b_mode;

	if (inst->modifier == MOD_UNDEFINED)
		inst->modifier = get_default_modifier(inst);

	if (pass == 2) {
		printf("\t%s.%-2s %c%6d, %c%6d\n", inst_to_str[inst->opcode], mod_to_str[inst->modifier], mode_to_str[inst->a_mode], inst->a_addr, mode_to_str[inst->b_mode], inst->b_addr);
		}

}


void parse_comment(const char *str)
{
	/* blah */
}

struct symbol_t *add_symbol(const char *name, int address)
{
	struct symbol_t *sym = malloc(sizeof(struct symbol_t));
	sym->name = strdup(name);
	sym->address = address;
	sym->text = NULL;
	//printf("adding %s at %d for %d\n", name, address, instno);
 	return sym;
}

struct symbol_t *add_macro(const char *name, const char *text)
{
	struct symbol_t *sym = malloc(sizeof(struct symbol_t));
	sym->name = strdup(name);
	sym->address = -500;
	sym->text = strdup(text);
	//printf("adding %s -> %s\n", name, text);
 	return sym;
}

struct equ_t *add_equ(const char *name, struct instruction_t *inst)
{
	struct equ_t *equ = malloc(sizeof(struct equ_t));
	equ->name = strdup(name);
	equ->inst = inst;
	//printf("adding %s at %d for %d\n", name, address, instno);
 	return equ;
}

char *lookup_macro(const char *name)
{
	int i;
	struct symbol_t *sym;
	for (i = 0; i < nsymbols; i++) {
		sym = symboldb[i];
		if (sym->text && (strcmp(name, sym->name) == 0))
			return sym->text;
	}
	return NULL;
}

int lookup_symbol(const char *name)
{
	int i;
	struct symbol_t *sym;
	for (i = 0; i < nsymbols; i++) {
		sym = symboldb[i];
		if (!sym->text && (strcmp(name, sym->name) == 0))
			return sym->address;
	}
	return -100;
}


int started = 0;
extern int yylineno;
%}

%define api.pure
%name-prefix = "pass2_"

%pure_parser

%union {
	int number;
	char *string;
	char *modifier;
	struct instruction_t *inst;
	int mode;
	char *equ_list;
	char *for_list;
	struct label_list_t *label_list;
}

/*%token TOK_DAT TOK_MOV TOK_ADD TOK_SUB TOK_MUL TOK_DIV TOK_MOD
%token TOK_JMP TOK_JMZ TOK_JMN TOK_DJN TOK_CMP TOK_SLT TOK_SPL */

%token <inst> TOK_OPCODE
%token <string> TOK_LABEL
%token <string> TOK_MODIFIER
%token <string> TOK_COMMENT
%token TOK_ORG
%token TOK_END
%token TOK_EQU
%token TOK_FOR
%token TOK_ROF
%token <string> TOK_FOR_GOBBLE
%token <string> TOK_GOBBLE
/* %type <string> symbol */
%type <string> label
%type <string> equ
%type <equ_list> equ_list
%type <equ_list> macro
%type <string> for_gobble
%type <for_list> for_gobble_list
%type <number> symbol
%type <inst> opcode
%type <inst> operation
/*%type <string> modifier*/
%type <number> expr
%type <number> term
%type <number> number
%type <number> whole_number
%type <number> signed_integer
%type <mode> mode
%type <string> comment
%type <label_list> label_list

%token A B AB BA F X I

%token TOK_NEWLINE 
%token <number> TOK_NUMBER

/*%token <string> TOK_SYMBOL
%token <value> TOK_NUMBER

%token <str> TOK_COMMENT*/

%left '*'
%left '+'
%left '-'

%%

assembly_file:
        list
list:
        line | list line
line:
        comment |
	pseudoop |
        instruction |
	label_list |
        TOK_NEWLINE

pseudoop: macro | org | end | for

comment: TOK_COMMENT { parse_comment($1); }

instruction:
        label_list operation mode expr ',' mode expr {
		set_fields($2, $4, $3, $7, $6);
		instno++;
		} |
        label_list operation mode expr {
		set_fields($2, $4, $3, 0, DIRECT);
		instno++;
	} |
        operation mode expr ',' mode expr {
		set_fields($1, $3, $2, $6, $5);
		instno++;
		} |
        operation mode expr {
		set_fields($1, $3, $2, 0, DIRECT);
		instno++;
	}


label_list:
        label { $$ = malloc(sizeof(struct label_list_t)); $$->nlabels = 1; $$->labels[0] = $1; }
      | label_list label { $$->labels[$$->nlabels++] = $2; }

label:
      TOK_LABEL {
		if (pass == 1)
			symboldb[nsymbols++] = add_symbol($1, instno);
		$$ = strdup($1);
	}
operation:
        opcode
opcode: TOK_OPCODE

macro:
 label_list equ_list {
     		int i;
     		if (pass == 2)
			for (i = 0; i < $1->nlabels; i++)
				symboldb[nsymbols++] = add_macro($1->labels[i], $2);
	}

equ_list: equ { $$ = malloc(256); strcpy($$, $1); }
	| equ_list equ { strcat($1, $2); $$ = $1; }
equ: TOK_EQU TOK_GOBBLE TOK_NEWLINE {
   $$ = strdup($2);
   /* XXX: can't figure out why the newline is becoming part of $2 */
   $$[strlen($$) - 1] = '\0';
   }

for: TOK_FOR expr for_gobble_list TOK_ROF TOK_NEWLINE { printf("gobble list is %s\n", $3); }
for_gobble_list: for_gobble { $$ = malloc(256); strcpy($$, $1); }
	       | for_gobble_list for_gobble { strcat($1, $2); $$ = $1; }
for_gobble: TOK_FOR_GOBBLE { $$ = strdup($1); }

org: TOK_ORG TOK_LABEL { 
	if (pass == 2)
		origin = lookup_symbol($2);
	}

end: TOK_END { YYACCEPT; }
   | TOK_END TOK_LABEL {
	if (pass == 2)
		origin = lookup_symbol($2);
	YYACCEPT;
}


mode:
	    { $$ = DIRECT; } |
        '#' { $$ = IMMEDIATE; } |
        '$' { $$ = DIRECT; } |
        '@' { $$ = INDIRECT; } |
        '<' { $$ = DECREMENT; } |
        '>' { $$ = INCREMENT; }
/*field:  expr |
     	expr ',' expr*/
expr:
        term |
	'-'term { $$ = -$2; } |
        term '+' expr { $$ = $1 + $3; } |
        term '-' expr { $$ = $1 - $3; } |
        term '*' expr { $$ = $1 * $3; } |
        term '/' expr { $$ = $1 / $3; } |
        term '%' expr { $$ = $1 % $3; }
term:
        symbol | number | '(' expr ')' { $$ = $2; }
symbol: TOK_LABEL { $$ = lookup_symbol($1) - instno;}
number:
        whole_number | signed_integer
/*signed_integer:
        '+'whole_number | '-'whole_number*/
signed_integer: '-'whole_number { $$ = -$2; }

whole_number:
        TOK_NUMBER
/*EOL:
        TOK_NEWLINE*/
/*e:*/

%%
