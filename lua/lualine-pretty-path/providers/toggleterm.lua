---@class PrettyPath.ToggleTermProvider: PrettyPath.TermProvider
---@field super PrettyPath.TermProvider
local M = require("lualine-pretty-path.providers.terminal"):extend()

local suffix = vim.fn.has("win32") == 1 and "::toggleterm::" or "#toggleterm#"

function M.can_handle(path)
    return path:match(suffix) and vim.bo.buftype == "terminal"
end

function M:format_path(path)
    local p = self.super.format_path(self, path)
    local tid = p:match(suffix .. "(%d+)$")
    if tid then
        self.tid = tid
        p = p:gsub("[&;]?" .. suffix .. "%d+$", "")
    end

    return p
end

function M:extract_name()
    if package.loaded.toggleterm then
        if self.tid then
            local term = require("toggleterm.terminal").get(tonumber(self.tid))
            if term then
                return term:_display_name()
            end
        end
    end

    return self.super.extract_name(self)
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
