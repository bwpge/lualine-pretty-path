local utils = require("lualine-pretty-path.utils")

---Type hint information from lualine's `class` implementation.
---
---See: https://github.com/nvim-lualine/lualine.nvim/blob/0a5a66803c7407767b799067986b4dc3036e1983/lua/lualine/utils/class.lua
---@class Class
---@field init fun(obj: Class, ...)
---@field new fun(obj: Class, ...): Class
---@field extend fun(obj: Class): Class

---@alias PrettyPath.HlFunc fun(text: string, group: string?): string

---A base provider implementation.
---
---This class should be extended for specific path/file types, like terminals or diffs.
---@class PrettyPath.Provider: Class
---@field new fun(self: PrettyPath.Provider, path: string, is_focused: boolean, hl: PrettyPath.HlFunc, opts: PrettyPath.Options): PrettyPath.Provider
---@field super Class
---@field path_sep string
---@field is_focused boolean
---@field hl fun(text: string, group: string?): string
---@field opts PrettyPath.Options
---@field path string
---@field scheme string?
---@field parts string[]
---@field name string?
---@field icon { [1]: string?, [2]: string? }
---@field extend fun(self: PrettyPath.Provider): PrettyPath.Provider
local M = require("lualine.utils.class"):extend()

---Initializes the provider and parses the input path.
---
---This method should not be overridden.
---@param path string
---@param is_focused boolean
---@param hl PrettyPath.HlFunc
---@param opts PrettyPath.Options
function M:init(path, is_focused, hl, opts)
    self.path_sep = package.config:sub(1, 1)
    self.hl = hl
    self.is_focused = is_focused
    self.opts = opts
    self.path = self:format_path(path)
    self:parse()
end

---A class function that returns whether or not this provider can handle the current buffer.
---
---This is called when the plugin is looking for a provider to render the component. When extending,
---providers **must** override this function.
---
---**IMPORTANT:** Note that this function uses a period (`.`) not a colon (`:`). This is a class
---**function**, not a method. There is no `self` parameter, so this function cannot access any
---instance methods or fields.
---@param _ string
---@return boolean
function M.can_handle(_)
    error("`can_handle` must be implemented by extension providers", 2)
end

---Formats or pre-processes the `path`, such as removing prefixes or ID numbers.
---
---The output of this method will be stored as `self.path` for reference in other methods.
---@param path string
---@return string
function M:format_path(path)
    return path
end

---Parses the `self.path` field to extract directory parts, filename, etc.
---
---This method should modify all internal state required, such as icon, scheme, name, etc.
function M:parse()
    self.scheme = self:extract_scheme()
    self.parts = self:split_path()
    self.name = self:extract_name()
    self.icon = self:get_icon()
end

---Extracts the file scheme, such as `term://`.
---
---Some schemes, like those created by `vim-fugitive`, use the operating system path separator. This
---base implementation does not handle these cases.
---@return string?
function M:extract_scheme()
    local pat = "^(%a[%a%d%-%+%.]*)://"
    local scheme = self.path:match(pat) --[[@as string?]]
    self.path = self.path:gsub(pat, "")
    return scheme
end

