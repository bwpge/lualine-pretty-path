---@class PrettyPath.TroubleProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

function M.can_handle()
    return vim.bo.filetype == "trouble" or vim.bo.filetype == "Trouble"
end

function M:render_symbols() end

function M:extract_name()
    return "Trouble"
end

return M
