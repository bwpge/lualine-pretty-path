local utils = require("lualine-pretty-path.utils")

---@class PrettyPath.FugitiveProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

function M:format_path(path)
    local p = vim.split(path, self.path_sep .. self.path_sep)[3] or ""
    local id = p:match("^%d+")
    if id then
        self.id = id
        p = p:gsub("^%d+" .. self.path_sep, "")
    end

    return p
end

function M:is_diff()
    return vim.wo.diff or false
end

function M:extract_scheme() end

function M:get_icon()
    local name = self:is_diff() and "diff" or "git"
    return { utils.get_icon(name) }
end

function M:render()
    if self:is_unnamed() then
        return "Git status"
    end

    local status = M.super.render(self)
    if self.id then
        status = status .. " " .. self.hl(self.id, self.opts.highlights.fugitive_id)
    end
    return status
end

return M
