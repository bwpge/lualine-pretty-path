local M = {}

M.path_sep = package.config:sub(1, 1)

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
        }, hl_group) --[[@as string]]
        component.hl_cache[hl_group] = lualine_hl_group
    end

    return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

---Returns the nvim-web-devicon and highlight for the given value, if available.
---@param s string
---@param filetype string?
---@param buftype string?
---@return string?, string?
function M.get_icon(s, filetype, buftype)
    local ok, icons = pcall(require, "nvim-web-devicons")
    if not ok then
        return
    end

    local icon, hl = icons.get_icon(s)
    -- use correct icon for treesitter query buffers
    if filetype == "query" then
        icon, hl = icons.get_icon_by_filetype(filetype)
    end
    if not icon and filetype then
        icon, hl = icons.get_icon_by_filetype(filetype)
    end
    if not icon and buftype then
        icon, hl = icons.get_icon_by_filetype(buftype)
    end

    return icon, hl
end

local function require_provider(item)
    if type(item) == "string" then
        local ok, p = pcall(require, "lualine-pretty-path.providers." .. item)
        if ok and type(p) == "table" then
            return p
        end

        vim.notify(
            "Unknown provider `" .. item .. "`",
            vim.log.levels.WARN,
            { title = "pretty-path" }
        )
        return p
    elseif type(item) ~= "table" then
        vim.notify(
            "Provider must be a table or string value (got " .. type(item) .. ")",
            vim.log.levels.WARN,
            { title = "pretty-path" }
        )
    end
end

function M.resolve_providers(list)
    for i, item in ipairs(list) do
        list[i] = require_provider(item)
    end

    if list.default then
        list.default = require_provider(list.default)
    end

    return vim.tbl_filter(function(x)
        return x ~= nil
    end, list)
end

return M
