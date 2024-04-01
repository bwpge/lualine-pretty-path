# lualine-pretty-path

A [LazyVim](https://www.lazyvim.org/plugins/ui#lualinenvim)-style filename component for [`lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim).

<p align="center">
    <img src="https://github.com/bwpge/lualine-pretty-path/assets/114827766/e88b2c0f-a481-4f4b-82db-03ed642d9a6c">
</p>

## Overview

First and foremost, [@folke](https://github.com/folke) deserves all credit for this style. All I've done with this plugin is pull out some of the LazyVim logic and placed it into a package with some additional features tacked on. If you like what he creates, be sure to star his projects and support his work however you can.

This plugin provides a component that combines LazyVim's `pretty_path` function and lualine's `filetype` and `filename` components, with some extra logic. Features include:

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

By default, `"pretty_path"` will appear essentially equivalent to LazyVim's `lualine` config:

```lua
lualine_c = {
    -- this plugin
    "pretty_path",

    -- equivalent LazyVim
    { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
    { LazyVim.lualine.pretty_path() }

    -- ...
}
```

The following are the default component options:

```lua
{
    icon_show = true, -- show the filetype icon in this component, disable if you want to use lualine's `filetype`
    use_color = true, -- whether or not to apply highlights to the component, use false to disable all color
    path_sep = "", -- path separator for styling output (doesn't affect buffer path)
    file_status = true, -- whether or not to indicate file status with symbols
    unnamed = "[No Name]", -- label for unnamed buffers
    symbols = {
        modified = "", -- somewhat redundant if using modified highlight
        readonly = "",
        ellipsis = "…", -- used between shortened directory parts
    },
    directories = {
        enable = true, -- show directory in component
        shorten = true, -- whether or not to shorten directories, see max_depth
        exclude_filetypes = { "help" }, -- do not show directory for these filetypes
        use_absolute = false, -- use absolute path for directory
        max_depth = 2, -- maximum depth allowed before shortening, ignored if shorten = false
    },
    terminals = {
        show_pid = true, -- display the process id in a terminal buffer
        show_term_id = true, -- display the terminal id for toggleterm windows
    },
    -- highlights can be a string for copying existing styles, or table to create a new one.
    -- empty string implies default lualine section style.
    highlights = {
        directory = "", -- the directory portion of the component
        filename = "Bold", -- the filename portion of the component
        modified = "MatchParen", -- filename highlight if it is modified
        path_sep = "", -- highlight for path separator, uses `directory` if empty string
        pid = "Comment", -- the process id in a terminal window
        symbols = "", -- the symbols at the end of the component
        term = "Bold", -- highlight if the buffer is a terminal
        toggleterm_id = "Number", -- terminal id if in a toggleterm window
        unnamed = "", -- highlight if the buffer is unnamed
    },
    -- see *hooks* section below
    hooks = {
        on_icon_update = nil,
        on_shorten_dir = nil,
        on_fmt_filename = nil,
        on_fmt_terminal = nil,
        on_fmt_directory = nil,
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

### Pre-Configured Styles

The main module `require("lualine-pretty-path")` includes some common styles. For `lazy.nvim` users, you **must** provide options in your plugin spec as a `function` to ensure this plugin is loaded:

```lua
{
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "bwpge/lualine-pretty-path",
    },
    opts = function()
        return {
            sections = {
                lualine_c = { require("lualine-pretty-path").minimal }
            }
        }
    end,
}
```

It is not necessary to use styles from the `lualine-pretty-path` module, they are provided only for convenience. You can copy and paste them directly into your `lualine` config to achieve the same results.

#### `lazy_vim`

**Description:** Produces exactly [LazyVim's](https://www.lazyvim.org/plugins/ui#lualinenvim) style by using the builtin `lualine` filetype component and disables this component's icon.

> [!NOTE]
>
> There are some subtle icon/padding differences between the default style of this component and LazyVim.

**Usage:**

```lua
lualine_c = {
    -- note that this is a function returning a tuple
    require("lualine-pretty-path").lazy_vim()
}
```

**Reference:**

```lua
lazy_vim = function()
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
```

#### `powerline`

**Description:** Displays path parts as powerline segments.

**Usage:**

```lua
lualine_c = {
    require("lualine-pretty-path").powerline
}
```
**Reference:**

```lua
powerline = {
    "pretty_path",
    path_sep = "  ",
    highlights = {
        path_sep = "Comment",
    },
}
```

#### `minimal`

**Description:** Disables everything except the filename.

**Usage:**


```lua
lualine_c = {
    require("lualine-pretty-path").minimal
}
```
**Reference:**

```lua
minimal = {
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
```

## Hooks

Hooks can be used to customize how this component is rendered. Due to how `lualine` passes options to components, type hints won't be available in your plugin configuration (such as through [`neodev.nvim`](https://github.com/folke/neodev.nvim)). This section provides types and examples for each hook.

All hooks are optional and are disabled by default.

### `on_icon_update`

**Type:** `fun(icon?: string, hl_group?: string): string?, string?`

**Description:** Called if the component icon is updated. The `icon` value passed to the hook is *before* extra padding from `icon_padding` is added. The values returned from this function are expected to be in the order `icon, hl_group` (both optional). Returning nothing (`nil`) will hide the icon, but prefer using `icon_show = false` if you never want to render the icon.

Not used if `icon_show = false`.

> [!NOTE]
>
> The input `icon` might be `nil`, such as for unnamed buffers.

**Example:**

```lua
-- hide lua file icon, unset highlight used for the terminal icon
on_icon_update = function(icon, hl_group)
    if icon == "" then
        return
    end
    if icon == "" then
        hl_group = ""
    end
    return icon, hl_group
end
```

### `on_shorten_dir`

**Type:** `fun(parts: string[], ellipsis: string): string[]`

**Description:** Called if `directories.shorten = true` and number of directory parts (depth) exceeds `directories.max_depth`. If this function does not return a table, default shortening logic is used.

Not used if `directories.enable = false`.

> [!TIP]
>
> The `symbols.ellipsis` string is passed to this function so you can use it where needed.

**Example:**

```lua
-- use all directory parts, but only take first letter of each, followed by
-- the ellipsis string. preserve partition on windows with absolute paths.
on_shorten_dir = function(parts, ellipsis)
    return vim.tbl_map(function(x)
        if x:match("^%a:$") then
            return x
        else
            return x:sub(1, 1) .. ellipsis
        end
    end, parts)
end

-- foo, bar, baz -> f…, b…, b…
-- X:, foo, bar, baz -> X:, f…, b…, b…
```

### `on_fmt_filename`

**Type:** `fun(name: string): string`

**Description:** Called if the buffer is a file (see: `on_fmt_terminal` for terminals).

Controls how the filename is displayed. If this function does not return a string, the original filename is used.

**Example:**

```lua
-- remove filename extension
on_fmt_filename = function(name)
    return name:match("(.*)%..+$") or name
end

-- foo.bar.txt -> foo.bar
```

### `on_fmt_terminal`

**Type:** `fun(info: { name: string, path: string, pid?: string, term_id?: string, term?: toggleterm.Terminal }): { name: string, pid?: string, term_id?: string }`

**Description:** Called if the buffer is a terminal (see `on_fmt_filename` for files).

Controls how the terminal's name, PID, and terminal ID are displayed. The suggested name, original path, PID (if available), terminal ID (if available), and [`toggleterm.Terminal`](https://github.com/akinsho/toggleterm.nvim/blob/193786e0371e3286d3bc9aa0079da1cd41beaa62/lua/toggleterm/terminal.lua#L68-L95) (if available) are passed as arguments to the hook as a single table.

The expected return value is a table with fields `name`, `pid` (optional), and `term_id` (optional). If this function does not return a `table` with at least a `name` field, default formatting logic is used. If `pid` and/or `term_id` are not provided by the return value, they are not displayed (prefer using `terminals.show_pid = false` or `terminals.show_term_id = false` if you never want to show them).

**Example:**

```lua
-- use suggested name with a `in {terminal dir}` suffix. if in a toggleterm,
-- show id as `TID:XXX` and hide the PID. otherwise show the pid as `PID:XXX`.
on_fmt_terminal = function(info)
    local cwd = vim.split(info.path, "//")[2]
    local name = info.name .. (cwd and (" in " .. cwd) or "")
    local pid = not info.term and string.format("PID:%s", info.pid)
    local term_id = info.term_id and string.format("TID:%s", info.term_id)

    return {
        name = name,
        pid = pid,
        term_id = term_id,
    }
end

-- toggleterm becomes: some-name in ~/foo/bar TID:1
-- `:term` becomes:    my_shell in ~/foo/bar PID:4567
```

### `on_fmt_directory`

**Type:** `fun(parts: string[]): string[]`

**Description:** Controls how the directory parts are displayed. The input to this function is the parts that remain after processing shortening logic (see `on_shorten_dir` hook). If this function does not a return a table, the original `parts` are used.

Not used if `directories.enable = false`.

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

-- foo-bar-baz-qux, my, dir -> foo-bar-ba…, my, dir
```

## Contributing

Contributions are welcome. The best way to start is to [create an issue](https://github.com/bwpge/lualine-pretty-path/issues/new/choose) and have a discussion. This helps coordinate efforts and align expectations for all parties involved.
