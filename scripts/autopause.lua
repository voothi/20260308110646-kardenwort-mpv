local mp = require 'mp'

local auto_pause_enabled = true
local current_phrase = ""
local is_auto_paused = false
local original_sub_delay = 0

-- Очистка текста от тегов (чтобы Караоке воспринималось как одна фраза)
local function clean_sub_text(text)
    if not text then return "" end
    local s = text:gsub("{.-}", "")
    s = s:gsub("\\N", " "):gsub("\\n", " ")
    s = s:match("^%s*(.-)%s*$") or ""
    return s
end

-- Отслеживаем изменение текста на экране в реальном времени
mp.observe_property("sub-text", "string", function(name, raw_text)
    if not auto_pause_enabled then return end
    if is_auto_paused then return end -- Не реагируем, пока сами держим паузу

    local stripped = clean_sub_text(raw_text)
    
    -- Игнорируем промежуточные шаги Караоке, где базовый текст тот же
    if stripped == current_phrase then return end
    
    -- Фраза полностью сменилась или исчезла (появился пустой промежуток)
    if current_phrase ~= "" then
        mp.set_property_bool("pause", true)
        is_auto_paused = true
        
        -- Запоминаем текущую синхронизацию и делаем искусственную задержку 0.1 сек,
        -- чтобы предыдущая фраза "вернулась" на экран во время паузы
        original_sub_delay = mp.get_property_number("sub-delay", 0)
        mp.set_property_number("sub-delay", original_sub_delay + 0.1)
    end
    
    current_phrase = stripped
end)

-- Отслеживаем ручное снятие с паузы (нажатие Пробела)
mp.observe_property("pause", "bool", function(name, paused)
    if not paused and is_auto_paused then
        -- Возвращаем нормальную синхронизацию субтитров
        mp.set_property_number("sub-delay", original_sub_delay)
        is_auto_paused = false
    end
end)

-- Защита от багов при ручной перемотке видео мышкой/стрелками
mp.register_event("seek", function()
    current_phrase = ""
    if is_auto_paused then
        mp.set_property_number("sub-delay", original_sub_delay)
        is_auto_paused = false
    end
end)

-- Горячая клавиша для быстрого включения/выключения
mp.add_key_binding("P", "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    mp.osd_message("Автопауза: " .. (auto_pause_enabled and "ВКЛ" or "ВЫКЛ"), 2)
end)