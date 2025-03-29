local misc = require("general_converter.misc")
local M = {}

---@alias Config {converters: ConvertConfig[]}
---@alias ConvertConfig {desc: string, converter: Converter, labels?: string[]}
---@alias Converter fun(text: string): string

---@alias ConverterStateDetermined {determined: true, converter: Converter}
---@alias ConverterStateNotDetermined  {determined: false, cands: ConvertConfig[]}
---@alias ConverterState ConverterStateDetermined | ConverterStateNotDetermined

-- Check if the argument is a valid list (which does not contain nil).
---@param name string
---@param list any[]
---@param arg1 string | function
---@param arg2? string
local function validate_list(name, list, arg1, arg2)
    if not vim.islist(list) then
        error(("%s is not list."):format(name))
    end

    if type(arg1) == "string" then
        local typename, _ = arg1, arg2

        local count_idx = 0
        for idx, value in ipairs(list) do
            count_idx = idx
            if type(value) ~= typename then
                error(("Type error: %s[%d] should have type %s, got %s"):format(name, idx, typename, type(value)))
            end
        end

        if count_idx ~= #list then
            error(("The %s[%d] is nil. nil is not allowed in a list."):format(name, count_idx + 1))
        end
    else
        local checkf, errormsg = arg1, arg2

        local count_idx = 0
        for idx, value in ipairs(list) do
            count_idx = idx
            local ok, err = checkf(value)
            if not ok then
                error(("List validation error: %s[%d] does not satisfy '%s' (%s)"):format(name, idx, errormsg, err))
            end
        end

        if count_idx ~= #list then
            error(("The %s[%d] is nil. nil is not allowed in valid list."):format(name, count_idx + 1))
        end
    end
end

---@type ConverterState
local converter_state = { determined = false, cands = {} }
---@type ConvertConfig[]
local converters = {}

function M._op(type)
    -- Choose converter

    ---@type Converter | nil
    local converter = nil
    if converter_state.determined then
        converter = converter_state.converter
    else
        if #converter_state.cands >= 1 then
            vim.ui.select(converter_state.cands, {
                format_item = function(item)
                    return item.desc
                end,
            }, function(item)
                if item ~= nil then
                    converter = item.converter
                end
            end)
        else
            error("cannot find any valid converter.")
        end
    end

    -- save converter for dot repeating
    if converter == nil then
        return
    end
    converter_state = { determined = true, converter = converter }

    misc.with_opt { selection = "inclusive" }(function()
        misc.borrow_register { "m" }(function()
            local visual_range
            if type == "line" then
                visual_range = "'[V']"
            else
                visual_range = "`[v`]"
            end
            vim.cmd("normal! " .. visual_range .. '"my')
            local content = vim.fn.getreg("m", nil, nil)
            local new_content = converter(content, type)
            if content == new_content then
                return
            end

            if type == "line" then
                vim.fn.setreg("m", new_content, "V")
            else
                vim.fn.setreg("m", new_content, "v")
            end
            vim.cmd("normal! " .. visual_range .. '"mp')
        end)
    end)
end

---@param config Config
function M.setup(config)
    if config.converters == nil then
        config.converters = {}
    end
    validate_list("converters", config.converters, function(t)
        if t.desc == nil then
            return nil, "missing field: desc"
        end
        if t.converter == nil then
            return nil, "missing field: converter"
        end
        if type(t.converter) ~= "function" then
            return nil, "converter is not callable"
        end
        return true
    end, "Converters")
    converters = config.converters
end

---@param converter? Converter | string
---@return fun(): string
function M.operator_convert(converter)
    return function()
        if type(converter) == "function" then
            converter_state = { determined = true, converter = converter }
        elseif type(converter) == "string" then
            local cands = vim.tbl_filter(
                ---@param convert_config ConvertConfig
                ---@return boolean
                function(convert_config)
                    return vim.tbl_contains(convert_config.labels or {}, converter)
                end,
                converters
            )
            if #cands == 1 then
                converter_state = { determined = true, converter = cands[1].converter }
            else
                converter_state = { determined = false, cands = cands }
            end
        else
            converter_state = { determined = false, cands = converters }
        end
        vim.opt.operatorfunc = "general_converter#operator"
        return "g@"
    end
end

---@param converter? Converter | string
---@return fun(): string
function M.operator_convert_line(converter)
    return function()
        return M.operator_convert(converter)() .. "_"
    end
end

return M
