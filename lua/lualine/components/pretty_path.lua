local utils = require("lualine-pretty-path.utils")
local lualine_require = require("lualine_require")
local M = lualine_require.require("lualine.component"):extend()

local default_options = {
    icon_show = true,
    use_color = true,
    path_sep = "",
    file_status = true,
    unnamed = "[No Name]",
    symbols = {
        modified = "",
        readonly = "",
        ellipsis = "…",
    },
    directories = {
        enable = true,
        shorten = true,
        exclude_filetypes = { "help" },
        use_absolute = false,
        max_depth = 2,
    },
    terminals = {
        show_pid = true,
        show_term_id = true,
    },
    highlights = {
        directory = "",
        filename = "Bold",
        modified = "MatchParen",
        path_sep = "",
        pid = "Comment",
        symbols = "",
        term = "Bold",
        toggleterm_id = "Number",
        unnamed = "",
    },
    hooks = {
        on_shorten_dir = nil,
        on_fmt_filename = nil,
        on_fmt_terminal = nil,
        on_fmt_directory = nil,
    },
    icon_padding = {
        [""] = 1,
    },
}

function M:init(options)
    M.super.init(self, options)
    self.options = vim.tbl_deep_extend("keep", self.options or {}, default_options)
    if self.options.symbols.modified == "" then
        self.options.symbols.modified = nil
    end
    if self.options.symbols.readonly == "" then
        self.options.symbols.readonly = nil
    end
    if self.options.path_sep == "" then
        self.options.path_sep = utils.path_sep
    end

    -- unset invalid hooks
    for key, hook in pairs(self.options.hooks) do
        if type(hook) ~= "function" then
            self.options.hooks[key] = nil
        end
    end

    -- create highlight groups
    for key, hl in pairs(self.options.highlights) do
        if type(hl) == "table" then
            local name = "PrettyPath_" .. key
            vim.api.nvim_set_hl(0, name, hl)
            self.options.highlights[key] = name
        end
    end
end

function M:update_status()
    local s = self.options.directories.use_absolute and ":p" or ":~:."
    local info = utils.parse_path(vim.fn.expand("%"), s)
    if info.is_unnamed then
        info.parts = { self.options.unnamed or "" }
    end

    self:_set_icon(info)
    local name = self:_get_name(info)
    local symbols = self:_get_symbols(info)
    local dir = self:_get_dir(info)

    return dir .. name .. symbols
end

---@private
---@param text string
---@param hl_group? string
---@return string
function M:_hl(text, hl_group)
    if not self.options.use_color then
        return text
    end
    return utils.lualine_format_hl(self, text, hl_group)
end

---Updates the component icon based on the current path information.
---@private
---@param info BufferInfo
function M:_set_icon(info)
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok or not self.options.icon_show then
        self.options.icon = nil
        return
    end

    local icon, hl
    if info.is_unnamed then
        icon = nil
    elseif info.is_term then
        icon = devicons.get_icon_by_filetype("terminal")
    else
        icon, hl = devicons.get_icon(vim.fn.expand("%:t"))
    end

    if icon then
        local padding = self.options.icon_padding[icon] or 0
        if padding > 0 then
            icon = icon .. string.rep(" ", padding)
        end
        self.options.icon = self:_hl(icon, hl)
    else
        self.options.icon = nil
    end
end

---Returns a formatted filename for the given path information.
---@private
---@param info BufferInfo
---@return string
function M:_get_name(info)
    local items = {}
    local name = info.parts[#info.parts] or ""
    local pid = tostring(info.pid)
    local term_id = info.terminal and tostring(info.terminal.id)

    if info.is_term then
        if self.options.hooks.on_fmt_terminal then
            local tmp = self.options.hooks.on_fmt_terminal({
                name = name,
                path = info.path,
                pid = pid,
                term_id = term_id,
                term = info.terminal,
            })
            if type(tmp) == "table" and tmp.name then
                name = tmp.name
                pid = tmp.pid
                term_id = tmp.term_id
            end
        end
    else
        if self.options.hooks.on_fmt_filename then
            local tmp = self.options.hooks.on_fmt_filename(name)
            if type(tmp) == "string" then
                name = tmp
            end
        end
    end

    if vim.bo.modified then
        name = self:_hl(name, self.options.highlights.modified)
    elseif info.is_unnamed then
        name = self:_hl(name, self.options.highlights.unnamed)
    elseif info.terminal then
        name = self:_hl(name, self.options.highlights.term)
    else
        name = self:_hl(name, self.options.highlights.filename)
    end
    table.insert(items, name)

    if self.options.terminals.show_term_id and term_id then
        table.insert(items, self:_hl(term_id, self.options.highlights.toggleterm_id))
    end
    if self.options.terminals.show_pid and pid then
        table.insert(items, self:_hl(pid, self.options.highlights.pid))
    end

    return table.concat(items, " ")
end

---Returns a formatted symbols string based on the current buffer and path information.
---@private
---@param info BufferInfo
---@return string
function M:_get_symbols(info)
    local opts = self.options
    if not opts.file_status then
        return ""
    end

    local symbols = {}
    if not info.is_term and opts.file_status then
        if opts.symbols.modified and vim.bo.modified then
            table.insert(symbols, self:_hl(opts.symbols.modified, opts.highlights.symbols))
        end
        if opts.symbols.readonly and utils.is_readonly() then
            table.insert(symbols, self:_hl(opts.symbols.readonly, opts.highlights.symbols))
        end
    end

    if #symbols > 0 then
        return " " .. table.concat(symbols, " ")
    else
        return ""
    end
end

---Returns a formatted directory for the given path information.
---@private
---@param info BufferInfo
---@return string
function M:_get_dir(info)
    local opts = self.options
    local dir = ""
    if
        not opts.directories.enable
        or vim.tbl_contains(opts.directories.exclude_filetypes, vim.bo.filetype)
    then
        return dir
    end

    local slice = { unpack(info.parts, 1, #info.parts - 1) }
    if opts.directories.shorten and #slice > opts.directories.max_depth then
        local tmp
        if opts.hooks.on_shorten_dir then
            tmp = opts.hooks.on_shorten_dir(slice)
        end
        if type(tmp) ~= "table" then
            if #slice == 1 then
                tmp = slice
            elseif #slice == 2 then
                tmp = { slice[1], opts.symbols.ellipsis }
            else
                tmp = { slice[1], opts.symbols.ellipsis, slice[#slice] }
            end
        end
        slice = tmp
    end

    if #slice > 1 then
        local sep = opts.path_sep
        if #opts.highlights.path_sep > 0 then
            sep = self:_hl(sep, opts.highlights.path_sep)
        end
        local hl = opts.highlights.directory

        if opts.hooks.on_fmt_directory then
            local tmp = opts.hooks.on_fmt_directory(slice)
            if type(tmp) == "table" then
                slice = tmp
            end
        end
        dir = table.concat(slice, sep)
        dir = self:_hl(dir .. sep, hl)
    end

    return dir
end

return M
