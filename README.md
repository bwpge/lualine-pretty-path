# lualine-pretty-path

A [LazyVim](https://www.lazyvim.org/plugins/ui#lualinenvim)-style filename component for [`lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim).

<p align="center">
    <img src="https://github.com/bwpge/lualine-pretty-path/assets/114827766/e88b2c0f-a481-4f4b-82db-03ed642d9a6c">
</p>

## Overview

First and foremost, [@folke](https://github.com/folke) deserves all credit for this style. All I've done with this plugin is pull out some of the LazyVim logic and placed it into a package with some additional features tacked on. If you like what he creates, be sure to star his projects and support his work however you can.

This plugin provides a component that combines LazyVim's `pretty_path` function and lualine's `filetype` and `filename` components. Features include:

- Display directory and file name with highlights
- Customize path separator for powerline or breadcrumb styles
- Hooks for manipulating component rendering logic
- Custom formatting and highlights for terminal process ID numbers
- Support for [`toggleterm`](https://github.com/akinsho/toggleterm.nvim) display names and ID numbers
- Per-icon padding to account for different fonts and terminal rendering

## Installation

With [`lazy.nvim`](https://github.com/folke/lazy.nvim)

```lua
{
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        -- add this plugin as dependency for lualine
        "bwpge/lualine-pretty-path",
    },
    opts = {
        sections = {
            -- recommended to use this plugin in lualine_c,
            -- see below for options
            lualine_c = { "pretty_path" }
        },
        -- ... other lualine config
    },
}
```

## Configuration

By default, `"pretty_path"` will appear equivalent to LazyVim's `lualine` config:

```lua
lualine_c = {
    -- ...
    { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
    { LazyVim.lualine.pretty_path() }
}
```

The following are the default component options:

```lua
{
    icon_show = true, -- show the filetype icon in this component, disable if you want to use lualine's `filetype`
    path_sep = "", -- path separator for styling output (doesn't affect buffer path)
    file_status = true, -- whether or not to indicate file status with symbols
    unnamed = "[No Name]", -- label for unnamed/new buffers
    symbols = {
        modified = "", -- somewhat redundant if using modified highlight
        readonly = "",
        ellipsis = "…", -- used between shortened directory parts
    },
    directories = {
        enable = true, -- show directory in component
        exclude_filetypes = { "help" }, -- do not show directory for these filetypes
        use_absolute = false, -- use absolute path for directory
        max_depth = 2, -- maximum directory depth before shortening
    },
    -- terminal-specific options
    terminals = {
        show_pid = true, -- display the process id in a terminal buffer
        show_toggleterm_id = true, -- display the terminal id for toggleterm windows
    },
    -- highlights can be a string for copying existing styles, or table to be
    -- passed to vim.api.nvim_set_hl. empty string uses default section style.
    highlights = {
        directory = "", -- the directory portion of the component
        filename = "Bold", -- the filename portion of the component
        modified = "MatchParen", -- filename highlight if it is modified
        path_sep = "", -- highlight for separator between path parts, defaults to `directory` if unset
        pid = "Comment", -- the process id in a terminal window
        symbols = "", -- the symbols at the end of the component
        term = "Bold", -- highlight if the buffer is a terminal
        toggleterm_id = "Number", -- terminal id if in a toggleterm window
        unnamed = "", -- highlight if the buffer is unnamed
    },
    -- see *hooks* section below
    hooks = {
        on_shorten_dir = nil,
        on_fmt_filename = nil,
        on_fmt_directory = nil,
        on_fmt_pid = nil,
        on_fmt_term_id = nil,
    },
    -- some icons may need additional padding depending on your font and terminal.
    -- refer to nvim-web-devicons for the correct key (icon):
    -- https://github.com/nvim-tree/nvim-web-devicons/blob/master/lua/nvim-web-devicons/icons-default.lua
    icon_padding = {
        [""] = 1, -- value here adds *additional* spaces (use 0 or negative to disable)
    },
}
```

To use these options, specify them in a table with `"pretty_path"`:

```lua
{
    -- other lualine settings...
    lualine_c = {
        {
            "pretty_path",
            icon_show = false,
            path_sep = "  ", -- powerline/breadcrumb style path
            terminals = {
                show_pid = false,
            },
            highlights = {
                modified = { fg = "#ff00ff", bold = true, italic = true },
                path_sep = "Comment",
            },
            icon_padding = {
                [""] = 0 -- disable extra padding for terminal icon
            }
        }
    },
    -- ...
}
```

### Hooks

Hooks can be used to customize how this component is rendered. Due to how `lualine` passes options to components, type hints aren't really feasible. This section provides types and examples for each hook.

All hooks are optional and are disabled by default.

#### `on_shorten_dir`

**Type:** `fun(parts: string[], ellipsis: string): string[]`

**Description:** Called if `directories.shorten = true` and number of directory parts (depth) exceeds `directories.max_depth`. If this function does not return a table, defualt shortening logic is used.

**Example:**

```lua
-- use all directory parts, but only take first letter of each.
-- preserve partition on windows with absolute paths.
on_shorten_dir = function(parts, _)
    return vim.tbl_map(function(x)
        if x:match("^%a:$") then
            return x
        else
            return x:sub(1, 1)
        end
    end, parts)
end
```

#### `on_fmt_filename`

**Type:** `fun(name: string): string?`

**Description:** Called just before the filename is highlighted.

**Example:**

```lua
-- convert filename to uppercase
on_fmt_filename = string.upper
```

#### `on_fmt_directory`

**Type:** `fun(parts: string[]): string[]`

**Description:** Called just before the directory parts are joined with separators and highlighted. If this function does not a return a table, the original `parts` are used.

**Example:**

```lua
-- truncate long directory names
on_fmt_directory = function(parts)
    return vim.tbl_map(function(x)
        if #x >= 10 then
            return x:sub(1, 10) .. "…"
        else
            return x
        end
    end, parts)
end
```

#### `on_fmt_pid`

**Type:** `fun(id: number): string?`

**Description:** Controls how terminal's process ID is displayed. If this function returns `nil`, the number will be displayed with `tostring` as a fallback. Use `terminals.show_pid = false` to disable rendering.

**Example:**

```lua
-- show pid as `[PID:XXX]`
on_fmt_pid = function(id)
    return string.format("[PID:%d]", id)
end
```

#### `on_fmt_term_id`

**Type:** `fun(id: number): string?`

**Description:** Controls how a `toggleterm` ID is displayed. If this function returns `nil`, the number will be displayed with `tostring` as a fallback. Use `terminals.show_term_id = false` to disable rendering.

**Example:**

```lua
-- show terminal id with a tag icon
on_fmt_pid = function(id)
    return "󰓼 " .. id
end
```
