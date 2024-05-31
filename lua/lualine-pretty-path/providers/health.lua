---@class PrettyPath.HealthProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

function M.can_handle()
    return vim.bo.filetype == "checkhealth"
end

function M:extract_scheme() end

function M:render_symbols() end

function M:extract_name()
    return "Health"
end

return M
