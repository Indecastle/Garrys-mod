local syntax = {}

--------------------

local syntaxEnvironment = {
    keywords = {
        ["and"] = true,
        ["break"] = true,
        ["do"] = true,
        ["else"] = true,
        ["elseif"] = true,
        ["end"] = true,
        ["for"] = true,
        ["function"] = true,
        ["if"] = true,
        ["in"] = true,
        ["local"] = true,
        ["not"] = true,
        ["or"] = true,
        ["repeat"] = true,
        ["return"] = true,
        ["then"] = true,
        ["until"] = true,
        ["while"] = true,
        ["goto"] = true
    }, tokens = {
        ["%+"] = true,
        ["%-"] = true,
        ["%*"] = true,
        ["/"] = true,
        ["%%"] = true,
        ["%^"] = true,
        ["#"] = true,
        ["!"] = true,
        ["~"] = true,
        ["<"] = true,
        [">"] = true,
        ["="] = true,
        [";"] = true,
        [":"] = true,
        [","] = true,
        ["%."] = true
    }, values = {
        ["true"] = true,
        ["false"] = true,
        ["nil"] = true,
        ["CLIENT"] = true,
        ["SERVER"] = true,
        ["_G"] = true,
    }, functions = _G
}

local tokenPatern = "["
for k, v in pairs(syntaxEnvironment.tokens) do
    tokenPatern = tokenPatern .. k
end

tokenPatern = tokenPatern .. "]"

--------------------

syntax.colorTable = {
    ["function"] = Color(102, 217, 239),
    keyword = Color(249, 38, 114),
    token = Color(249, 38, 114),
    string = Color(230, 219, 116),
    value = Color(174, 129, 255),
    number = Color(174, 129, 255),
    comment = Color(117, 113, 94),
    rest = Color(248, 248, 242),
    functionName = Color(151, 224, 41),
    functionArgs = Color(255, 174, 0)
}

function syntax.validate(code)
    if #code > 0 and type(code) == "string" then
        local err = loadstring(code)
        
        if type(err) == "string" then
            if string.find(err, "SF:table:") then
                local s = 0
                
                for i = 1, 3 do
                    s = string.find(err, ":", s) + 1
                end
                
                return false, "line " .. string.sub(err, s), tonumber(string.sub(err, s, string.find(err, ":", s) - 1))
            else
                return false, err
            end
        end
        
        return true, "Validation successful!"
    end
    
    return false, "Invalid script - or to short"
end

function syntax.setEnvironment(tbl)
    syntaxEnvironment.functions = tbl
end

