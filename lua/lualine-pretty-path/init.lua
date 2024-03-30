local utils = require("lualine-pretty-path.utils")

local M = {}

---@class PathInfo
---@field path string
---@field is_unnamed boolean
---@field parts table
---@field is_term boolean
---@field pid? number
---@field toggleterm_id? number

---@class TermInfo
---@field name string
---@field pid? number
---@field toggleterm_id? number

---Parses the current buffer path and returns its details.
---@param opts table
---@return PathInfo
function M.parse_path(opts)
    local path = vim.fn.expand("%:~:.")

    local sep = utils.path_sep
    local is_term = false
    local parts, pid, toggleterm_id
    if path:find("^term://") then
        local t = M.parse_term_path(path)
        is_term = true
        parts = { t.name }
        pid = t.pid
        toggleterm_id = t.toggleterm_id
    else
        parts = vim.split(path, sep)
    end

    if #parts > 3 then
        parts = { parts[1], opts.symbols.ellipsis, parts[#parts - 1], parts[#parts] }
    end

    local is_unnamed = false
    if parts[#parts] == "" then
        is_unnamed = true
        parts[#parts] = opts.unnamed
    end

    return {
        path = path,
        is_term = is_term,
        parts = parts,
        is_unnamed = is_unnamed,
        pid = pid,
        toggleterm_id = toggleterm_id,
    }
end

---Parses a `term://` path and returns its parts.
---@param path string
---@return TermInfo
function M.parse_term_path(path)
    path = vim.split(path, "//")[3] or ""
    local pid = tonumber(path:match("^(%d+):"))
    local toggleterm_id = tonumber(path:match("::toggleterm::(%d+)"))

    if toggleterm_id then
        local term = utils.get_toggleterm_by_id(toggleterm_id)
        if term then
            path = term:_display_name() or ""
            path = path:gsub("::toggleterm::%d+$", "")
        end
    else
        path = path:gsub("^%d+:", ""):gsub("::toggleterm::%d+", "")
    end

    return {
        name = vim.fn.fnamemodify(path, ":t"),
        pid = pid,
        toggleterm_id = toggleterm_id,
    }
end

return M
