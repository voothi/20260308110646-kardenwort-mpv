local mp = require 'mp'

local auto_pause_enabled = true
local last_paused_sub_end = nil

local function check_sub()
    if not auto_pause_enabled then return end

    local raw_text = mp.get_property("sub-text")
    if not raw_text or raw_text == "" then return end

    -- Ищем точное совпадение с закрывающим тегом {\c} (plain=true отключает регулярки)
    -- Если тег есть — фраза еще произносится (караоке в процессе). Ждем.
    if string.find(raw_text, "{\\c}", 1, true) then
        return
    end

    -- Если тега нет, значит это финальный кадр фразы (или обычный субтитр).
    -- Включаем классическую автопаузу перед самым концом субтитра.
    local sub_end = mp.get_property_number("sub-end")
    local time_pos = mp.get_property_number("time-pos")

    if sub_end ~= nil and time_pos ~= nil then
        -- Пауза за 0.15 сек до того, как текст пропадет с экрана
        if (sub_end - time_pos) < 0.15 and (sub_end - time_pos) > 0 then
            if last_paused_sub_end ~= sub_end then
                mp.set_property_bool("pause", true)
                last_paused_sub_end = sub_end
            end
        end
    end
end

-- Проверять таймер каждые 0.05 сек
mp.add_periodic_timer(0.05, check_sub)

-- Горячая клавиша (Shift + p) для быстрого включения/выключения
mp.add_key_binding("P", "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    mp.osd_message("Автопауза: " .. (auto_pause_enabled and "ВКЛ" or "ВЫКЛ"), 2)
end)