local utils = require("lualine-pretty-path.utils")
local default_provider = require("lualine-pretty-path.providers.base")
-- TODO: why do we need lualine_require?
local lualine_require = require("lualine_require")
local M = lualine_require.require("lualine.component"):extend()

---@class PrettyPath.SymbolOptions
---@field modified string
---@field readonly string
---@field newfile string
---@field ellipsis string

---@class PrettyPath.DirectoryOptions
---@field enable boolean
---@field shorten boolean
---@field exclude_filetypes string[]
---@field max_depth number

---@class PrettyPath.HookOptions
---@field on_icon_update? fun(icon?: string, hl_group?: string): string?, string?
---@field on_shorten_dir? fun(parts: string[], ellipsis: string): string[]
---@field on_fmt_filename? fun(name: string): string
---@field on_fmt_terminal? fun(info: { name: string, path: string, pid?: string, term_id?: string, term?: unknown }): { name: string, pid?: string, term_id?: string }
---@field on_fmt_directory? fun(parts: string[]): string[]

---@alias PrettyPath.ProviderOption { value: PrettyPath.Provider, cond: fun(path: string): boolean }

---@class PrettyPath.Options
---@field icon string?
---@field icon_show boolean
---@field icon_show_inactive boolean
---@field use_color boolean
---@field use_absolute boolean
---@field path_sep string
---@field file_status boolean
---@field unnamed string
---@field symbols PrettyPath.SymbolOptions
---@field directories PrettyPath.DirectoryOptions
---@field highlights table<string, string?>
---@field icon_padding table<string, number>
---@field providers { default: PrettyPath.Provider?, [number]: PrettyPath.ProviderOption?  }

---@type PrettyPath.Options
local default_options = {
    icon_show = true,
    icon_show_inactive = false,
    use_color = true,
    use_absolute = false,
    path_sep = "",
    file_status = true,
    unnamed = "[No Name]",
    symbols = {
        modified = "",
        readonly = "",
        newfile = "",
        ellipsis = "…",
    },
    directories = {
        enable = true,
        shorten = true,
        exclude_filetypes = { "help" },
        max_depth = 2,
    },
    highlights = {
        directory = "",
        filename = "Bold",
        fugitive_id = "Number",
        modified = "MatchParen",
        newfile = "Special",
        path_sep = "",
        pid = "Comment",
        symbols = "",
        term = "Bold",
        toggleterm_id = "Number",
        unnamed = "",
    },
    icon_padding = {
        [""] = 1,
    },
    -- TODO: using an array makes it hard for the user to keep defaults and replace 1 or 2 items.
    -- we should have an easier way for them to build/modify the default list.
    providers = {
        {
            value = require("lualine-pretty-path.providers.fugitive"),
            cond = function(path)
                return vim.bo.filetype == "fugitive" or path:match("^fugitive:") ~= nil
            end,
        },
        {
            value = require("lualine-pretty-path.providers.help"),
            cond = function()
                return vim.bo.filetype == "help"
            end,
        },
        {
            value = require("lualine-pretty-path.providers.toggleterm"),
            cond = function(path)
                return path:match("::toggleterm::") and vim.bo.buftype == "terminal"
            end,
        },
        {
            value = require("lualine-pretty-path.providers.terminal"),
            cond = function()
                return vim.bo.buftype == "terminal"
            end,
        },
    },
}

function M:init(options)
    M.super.init(self, options)
    ---@type PrettyPath.Options
    self.options = vim.tbl_deep_extend("keep", self.options or {}, default_options)

    -- TODO: clean up default options. decide if we want to use empty strings or nils
    for k, v in pairs(self.options.symbols) do
        if v == "" then
            self.options.symbols[k] = nil
        end
    end
    if not self.options.symbols.ellipsis then
        self.options.symbols.ellipsis = "…"
    end
    if self.options.path_sep == "" then
        self.options.path_sep = utils.path_sep
    end

    -- providers array needs to be overwritten entirely
    if options.providers then
        self.options.providers = options.providers
    end
    self._default_provider = self.options.providers.default or default_provider

    -- create highlight groups
    for key, hl in pairs(self.options.highlights) do
        if type(hl) == "table" then
            local name = "PrettyPath_" .. key
            vim.api.nvim_set_hl(0, name, hl)
            self.options.highlights[key] = name
        end
    end
end

---@param path string
---@return PrettyPath.Provider
function M:get_provider(path)
    for _, item in ipairs(self.options.providers) do
        if item.cond(path) == true then
            return item.value
        end
    end

    return self._default_provider
end

local function make_hl_fn(self)
    return function(text, group)
        return self:_hl(text, group)
    end
end

---@param is_focused boolean
---@return string?
function M:update_status(is_focused)
    self.is_focused = is_focused
    local path = vim.fn.expand(self.options.use_absolute and "%:p" or "%:~:.")
    local provider = self:get_provider(path)
    local hl_fn = make_hl_fn(self)

    local p = provider:new(path, is_focused, hl_fn, self.options)
    if
        not self.options.icon_show
        or not (self.is_focused or self.options.icon_show_inactive)
        or #p.icon == 0
    then
        self.icon = nil
    else
        local icon = p.icon[1]
        local padding = self.options.icon_padding[icon] or 0
        self.options.icon = self:_hl(icon .. string.rep(" ", padding), p.icon[2])
    end

    return p:render()
end

---@private
---@param text string
---@param hl_group? string
---@return string
function M:_hl(text, hl_group)
    if not self.options.use_color or not self.is_focused then
        return text
    end
    return utils.lualine_format_hl(self, text, hl_group)
end

return M
