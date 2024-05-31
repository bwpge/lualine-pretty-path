---@class PrettyPath.DapUiProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

function M.can_handle()
    return vim.bo.filetype == "dap-repl" or vim.bo.filetype:match("^dapui_")
end

function M:render_name()
    return self.hl(self.name, self.opts.highlights.filename)
end

function M:extract_name()
    local name = self.super.extract_name(self)
    if name == "[dap-repl]" then
        name = "DAP REPL"
    end

    return name
end

function M:render()
    return self:render_name()
end

return M
