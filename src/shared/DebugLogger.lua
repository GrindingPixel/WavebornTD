-- DebugLogger.lua
-- Shared debug logging utility

local function new(prefix, enabled)
    enabled = enabled ~= false

    local function log(...)
        if enabled then
            print("[" .. prefix .. "]", ...)
        end
    end

    local function warnf(...)
        if enabled then
            warn("[" .. prefix .. "]", ...)
        end
    end

    return log, warnf
end

return {
    new = new,
}

