---@class PrettyPath.OilProvider: PrettyPath.Provider
---@field super PrettyPath.Provider
local M = require("lualine-pretty-path.providers.base"):extend()

function M.can_handle()
    return vim.bo.filetype == "oil"
end

function M:format_path(_)
    return require("oil").get_current_dir()
end

---Renders the oil current directory as if it was the "filename" part.
---@return string
function M:render_dir()
    local dir = self.super.render_dir(self) or ""
    dir = dir:sub(1, #dir - #self.path_sep) -- remove trailing separator

    return self.hl(dir, self.opts.highlights.filename)
end

function M:render()
    return table.concat({
        self:render_dir() or "",
        self:render_symbols() or "",
    }, "")
end

return M
