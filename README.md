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
        -- recommended to use this plugin in lualine_c,
        -- see below for options
        sections = {
            lualine_c = { "pretty_path" }
        },
        inactive_sections = {
            lualine_c = { "pretty_path" }
        }
        -- other lualine config...
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
    icon_show_inactive = false, -- same as above, but only affects `inactive_sections` (always disabled if icon_show = false)
    use_color = true, -- whether or not to apply highlights to the component, use false to disable all color
    use_absolute = false, -- pass absolute paths to providers
    path_sep = "", -- path separator for styling output (doesn't affect buffer path)
    file_status = true, -- whether or not to indicate file status with symbols
    unnamed = "[No Name]", -- label for unnamed buffers
    symbols = {
        modified = "", -- somewhat redundant if using modified highlight
        readonly = "",
        newfile = "", -- somewhat redundant if using newfile highlight
        ellipsis = "…", -- used between shortened directory parts
    },
    directories = {
        enable = true, -- show directory in component
        shorten = true, -- whether or not to shorten directories, see max_depth
        exclude_filetypes = { "help" }, -- do not show directory for these filetypes
        max_depth = 2, -- maximum depth allowed before shortening, ignored if shorten = false
    },
    -- highlights can be a string for copying existing styles, or table to create a new one.
    -- empty string implies default lualine section style.
    highlights = {
        directory = "", -- the directory portion of the component
        filename = "Bold", -- the filename portion of the component
        id = "Number", -- various id numbers like toggleterm id, diff files, etc.
        modified = "MatchParen", -- filename highlight if it is modified
        newfile = "Special", -- highlight if the buffer is new
        path_sep = "", -- highlight for path separator, uses `directory` if empty string
        symbols = "", -- the symbols at the end of the component
        term = "Bold", -- highlight if the buffer is a terminal
        unnamed = "", -- highlight if the buffer is unnamed
        verbose = "Comment", -- verbose information like terminal PID's
    },
    -- some icons may need additional padding depending on your font and terminal.
    -- refer to nvim-web-devicons for the correct key (icon):
    -- https://github.com/nvim-tree/nvim-web-devicons/blob/master/lua/nvim-web-devicons/icons-default.lua
    icon_padding = {
        [""] = 1, -- value here adds *additional* spaces (use 0 or negative to disable)
    },
    providers = {}, -- see *providers* section
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

### Inactive Section

This component can be used in `inactive_sections` to replace the default filename component.

When inactive (`is_focused = false`), highlights are disabled. This will use the `lualine` default text color for inactive components in whatever section this is set to.

This is a completely separate configuration, and so it requires specifying all of your options again if you want identical components for active and inactive modes. While this might be a bit annoying if you want to use the same configuration, it allows for rendering different versions for active/inactive modes.

One way to use the same config is by extracting the table to a variable:

```lua
local pretty_path = {
    "pretty_path",
    icon_show = false,
    directories = { shorten = false },
    -- ...
}

return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "bwpge/lualine-pretty-path",
    },
    opts = {
        sections = {
            lualine_c = { pretty_path }
        },
        inactive_sections = {
            lualine_c = { pretty_path }
        },
    },
}
```

Conversely, you might want completely different styles for active/inactive:

```lua
return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "bwpge/lualine-pretty-path",
    },
    opts = {
        sections = {
            -- use default for active
            lualine_c = { "pretty_path" }
        },
        inactive_sections = {
            -- use absolute path with no shortening for inactive
            lualine_c = {
                {
                    "pretty_path",
                    directories = {
                        shorten = false,
                        use_absolute = true,
                    },
                },
            },
        },
    },
}
```

## Providers

This plugin uses the concept of *providers* to parse and render the component content. This allows reusing and extending logic for specialized buffers (e.g., terminals, plugin buffers like `vim-fugitive`, etc.).

The `base` provider (`lualine-pretty-path.providers.base`) is implemented to be as flexible as possible, and easy to override small, logical chunks. The `extend` method allows one to inherit all the logic of the provider and customize certain parts.

For an easy example, take a look at the `help` provider:

```lua
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
```

This provider mostly relies on the `base` implementation, but overrides the `get_icon` method to change the icon returned (if `base` could find one). The `can_handle` function (not method) is required to be implemented by all extensions from `base`.

> [!IMPORTANT]
>
> Note the call to `super` with `self.super.get_icon(self)`. This indexes the provider that was extended (`base`), calls the method `get_icon`, using the current provider object (`help`) as the `self` argument. This is a quirk of how `lualine` implements class/inheritance logic in Lua. If `super` methods are not called this way, you will get a bunch of cryptic errors about indexing `nil` fields.

### Selecting Providers

The provider selection order is based on `options.providers`. The builtin list is equivalent to:

```lua
providers = {
    default = "base",
    "fugitive",
    "help",
    "toggleterm",
    "terminal",
}
```

Providers can be specified by table values (e.g., `require("some.provider")`) or by strings (similar to how `lualine` requires components).

### Default Provider

If no provider matches from `options.providers` or the builtin list, the default (`base`) is used. This can be overridden with the `default` field:

```lua
providers = {
    default = "my_default",
    -- ...
}
```

It is recommended to put the most specific providers first in the list, to allow `can_handle` tests to fall through to more general ones.

### Custom Providers

Custom providers can be extended from existing ones to reuse logic and reduce boilerplate. Refer to the [`base` provider implementation](https://github.com/bwpge/lualine-pretty-path/tree/main/lua/lualine-pretty-path/providers/base.lua) for more information.

For example, say you want to remove the PID from the `terminal` provider. You can extend it and override the `render_extra` method to return nothing, and add that to your `providers` option:

```lua
local new_term_provider = require("lualine-pretty-path.providers.terminal"):extend()
-- no need to override `can_handle`, terminal provider already does
function new_term_provider:render_extra() end

-- ...

lualine_c = {
    {
        "pretty_path"
        providers = { new_term_provider },
    },
}

```

The providers in your config will always take priority over the builtin ones.

## Contributing

Contributions are welcome. The best way to start is to [create an issue](https://github.com/bwpge/lualine-pretty-path/issues/new/choose) and have a discussion. This helps coordinate efforts and align expectations for all parties involved.
