-- some common utility functions
local M = {}

M.table_merge = function(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = M.table_merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end


M.table_sort = function(t, key)
    table.sort(t, function(a, b)
        if a[key] == nil or b[key] == nil then
            return false
        end
        return a[key] < b[key]
    end)
end

return M