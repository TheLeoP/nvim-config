local keymap = vim.keymap

---@param node TSNode
---@return TSNode[] nodes
local extract_from_var = function(node)
  local nodes_utils = require "neogen.utilities.nodes"
  local tree = {
    {
      retrieve = "first",
      node_type = "assignment_statement",
      subtree = {
        {
          retrieve = "first",
          node_type = "variable_list",
          subtree = {
            { retrieve = "all", node_type = "identifier", extract = true },
          },
        },
      },
    },
    {
      position = 2,
      extract = true,
    },
  }
  local nodes = nodes_utils:matching_nodes_from(node, tree)
  return nodes
end

return {
  "danymat/neogen",
  opts = function()
    local i = require("neogen.types.template").item
    local extractors = require "neogen.utilities.extractors"
    return {
      placeholders_hl = "None",
      snippet_engine = "luasnip",
      languages = {
        lua = {
          parent = {
            type = { "local_variable_declaration", "variable_declaration", "field" },
          },
          data = {
            type = {
              ["field"] = {
                ["0"] = {
                  ---@param node TSNode
                  ---@return table
                  extract = function(node)
                    local result = {} ---@type table<string, table>
                    result[i.Type] = {}

                    local nodes = extract_from_var(node)
                    local res = extractors:extract_from_matched(nodes, { type = true })

                    -- We asked the extract_from_var function to find the type node at right assignment.
                    -- We check if it found it, or else will put `any` in the type
                    if res["_"] then
                      vim.list_extend(result[i.Type], res["_"])
                    else
                      if res.identifier or res.field_expression then vim.list_extend(result[i.Type], { "any" }) end
                    end
                    return result
                  end,
                },
              },
            },
          },
          template = {
            annotation_convention = "luacat",
            luacat = {
              -- { nil, "- $1", { type = { "class", "func" } } }, -- Do not add 'description' above func and class
              { nil, "- $1", { no_results = true, type = { "class", "func" } } },
              { nil, "-@module $1", { no_results = true, type = { "file" } } },
              { nil, "-@author $1", { no_results = true, type = { "file" } } },
              { nil, "-@license $1", { no_results = true, type = { "file" } } },
              { nil, "", { no_results = true, type = { "file" } } },

              { i.Parameter, "-@param %s $1|any" },
              { i.Vararg, "-@param ... $1|any" },
              { i.Return, "-@return $1|any" },
              { i.ClassName, "-@class $1|any" },
              { i.Type, "-@type $1" },
            },
          },
        },
      },
    }
  end,
  config = function(_, opts)
    require("neogen").setup(opts)
    keymap.set("n", "<leader>gf", "<cmd>Neogen func<cr>")
    keymap.set("n", "<leader>gF", "<cmd>Neogen file<cr>")
    keymap.set("n", "<leader>gc", "<cmd>Neogen class<cr>")
    keymap.set("n", "<leader>gt", "<cmd>Neogen type<cr>")
  end,
}
