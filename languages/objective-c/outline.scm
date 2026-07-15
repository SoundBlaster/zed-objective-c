(preproc_def
  "#define" @context
  name: (_) @name) @item

(preproc_function_def
  "#define" @context
  name: (_) @name) @item

(class_interface
  "@interface" @context .
  (identifier) @name
  category: (identifier)? @context) @item

(class_implementation
  "@implementation" @context .
  (identifier) @name
  category: (identifier)? @context) @item

(protocol_declaration
  "@protocol" @context .
  (identifier) @name) @item

(method_declaration
  ["+" "-"] @context
  [
    (identifier) @name
    (method_parameter
      ":" @name)
  ]+) @item

(method_definition
  ["+" "-"] @context
  [
    (identifier) @name
    (method_parameter
      ":" @name)
  ]+) @item

(property_declaration
  "@property" @context
  (struct_declaration
    (struct_declarator
      (identifier) @name))) @item

(property_declaration
  "@property" @context
  (struct_declaration
    (struct_declarator
      (pointer_declarator
        declarator: (identifier) @name)))) @item

(function_definition
  declarator: (function_declarator
    declarator: (_) @name)) @item

(struct_specifier
  "struct" @context
  name: (_) @name) @item

(enum_specifier
  "enum" @context
  name: (_) @name) @item

(comment) @annotation
