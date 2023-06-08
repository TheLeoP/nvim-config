;; extends
(call_expression
  (selector_expression field:
                       (field_identifier) @_function (#any-of? @_function
                                                      "QueryRowContext"
                                                      "QueryRow"
                                                      "Query"
                                                      "QueryContext"
                                                      "Prepare"
                                                      "PrepareContext"
                                                      "Exec"
                                                      "ExecContext"
                                                      ))
  (argument_list
    [(raw_string_literal) (interpreted_string_literal)] @sql (#offset! @sql 0 1 0 -1))
  )
