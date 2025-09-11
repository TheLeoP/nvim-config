(function_statement
  "function" @open.function)

(function_statement) @scope.function

(function_statement
  (script_block
    (script_block_body
      (statement_list
        (flow_control_statement
          "return" @mid.function.1))))) @scope.function
