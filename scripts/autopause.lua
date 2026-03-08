local mp = require 'mp'

-- =========================================================================
-- НАСТРОЙКИ СКРИПТА
-- =========================================================================

-- Включить режим "Караоке" (склеивает слова одной фразы и делает паузу только в конце)
local karaoke_mode = true

-- Включить саму автопаузу по умолчанию при запуске плеера
local auto_pause_enabled = true

-- =========================================================================

local last_paused_sub_end = nil
local current_phrase = ""
local last_paused_phrase = ""
local last_time_pos = 0

-- Функция для очистки текста от ASS-тегов и спецсимволов
local function clean_sub_text(text)
    if not text then return "" end
    -- Удаляем любые теги внутри фигурных скобок { ... }
    local s = text:gsub("{.-}", "")
    -- Заменяем принудительные переносы строк на пробелы
    s = s:gsub("\\N", " "):gsub("\\n", " ")
    -- Обрезаем случайные пробелы по краям
    s = s:match("^%s*(.-)%s*$") or ""
    return s
end

local function check_sub()
    if not auto_pause_enabled then return end

    local time_pos = mp.get_property_number("time-pos")
    if time_pos == nil then return end

    if karaoke_mode then
        local time_diff = math.abs(time_pos - last_time_pos)
        last_time_pos = time_pos

        -- Защита от ручной перемотки: если скачок больше 0.5 сек (пользователь мотает видео),
        -- сбрасываем кэш, чтобы скрипт не поставил ложную паузу.
        if time_diff > 0.5 then
            current_phrase = clean_sub_text(mp.get_property("sub-text", ""))
            last_paused_phrase = ""
            return
        end

        local raw_text = mp.get_property("sub-text", "")
        local stripped = clean_sub_text(raw_text)

        -- Если очищенный текст изменился, значит фраза закончилась
        if stripped ~= current_phrase then
            if current_phrase ~= "" and current_phrase ~= last_paused_phrase then
                -- Ставим паузу и делаем микро-шаг назад (0.08 сек), 
                -- чтобы предыдущая фраза со всеми подсветками вернулась на экран
                mp.set_property_bool("pause", true)
                mp.commandv("seek", -0.08, "relative", "exact")
                last_paused_phrase = current_phrase
                return
            end
            current_phrase = stripped
        end
    else
        -- Оригинальная логика для обычных субтитров (пауза по таймеру окончания)
        local sub_end = mp.get_property_number("sub-end")
        
        if sub_end ~= nil then
            if (sub_end - time_pos) < 0.15 and (sub_end - time_pos) > 0 then
                if last_paused_sub_end ~= sub_end then
                    mp.set_property_bool("pause", true)
                    last_paused_sub_end = sub_end
                end
            end
        end
    end
end

-- Проверять таймер каждые 0.05 сек
mp.add_periodic_timer(0.05, check_sub)

-- Горячая клавиша для быстрого включения/выключения автопаузы
mp.add_key_binding("P", "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    if auto_pause_enabled then
        mp.osd_message("Автопауза: ВКЛ", 2)
    else
        mp.osd_message("Автопауза: ВЫКЛ", 2)
    end
end)