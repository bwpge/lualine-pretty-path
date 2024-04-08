local utils = require("lualine-pretty-path.utils")

---@class PrettyPath.FugitiveProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

local function is_hash(s)
    return s and #s == 40 and s:match("^[%a%d]+$") ~= nil
end

function M.can_handle(path)
    return path:match("^fugitive:") ~= nil or vim.bo.filetype:match("^fugitive") ~= nil
end

function M:format_path(path)
    local p = vim.split(path, self.path_sep .. self.path_sep)[3] or path
    local id = p:match("^(%d+)" .. self.path_sep)

    if id then
        self.id = id
        p = p:gsub("^%d+" .. self.path_sep, "")
    end

    return p
end

function M:split_path()
    local parts = self.super.split_path(self)
    if is_hash(parts[1]) then
        self.hash = table.remove(parts, 1)
    end
    return parts
end

function M:is_diff()
    return vim.wo.diff
end

function M:is_blame()
    return vim.bo.filetype == "fugitiveblame"
end

function M:extract_scheme() end

function M:get_icon()
    local ft = "git"
    if self:is_diff() then
        ft = "diff"
    end
    return { utils.get_icon(ft) }
end

function M:render_name()
    if is_hash(self.name) then
        return self.hl(self.name, "fugitiveHash")
    end

    return self.super.render_name(self)
end

function M:render()
    if self:is_unnamed() then
        return self.hl("Git status", self.opts.highlights.filename)
    elseif self:is_blame() then
        return self.hl("Git blame", self.opts.highlights.filename)
    end

    local status = M.super.render(self)
    if self.hash then
        status = self.hl(self.hash, "fugitiveHash")
            .. self.hl(self.opts.path_sep, self.opts.highlights.path_sep)
            .. status
    end
    if self.id then
        status = status .. " " .. self.hl(self.id, self.opts.highlights.id)
    end
    return status
end

return M
