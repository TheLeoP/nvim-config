---@type vim.lsp.Config
return {
  settings = {
    parser_install_directories = {
      vim.fn.stdpath "data" .. "/site/parser",
    },
    valid_captures = {
      highlights = {
        variable = "various variable names",
        ["variable.builtin"] = "built-in variable names (e.g. `this`)",
        ["variable.parameter"] = "parameters of a function",
        ["variable.parameter.builtin"] = "special parameters (e.g. `_`, `it`)",
        ["variable.member"] = "object and struct fields",

        constant = "constant identifiers",
        ["constant.builtin"] = "built-in constant values",
        ["constant.macro"] = "constants defined by the preprocessor",

        module = "modules or namespaces",
        ["module.builtin"] = "built-in modules or namespaces",
        label = "GOTO and other labels (e.g. `label:` in C), including heredoc labels",

        string = "string literals",
        ["string.documentation"] = "string documenting code (e.g. Python docstrings)",
        ["string.regexp"] = "regular expressions",
        ["string.escape"] = "escape sequences",
        ["string.special"] = "other special strings (e.g. dates)",
        ["string.special.symbol"] = "symbols or atoms",
        ["string.special.url"] = "URIs (e.g. hyperlinks)",
        ["string.special.path"] = "filenames",

        character = "character literals",
        ["character.special"] = "special characters (e.g. wildcards)",

        boolean = "boolean literals",
        number = "numeric literals",
        ["number.float"] = "floating-point number literals",

        type = "type or class definitions and annotations",
        ["type.builtin"] = "built-in types",
        ["type.definition"] = "identifiers in type definitions (e.g. `typedef <type> <identifier>` in C)",

        attribute = "attribute annotations (e.g. Python decorators, Rust lifetimes)",
        ["attribute.builtin"] = "builtin annotations (e.g. `@property` in Python)",
        property = "the key in key/value pairs",

        ["function"] = "function definitions",
        ["function.builtin"] = "built-in functions",
        ["function.call"] = "function calls",
        ["function.macro"] = "preprocessor macros",

        ["function.method"] = "method definitions",
        ["function.method.call"] = "method calls",

        constructor = "constructor calls and definitions",
        operator = "symbolic operators (e.g. `+` / `*`)",

        keyword = "keywords not fitting into specific categories",
        ["keyword.coroutine"] = "keywords related to coroutines (e.g. `go` in Go, `async/await` in Python)",
        ["keyword.function"] = "keywords that define a function (e.g. `func` in Go, `def` in Python)",
        ["keyword.operator"] = "operators that are English words (e.g. `and` / `or`)",
        ["keyword.import"] = "keywords for including or exporting modules (e.g. `import` / `from` in Python)",
        ["keyword.type"] = "keywords describing namespaces and composite types (e.g. `struct`, `enum`)",
        ["keyword.modifier"] = "keywords modifying other constructs (e.g. `const`, `static`, `public`)",
        ["keyword.repeat"] = "keywords related to loops (e.g. `for` / `while`)",
        ["keyword.return"] = "keywords like `return` and `yield`",
        ["keyword.debug"] = "keywords related to debugging",
        ["keyword.exception"] = "keywords related to exceptions (e.g. `throw` / `catch`)",
        ["keyword.conditional"] = "keywords related to conditionals (e.g. `if` / `else`)",
        ["keyword.conditional.ternary"] = "ternary operator (e.g. `?` / `:`)",
        ["keyword.directive"] = "various preprocessor directives & shebangs",
        ["keyword.directive.define"] = "preprocessor definition directives",

        ["punctuation.delimiter"] = "delimiters (e.g. `;` / `.` / `,`)",
        ["punctuation.bracket"] = "brackets (e.g. `()` / `{}` / `[]`)",
        ["punctuation.special"] = "special symbols (e.g. `{}` in string interpolation)",

        comment = "line and block comments",
        ["comment.documentation"] = "comments documenting code",
        ["comment.error"] = "error-type comments (e.g. `ERROR`, `FIXME`, `DEPRECATED`)",
        ["comment.warning"] = "warning-type comments (e.g. `WARNING`, `FIX`, `HACK`)",
        ["comment.todo"] = "todo-type comments (e.g. `TODO`, `WIP`)",
        ["comment.note"] = "note-type comments (e.g. `NOTE`, `INFO`, `XXX`)",

        ["markup.strong"] = "bold text",
        ["markup.italic"] = "italic text",
        ["markup.strikethrough"] = "struck-through text",
        ["markup.underline"] = "underlined text (only for literal underline markup!)",
        ["markup.heading"] = "headings, titles (including markers)",
        ["markup.heading.1"] = "top-level heading",
        ["markup.heading.2"] = "section heading",
        ["markup.heading.3"] = "subsection heading",
        ["markup.heading.4"] = "and so on",
        ["markup.heading.5"] = "and so forth",
        ["markup.heading.6"] = "six levels ought to be enough for anybody",
        ["markup.quote"] = "block quotes",
        ["markup.math"] = "math environments (e.g. `$ ... $` in LaTeX)",
        ["markup.link"] = "text references, footnotes, citations, etc.",
        ["markup.link.label"] = "link, reference descriptions",
        ["markup.link.url"] = "URL-style links",
        ["markup.raw"] = "literal or verbatim text (e.g. inline code)",
        ["markup.raw.block"] = "literal or verbatim text as a stand-alone block ; (use priority 90 for blocks with injections)",
        ["markup.list"] = "list markers",
        ["markup.list.checked"] = "checked todo-style list markers",
        ["markup.list.unchecked"] = "unchecked todo-style list markers",

        ["diff.plus"] = "added text (for diff files)",
        ["diff.minus"] = "deleted text (for diff files)",
        ["diff.delta"] = "changed text (for diff files)",

        tag = "XML-style tag names (and similar)",
        ["tag.builtin"] = "builtin tag names (e.g. HTML5 tags)",
        ["tag.attribute"] = "XML-style tag attributes",
        ["tag.delimiter"] = "XML-style tag delimiters",

        conceal = "captures that are only meant to be concealed",
        spell = "for defining regions to be spellchecked",
        nospell = "for defining regions that should NOT be spellchecked",
        none = "completely disable the highlight",
      },
      injections = {
        ["injection.content"] = "indicates that the captured node should have its contents re-parsed using another language",
        ["injection.language"] = "indicates that the captured node’s text may contain the name of a language that should be used to re-parse the `@injection.content`",
        ["injection.filename"] = "indicates that the captured node’s text may contain a filename; the corresponding filetype is then looked-up up via `vim.filetype.match()` and treated as the name of a language that should be used to re-parse the `@injection.content`",
      },
      folds = {
        fold = "fold this node",
      },
      indents = {
        ["indent.begin"] = "Specifies that the next line should be indented.  Multiple indents on the same line get collapsed. Indent can also have `indent.immediate` set using a `#set!` directive, which permits the next line to indent even when the block intended to be indented has no content yet, improving interactive typing.",
        ["indent.end"] = "Used to specify that the indented region ends and any text subsequent to the capture should be dedented.",
        ["indent.align"] = "Specifies aligned indent blocks (like python aligned/hanging indent). Specify the delimiters with `indent.open_delimiter` and `indent.close_delimiter` metadata. For some languages, the last line of an `indent.align` block must not be the same indent as the natural next line, which can be controlled by setting `indent.avoid_last_matching_next`.",
        ["indent.dedent"] = "Specifies dedenting starting on the next line.",
        ["indent.branch"] = "Used to specify that a dedented region starts at the line including the captured nodes.",
        ["indent.ignore"] = "Specifies that indentation should be ignored for this node.",
        ["indent.auto"] = "Behaves like 'autoindent' buffer option.",
        ["indent.zero"] = "Sets indentation for this node to zero (no indentation).",
      },
      locals = {
        ["local.definition"] = "various definitions",
        ["local.definition.constant"] = "constants",
        ["local.definition.function"] = "functions",
        ["local.definition.method"] = "methods",
        ["local.definition.var"] = "variables",
        ["local.definition.parameter"] = "parameters",
        ["local.definition.macro"] = "preprocessor macros",
        ["local.definition.type"] = "types or classes",
        ["local.definition.field"] = "fields or properties",
        ["local.definition.enum"] = "enumerations",
        ["local.definition.namespace"] = "modules or namespaces",
        ["local.definition.import"] = "imported names",
        ["local.definition.associated"] = "the associated type of a variable",
        ["local.scope"] = "scope block",
        ["local.reference"] = "identifier reference",
      },
    },
    valid_predicates = {
      eq = {
        any = true,
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "any",
            arity = "required",
          },
        },
        description = "Checks for equality between two nodes, or a node and a string",
      },
      ["any-of"] = {
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
          {
            type = "string",
            arity = "variadic",
          },
        },
        description = "Match any of the given strings against the text corresponding to a node",
      },
      contains = {
        any = true,
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
          {
            type = "string",
            arity = "variadic",
          },
        },
        description = "Match a string against parts of the text corresponding to a node",
      },
      match = {
        any = true,
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
        },
        description = "Match a regexp against the text corresponding to a node",
      },
      ["lua-match"] = {
        any = true,
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
        },
        description = "Match a Lua pattern against the text corresponding to a node",
      },
      ["has-ancestor"] = {
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
          {
            type = "string",
            arity = "variadic",
          },
        },
        description = "Match any of the given node types against all ancestors of a node",
      },
      ["has-parent"] = {
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "any",
            arity = "required",
          },
          {
            type = "any",
            arity = "variadic",
          },
        },
        description = "Match any of the given node types against the direct ancestor of a node",
      },
    },
    valid_directives = {
      set = {
        parameters = {
          {
            type = "any",
            arity = "required",
          },
          {
            type = "any",
            arity = "optional",
          },
          {
            type = "any",
            arity = "optional",
          },
        },
        description = "Sets key/value metadata for a specific match or capture",
      },
      offset = {
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
        },
        description = "Takes the range of the captured node and applies an offset. This will set a new range in the form of a list like { {start_row}, {start_col}, {end_row}, {end_col} } for the captured node with `capture_id` as `metadata[capture_id].range`.",
      },
      gsub = {
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
          {
            type = "string",
            arity = "required",
          },
        },
        description = "Transforms the content of the node using a Lua pattern. This will set a new `metadata[capture_id].text`.",
      },
      trim = {
        parameters = {
          {
            type = "capture",
            arity = "required",
          },
          {
            type = "string",
            arity = "optional",
          },
          {
            type = "string",
            arity = "optional",
          },
          {
            type = "string",
            arity = "optional",
          },
          {
            type = "string",
            arity = "optional",
          },
        },
        description = "Trims whitespace from the node. Sets a new `metadata[capture_id].range`. Takes a capture ID and, optionally, four integers to customize trimming behavior (`1` meaning trim, `0` meaning don't trim). When only given a capture ID, trims blank lines (lines that contain only whitespace, or are empty) from the end of the node (for backwards compatibility). Can trim all whitespace from both sides of the node if parameters are given.",
      },
    },
  },
}
