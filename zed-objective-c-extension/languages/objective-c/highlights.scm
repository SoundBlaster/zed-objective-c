; C syntax. Adapted from tree-sitter-c v0.23.4 (MIT).

(identifier) @variable

((identifier) @constant
  (#match? @constant "^_*[A-Z][A-Z\\d_]*$"))

[
  "const"
  "enum"
  "extern"
  "inline"
  "sizeof"
  "static"
  "struct"
  "typedef"
  "union"
  "volatile"
] @keyword

[
  "break"
  "case"
  "continue"
  "default"
  "do"
  "else"
  "for"
  "goto"
  "if"
  "return"
  "switch"
  "while"
] @keyword.control

[
  "#define"
  "#elif"
  "#else"
  "#endif"
  "#if"
  "#ifdef"
  "#ifndef"
  "#include"
  (preproc_directive)
] @preproc

[
  "="
  "+="
  "-="
  "*="
  "/="
  "%="
  "&="
  "|="
  "^="
  "<<="
  ">>="
  "++"
  "--"
  "+"
  "-"
  "*"
  "/"
  "%"
  "~"
  "&"
  "|"
  "^"
  "<<"
  ">>"
  "!"
  "&&"
  "||"
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "->"
  "?"
  ":"
] @operator

[
  "."
  ";"
  ","
] @punctuation.delimiter

[
  "{"
  "}"
  "("
  ")"
  "["
  "]"
] @punctuation.bracket

[
  (string_literal)
  (system_lib_string)
  (char_literal)
] @string

(escape_sequence) @string.escape
((comment) @comment
  (#not-match? @comment "^/\\*\\*"))

((comment) @comment.doc
  (#match? @comment.doc "^/\\*\\*"))
(number_literal) @number
(null) @constant.builtin

(call_expression
  function: (identifier) @function)

(call_expression
  function: (field_expression
    field: (field_identifier) @function))

(function_declarator
  declarator: (identifier) @function)

(preproc_function_def
  name: (identifier) @function.special)

(field_identifier) @property
(statement_identifier) @label

[
  (type_identifier)
  (primitive_type)
  (sized_type_specifier)
] @type

; Objective-C preprocessing and imports.

(preproc_undef
  name: (_) @constant) @preproc

(module_import
  "@import" @preproc
  path: (identifier) @type)

((preproc_include
  _ @preproc
  path: (_))
  (#any-of? @preproc "#include" "#import"))

; Objective-C declarations and control flow.

[
  "@protocol"
  "@interface"
  "@implementation"
  "@compatibility_alias"
  "@property"
  "@selector"
  "@encode"
  "@defs"
  "@end"
] @keyword

(class_declaration
  "@" @keyword
  "class" @keyword)

[
  "@optional"
  "@required"
  "__covariant"
  "__contravariant"
  (visibility_specification)
  (protocol_qualifier)
] @keyword

[
  "@autoreleasepool"
  "@synchronized"
  "@synthesize"
  "@dynamic"
  "oneway"
] @keyword.control

[
  "@try"
  "__try"
  "@catch"
  "__catch"
  "@finally"
  "__finally"
  "@throw"
] @keyword.control

[
  "__typeof__"
  "__typeof"
  "typeof"
  "in"
] @keyword

(method_definition ["+" "-"] @keyword)
(method_declaration ["+" "-"] @keyword)

; Objective-C names, selectors, and messages.

((identifier) @variable.special
  (#any-of? @variable.special "self" "super"))

(method_definition
  (identifier) @function)

(method_declaration
  (identifier) @function)

(method_identifier
  (identifier)? @function
  ":" @punctuation.delimiter
  (identifier)? @function)

(message_expression
  method: (identifier) @function)

((message_expression
  receiver: (identifier) @type)
  (#match? @type "^[A-Z]"))

((message_expression
  method: (identifier) @constructor)
  (#eq? @constructor "init"))

(method_parameter
  ":" @punctuation.delimiter
  (identifier) @variable.parameter)

(method_parameter
  declarator: (identifier) @variable.parameter)

(parameter_declaration
  declarator: (identifier) @variable.parameter)

(parameter_declaration
  declarator: (pointer_declarator
    declarator: (identifier) @variable.parameter))

(parameter_declaration
  declarator: (function_declarator
    declarator: (parenthesized_declarator
      (block_pointer_declarator
        declarator: (identifier) @variable.parameter))))

; Objective-C types, properties, attributes, and literals.

(class_declaration
  (identifier) @type)

(class_interface
  "@interface" .
  (identifier) @type
  superclass: _? @type
  category: _? @type)

(class_implementation
  "@implementation" .
  (identifier) @type
  superclass: _? @type
  category: _? @type)

(protocol_forward_declaration
  (identifier) @type)

(protocol_declaration
  (identifier) @type)

(protocol_reference_list
  (identifier) @type)

[
  "BOOL"
  "IMP"
  "SEL"
  "Class"
  "id"
] @type.builtin

(property_attribute .
  (identifier) @attribute)

(property_attribute .
  (identifier) @attribute
  (identifier) @function)

(property_declaration
  (struct_declaration
    (struct_declarator
      (identifier) @property)))

(property_declaration
  (struct_declaration
    (struct_declarator
      (pointer_declarator
        declarator: (identifier) @property))))

(property_implementation
  "@synthesize"
  (identifier) @property)

(availability_attribute_specifier) @attribute

((identifier) @constant.builtin
  (#any-of? @constant.builtin "nil" "Nil"))

((identifier) @boolean
  (#any-of? @boolean "YES" "NO"))

(type_qualifier
  [
    "_Complex"
    "_Nonnull"
    "_Nullable"
    "_Nullable_result"
    "_Null_unspecified"
    "__autoreleasing"
    "__block"
    "__bridge"
    "__bridge_retained"
    "__bridge_transfer"
    "__complex"
    "__kindof"
    "__nonnull"
    "__nullable"
    "__strong"
    "__unsafe_unretained"
    "__unused"
    "__weak"
  ]) @attribute

[
  "objc_bridge_related"
  "@available"
  "__builtin_available"
  "va_arg"
  "asm"
] @function.special

(block_literal
  (parameter_list
    (parameter_declaration
      declarator: (identifier) @variable.parameter)))

(platform) @string.special
(version_number) @number
"@" @punctuation.special
