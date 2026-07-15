(method_definition
  (compound_statement
    "{"
    (_)* @function.inside
    "}")) @function.around

(method_declaration) @function.around

(function_definition
  body: (compound_statement
    "{"
    (_)* @function.inside
    "}")) @function.around

(class_interface) @class.around
(class_implementation) @class.around
(protocol_declaration) @class.around

(comment)+ @comment.around
