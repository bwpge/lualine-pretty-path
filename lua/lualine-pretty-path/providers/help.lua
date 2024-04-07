---@class PrettyPath.HelpProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

function M.can_handle()
    return vim.bo.filetype == "help"
end

function M:get_icon()
    local icon = self.super.get_icon(self)
    if icon[1] then
        icon[1] = "󰋖"
    end

    return icon
end

return M
