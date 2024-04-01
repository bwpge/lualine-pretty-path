local M = {}

---@class BufferInfo
---@field path string
---@field parts string[]
---@field is_unnamed boolean
---@field is_term boolean
---@field pid? number
---@field terminal? table

---@alias TermInfo { name: string, pid?: number, terminal?: table }

M.path_sep = package.config:sub(1, 1)

function M.is_readonly()
    return vim.bo.modifiable == false or vim.bo.readonly == true
end

---Returns a toggleterm `Terminal` if the given `id` exists and is not hidden.
---@param tid number?
---@return any
function M.get_toggleterm_by_id(tid)
    if not tid or not package.loaded["toggleterm"] then
        return
    end

    return require("toggleterm.terminal").get(tid)
end

---Formats a lualine component with a highlight group.
---@param component any
---@param text string
---@param hl_group? string
---@return string
function M.lualine_format_hl(component, text, hl_group)
    if not hl_group or hl_group == "" or text == "" then
        return text
    end

    ---@type table<string, string>
    component.hl_cache = component.hl_cache or {}
    local lualine_hl_group = component.hl_cache[hl_group]
    if not lualine_hl_group then
        local u = require("lualine.utils.utils")
        ---@type string[]
        local gui = vim.tbl_filter(function(x)
            return x
        end, {
            u.extract_highlight_colors(hl_group, "bold") and "bold",
            u.extract_highlight_colors(hl_group, "italic") and "italic",
        })

        lualine_hl_group = component:create_hl({
            fg = u.extract_highlight_colors(hl_group, "fg"),
            gui = #gui > 0 and table.concat(gui, ",") or nil,
        }, hl_group) --[[@as string]]
        component.hl_cache[hl_group] = lualine_hl_group
    end

    return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

---Formats a number with a hook or fallback function.
---@param value number
---@param hook fun(id: number): string
---@return string
function M.fmt_number(value, hook)
    local s = hook(value)
    if type(s) ~= "string" then
        return tostring(value)
    end
    return s
end

---Parses the `fname` with the given `mods` and returns `PathInfo`.
---@param fname string The filename (default: `vim.fn.expand("%")`)
---@param mods string? Modifiers passed to fnamemodify (e.g., `:~:.`)
---@return BufferInfo
function M.parse_path(fname, mods)
    -- avoid expanding an empty filename
    local path = #fname > 0 and vim.fn.fnamemodify(fname, mods) or ""
    local is_term = false
    local parts, pid, terminal = nil, nil, nil

    if path:find("^term://") then
        local t = M.parse_term_path(path)
        is_term = true
        parts = { t.name }
        pid = t.pid
        terminal = t.terminal
    else
        parts = vim.split(path, M.path_sep, { trimempty = true })
    end

    local is_unnamed = #parts == 0
    return {
        path = path,
        parts = parts,
        is_unnamed = is_unnamed,
        is_term = is_term,
        pid = pid,
        terminal = terminal,
    }
end

---Parses a `term://` path and returns its parts.
---@param path string
---@return TermInfo
function M.parse_term_path(path)
    path = vim.split(path, "//")[3] or ""
    local pid = tonumber(path:match("^(%d+):"))
    local toggleterm_id = tonumber(path:match("::toggleterm::(%d+)"))
    local terminal = nil

    if toggleterm_id then
        terminal = M.get_toggleterm_by_id(toggleterm_id)
        if terminal then
            path = terminal:_display_name() or ""
            path = path:gsub("::toggleterm::%d+$", ""):gsub("[&;]$", "")
        end
    else
        path = path:gsub("^%d+:", "")
    end

    return {
        name = vim.fn.fnamemodify(path, ":t"),
        pid = pid,
        terminal = terminal,
    }
end
return M
