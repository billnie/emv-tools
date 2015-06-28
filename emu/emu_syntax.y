%{
#include "emu_syntax.h"
#include "emu_ast.h"

#include <stdio.h>
#include <stdbool.h>

extern int yylex(YYSTYPE * yylval_param,YYLTYPE * yylloc_param );
extern void yyset_in (FILE *  in_str );

static void yyerror(char *msg);
%}

%union {
	char *str;
	struct emu_value *val;
	struct emu_property *prop;
}

%locations
%token EQ LBRACE RBRACE SEMICOLON COMMA
%token <str> STRING VALUE
%type <val> values
%type <prop> property properties df

%define api.pure true

%printer { fprintf (yyoutput, "%s", $$ ); } STRING VALUE
%printer { property_dump($$, yyoutput); } properties property
%destructor { free($$); } STRING VALUE
%destructor { value_free($$); } values
%destructor { property_free($$); } properties property

%%

file: df { property_free($1); }
    ;

df: LBRACE properties RBRACE SEMICOLON { $$ = $2; }
  ;

properties: property {$$ = $1; }
	  | properties property { $$ = property_append($1, $2); }
	  | properties error {$$ = $1; }
	;

property: STRING EQ values SEMICOLON { $$ =  property_new($1, $3); }
	;

values: VALUE { $$ = value_new($1); }
      | values COMMA VALUE { $$ = value_append($1, value_new($3)); }
	;

%%
static bool had_errors = false;

static void yyerror(char *msg)
{
	fprintf(stderr, "Syntax error: %s\n", msg);

	had_errors = true;
}

int main(int argc, char **argv)
{
	if (argc > 2)
		return 5;

	FILE *f = (argc == 1) ? stdin : fopen(argv[1], "r");
	if (!f) {
		perror("fopen");
	}

	yyset_in(f);

	int ret = yyparse();

	if (f != stdin)
		fclose(f);

	return ret ? ret : (had_errors ? 3 : 0);
}