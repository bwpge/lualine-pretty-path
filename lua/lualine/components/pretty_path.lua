local pretty_path = require("lualine-pretty-path")
local utils = require("lualine-pretty-path.utils")
local lualine_require = require("lualine_require")
local M = lualine_require.require("lualine.component"):extend()

local default_options = {
    visual_path_sep = "",
    file_status = true,
    symbols = {
        modified = "",
        readonly = "",
        unnamed = "[No Name]",
    },
    term = {
        show_pid = true,
        show_toggleterm_id = true,
        pid_fmt = tostring,
        toggleterm_id_fmt = tostring,
    },
    highlights = {
        directory = "",
        file = "Bold",
        modified = "MatchParen",
        pid = "Comment",
        symbols = "",
        term = "",
        toggleterm_id = "Number",
        unnamed = "",
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
    if self.options.visual_path_sep == "" then
        self.options.visual_path_sep = utils.path_sep
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
    local p = pretty_path.parse_path(self.options)

    self:_set_icon(p)
    local name = self:_get_name(p)
    local symbols = self:_get_symbols(p)
    local dir = self:_get_dir(p)

    return dir .. name .. symbols
end

---Updates the component icon based on the current path information.
---@param p PathInfo
function M:_set_icon(p)
    local _, devicons = pcall(require, "nvim-web-devicons")
    if devicons then
        local icon, hl
        if p.is_unnamed then
            icon = nil
        elseif p.is_term then
            icon = devicons.get_icon_by_filetype("terminal")
            if icon then
                icon = icon .. " "
            end
        else
            icon, hl = devicons.get_icon(vim.fn.expand("%:t"))
        end

        if icon then
            self.options.icon = utils.lualine_format_hl(self, icon, hl)
        else
            self.options.icon = nil
        end
    end
end

---Returns a formatted filename for the given path information.
---@param p PathInfo
---@return string
function M:_get_name(p)
    local name = p.parts[#p.parts]
    if vim.bo.modified then
        name = utils.lualine_format_hl(self, name, self.options.highlights.modified)
    elseif p.is_unnamed then
        name = utils.lualine_format_hl(self, name, self.options.highlights.unnamed)
    else
        name = utils.lualine_format_hl(self, name, self.options.highlights.file)
    end

    return name
end

---Returns a formatted symbols string based on the current buffer and path information.
---@param p PathInfo
---@return string
function M:_get_symbols(p)
    local opts = self.options
    local symbols = {}

    if p.is_term then
        -- toggleterm id
        if opts.term.show_toggleterm_id and p.toggleterm_id then
            local tid = opts.term.toggleterm_id_fmt(p.toggleterm_id)
            if tid then
                table.insert(
                    symbols,
                    utils.lualine_format_hl(self, tid, opts.highlights.toggleterm_id)
                )
            end
        end
        -- terminal pid
        if opts.term.show_pid and p.pid then
            local pid = opts.term.pid_fmt(p.pid)
            if pid then
                table.insert(symbols, utils.lualine_format_hl(self, pid, opts.highlights.pid))
            end
        end
    else
        if opts.symbols.modified and vim.bo.modified then
            table.insert(symbols, opts.symbols.modified)
        end
        if opts.symbols.readonly and utils.is_readonly() then
            table.insert(symbols, opts.symbols.readonly)
        end
    end

    if #symbols > 0 then
        return " " .. table.concat(symbols, " ")
    else
        return ""
    end
end

---Returns a formatted directory for the given path information.
---@param p PathInfo
---@return string
function M:_get_dir(p)
    local dir = ""
    if #p.parts > 1 then
        local sep = self.options.visual_path_sep
        local hl = self.options.highlights.directory

        dir = table.concat({ unpack(p.parts, 1, #p.parts - 1) }, sep)
        dir = utils.lualine_format_hl(self, dir .. sep, hl)
    end

    return dir
end

return M
