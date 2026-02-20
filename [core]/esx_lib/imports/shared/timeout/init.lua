local xTimeout = {} 

local timeoutsCanceled = {}
local timeouts = 0 

---@param ms number
---@param cb function
---@return number
function xTimeout.set(ms, cb) 
    local id = timeouts + 1 

    SetTimeout(ms, function()
        if timeoutsCanceled[id] then 
            timeoutsCanceled[id] = nil 
            return 
        end

        cb()
    end)

    timeouts = id  

    return id 
end

---@param id number
function xTimeout.cancel(id) 
    timeoutsCanceled[id] = true
end

return xTimeout 