local M = {}

--- 一時的にオプションの値を差し替えて callback を実行する。
--- もとの値は callback 実行後にリストアされる。
function M.with_opt(t)
    return function(callback)
        local backup = {}
        for key, value in pairs(t) do
            backup[key] = vim.opt[key]:get()
            vim.opt[key] = value
        end
        local succeeded, result = pcall(callback)
        for key, value in pairs(backup) do
            vim.opt[key] = value
        end
        if succeeded then
            return result
        else
            error(result)
        end
    end
end

--- レジスタを一時的に借りる。もとの値は callback 実行後にリストアされる。
function M.borrow_register(t)
    return function(callback)
        local backup = {}
        for _, reg in ipairs(t) do
            backup[reg] = vim.fn.getreginfo(reg)
        end
        local succeeded, result = pcall(callback)
        for reg, value in pairs(backup) do
            vim.fn.setreg(reg, value)
        end
        if succeeded then
            return result
        else
            error(result)
        end
    end
end

function M.sync_ui_select(items, opts, on_choice)
    local prompt = opts.prompt or "Select one of:"
    local format_item = opts.format_item or tostring
    local t = { prompt }
    for idx, item in ipairs(items) do
        t[#t + 1] = tostring(idx) .. ". " .. format_item(item)
    end
    local result = vim.fn.inputlist(t)
    on_choice(items[result])
end

return M
