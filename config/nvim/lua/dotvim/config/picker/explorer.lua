local M = {}

---@param picker snacks.Picker
---@param item snacks.picker.Item
---@return snacks.picker.Item[]
local function get_siblings(picker, item)
    local siblings = vim.iter(picker.list.items)
        :filter(function(sib)
            return sib.parent == item.parent
        end)
        :totable()

    table.sort(siblings, function(a, b)
        return a.idx < b.idx
    end)
    return siblings
end

---@param picker snacks.Picker
---@param file string
local function goto_file(picker, file)
    require('snacks.explorer.actions').reveal(picker, file)
end

---@param fn fun(siblings: snacks.picker.Item[], item: snacks.picker.Item): snacks.picker.Item
---@return fun(picker: snacks.Picker, item: snacks.picker.Item)
local function sibling_action(fn)
    return function(picker, item)
        local siblings = get_siblings(picker, item)
        local sib = fn(siblings, item)
        goto_file(picker, sib.file)
    end
end

local actions = {}

function actions.first(siblings)
    return siblings[1]
end

function actions.last(siblings)
    return siblings[#siblings]
end

function actions.prev(siblings, item)
    for idx, sib in ipairs(siblings) do
        if sib == item then
            return siblings[math.max(idx - 1, 1)]
        end
    end
end

function actions.next(siblings, item)
    for idx, sib in ipairs(siblings) do
        if sib == item then
            return siblings[math.min(idx + 1, #siblings)]
        end
    end
end

local function git_diff(path)
    require('dotvim.util.git').show_diff(path)
end

M.actions = {
    sibling_first = sibling_action(actions.first),
    sibling_last = sibling_action(actions.last),
    sibling_prev = sibling_action(actions.prev),
    sibling_next = sibling_action(actions.next),
    git_diff = function(_, item)
        git_diff(item.file)
    end,
}

return M
