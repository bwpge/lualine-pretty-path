local M = {}

---Returns components configured to produce LazyVim's lualine style.
---@return table
---@return table
M.lazy_vim = function()
    return {
        "filetype",
        icon_only = true,
        separator = "",
        padding = { left = 1, right = 0 },
    }, {
        "pretty_path",
        icon_show = false,
    }
end

---Returns a configuration to produce a powerline or breadcrumb style path.
M.powerline = {
    "pretty_path",
    path_sep = "  ",
    highlights = {
        path_sep = "Comment",
    },
}

---Disables all component features except the filename.
M.minimal = {
    "pretty_path",
    icon_show = false,
    use_color = false,
    file_status = false,
    directories = { enable = false },
    terminals = {
        show_pid = false,
        show_term_id = false,
    },
}

return M
