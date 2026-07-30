-- script4.lua
function my_function(a, b)
    return a * b
end

function consume_table(table_)
    return table_[1] + table_[2]
end

function consume_table2(table_)
    -- return table
    local result = {}
    table.insert(result, table_[1]+ table_[2])
    return result
end