function M:split_path()
    local parts = vim.split(self.path, self.path_sep, { trimempty = true }) or {}
    if #parts == 0 then
        return parts
    end
    parts[#parts] = nil
    return parts
end

---Extracts the filename portion of this provider.
---
---The base implementation simply uses the tail (`:t`) of `self.path`.
---@return string?
function M:extract_name()
    return vim.fn.fnamemodify(self.path, ":t")
end

---Returns the appropriate icon for this buffer.
---
---This method should return an array with the form `{ icon, highlight_group }` (both can be `nil`).
---This method does not have to respect any user options, the decision to display the icon is made by
---the caller.
---@return { [1]: string?, [2]: string? }
function M:get_icon()
    local name = vim.fn.expand("%:t")
    local ft = vim.bo.filetype
    local bt = vim.bo.buftype

    if package.loaded["nvim-web-devicons"] then
        local custom_icons = self.opts.custom_icons
        local item = custom_icons[name] or custom_icons[ft or ""] or custom_icons[bt or ""]
        if item then
            return item
        end
    end

    return { utils.get_icon(name, vim.bo.filetype, vim.bo.buftype) }
end

---Returns an array of shortened directory parts.
---
---This method should respect the `max_depth` option, but different providers may have different
---logic for what counts as "depth". It should also respect the `directories.shorten` option.
---@return string[]
function M:shorten_dir()
    if not self.opts.directories.shorten or #self.parts <= self.opts.directories.max_depth then
        return self.parts
    end

    local slice = {} ---@type string[]
    local ellipsis = self.opts.symbols.ellipsis
    if #self.parts == 1 then
        return self.parts
    elseif #self.parts == 2 then
        slice = { self.parts[1], ellipsis }
    else
        slice = { self.parts[1], ellipsis, self.parts[#self.parts] }
    end

    return slice
end

---Returns whether or not this buffer is unnamed.
---@return boolean
function M:is_unnamed()
    if self.name then
        return #self.name == 0
    end
    return true
end

---Returns whether or not this buffer is readonly.
---@return boolean
function M:is_readonly()
    return vim.bo.modifiable == false or vim.bo.readonly == true
end

---Returns whether or not this buffer is new (such as buffers created with `:e foo.txt`).
---
---Readonly buffers are not considered "new" because they are usually special buffer types.
---@return boolean
function M:is_new()
    return not self:is_readonly()
        and self.path ~= ""
        and vim.bo.buftype == ""
        and not vim.wo.diff
        and vim.uv.fs_stat(vim.fn.expand("%:p")) == nil
end

---Returns whether or not this buffer is modified.
---@return boolean
function M:is_modified()
    return vim.bo.modified
end

---Returns the rendered scheme portion.
---@return string?
function M:render_scheme()
    return self.scheme and (self.scheme .. "://")
end

---Returns the rendered directory portion.
---
---This method should respect the `directories.enable` and `directories.exclude_filetypes` options.
---@return string?
function M:render_dir()
    if
        not self.opts.directories.enable
        or #self.parts == 0
        or vim.tbl_contains(self.opts.directories.exclude_filetypes, vim.bo.filetype)
    then
        return
    end

    local slice = self:shorten_dir()
    if #slice == 0 then
        return
    end

    local sep = self.hl(self.opts.path_sep, self.opts.highlights.path_sep)
    local dir = table.concat(slice, sep)
    local escaped_path = (dir .. sep):gsub("%%", "%%%%")
    return self.hl(escaped_path, self.opts.highlights.directory)
end

---Returns the rendered name portion.
---@return string?
function M:render_name()
    local name = self:is_unnamed() and self.opts.unnamed or self.name
    if not name then
        return
    end

    local name_hl = ""
    if self:is_modified() then
        name_hl = self.opts.highlights.modified
    elseif self:is_unnamed() then
        name_hl = self.opts.highlights.unnamed
    elseif self:is_new() then
        name_hl = self.opts.highlights.newfile
    else
        name_hl = self.opts.highlights.filename
    end

    local escaped_name = name:gsub("%%", "%%%%")
    return self.hl(escaped_name, name_hl)
end

---Returns the rendered symbols portion.
---@return string?
function M:render_symbols()
    if not self.opts.use_symbols then
        return
    end
    local symbols = {}

    for k, v in pairs({
        newfile = self:is_new(),
        modified = self:is_modified(),
        readonly = self:is_readonly(),
    }) do
        local symbol = self.opts.symbols[k] or ""
        if v and #symbol > 0 then
            table.insert(symbols, self.hl(symbol, self.opts.highlights.symbols))
        end
    end

    if #symbols > 0 then
        return " " .. table.concat(symbols, " ")
    end
end

---Returns any extra rendered information the provider chooses.
---
---For the base implementation, this does nothing. This is a good spot to add extra items like ID
---numbers, icons, etc.
---@return string?
function M:render_extra() end

---Returns the rendered text to display in the component.
---
---The component can be hidden entirely by returning `nil`.
---@return string?
function M:render()
    return table.concat({
        self:render_scheme() or "",
        self:render_dir() or "",
        self:render_name() or "",
        self:render_symbols() or "",
        self:render_extra() or "",
    }, "")
end

return M
