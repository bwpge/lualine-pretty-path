local M = {}

M.path_sep = package.config:sub(1, 1)

function M.is_readonly()
    return vim.bo.modifiable == false or vim.bo.readonly == true
end

---Returns a toggleterm `Terminal` if the given `id` exists and is not hidden.
---@param tid number?
---@return any
function M.get_toggleterm_by_id(tid)
    if not tid or not package.loaded["toggleterm"] then
        return
    end

    return require("toggleterm.terminal").get(tid)
end

---Formats a lualine component with a highlight group.
---@param component any
---@param text string
---@param hl_group? string
---@return string
function M.lualine_format_hl(component, text, hl_group)
    if not hl_group or hl_group == "" or text == "" then
        return text
    end

    ---@type table<string, string>
    component.hl_cache = component.hl_cache or {}
    local lualine_hl_group = component.hl_cache[hl_group]
    if not lualine_hl_group then
        local u = require("lualine.utils.utils")
        ---@type string[]
        local gui = vim.tbl_filter(function(x)
            return x
        end, {
            u.extract_highlight_colors(hl_group, "bold") and "bold",
            u.extract_highlight_colors(hl_group, "italic") and "italic",
        })

        lualine_hl_group = component:create_hl({
            fg = u.extract_highlight_colors(hl_group, "fg"),
            gui = #gui > 0 and table.concat(gui, ",") or nil,
        }, "PRETTY_" .. hl_group) --[[@as string]]
        component.hl_cache[hl_group] = lualine_hl_group
    end

    return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

return M
