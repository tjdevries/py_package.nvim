package.loaded['py_package'] = nil

local vim = vim

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local py_package = {}

function py_package.find(mod_name)
  return vim.fn.fnamemodify(
    vim.split(
      vim.fn.system(string.format('python -c "import %s; print(%s.__file__)"', mod_name, mod_name)),
      "\n"
    )[1],
    ":p:h"
  )
end

-- function py_package.many_find(mod_list)
--   local joined_strings = table.concat(mod_list, ", ")
--   local file_strings = {}
--   for _, mod in ipairs(mod_list) do
--     table.insert(file_strings, string.format("print(%s.__file__)", mod))
--   end

--   return  vim.fn.system(
--         string.format(
--           'python -c "import %s; %s"',
--           joined_strings,
--           table.concat(file_strings, "; ")
--         )
--       )
-- end

function py_package.list_possible_modules()
  if py_package._possible_matches == nil then

    local raw_json = vim.fn.system("pip list --verbose --format json")
    local options = vim.fn.json_decode(raw_json)

    py_package._possible_matches = {}
    py_package._files = {}
    py_package._name_to_file = {}
    for _, dict in ipairs(options) do
      local name = dict["name"]

      table.insert(py_package._possible_matches, name)
      table.insert(py_package._files, dict["location"] .. "/" .. name)
      py_package._name_to_file[name] = dict["location"] .. "/" .. name
    end
  end

  return py_package._possible_matches
end

function py_package.command_complete(arg_lead, cmd_line, cursor_pos)
  local possible_matches = py_package.list_possible_modules()

  local result = {}
  for _, possible in ipairs(possible_matches) do
    if starts_with(possible, arg_lead) then
      table.insert(result, possible)
    end
  end

  return result
end

function py_package.fancy_complete()
  vim.fn["fzf_preview#window#create_centered_floating_window"]()
end

function py_package.fzf_preview_modules()
  -- side effects...
  py_package.list_possible_modules()

  return py_package._files
end

function py_package.transform_mod_name(mod_name)
  local mod_location = py_package._name_to_file[mod_name]

  local potential_py = mod_location .. '.py'

  if vim.fn.isdirectory(mod_location) then
    local init_py = mod_location .. "/__init__.py"
    if vim.fn.filereadable(init_py) then
      return init_py
    end

    return mod_location
  end

  if vim.fn.filereadable(potential_py) then
    return potential_py
  end

  return mod_location
end

return py_package
