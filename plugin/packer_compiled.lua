-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

  local time
  local profile_info
  local should_profile = false
  if should_profile then
    local hrtime = vim.loop.hrtime
    profile_info = {}
    time = function(chunk, start)
      if start then
        profile_info[chunk] = hrtime()
      else
        profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
      end
    end
  else
    time = function(chunk, start) end
  end
  
local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end

  _G._packer = _G._packer or {}
  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "C:\\Users\\pcx\\AppData\\Local\\Temp\\nvim\\packer_hererocks\\2.1.0-beta3\\share\\lua\\5.1\\?.lua;C:\\Users\\pcx\\AppData\\Local\\Temp\\nvim\\packer_hererocks\\2.1.0-beta3\\share\\lua\\5.1\\?\\init.lua;C:\\Users\\pcx\\AppData\\Local\\Temp\\nvim\\packer_hererocks\\2.1.0-beta3\\lib\\luarocks\\rocks-5.1\\?.lua;C:\\Users\\pcx\\AppData\\Local\\Temp\\nvim\\packer_hererocks\\2.1.0-beta3\\lib\\luarocks\\rocks-5.1\\?\\init.lua"
local install_cpath_pattern = "C:\\Users\\pcx\\AppData\\Local\\Temp\\nvim\\packer_hererocks\\2.1.0-beta3\\lib\\lua\\5.1\\?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s))
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  ReplaceWithRegister = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\ReplaceWithRegister"
  },
  ["colorbuddy.vim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\colorbuddy.vim"
  },
  ["gruvbuddy.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\gruvbuddy.nvim"
  },
  ["lightline.vim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\lightline.vim"
  },
  ["lsp_signature.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\lsp_signature.nvim"
  },
  ["lspsaga.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\lspsaga.nvim"
  },
  ["nvim-compe"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\nvim-compe"
  },
  ["nvim-jdtls"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\nvim-jdtls"
  },
  ["nvim-lspconfig"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\nvim-lspconfig"
  },
  ["nvim-treesitter"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\nvim-treesitter"
  },
  ["nvim-treesitter-textobjects"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\nvim-treesitter-textobjects"
  },
  ["nvim-web-devicons"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\nvim-web-devicons"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\plenary.nvim"
  },
  ["popup.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\popup.nvim"
  },
  ["telescope-fzf-native.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\telescope-fzf-native.nvim"
  },
  ["telescope.nvim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\telescope.nvim"
  },
  ultisnips = {
    after_files = { "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\opt\\ultisnips\\after\\plugin\\UltiSnips_after.vim" },
    loaded = false,
    needs_bufread = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\opt\\ultisnips"
  },
  ["vim-commentary"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-commentary"
  },
  ["vim-dispatch"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-dispatch"
  },
  ["vim-dispatch-neovim"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-dispatch-neovim"
  },
  ["vim-fugitive"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-fugitive"
  },
  ["vim-illuminate"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-illuminate"
  },
  ["vim-indent-object"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-indent-object"
  },
  ["vim-polyglot"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-polyglot"
  },
  ["vim-repeat"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-repeat"
  },
  ["vim-rhubarb"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-rhubarb"
  },
  ["vim-snippets"] = {
    loaded = false,
    needs_bufread = false,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\opt\\vim-snippets"
  },
  ["vim-surround"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-surround"
  },
  ["vim-test"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-test"
  },
  ["vim-textobj-line"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-textobj-line"
  },
  ["vim-textobj-user"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-textobj-user"
  },
  ["vim-vinegar"] = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vim-vinegar"
  },
  vimspector = {
    loaded = true,
    path = "C:\\Users\\pcx\\AppData\\Local\\nvim-data\\site\\pack\\packer\\start\\vimspector"
  }
}

time([[Defining packer_plugins]], false)
vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time([[Defining lazy-load filetype autocommands]], true)
vim.cmd [[au FileType java ++once lua require("packer.load")({'vim-snippets', 'ultisnips'}, { ft = "java" }, _G.packer_plugins)]]
time([[Defining lazy-load filetype autocommands]], false)
vim.cmd("augroup END")
vim.cmd [[augroup filetypedetect]]
time([[Sourcing ftdetect script at: C:\Users\pcx\AppData\Local\nvim-data\site\pack\packer\opt\ultisnips\ftdetect\snippets.vim]], true)
vim.cmd [[source C:\Users\pcx\AppData\Local\nvim-data\site\pack\packer\opt\ultisnips\ftdetect\snippets.vim]]
time([[Sourcing ftdetect script at: C:\Users\pcx\AppData\Local\nvim-data\site\pack\packer\opt\ultisnips\ftdetect\snippets.vim]], false)
vim.cmd("augroup END")
if should_profile then save_profiles() end

end)

if not no_errors then
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
