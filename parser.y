%{
#define YYDEBUG 1
%}

%union {
	char *str;
	int num;
}

%token TOK_DAT TOK_MOV TOK_ADD TOK_SUB TOK_MUL TOK_DIV TOK_MOD
%token TOK_JMP TOK_JMZ TOK_JMN TOK_DJN TOK_CMP TOK_SLT TOK_SPL
%token TOK_ORG TOK_EQU TOK_END

%token A B AB BA F X I

%token TOK_NEWLINE 
%token <str> TOK_LABEL
%token <num> TOK_NUMBER
%token <str> TOK_COMMENT

%%

assembly_file:
        list
list:
        line | line list
line:
        comment | instruction comment | instruction | TOK_NEWLINE

comment: TOK_COMMENT;

instruction:
        label_list operation mode expr ',' mode expr |
        label_list operation mode expr
label_list:
        label | label label_list /*| label TOK_NEWLINE label_list*/
label:
        | TOK_LABEL
operation:
        opcode | opcode '.' modifier
opcode:
        TOK_DAT | TOK_MOV | TOK_ADD | TOK_SUB | TOK_MUL | TOK_DIV | TOK_MOD |
        TOK_JMP | TOK_JMZ | TOK_JMN | TOK_DJN | TOK_CMP | TOK_SLT | TOK_SPL |
        TOK_ORG | TOK_EQU | TOK_END
modifier:
        A | B | AB | BA | F | X | I
mode:
        | '#' | '$' | '@' | '<' | '>' | 'e'
/*field:  expr |
     	expr ',' expr*/
expr:
        term |
        term '+' expr | term '-' expr |
        term '*' expr | term '/' expr |
        term '%' expr
term:
        label | number | '(' expr ')'
number:
        whole_number | signed_integer
/*signed_integer:
        '+'whole_number | '-'whole_number*/
signed_integer: '-'whole_number

whole_number:
        TOK_NUMBER
/*EOL:
        TOK_NEWLINE*/
/*e:*/

%%
