local pretty_path = require("lualine-pretty-path")
local utils = require("lualine-pretty-path.utils")
local lualine_require = require("lualine_require")
local M = lualine_require.require("lualine.component"):extend()

local default_options = {
    icon_show = true,
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
        on_fmt_directory = nil,
        on_fmt_pid = nil,
        on_fmt_term_id = nil,
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
    local p = pretty_path.parse_path(vim.fn.expand("%"), s)
    if p.is_unnamed then
        p.parts = { self.options.unnamed or "" }
    end

    self:_set_icon(p)
    local name = self:_get_name(p)
    local symbols = self:_get_symbols(p)
    local dir = self:_get_dir(p)

    return dir .. name .. symbols
end

---@private
---@param text string
---@param hl_group? string
---@return string
function M:_hl(text, hl_group)
    return utils.lualine_format_hl(self, text, hl_group)
end

---Updates the component icon based on the current path information.
---@private
---@param p PathInfo
function M:_set_icon(p)
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok or not self.options.icon_show then
        self.options.icon = nil
        return
    end

    local icon, hl
    if p.is_unnamed then
        icon = nil
    elseif p.is_term then
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
---@param p PathInfo
---@return string
function M:_get_name(p)
    local name = p.parts[#p.parts] or ""
    if self.options.hooks.on_fmt_filename then
        name = self.options.hooks.on_fmt_filename(name)
    end

    if vim.bo.modified then
        name = self:_hl(name, self.options.highlights.modified)
    elseif p.is_unnamed then
        name = self:_hl(name, self.options.highlights.unnamed)
    elseif p.is_term then
        name = self:_hl(name, self.options.highlights.term)
    else
        name = self:_hl(name, self.options.highlights.filename)
    end

    return name
end

---Returns a formatted symbols string based on the current buffer and path information.
---@private
---@param p PathInfo
---@return string
function M:_get_symbols(p)
    local opts = self.options
    local symbols = {}

    if p.is_term then
        if opts.terminals.show_term_id and p.toggleterm_id then
            local tid = utils.fmt_number(p.toggleterm_id, opts.hooks.on_fmt_term_id)
            table.insert(symbols, self:_hl(tid, opts.highlights.toggleterm_id))
        end
        if opts.terminals.show_pid and p.pid then
            local pid = utils.fmt_number(p.pid, opts.hooks.on_fmt_pid)
            table.insert(symbols, self:_hl(pid, opts.highlights.pid))
        end
    elseif opts.file_status then
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
---@param p PathInfo
---@return string
function M:_get_dir(p)
    local opts = self.options
    local dir = ""
    if
        not opts.directories.enable
        or vim.tbl_contains(opts.directories.exclude_filetypes, vim.bo.filetype)
    then
        return dir
    end

    local slice = { unpack(p.parts, 1, #p.parts - 1) }
    if opts.directories.shorten and #slice > opts.directories.max_depth then
        local tmp = nil
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
