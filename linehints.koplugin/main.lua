local Device = require("device")
if not Device:hasKeyboard() then
    return { disabled = true }
end

local Blitbuffer = require("ffi/blitbuffer")
local InputContainer = require("ui/widget/container/inputcontainer")
local TextWidget = require("ui/widget/textwidget")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local Size = require("ui/size")
local Font = require("ui/font")
local logger = require("logger")
local _ = require("gettext")

local LineHints = InputContainer:extend{
    name = "linehints",
    is_doc_only = true,
}

local ITEM_SHORTCUTS = {
    "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
    "A", "S", "D", "F", "G", "H", "J", "K", "L",
    "Z", "X", "C", "V", "B", "N", "M",
}

function LineHints:init()
    self.visible = false
    self.line_infos = {}

    self.key_events = {
        ToggleLineHints = { { "Alt", "L" } },
        LineHintJump = { { ITEM_SHORTCUTS }, event = "LineHintJump" },
    }

    if self.view then
        self.view:registerViewModule("linehints", self)
    end
end

function LineHints:onToggleLineHints()
    self.visible = not self.visible
    if self.visible then
        self:recomputeLines()
    else
        self.line_infos = {}
    end
    UIManager:setDirty(self.dialog, "ui")
    return true
end

function LineHints:onLineHintJump(_, keyevent)
    if not self.visible then return end
    for idx, letter in ipairs(ITEM_SHORTCUTS) do
        if letter == keyevent.key then
            if self.line_infos[idx] then
                self:jumpToLine(idx)
            end
            return true
        end
    end
end

function LineHints:recomputeLines()
    self.line_infos = {}

    if not self.ui or not self.ui.document then return end
    -- This plugin only supports reflowable/CRE documents (EPUB, MOBI, AZW3, etc.).
    if self.ui.paging then return end

    local screen_w = Screen:getWidth()
    local screen_h = Screen:getHeight()

    local res = self.ui.document:getTextFromPositions(
        {x = 0, y = 0},
        {x = screen_w, y = screen_h},
        true) -- do not draw selection
    if not res or not res.pos0 or not res.pos1 then return end

    local line_boxes = self.ui.document:getScreenBoxesFromPositions(res.pos0, res.pos1, true)
    if not line_boxes or #line_boxes == 0 then return end

    local margins = self.ui.document:getPageMargins()
    local left_margin = margins and margins["left"] or 0
    if left_margin <= 0 then return end

    local badge_size = Screen:scaleBySize(22)
    local sc_face = Font:getFace("scfont", 14)

    for idx, line_box in ipairs(line_boxes) do
        if idx > #ITEM_SHORTCUTS then break end

        local text_widget = TextWidget:new{
            text = ITEM_SHORTCUTS[idx],
            face = sc_face,
        }
        local text_size = text_widget:getSize()
        local badge_w = math.max(badge_size, text_size.w + Screen:scaleBySize(8))
        local badge_h = math.max(badge_size, text_size.h + Screen:scaleBySize(6))

        -- Center the badge in the left margin.
        local badge_x = math.floor((left_margin - badge_w) / 2)
        local badge_y = math.floor(line_box.y + line_box.h / 2 - badge_h / 2)

        self.line_infos[idx] = {
            letter = ITEM_SHORTCUTS[idx],
            line_box = line_box,
            text_widget = text_widget,
            badge_w = badge_w,
            badge_h = badge_h,
            badge_x = badge_x,
            badge_y = badge_y,
        }
    end
end

function LineHints:jumpToLine(idx)
    local info = self.line_infos[idx]
    if not info then return end

    -- Find the first word on this line so the indicator lands exactly on it.
    local probe_x = info.line_box.x + Size.border.thick
    local probe_y = info.line_box.y + info.line_box.h / 2
    local word = self.ui.document:getWordFromPosition({x = probe_x, y = probe_y}, true)

    local target_rect
    if word and word.sbox then
        target_rect = word.sbox:copy()
    else
        -- Fallback: place indicator at the start of the line.
        target_rect = Geom:new{
            x = info.line_box.x,
            y = info.line_box.y,
            w = math.max(Size.border.thick * 4, info.line_box.h),
            h = info.line_box.h,
        }
    end

    -- Activate the highlight indicator if it is not already active.
    self.ui.highlight:onStartHighlightIndicator()

    -- Move the indicator to the target word/line.
    local old_pos = self.ui.highlight._current_indicator_pos
    if old_pos then
        UIManager:setDirty(self.dialog, "ui", old_pos)
    end
    self.ui.highlight._current_indicator_pos = target_rect
    self.view.highlight.indicator = target_rect
    UIManager:setDirty(self.dialog, "ui", target_rect)

    return true
end

function LineHints:paintTo(bb, x, y)
    if not self.visible then return end
    for _, info in ipairs(self.line_infos) do
        -- White background.
        bb:paintRect(x + info.badge_x, y + info.badge_y,
            info.badge_w, info.badge_h, Blitbuffer.COLOR_WHITE)
        -- Black border.
        bb:paintBorder(x + info.badge_x, y + info.badge_y,
            info.badge_w, info.badge_h, Size.border.default, Blitbuffer.COLOR_BLACK)
        -- Centered letter.
        local text_size = info.text_widget:getSize()
        local text_x = x + info.badge_x + math.floor((info.badge_w - text_size.w) / 2)
        local text_y = y + info.badge_y + math.floor((info.badge_h - text_size.h) / 2)
        info.text_widget:paintTo(bb, text_x, text_y)
    end
end

-- Recompute hints whenever the document view changes.
function LineHints:onPageUpdate()
    if self.visible then
        self:recomputeLines()
        UIManager:setDirty(self.dialog, "ui")
    end
end

function LineHints:onPosUpdate()
    if self.visible then
        self:recomputeLines()
        UIManager:setDirty(self.dialog, "ui")
    end
end

function LineHints:onChangeViewMode()
    if self.visible then
        self:recomputeLines()
        UIManager:setDirty(self.dialog, "ui")
    end
end

function LineHints:onSetStatusLine()
    if self.visible then
        self:recomputeLines()
        UIManager:setDirty(self.dialog, "ui")
    end
end

function LineHints:onSetPageMargins()
    if self.visible then
        self:recomputeLines()
        UIManager:setDirty(self.dialog, "ui")
    end
end

return LineHints
