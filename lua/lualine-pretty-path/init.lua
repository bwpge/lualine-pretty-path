local utils = require("lualine-pretty-path.utils")

local M = {}

---@param opts table
---@return table
function M.parse_path(opts)
    local path = vim.fn.expand("%:~:.")

    local sep = utils.path_sep
    local is_term = false
    local parts, pid, toggleterm_id
    if path:find("^term://") then
        local t = M.parse_term_path(path)
        is_term = true
        parts = { t.path }
        pid = t.pid
        toggleterm_id = t.toggleterm_id
    else
        parts = vim.split(path, sep)
    end

    if #parts > 3 then
        parts = { parts[1], "…", parts[#parts - 1], parts[#parts] }
    end

    local unnamed = false
    if parts[#parts] == "" then
        unnamed = true
        parts[#parts] = opts.symbols.unnamed
    end

    return {
        path = path,
        is_term = is_term,
        parts = parts,
        unnamed = unnamed,
        pid = pid,
        toggleterm_id = toggleterm_id,
    }
end

---Parses a `term://` path and returns its parts.
---@param path string
---@return { path: string, pid?: number, toggleterm_id?: number }
function M.parse_term_path(path)
    path = vim.split(path, "//")[3] or ""
    local pid = tonumber(path:match("^(%d+):"))
    local toggleterm_id = tonumber(path:match("::toggleterm::(%d+)"))
    path = path:gsub("^%d+:", ""):gsub("::toggleterm::%d+", "")

    if toggleterm_id then
        local term = utils.get_toggleterm_by_id(toggleterm_id)
        if term then
            path = term:_display_name() or ""
            path = path:gsub("::toggleterm::%d+", "")
        end
    end

    return {
        path = vim.fn.fnamemodify(path, ":t"),
        pid = pid,
        toggleterm_id = toggleterm_id,
    }
end

return M
