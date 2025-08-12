-- Provides simple structured logging with an optional warning method.

local DebugLogger = {}

function DebugLogger.new(prefix, enabled)
    enabled = enabled ~= false

    local logger = {}

    function logger:Warn(...)
        if enabled then
            warn("[" .. prefix .. "]", ...)
        end
    end

    setmetatable(logger, {
        __call = function(_, ...)
            if enabled then
                print("[" .. prefix .. "]", ...)
            end
        end,
    })

    return logger
end

return DebugLogger

