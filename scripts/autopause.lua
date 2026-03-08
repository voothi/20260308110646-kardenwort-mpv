local mp = require 'mp'
local last_paused_sub_end = nil
local auto_pause_enabled = true

local function check_sub_end()
    -- Если функция выключена, ничего не делаем
    if not auto_pause_enabled then return end
    
    local sub_end = mp.get_property_number("sub-end")
    local time_pos = mp.get_property_number("time-pos")
    
    if sub_end ~= nil and time_pos ~= nil then
        -- Ставим на паузу за 0.15 секунд до того, как текст пропадет
        if (sub_end - time_pos) < 0.15 and (sub_end - time_pos) > 0 then
            if last_paused_sub_end ~= sub_end then
                mp.set_property_bool("pause", true)
                last_paused_sub_end = sub_end
            end
        end
    end
end

-- Проверять таймер каждые 0.05 сек
mp.add_periodic_timer(0.05, check_sub_end)

-- Горячая клавиша для быстрого включения/выключения
mp.add_key_binding("P", "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    if auto_pause_enabled then
        mp.osd_message("Автопауза: ВКЛ", 2)
    else
        mp.osd_message("Автопауза: ВЫКЛ", 2)
    end
end)