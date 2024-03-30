# lualine-pretty-path

A [LazyVim](https://www.lazyvim.org/plugins/ui#lualinenvim)-style filename component for [`lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim).

## Overview

First and foremost, [@folke](https://github.com/folke) deserves all credit for this style. All I've done with this plugin is pull out some of the LazyVim logic and placed it into a package with some additional options. If you like what he creates, be sure to star his projects and support his work however you can.

This plugin provides a component that combines LazyVim's `pretty_path` function and lualine's `filetype` and `filename` components. Features include:

- Display directory and file name with highlights
- Custom path separator for powerline or breadcrumb styles
- File status symbols
- Custom formatting and highlights for terminal process ID numbers
- Support for [`toggleterm`](https://github.com/akinsho/toggleterm.nvim) display names and id numbers
- Per-icon padding to account for different fonts and terminal rendering

## Installation

With [`lazy.nvim`](https://github.com/folke/lazy.nvim):

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
    dir_show = true, -- show the directory in this component
    path_sep = "", -- path separator for styling output (doesn't affect buffer path)
    file_status = true, -- whether or not to indicate file status with symbols
    unnamed = "[No Name]", -- label for unnamed/new buffers
    -- symbols used to indicate the status of the buffer
    symbols = {
        modified = "", -- somewhat redundant if using modified highlight
        readonly = "",
    },
    -- terminal-specific options
    term = {
        show_pid = true, -- display the process id in a terminal buffer
        show_toggleterm_id = true, -- display the terminal id for toggleterm windows
        pid_fmt = tostring, -- a function to format the process id number
        toggleterm_id_fmt = tostring, -- a function to format the terminal id number
    },
    -- highlights can be a string for copying existing styles, or table to be
    -- passed to vim.api.nvim_set_hl. empty string uses default section style.
    highlights = {
        directory = "", -- the directory portion of the component
        file = "Bold", -- the filename portion of the component
        modified = "MatchParen", -- the filename if it is modified
        pid = "Comment", -- the process id in a terminal window
        symbols = "", -- the symbols at the end of the component
        term = "", -- highlight if the buffer is a terminal
        toggleterm_id = "Number", -- terminal id if in a toggleterm window
        unnamed = "", -- highlight if the buffer is unnamed
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
            term = {
                pid_fmt = function(id)
                    return string.format("[PID:%d]", id)
                end,
                toggleterm_id_fmt = function(id)
                    return string.format(" %d", id)
                end
            },
            highlights = {
                file = "",
                modified = { fg = "#ff00ff", underline = true, bold = true }
                unnamed = "Comment",
            }
        }
    },
    -- ...
}
```
