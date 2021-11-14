local xml = {}

----------------------------------------

function xml.xmlToTable(xml)
    local tbl, pos = {}, 0
    local parent = tbl
    
    while true do
        local s, e, elem = string.find(xml, "<([^%?][^<>]+)>", pos)
        if not s then break end
        pos = s + 1
        
        if elem[1] == "/" then
            parent = parent.parent or tbl
            continue
        end
        
        local element = {
            parent = parent,
            attributes = {},
            children = {},
            content = string.match(xml, ">([^<>]+)<", pos),
            type = string.match(elem, "([%w_]+) ")
        }
        
        for k, v in string.gmatch(elem, "([%w_-]+)%s*=%s*[\"'](.-)[\"']") do
            element.attributes[k] = v
        end
        
        table.insert(parent.children and parent.children or parent, element)
        
        if elem[-1] ~= "/" then
            parent = element
        end
    end
    
    return tbl
end

----------------------------------------

return xml