function syntax.color(code, dataTable)
    local lines = string.split(code, "\n")
    local data = {
        rest = {},
        string = {},
        keyword = {},
        value = {},
        ["function"] = {},
        number = {},
        token = {},
        comment = {},
        functionName = {},
        functionArgs = {}
    }
    local data2 = table.copy(data)
    
    for k, v in pairs(data) do
        for i = 1, #lines do
            data[k][i] = ""
        end
    end
    
    ----------
    
    local addData
    
    if dataTable then
        addData = function(typ, data, pos)
            table.insert(data2[typ], {
                type = data,
                pos = pos
            })
        end
    else
        addData = function() end
    end
    
    ----------
    
    local isString = {state = false, typ = "", start = 0, multi = false} --typ is the comment type example: '[[' will be typ ']]' (because ]] is closing), multi would also be set to true in case of multiline comment
    local isFunction = false
    local customFunction
    
    for lineInd, line in pairs(lines) do
        local i = 1
        
        while i <= #line do
            local findPos, findData = math.huge, nil
            --local commentFind = string.find(line, "%-%-%[?[=]*%[?", i)
            
            ---String---
            if isString.state then
                --There currently is a string active
                local pos, prevChar, char = string.match(line, "()(.)(" .. isString.typ .. ")", i)
                if pos and (isString.multi or (not isString.multi and prevChar ~= "\\")) then
                    --print("quit da string " .. filter .. " ; " .. char)
                    findPos = pos
                    findData = {
                        type = isString.type,
                        type2 = "string",
                        add = string.sub(line, i, pos) .. char,
                        off = true
                    }
                end
            else
                --There currently is no string active
                
                local i2 = i
                while i2 <= #line do
                    local pos, prevChar, char = string.match(line, "()([\\]?)(\"\"?)", i2)
                    if pos and pos < findPos then
                        if prevChar ~= "\\" then
                            findPos = pos
                            findData = {
                                type = "string",
                                type2 = "string",
                                add = char,
                                dont = (char == "\"\""),
                                startPos = pos + 1,
                                typ = char,
                                len = 1
                            }
                            
                            i2 = math.huge
                        else
                            i2 = pos + 2
                        end
                    else
                        i2 = math.huge
                    end
                end
                
                local i2 = i
                while i2 <= #line do
                    local pos, prevChar, char = string.match(line, "()([\\]?)(''?)", i2)
                    if pos and pos < findPos then
                        if prevChar ~= "\\" then
                            findPos = pos
                            findData = {
                                type = "string",
                                type2 = "string",
                                add = char,
                                dont = (char == "\"\""),
                                startPos = pos + 1,
                                typ = char,
                                len = 1
                            }
                            
                            i2 = math.huge
                        else
                            i2 = pos + 2
                        end
                    else
                        i2 = math.huge
                    end
                end
                
                local special = ((lineInd == 1) and "#?" or "")
                local pos, prevChar, char = string.match(line, "()(" .. special .. ")([%-]*%[=*%[)", i)
                if pos and pos < findPos then
                    pos = pos + ((prevChar == "#" and pos ~= 1) and 1 or 0)
                    
                    if prevChar == "#" and pos == 1 then
                        findPos = pos
                        findData = {
                            type = "comment",
                            add = string.sub(line, findPos)
                        }
                    else
                        local rchar = string.replace(char, "-", "")
                        local comment = (#char - #rchar) >= 2
                        
                        findPos = pos
                        findData = {
                            type = comment and "comment" or "string",
                            type2 = "string",
                            add = char,
                            startPos = pos + #char,
                            multi = true,
                            typ = "%]" .. string.rep("=", #rchar - 2) .. "%]",
                            len = #rchar
                        }
                    end
                end
            end
            
            if not isString.state then
                ---Custom Function Colors---
                if customFunction then
                    if customFunction == 1 then
                        local pos, name, args = string.match(line, "()([%w_]*)(%([^%)]+%))", i)
                        if name and #name > 0 then
                            local pos, char = string.match(line, "()([%w_]+)", i)
                            findPos = pos
                            findData = {
                                type = "functionName",
                                add = char
                            }
                            
                            customFunction = 2
                        else
                            if args and #args > 0 then
                                local pos, char = string.match(line, "()([^%)]+)", i + 1)
                                findPos = pos
                                findData = {
                                    type = "functionArgs",
                                    add = char
                                }
                            end
                            
                            customFunction = nil
                        end
                    else
                        local pos, char = string.match(line, "()([^%)]+)", i + 1)
                        findPos = pos
                        findData = {
                            type = "functionArgs",
                            add = char
                        }
                        
                        customFunction = nil
                    end
                end
                
                ---Comment---
                do
                    local pos, char = string.match(line, "()(%-%-)", i2)
                    if pos and pos < findPos then
                        findPos = pos
                        findData = {
                            type = "comment",
                            add = string.sub(line, findPos)
                        }
                    end
                end
                
                ---Keywords---
                local i2 = i
                while i2 <= #line do
                    local pos, char = string.match(line, "()(%w+)", i2)
                    if pos and pos < findPos then
                        if string.find(char[1], "%D") and syntaxEnvironment.keywords[char] then
                            findPos = pos
                            findData = {
                                type = "keyword",
                                add = char
                            }
                            
                            i2 = math.huge
                        else
                            i2 = pos + #char
                        end
                    else
                        i2 = math.huge
                    end
                end
                
                ---Values---
                local i2 = i
                while i2 <= #line do
                    local pos, char = string.match(line, "()([_%w]+)", i2)
                    if pos and pos < findPos then
                        if string.find(char[1], "%D") and syntaxEnvironment.values[char] then
                            findPos = pos
                            findData = {
                                type = "value",
                                add = char
                            }
                            
                            i2 = math.huge
                        else
                            i2 = pos + #char
                        end
                    else
                        i2 = math.huge
                    end
                end
                
                ---Functions---
                local i2 = i
                while i2 <= #line do
                    local pos, hasDot, valid, char = string.match(line, "()(%.?)(%d?)(%a+[%a%d]+)", i2)
                    if pos and pos < findPos then
                        if valid and ((not isFunction and syntaxEnvironment.functions[char]) or (hasDot and isFunction and syntaxEnvironment.functions[isFunction][char])) then
                            findPos = pos
                            findData = {
                                type = "function",
                                add = ((hasDot and isFunction) and "." or "") .. char,
                                istbl = type(syntaxEnvironment.functions[char]) == "table" and not isFunction
                            }
                            
                            i2 = math.huge
                        else
                            i2 = pos + #char
                        end
                    else
                        i2 = math.huge
                    end
                end
                
                ---Numbers---
                local i2 = i
                while i2 <= #line do
                    local pos, char = string.match(line, "()([^%d_]%.?[%d]+)", i2)
                    if pos and pos < findPos then
                        if string.find(char[1], "[%.%d]") then
                            findPos = pos
                            findData = {
                                type = "number",
                                add = char
                            }
                            
                            i2 = math.huge
                        elseif string.find(char[1], "[%A]") then
                            findPos = pos + 1
                            findData = {
                                type = "number",
                                add = string.sub(char, 2)
                            }
                            
                            i2 = math.huge
                        else
                            i2 = pos + #char
                        end
                    else
                        i2 = math.huge
                    end
                end
                
                ---Tokens---
                local i2 = i
                while i2 <= #line do
                    local pos, char = string.match(line, "()(" .. tokenPatern .. "+)", i)
                    if pos and pos < findPos then
                        findPos = pos
                        findData = {
                            type = "token",
                            add = char
                        }
                    else
                        i2 = math.huge
                    end
                end
            end
            
            
            -----Line Adding
            if findData then
                if isString.state then
                    local add = string.sub(line, i, findPos + isString.len)
                    
                    for k, v in pairs(data) do
                        if k == findData.type then
                            v[lineInd] = v[lineInd] .. add
                            addData(k, add, {x = #v[lineInd] - #add + 1, y = lineInd})
                        else
                            v[lineInd] = v[lineInd] .. string.rep(" ", #add)
                        end
                    end
                    
                    i = findPos + isString.len + 1
                    isString = {state = false, typ = "", start = 0, multi = false}
                else
                    if findData.type == "function" then
                        if findData.istbl then
                            isFunction = findData.add
                        else
                            isFunction = nil
                        end
                    else
                        isFunction = nil
                        
                        if findData.type2 == "string" and not findData.dont then
                            isString = {
                                state = true,
                                type = findData.type,
                                typ = findData.typ,
                                start = findData.startPos,
                                line = lineInd,
                                multi = findData.multi,
                                len = findData.len
                            }
                        elseif findData.type == "keyword" then
                            if findData.add == "function" then
                                customFunction = 1
                            end
                        end
                    end
                    
                    for k, v in pairs(data) do
                        if k == findData.type then
                            v[lineInd] = v[lineInd] .. string.rep(" ", findPos - i) .. findData.add
                            addData(k, findData.add, {x = #v[lineInd] - #findData.add + 1, y = lineInd})
                        elseif k ~= "rest" then
                            v[lineInd] = v[lineInd] .. string.rep(" ", (findPos - i) + #findData.add)
                        else
                            v[lineInd] = v[lineInd] .. string.sub(line, i, findPos - 1) .. string.rep(" ", #findData.add)
                        end
                    end
                    
                    i = findPos + #findData.add
                end
            else
                if isString.state then
                    for k, v in pairs(data) do
                        if k == isString.type then
                            local start = isString.start
                            
                            if isString.line ~= lineInd then
                                start = 1
                            end
                            
                            local text = string.sub(line, start, #line)
                            
                            v[lineInd] = v[lineInd] .. text
                            addData(k, text, {x = #v[lineInd] - #text + 1, y = lineInd})
                        else
                            v[lineInd] = v[lineInd] .. string.rep(" ", #line - i)
                        end
                    end
                else
                    for k, v in pairs(data) do
                        if k ~= "rest" then
                            v[lineInd] = v[lineInd] .. string.rep(" ", #line - i)
                        else
                            v[lineInd] = v[lineInd] .. string.sub(line, i, #line)
                        end
                    end
                end
                
                customFunction = nil
                if isString.state then
                    if not isString.multi then
                        isString = {state = false, typ = "", start = 0, multi = false}
                    end
                end
                
                break
            end
        end
    end
    
    local tbl = {}
    for k, v in pairs(data) do
        tbl[k] = table.concat(v, "\n")
    end
    
    return tbl, data2
end

--------------------

return syntax
