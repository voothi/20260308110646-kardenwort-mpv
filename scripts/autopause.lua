local mp = require 'mp'

-- =========================================================================
-- НАСТРОЙКИ СКРИПТА
-- =========================================================================

-- Включена ли автопауза сразу при запуске плеера (true - да, false - нет)
local auto_pause_enabled = true

-- Останавливаться ли на КАЖДОМ слове в режиме караоке?
-- false = проигрывать фразу целиком и делать паузу только в конце.
-- true = ставить на паузу после каждого произнесенного слова.
local pause_every_word = false

-- Горячая клавиша для быстрого включения/выключения автопаузы
local toggle_key = "P"

-- Горячая клавиша для переключения режима "Пауза на каждом слове"
local toggle_mode_key = "K"

-- Тег, по которому скрипт понимает, что караоке-фраза еще произносится.
local karaoke_token = "{\\c}"

-- За сколько секунд до исчезновения текста ставить видео на паузу
-- (0.15 обычно идеально, чтобы текст оставался на экране)
local pause_padding = 0.15

-- Как часто скрипт проверяет время (в секундах). 
-- 0.05 - оптимальный баланс между точностью паузы и нагрузкой на плеер.
local check_interval = 0.05

-- =========================================================================
-- ОСНОВНОЙ КОД (НИЖЕ МОЖНО НЕ МЕНЯТЬ)
-- =========================================================================

local last_paused_sub_end = nil

local function check_sub()
    if not auto_pause_enabled then return end

    -- Запрашиваем сырой текст со всеми ASS-тегами
    local raw_text = mp.get_property("sub-text/ass") or mp.get_property("sub-text-ass")
    if not raw_text or raw_text == "" then return end

    -- Если режим "пауза на каждом слове" ВЫКЛЮЧЕН, мы ищем токен, чтобы пропустить промежуточные слова.
    -- Если ВКЛЮЧЕН — мы просто игнорируем этот блок и всегда переходим к паузе.
    if not pause_every_word then
        if string.find(raw_text, karaoke_token, 1, true) then
            return
        end
    end

    -- Включаем таймер для автопаузы
    local sub_end = mp.get_property_number("sub-end")
    local time_pos = mp.get_property_number("time-pos")

    if sub_end ~= nil and time_pos ~= nil then
        -- Ставим видео на паузу за заданное время до того, как текст пропадет с экрана
        if (sub_end - time_pos) < pause_padding and (sub_end - time_pos) > 0 then
            if last_paused_sub_end ~= sub_end then
                mp.set_property_bool("pause", true)
                last_paused_sub_end = sub_end
            end
        end
    end
end

-- Запуск периодической проверки таймера
mp.add_periodic_timer(check_interval, check_sub)

-- Регистрация горячей клавиши (вкл/выкл самой автопаузы)
mp.add_key_binding(toggle_key, "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    mp.osd_message("Автопауза: " .. (auto_pause_enabled and "ВКЛ" or "ВЫКЛ"), 2)
end)

-- Регистрация горячей клавиши (переключение режима караоке)
mp.add_key_binding(toggle_mode_key, "toggle-karaoke-mode", function()
    pause_every_word = not pause_every_word
    if pause_every_word then
        mp.osd_message("Режим: ПАУЗА НА КАЖДОМ СЛОВЕ", 2)
    else
        mp.osd_message("Режим: ПАУЗА В КОНЦЕ ФРАЗЫ", 2)
    end
end)