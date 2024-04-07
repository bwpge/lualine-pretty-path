local utils = require("lualine-pretty-path.utils")

---@class PrettyPath.TermProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

function M:format_path(path)
    local p = vim.split(path, "//")[3] or ""
    local pid = p:match("^%d+")
    if pid then
        self.pid = pid
        p = p:gsub("^%d+:", "")
    end

    return p
end

function M:extract_scheme() end

function M:render_symbols() end

function M:render_dir() end

function M:get_icon()
    return { utils.get_icon("terminal") }
end

function M:render_extra()
    if self.pid then
        return " " .. self.hl(self.pid, self.opts.highlights.pid)
    end
end

return M
