%{

  open Ast

  let loc () = symbol_start_pos (), symbol_end_pos ()
  let mk_expr e = { pexpr_desc = e; pexpr_loc = loc () }
  let mk_patt p = { ppatt_desc = p; ppatt_loc = loc () }
  let mk_def d = { pdef_desc = d; pdef_loc = loc () }

%}

%token AND
%token BAR
%token COLONCOLON
%token COMMA
%token <Ast.binop> COMP
%token <bool> CONST_BOOL
%token <int> CONST_INT
%token <float> CONST_FLOAT
%token <string> CONST_STRING
%token ELSE
%token EOF
%token EQUAL
%token FUNCTION
%token <string> IDENT
%token IF
%token IN
%token LBRACKET
%token LET
%token LPAREN
%token MATCH
%token MINUS
%token MINUS_DOT
%token MINUS_GT
%token NEQ
%token NOT
%token OR
%token PLUS
%token PLUS_DOT
%token RBRACKET
%token REC
%token RPAREN
%token SEMI
%token SLASH
%token SLASH_DOT
%token STAR
%token STAR_DOT
%token THEN
%token UNDERSCORE
%token WITH

%nonassoc IN
%nonassoc ELSE
%nonassoc MINUS_GT
%left OR 
%left AND
%left COMP EQUAL NEQ                          /* < <= > >= <> = <> */
%right COLONCOLON                             /* :: */
%left PLUS MINUS PLUS_DOT MINUS_DOT           /* + -  */
%left STAR SLASH STAR_DOT SLASH_DOT           /* * /  */
%nonassoc uminus                              /* - */
%nonassoc NOT                                 /* not */


/* Point d'entr�e */

%start lets
%type <Ast.plets> lets

%%

lets: defs EOF { $1 }
;

defs:
| /* empty */       { [] }
| def defs    { $1 :: $2 }
;

def:
| LET binding 
    { let is_rec, patt, body = $2 in
      mk_def (is_rec, patt, body) } 
;

binding:
| rec_flag pattern EQUAL expr 
    { ($1, $2, $4) }
| rec_flag IDENT pattern_list EQUAL expr 
    { let body = 
         List.fold_right (fun patt e -> mk_expr (PE_fun(patt, e))) $3 $5
      in
      ($1, mk_patt (PP_ident $2), body) }
;

pattern:
| UNDERSCORE 
    { mk_patt PP_any }
| IDENT
    { mk_patt (PP_ident $1) }
| LPAREN pattern_comma_list RPAREN
    { mk_patt (PP_tuple $2) }
;

simple_expr:
| LPAREN expr RPAREN
    { $2 }
| const 
    { $1 }
| IDENT 
    { mk_expr (PE_ident $1) }
| LPAREN expr_comma_list  RPAREN
    { mk_expr (PE_tuple $2) }  
| LBRACKET expr_semi_list RBRACKET
    { List.fold_right 
	(fun e acc -> mk_expr (PE_cons (e, acc))) $2 (mk_expr PE_nil) } 
;

expr:
| simple_expr
    { $1 }
| simple_expr simple_expr_list
    { List.fold_left (fun acc e -> mk_expr (PE_app (acc, e))) $1 $2 }
| expr COLONCOLON expr
    { mk_expr (PE_cons ($1, $3)) }
| LET binding IN expr
    { let is_rec, patt, body = $2 in
      mk_expr (PE_let (is_rec, patt, body, $4)) }
| FUNCTION pattern MINUS_GT expr
    { mk_expr (PE_fun ($2, $4)) }
| IF expr THEN expr ELSE expr
    { mk_expr (PE_if ($2, $4, $6)) }
| MATCH expr WITH 
    opt_bar LBRACKET RBRACKET MINUS_GT expr 
    BAR pattern COLONCOLON pattern MINUS_GT expr
    { mk_expr (PE_match ($2, $8, ($10, $12, $14))) }
| expr PLUS expr          
    { mk_expr (PE_binop (Badd, $1, $3)) }
| expr PLUS_DOT expr          
    { mk_expr (PE_binop (Badd_f, $1, $3)) }
| expr MINUS expr         
    { mk_expr (PE_binop (Bsub, $1, $3)) }
| expr MINUS_DOT expr         
    { mk_expr (PE_binop (Bsub_f, $1, $3)) }
| expr STAR expr        
    { mk_expr (PE_binop (Bmul, $1, $3)) }
| expr STAR_DOT expr        
    { mk_expr (PE_binop (Bmul_f, $1, $3)) }
| expr SLASH expr        
    { mk_expr (PE_binop (Bdiv, $1, $3)) }
| expr SLASH_DOT expr        
    { mk_expr (PE_binop (Bdiv_f, $1, $3)) }
| expr COMP expr         
    { mk_expr (PE_binop ($2, $1, $3)) }
| expr EQUAL expr         
    { mk_expr (PE_binop (Beq, $1, $3)) }
| expr NEQ expr         
    { mk_expr (PE_binop (Bneq, $1, $3)) }
| expr AND expr          
    { mk_expr (PE_binop (Band, $1, $3)) }
| expr OR expr          
    { mk_expr (PE_binop (Bor, $1, $3)) }
| MINUS expr %prec uminus 
    { mk_expr (PE_unop (Uminus, $2)) }
| MINUS_DOT expr  %prec uminus 
    { mk_expr (PE_unop (Uminus_f, $2)) }
| NOT expr
    { mk_expr (PE_unop (Unot, $2)) }
;

const:
| LPAREN RPAREN
    { mk_expr (PE_cte Cunit) }
| CONST_BOOL 
    { mk_expr (PE_cte (Cbool $1)) }
| CONST_INT 
    { mk_expr (PE_cte (Cint $1)) }
| CONST_FLOAT
    { mk_expr (PE_cte (Cfloat $1)) }
| CONST_STRING 
    { mk_expr (PE_cte (Cstring $1)) }
;

rec_flag:
| /* empty */  { false }
| REC          { true }
;

opt_bar:
| /* empty */  { () }
| BAR          { () }
;

simple_expr_list:
| simple_expr simple_expr_list              { $1 :: $2 }
| simple_expr                               { [$1] }
;

expr_comma_list:
| expr COMMA expr_comma_list
    { $1 :: $3 }
| expr COMMA expr 
    { [$1; $3] }
;

expr_semi_list:
| /* empty */
    { [] }
| expr
    { [$1] }
| expr SEMI expr_semi_list 
    { $1 :: $3 }
;

pattern_comma_list:
| pattern COMMA pattern_comma_list
    { $1 :: $3 }
| pattern COMMA pattern
    { [$1; $3] }
;

pattern_list:
  pattern pattern_list            { $1 :: $2 }
| pattern                         { [$1] }
;
