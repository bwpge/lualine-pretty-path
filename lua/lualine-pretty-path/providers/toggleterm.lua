---@class PrettyPath.ToggleTermProvider: PrettyPath.TermProvider
---@field super PrettyPath.TermProvider
local M = require("lualine-pretty-path.providers.terminal"):extend()

function M.can_handle(path)
    return path:match("::toggleterm::") and vim.bo.buftype == "terminal"
end

function M:format_path(path)
    local p = self.super.format_path(self, path)
    local tid = p:match("::toggleterm::(%d+)$")
    if tid then
        self.tid = tid
        p = p:gsub("[&;]?::toggleterm::%d+$", "")
    end

    return p
end

function M:render_extra()
    local ids = {}
    if self.tid then
        table.insert(ids, self.hl(self.tid, self.opts.highlights.id))
    end
    if self.pid then
        table.insert(ids, self.hl(self.pid, self.opts.highlights.verbose))
    end

    if #ids > 0 then
        return " " .. table.concat(ids, " ")
    end
end

return M
