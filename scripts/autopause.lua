local mp = require 'mp'

-- ==========================================
-- НАСТРОЙКИ
-- ==========================================
local auto_pause_enabled = true
-- Насколько сдвигать субтитры назад при паузе (в секундах), чтобы вернуть текст.
local SUB_DELAY_SHIFT = 0.15 
-- ==========================================

local current_phrase = ""
local is_auto_paused = false
local original_sub_delay = 0
local is_seeking = false

-- Функция для очистки текста от мусора и скрытых переносов
local function clean_sub_text(text)
    if not text then return "" end
    local s = text:gsub("{.-}", "")
    s = s:gsub("\\N", " "):gsub("\\n", " ")
    s = s:match("^%s*(.-)%s*$") or ""
    return s
end

-- Защита: отключаем логику, пока ты вручную перематываешь видео стрелками
mp.register_event("seek", function()
    is_seeking = true
    if is_auto_paused then
        mp.set_property_number("sub-delay", original_sub_delay)
        is_auto_paused = false
    end
end)

-- Когда перемотка закончилась или видео только запустилось — обновляем текст
mp.register_event("playback-restart", function()
    mp.add_timeout(0.1, function()
        is_seeking = false
        current_phrase = clean_sub_text(mp.get_property("sub-text", ""))
    end)
end)

-- Главная логика: следим за изменением текста на экране
mp.observe_property("sub-text", "string", function(name, raw_text)
    if not auto_pause_enabled or is_seeking or is_auto_paused then return end

    local stripped = clean_sub_text(raw_text)
    
    -- Если смысловая часть не изменилась (идет раскраска слов караоке) — игнорируем
    if stripped == current_phrase then return end
    
    -- Если текст сменился на новую фразу, а старый не был пустым -> ПАУЗА
    if current_phrase ~= "" then
        mp.set_property_bool("pause", true)
        is_auto_paused = true
        
        -- Искусственно заставляем плеер отрисовать предыдущую фразу во время паузы
        original_sub_delay = mp.get_property_number("sub-delay", 0)
        mp.set_property_number("sub-delay", original_sub_delay + SUB_DELAY_SHIFT)
    end
    
    current_phrase = stripped
end)

-- Когда ты нажимаешь Пробел (снимаешь с паузы) — возвращаем нормальные субтитры
mp.observe_property("pause", "bool", function(name, paused)
    if not paused and is_auto_paused then
        mp.set_property_number("sub-delay", original_sub_delay)
        
        -- Даем плееру 0.1с, чтобы синхронизировать новые титры, и снимаем блокировку
        mp.add_timeout(0.1, function()
            is_auto_paused = false
            current_phrase = clean_sub_text(mp.get_property("sub-text", ""))
        end)
    end
end)

-- Горячая клавиша (P) для быстрого включения/выключения
mp.add_key_binding("P", "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    mp.osd_message("Автопауза: " .. (auto_pause_enabled and "ВКЛ" or "ВЫКЛ"), 2)
end)