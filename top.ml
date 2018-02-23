open Format
open Lexing
open Lexer
open Parser
open Ast
     	  
let () =
  printf "\t miniML version 0.1\n\n"

  (* 
    let lb = Lexing.from_string e in
      try
	let dl = Parser.lets Lexer.token lb in
        ...
      with
      | Lexical_error s ->  ...
                    
      | Parsing.Parse_error -> ...

      | ...
    done

   *)
