local M = {}

---@param f fun(c: string): (string | nil)
---@return fun(s: string): string
function M.linewise_converter(f)
    return function(s)
        local lines = vim.split(s, "\n")
        lines = vim.tbl_map(function(line)
            return f(line) or line
        end, lines)
        return table.concat(lines, "\n")
    end
end

---@param f fun(c: string): (string | nil)
---@return fun(s: string): string
function M.charwise_converter(f)
    return function(s)
        local chars = vim.fn.split(s, [[\zs]])
        chars = vim.tbl_map(function(char)
            return f(char) or char
        end, chars)
        return table.concat(chars, "")
    end
end

return M
