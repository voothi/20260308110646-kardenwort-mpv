local mp = require 'mp'

local auto_pause_enabled = true
local last_paused_sub_end = nil

local function check_sub()
    if not auto_pause_enabled then return end

    -- ЗАПРАШИВАЕМ СЫРОЙ ТЕКСТ С ТЕГАМИ. 
    -- Обычный "sub-text" удаляет все теги, поэтому скрипт их не видел.
    -- Используем sub-text/ass (или sub-text-ass для старых версий плеера)
    local raw_text = mp.get_property("sub-text/ass") or mp.get_property("sub-text-ass")
    if not raw_text or raw_text == "" then return end

    -- Ищем точное совпадение с закрывающим тегом {\c}.
    -- Если тег есть — это промежуточное слово (фраза еще подсвечивается). Ждем.
    if string.find(raw_text, "{\\c}", 1, true) then
        return
    end

    -- Если тега нет — это финальная строчка (подсвечена вся фраза целиком).
    -- Включаем таймер для классической автопаузы.
    local sub_end = mp.get_property_number("sub-end")
    local time_pos = mp.get_property_number("time-pos")

    if sub_end ~= nil and time_pos ~= nil then
        -- Ставим видео на паузу за 0.15 сек до того, как текст пропадет с экрана
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

-- Горячая клавиша для быстрого включения/выключения
mp.add_key_binding("P", "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    mp.osd_message("Автопауза: " .. (auto_pause_enabled and "ВКЛ" or "ВЫКЛ"), 2)
end)