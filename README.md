# general-converter.nvim

This plugin provides a generic string conversion operator.
By registering some string conversion functions of your choice, you can call these functions as an operator.

## Requirements

- Neovim (`>= 0.9.0` or later)
    - It may work with Neovim older than that although not guaranteed.

## Features

- Run-time selection of which converter function to apply
- Supports dot-repeating

## Usage

1. Register string converters you like using `require("general_converter").setup{}`.

    ```lua
    require("general_converter").setup {
        converters = {
            {
                desc = "Calculate as Vim script expression (e.g. 1 + 2 -> 3)",
                converter = function(text)
                    return vim.fn.string(vim.api.nvim_eval(text))
                end,
                labels = { "calc" },
            },
            {
                desc = "halve indentation",
                converter = require("general_converter.util").linewise_converter(function(line)
                    local _, indent = line:find "^[ ]*"
                    local indent_after = math.floor(indent / 2)
                    if indent_after >= 0 then
                        line = (" "):rep(indent_after) .. line:sub(indent + 1)
                    end
                    return line
                end),
                labels = { "indent" },
            },
            {
                desc = "double indentation",
                converter = require("general_converter.util").linewise_converter(function(line)
                    local _, indent = line:find "^[ ]*"
                    local indent_after = indent * 2
                    if indent_after >= 0 then
                        line = (" "):rep(indent_after) .. line:sub(indent + 1)
                    end
                    return line
                end),
                labels = { "indent" },
            },
        },
    }
    ```

2. Register some key mappings.

    ```lua
    -- Choose converters from pre-defined ones
    vim.keymap.set({ "n", "x" }, "<Space>c", require("general_converter").operator_convert(), { expr = true })
    vim.keymap.set("n", "<Space>cc", require("general_converter").operator_convert_line(), { expr = true })

    -- Choose converters from pre-defined ones with label "indent"
    vim.keymap.set({ "n", "x" }, "<Space>i", require("general_converter").operator_convert "indent", { expr = true })
    vim.keymap.set("n", "<Space>ii", require("general_converter").operator_convert_line "indent", { expr = true })

    -- If there is only one converter labeled "calc", it is automatically selected
    vim.keymap.set({ "n", "x" }, "<Space>C", require("general_converter").operator_convert "calc", { expr = true })
    vim.keymap.set("n", "<Space>CC", require("general_converter").operator_convert_line "calc", { expr = true })

    -- Directly specify the converter
    local function my_converter(text)
        return text:rep(2, "")
    end
    vim.keymap.set({ "n", "x" }, "@r", require("general_converter").operator_convert(my_converter), { expr = true })
    vim.keymap.set("n", "@rr", require("general_converter").operator_convert_line(my_converter), { expr = true })
    ```

3. Have fun!

## Examples

```lua
require("general_converter").setup {
    converters = {
        {
            desc = "half-width alphabets to full-width (abcABC -> ａｂｃＡＢＣ)",
            converter = util.charwise_converter(function(c)
                local codepoint = vim.fn.char2nr(c)
                local start_codepoint = vim.fn.char2nr "A"
                local end_codepoint = vim.fn.char2nr "z"
                if start_codepoint <= codepoint and codepoint <= end_codepoint then
                    codepoint = codepoint + 0xfee0
                    return vim.fn.nr2char(codepoint)
                end
                return nil
            end),
        },
        {
            desc = "hexadecimal number to binary (5A -> 10100101, 0xA5 -> 0b10100101)",
            converter = function(text)
                local prefix = ""
                if text:sub(1, 2) == "0x" then
                    text = text:sub(3)
                    prefix = "0b"
                end
                local num = tonumber(text, 16)
                return vim.fn.printf("%s%b", prefix, num)
            end,
        },
        {
            desc = "Title Case",
            converter = function(text)
                ---@param word string
                ---@return string
                local function capitalize(word)
                    local lower = word:lower()
                    local exception = {
                        "and",
                        "as",
                        "but",
                        "for",
                        "if",
                        "nor",
                        "or",
                        "so",
                        "yet",
                        "a",
                        "an",
                        "the",
                        "as",
                        "at",
                        "by",
                        "for",
                        "in",
                        "of",
                        "off",
                        "on",
                        "per",
                        "to",
                        "up",
                        "via",
                    }
                    if vim.list_contains(exception, lower) then
                        return lower
                    end
                    local new_word = lower:gsub("^.", function(c)
                        return c:upper()
                    end)
                    return new_word
                end
                local new_text = text:gsub("(%w+)", capitalize)
                return new_text
            end,
        },
    },
}
```
