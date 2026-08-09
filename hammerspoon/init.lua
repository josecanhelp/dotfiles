--------------------------------------------------------------------------------
-- JoseCanHelp - https://github.com/josecanhelp
--
-- This is my Hammerspoon init file. It is a big mix of inspiration from
-- others as well as my own work. Attributions and Inspirations below.
--
-- Feel free to steal any of this and use it for your own workflow.
--
-- Find your own liberation from default keybindings.
--------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------------------------------------------

require('helpers')
require('appBundles')
local chain = require('chain')
require('experimental')

----------------------------------------------------------------------------------------------------
-- Local State
----------------------------------------------------------------------------------------------------

local activeModal = nil
local hsapp_list = nil
local hspoon_list = nil

----------------------------------------------------------------------------------------------------
-- General Settings
----------------------------------------------------------------------------------------------------

hs.hotkey.alertDuration = 0
hs.window.animationDuration = 0
hs.application.enableSpotlightForNameSearches(true)

----------------------------------------------------------------------------------------------------
-- Configuration File Auto-Reload
----------------------------------------------------------------------------------------------------

-- Goku
hs.pathwatcher.new(os.getenv('HOME') .. '/.config/karabiner/', function()
    -- Absolute path, not bare 'goku'. Hammerspoon is a GUI app launched by
    -- launchd, so hs.execute runs under a minimal PATH that has no Nix
    -- entries. /run/current-system/sw/bin is a stable symlink maintained by
    -- nix-darwin, so this survives rebuilds. The old /usr/local/bin/goku was
    -- an Intel Homebrew path and has not existed since the ARM migration.
    local output = hs.execute('/run/current-system/sw/bin/goku')
    hs.notify.new({ title = 'Karabiner Config', informativeText = output }):send()
end):start()

-- Hammerspoon
hs.loadSpoon('ReloadConfiguration')
spoon.ReloadConfiguration:start()
hs.notify.new({ title = 'Hammerspoon', informativeText = 'Config loaded' }):send()

----------------------------------------------------------------------------------------------------
-- Lazy Load Spoons that aren't needed on script initialization
----------------------------------------------------------------------------------------------------

if not hspoon_list then
    hspoon_list = {
        'ModalMgr',
        'WinWin',
    }
end

for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

----------------------------------------------------------------------------------------------------
-- Add menubar items to track currently enabled Mode (Modal) and current space
----------------------------------------------------------------------------------------------------

local modeMenuBar = hs.menubar.new():setTitle('Normal');
local spaceMenuBar = hs.menubar.new():setTitle('Space 1');

-- Function to update space indicator
local function updateSpaceIndicator()
    local currentSpace = hs.spaces.focusedSpace()
    local allSpaces = hs.spaces.allSpaces()
    local spaceIndex = 1

    -- Find the index of the current space
    for screen, screenSpaces in pairs(allSpaces) do
        for i, spaceId in ipairs(screenSpaces) do
            if spaceId == currentSpace then
                spaceIndex = i
                break
            end
        end
    end

    spaceMenuBar:setTitle('Space ' .. spaceIndex)
end

-- Update space indicator on startup
updateSpaceIndicator()

-- Watch for space changes
local spaceWatcher = hs.spaces.watcher.new(updateSpaceIndicator)
spaceWatcher:start()

----------------------------------------------------------------------------------------------------
-- App Modal
--
-- This modal is used to open apps that are accessed semi-often:
-- Not often enough to warrant a direct hyper-key shortcut but
-- often enough that I don't want to use Raycast to open them
----------------------------------------------------------------------------------------------------

spoon.ModalMgr:new("appM")
local cmodal = spoon.ModalMgr.modal_list["appM"]
cmodal:bind('', 'escape', 'Deactivate appM', function() spoon.ModalMgr:deactivate({ "appM" }) end)
cmodal:bind('', 'Q', 'Deactivate appM', function() spoon.ModalMgr:deactivate({ "appM" }) end)
cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)

local modeText = hs.styledtext.new("App", {
    color = { hex = "#FFFFFF", alpha = 1 },
    backgroundColor = { hex = "#0000FF", alpha = 1 },
})
cmodal.entered = function()
    activeModal = 'appM'
    modeMenuBar:setTitle(modeText)
end
cmodal.exited = function()
    activeModal = nil
    modeMenuBar:setTitle('Normal')
end


if not hsapp_list then
    hsapp_list = {
        { key = 'a', name = 'Slack' },
        { key = 'b', name = 'Brave Browser' },
        { key = 'd', name = 'React Native Debugger' },
        { key = 'e', name = 'Finder' },
        { key = 'i', name = 'iTerm' },
        { key = 'k', name = 'Keynote' },
        { key = 'm', name = 'Messages' },
        { key = 'n', id = 'com.apple.ActivityMonitor' },
        { key = 'p', name = 'Paw' },
        { key = 'o', name = 'Obsidian' },
        { key = 's', name = 'Simulator' },
        { key = 't', name = 'TablePlus' },
        { key = 'y', id = 'com.apple.systempreferences' },
    }
end
for _, v in ipairs(hsapp_list) do
    if v.id then
        local located_name = hs.application.nameForBundleID(v.id)
        if located_name then
            cmodal:bind('', v.key, located_name, function()
                hs.application.launchOrFocusByBundleID(v.id)
                spoon.ModalMgr:deactivate({ "appM" })
            end)
        end
    elseif v.name then
        cmodal:bind('', v.key, v.name, function()
            hs.application.launchOrFocus(v.name)
            spoon.ModalMgr:deactivate({ "appM" })
        end)
    end
end

hs.urlevent.bind('openappmodal', function()
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ "appM" }, "#0000FF", false)
end)

----------------------------------------------------------------------------------------------------
-- Focus Modal
--
-- This modal is used to focus on windows in different directions using vim keybindings.
----------------------------------------------------------------------------------------------------

-- Window highlighting using canvas rectangles
local windowBorders = {}

local function hideWindowBorders()
    for _, border in ipairs(windowBorders) do
        if border then
            border:hide()
            border:delete()
        end
    end
    windowBorders = {}
    print("Cleared all window borders")
end

local function showWindowBorder(window)
    hideWindowBorders()
    local frame = window:frame()
    local borderWidth = 4

    print("Showing border for window:", window:title())
    print("Window frame:", frame.x, frame.y, frame.w, frame.h)

    -- Create 4 rectangles for top, bottom, left, right borders
    local borders = {
        -- Top border
        hs.canvas.new({x = frame.x - borderWidth, y = frame.y - borderWidth,
                      w = frame.w + 2*borderWidth, h = borderWidth}),
        -- Bottom border
        hs.canvas.new({x = frame.x - borderWidth, y = frame.y + frame.h,
                      w = frame.w + 2*borderWidth, h = borderWidth}),
        -- Left border
        hs.canvas.new({x = frame.x - borderWidth, y = frame.y,
                      w = borderWidth, h = frame.h}),
        -- Right border
        hs.canvas.new({x = frame.x + frame.w, y = frame.y,
                      w = borderWidth, h = frame.h})
    }

    for i, border in ipairs(borders) do
        border:appendElements({
            type = "rectangle",
            fillColor = {red = 0.8, green = 0.2, blue = 0.2, alpha = 0.8},
            strokeColor = {red = 0.8, green = 0.2, blue = 0.2, alpha = 0.8}
        })
        border:show()
        table.insert(windowBorders, border)
        print("Created border", i, "at", border:frame().x, border:frame().y)
    end
end

-- Directional window focusing
local function focusWindowInDirection(direction)
    local currentWindow = hs.window.focusedWindow()
    if not currentWindow then
        print("No current window focused")
        return
    end

    local targetWindows = currentWindow[direction](currentWindow)
    print("Direction:", direction, "Found windows:", targetWindows and #targetWindows or 0)

    if targetWindows and #targetWindows > 0 then
        targetWindows[1]:focus()
        print("Focused window:", targetWindows[1]:title())
        -- Show border around the newly focused window
        showWindowBorder(targetWindows[1])
        -- Stay in focus mode - don't deactivate modal
    else
        print("No target window found in direction:", direction)
    end
end

-- Modal setup - now that border functions are defined
spoon.ModalMgr:new("focusM")
local focusModal = spoon.ModalMgr.modal_list["focusM"]

local focusModeText = hs.styledtext.new("Focus", {
    color = { hex = "#FFFFFF", alpha = 1 },
    backgroundColor = { hex = "#8B4513", alpha = 1 },
})
focusModal.entered = function()
    activeModal = 'focusM'
    modeMenuBar:setTitle(focusModeText)
    -- Highlight the currently focused window when entering focus mode
    local currentWindow = hs.window.focusedWindow()
    if currentWindow then
        showWindowBorder(currentWindow)
    end
end
focusModal.exited = function()
    activeModal = nil
    modeMenuBar:setTitle('Normal')
    hideWindowBorders()
end

-- Modal bindings
focusModal:bind('', 'escape', 'Deactivate focusM', function() spoon.ModalMgr:deactivate({ "focusM" }) end)
focusModal:bind('', 'Q', 'Deactivate focusM', function() spoon.ModalMgr:deactivate({ "focusM" }) end)
focusModal:bind('', 'return', 'Deactivate focusM', function() spoon.ModalMgr:deactivate({ "focusM" }) end)
focusModal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)

focusModal:bind('', 'h', 'Focus Left Window', function()
    focusWindowInDirection('windowsToWest')
end)
focusModal:bind('', 'j', 'Focus Down Window', function()
    focusWindowInDirection('windowsToSouth')
end)
focusModal:bind('', 'k', 'Focus Up Window', function()
    focusWindowInDirection('windowsToNorth')
end)
focusModal:bind('', 'l', 'Focus Right Window', function()
    focusWindowInDirection('windowsToEast')
end)
focusModal:bind('', 'space', 'Swap Focused with Main Window', function()
    hs.eventtap.keyStroke({'shift', 'option'}, 'return')
end)

-- URL event to activate focus modal
hs.urlevent.bind('openfocusmodal', function()
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ "focusM" }, "#8B4513", false)
end)

----------------------------------------------------------------------------------------------------
-- Spaces Modal
--
-- This modal is used to navigate between macOS spaces using vim keybindings and number keys.
----------------------------------------------------------------------------------------------------

-- Space navigation functions using hs.spaces API
local function getAllSpacesForScreen()
    local screen = hs.screen.mainScreen()
    local screenUUID = screen:getUUID()
    return hs.spaces.allSpaces()[screenUUID] or {}
end

local function getCurrentSpaceIndex()
    local currentSpace = hs.spaces.focusedSpace()
    local allSpaces = getAllSpacesForScreen()

    for i, spaceId in ipairs(allSpaces) do
        if spaceId == currentSpace then
            return i
        end
    end
    return 1
end

local function switchToSpace(spaceNumber)
    print("Switching to space:", spaceNumber)
    local allSpaces = getAllSpacesForScreen()
    local targetSpaceId = allSpaces[tonumber(spaceNumber)]

    if targetSpaceId then
        hs.spaces.gotoSpace(targetSpaceId)
        print("Switched to space", spaceNumber)
    else
        print("Space", spaceNumber, "does not exist")
    end

    -- Update space indicator after a brief delay
    hs.timer.doAfter(0.2, updateSpaceIndicator)
end

local function moveToAdjacentSpace(direction)
    print("Moving to", direction, "space")
    local currentIndex = getCurrentSpaceIndex()
    local allSpaces = getAllSpacesForScreen()
    local targetIndex = currentIndex

    if direction == "left" then
        targetIndex = math.max(1, currentIndex - 1)
    elseif direction == "right" then
        targetIndex = math.min(#allSpaces, currentIndex + 1)
    end

    if targetIndex ~= currentIndex then
        local targetSpaceId = allSpaces[targetIndex]
        hs.spaces.gotoSpace(targetSpaceId)
        print("Moved from space", currentIndex, "to space", targetIndex)
    else
        print("Already at", direction == "left" and "first" or "last", "space")
    end

    -- Update space indicator after a brief delay
    hs.timer.doAfter(0.2, updateSpaceIndicator)
end

-- Modal setup
spoon.ModalMgr:new("spacesM")
local spacesModal = spoon.ModalMgr.modal_list["spacesM"]

local spacesModeText = hs.styledtext.new("Spaces", {
    color = { hex = "#FFFFFF", alpha = 1 },
    backgroundColor = { hex = "#800080", alpha = 1 },
})
spacesModal.entered = function()
    activeModal = 'spacesM'
    modeMenuBar:setTitle(spacesModeText)
end
spacesModal.exited = function()
    activeModal = nil
    modeMenuBar:setTitle('Normal')
end

-- Modal bindings
spacesModal:bind('', 'escape', 'Deactivate spacesM', function() spoon.ModalMgr:deactivate({ "spacesM" }) end)
spacesModal:bind('', 'return', 'Deactivate spacesM', function() spoon.ModalMgr:deactivate({ "spacesM" }) end)
spacesModal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)

-- Directional space navigation
spacesModal:bind('', 'h', 'Move to Left Space', function()
    moveToAdjacentSpace("left")
end)
spacesModal:bind('', 'l', 'Move to Right Space', function()
    moveToAdjacentSpace("right")
end)


-- Direct space navigation by number
local spaceNumbers = {'1', '2', '3', '4', '5', '6', '7', '8', '9'}
for _, num in ipairs(spaceNumbers) do
    -- Switch to space (no modifier)
    spacesModal:bind('', num, 'Switch to Space ' .. num, function()
        switchToSpace(num)
        spoon.ModalMgr:deactivate({ "spacesM" })
    end)
end

-- URL event to activate spaces modal
hs.urlevent.bind('openspacesmodal', function()
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ "spacesM" }, "#800080", false)
end)

----------------------------------------------------------------------------------------------------
-- Window Modal
--
-- This modal is used to manage the positioning of my application windows.
-- Is utilizes chaining to allow for toggling of 1/3, 1/2, 2/3
-- placement by hitting the same key multiple times.
----------------------------------------------------------------------------------------------------

-- Set up the grid and margins I want to use
hs.grid.setGrid('10x4')
hs.grid.setMargins({ x = 10, y = 10 })

hs.grid.HINTS = {
    { 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10' },
    { '1',  '2',  '3',  '4',  '5',  '6',  '7',  '8',  '9',  '0' },
    { 'Q',  'W',  'E',  'R',  'T',  'Y',  'U',  'I',  'O',  'P' },
    { 'A',  'S',  'D',  'F',  'G',  'H',  'J',  'K',  'L',  ';' },
    { 'Z',  'X',  'C',  'V',  'B',  'N',  'M',  ',',  '.',  '/' },
}

-- Available positions for application windows
positions = {
    full     = '0,0 10x4',

    tenths2  = {
        left  = '0,0 2x4',
        right = '8,0 2x4',
    },
    tenths3  = {
        left  = '0,0 3x4',
        right = '7,0 3x4',
    },
    tenths4  = {
        left  = '0,0 4x4',
        right = '6,0 4x4',
    },
    tenths5  = {
        left  = '0,0 5x4',
        right = '5,0 5x4',
    },

    fourths1 = {
        top    = '0,0 10x1',
        bottom = '0,3 10x1',
    },
    fourths2 = {
        top    = '0,0 10x2',
        bottom = '0,2 10x2',
    },
    fourths3 = {
        top    = '0,0 10x3',
        bottom = '0,1 10x3',
    },
    fourths4 = {
        top    = '0,0 10x4',
        bottom = '0,0 10x4',
    },
}

-- Splits (from positions above) that I'll make available to the modal keybindings
lrsplits = { 'tenths5', 'tenths4', 'tenths3', 'tenths2' }
tbsplits = { 'fourths1', 'fourths2', 'fourths3', 'fourths4' }

if spoon.WinWin then
    -- Create a new Modal Manager
    -- https://www.hammerspoon.org/Spoons/ModalMgr.html
    spoon.ModalMgr:new("windowM")

    -- Grab the actual Modal
    -- https://www.hammerspoon.org/docs/hs.hotkey.modal.html
    local cmodal = spoon.ModalMgr.modal_list["windowM"]

    -- Add hooks to the Modal to sync macOS menubar
    cmodal.entered = function()
        activeModal = 'windowM'
        local modeText = hs.styledtext.new("Window", {
            color = { hex = "#FFFFFF", alpha = 1 },
            backgroundColor = { hex = "#FFA500", alpha = 1 },
        })
        modeMenuBar:setTitle(modeText)
    end
    cmodal.exited = function()
        activeModal = nil
        modeMenuBar:setTitle('Normal')
    end

    -- Modal Specific Binding
    cmodal:bind('', 'escape', 'Deactivate windowM', function() spoon.ModalMgr:deactivate({ "windowM" }) end)
    cmodal:bind('', 'Q', 'Deactivate windowM', function() spoon.ModalMgr:deactivate({ "windowM" }) end)
    cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)
    -- Positioning
    cmodal:bind('', 'F', 'Full Screen', chain({ positions.full }))
    cmodal:bind('', 'H', 'Left Splits', chain(getPositions(lrsplits, 'left')))
    cmodal:bind('', 'L', 'Right Splits', chain(getPositions(lrsplits, 'right')))
    cmodal:bind('', 'J', 'Bottom Splits', chain(getPositions(tbsplits, 'bottom')))
    cmodal:bind('', 'K', 'Top Splits', chain(getPositions(tbsplits, 'top')))
    cmodal:bind('', 'M', 'Center Middle', chain(getPositions(lrsplits, 'center')))
    cmodal:bind('', 'Y', 'Upper Left Corner', chain(getPositions(lrsplits, 'left', 'top')))
    cmodal:bind('', 'U', 'Upper Right Corner', chain(getPositions(lrsplits, 'right', 'top')))
    cmodal:bind('', 'B', 'Bottom Left Corner', chain(getPositions(lrsplits, 'left', 'bottom')))
    cmodal:bind('', 'N', 'Bottom Right Corner', chain(getPositions(lrsplits, 'right', 'bottom')))
    cmodal:bind('shift', 'S', 'Snap To Grid', function() snap() end)
    cmodal:bind('', 'X', 'Interactive', function()
        spoon.ModalMgr:deactivate({ "windowM" }); hs.grid.show(nil, true)
    end)
    -- Movement
    cmodal:bind('', 'W', 'Move Upward', function() spoon.WinWin:stepMove("up") end)
    cmodal:bind('', 'A', 'Move Leftward', function() spoon.WinWin:stepMove("left") end)
    cmodal:bind('', 'S', 'Move Downward', function() spoon.WinWin:stepMove("down") end)
    cmodal:bind('', 'D', 'Move Rightward', function() spoon.WinWin:stepMove("right") end)
    cmodal:bind('', 'C', 'Center Window', function() spoon.WinWin:moveAndResize("center") end)
    -- Sizing
    cmodal:bind('', '-', 'Shrink Inward', function() spoon.WinWin:moveAndResize("shrink") end)
    cmodal:bind('shift', 'H', 'Resize Leftward', function() spoon.WinWin:stepResize("left") end)
    cmodal:bind('shift', 'L', 'Resize Rightward', function() spoon.WinWin:stepResize("right") end)
    cmodal:bind('shift', 'K', 'Resize Upward', function() spoon.WinWin:stepResize("up") end)
    cmodal:bind('shift', 'J', 'Resize Downward', function() spoon.WinWin:stepResize("down") end)
    -- Monitor Movement
    cmodal:bind('', 'left', 'Move to Left Monitor', function() spoon.WinWin:moveToScreen("left") end)
    cmodal:bind('', 'right', 'Move to Right Monitor', function() spoon.WinWin:moveToScreen("right") end)
    cmodal:bind('', 'space', 'Move to Next Monitor', function() spoon.WinWin:moveToScreen("next") end)
    -- Cursor
    cmodal:bind('', '`', 'Center Cursor', function() spoon.WinWin:centerCursor() end)

    -- Listen for this binding invocation to activate modal
    hs.urlevent.bind('openwindowmodal', function()
        spoon.ModalMgr:deactivateAll()
        spoon.ModalMgr:activate({ "windowM" }, "#FFA500")
    end)
end

----------------------------------------------------------------------------------------------------
-- Layout Modal
--
-- This modal is used to snap multiple windows to specific locations
-- depending on the hotkey selected.
----------------------------------------------------------------------------------------------------

spoon.ModalMgr:new("layoutM")
local cmodal = spoon.ModalMgr.modal_list["layoutM"]
cmodal:bind('', 'escape', 'Deactivate layoutM', function() spoon.ModalMgr:deactivate({ "layoutM" }) end)
cmodal:bind('', 'Q', 'Deactivate layoutM', function() spoon.ModalMgr:deactivate({ "layoutM" }) end)
cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)

local modeText = hs.styledtext.new("Layout", {
    color = { hex = "#FFFFFF", alpha = 1 },
    backgroundColor = { hex = "#FF00FF", alpha = 1 },
})
cmodal.entered = function()
    activeModal = 'layoutM'
    modeMenuBar:setTitle(modeText)
end
cmodal.exited = function()
    activeModal = nil
    modeMenuBar:setTitle('Normal')
end

currentLayout = nil

layouts = {
    standard = function()
        moveApp('Slack', '0,0 12x10')
        moveApp('Brave Browser', '12,0 20x20')
        moveApp('Iterm', '0,10 12x10')
    end,

    chat = function()
        moveApp('YT Music', '0,0 12x10')
        moveApp('Discord', '0,10 12x10')
        moveApp('Messages', '12,0 10x10')
        moveApp('Slack', '12,10 10x10')
        moveApp('WhatsApp', '22,0 8x10')
        moveApp('Telegram', '22,10 8x10')
    end,
}

cmodal:bind('', 'S', 'Standard Layout', function() setLayoutAndDeactivate('standard', true) end)
cmodal:bind('', 'C', 'Chat-centric', function() setLayoutAndDeactivate('chat') end)
cmodal:bind('', 'R', 'Reset Layout', function()
    resetLayout(); spoon.ModalMgr:deactivate({ "layoutM" })
end)

function setLayoutAndDeactivate(layoutKey, saveCurrentLayout)
    -- First hide all opened windows
    for index, value in ipairs(hs.window.visibleWindows()) do
        value:application():hide()
    end
    -- Then set the layout
    setLayout(layoutKey, saveCurrentLayout)
    -- Finally, deactivate the modal
    spoon.ModalMgr:deactivate({ "layoutM" })
end

hs.urlevent.bind('enablelayoutm', function()
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ "layoutM" }, "#FF00FF", false)
end)

----------------------------------------------------------------------------------------------------
-- Initialize ModalMgr Supervisor
----------------------------------------------------------------------------------------------------

spoon.ModalMgr.supervisor:enter()

----------------------------------------------------------------------------------------------------
-- Hammerspoon URL Event Bindings
--
-- This is a list of event bindings that can be invoked
-- from anywhere using the hammerspoon url protocol:
--
-- hammerspoon://hitMe
--
-- If the above protocol is accessed, then the binding below
-- will invoke the asssociated callback function:
--
-- hs.urlevent.bind('hitMe', function()...
--
-- Examples of invoking a url binding:
--
-- bash: open -g hammerspoon://hitMe
-- browser: go to hammerspoon://hitMe
-- goku/karabiner: hyper + h -> [:hs "hitMe"]
--
-- The true power here is in having each callback do something different
-- depending on the app in focus at the time of invocation.
----------------------------------------------------------------------------------------------------

hs.urlevent.bind('reloadhammerspoon', function()
    hs.reload()
end)

hs.urlevent.bind('createanything', function()
    if appIs(omnifocus) then
        hs.eventtap.keyStroke({ 'ctrl', 'option' }, 'space')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({ 'cmd' }, 'n')
    elseif appIs(brave) then
        hs.eventtap.keyStroke({ 'cmd' }, 't')
    end
end)

hs.urlevent.bind('closeanything', function()
    if appIncludes({ brave }) then
        hs.eventtap.keyStroke({ 'cmd' }, 'w')
    end
end)

hs.urlevent.bind('openanything', function()
    if appIncludes({ vscode, tableplus, fork }) then
        hs.eventtap.keyStroke({ 'cmd' }, 'p')
    elseif appIs(teams) then
        hs.eventtap.keyStroke({ 'cmd' }, 'e')
    elseif appIs(eclipse) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, 'r')
    elseif appIncludes({ discord, superhuman }) then
        hs.eventtap.keyStroke({ 'cmd' }, 'k')
    elseif appIncludes({ slack, monday }) then
        hs.eventtap.keyStroke({ 'cmd' }, 'k')
        hs.eventtap.keyStroke({}, 'down')
    elseif appIncludes({ phpstorm, xcode }) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, 'o')
    elseif appIncludes({ brave }) then
        hs.eventtap.keyStroke({ 'shift' }, 't') -- Open Vomnibar in Vimium
    elseif appIncludes({ omnifocus, obsidian }) then
        hs.eventtap.keyStroke({ 'cmd' }, 'o')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, 'f')
    elseif appIs(intellij) then
        hs.eventtap.keyStroke({ 'cmd' }, 't')
    elseif true then
        bundleId = getBundleId();
        hs.notify.new(function() hs.pasteboard.setContents(bundleId) end,
            { title = 'Hammerspoon', informativeText = 'Open Anything not set up', actionButtonTitle = 'Copy Bundle ID', alwaysShowAdditionalActions = true, hasActionButton = true })
            :send()
    end
end)

hs.urlevent.bind('togglesidebar', function()
    if appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd' }, 'b', 0)
        hs.eventtap.keyStroke({ 'cmd' }, 'h', 0)
    elseif appIs(slack) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, 'd')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({ 'control' }, '3')
    elseif appIs(phpstorm) then
        hs.eventtap.keyStroke({ 'cmd' }, '1')
    elseif appIs(sketch) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, '1')
        hs.eventtap.keyStroke({ 'cmd', 'option' }, '2')
    elseif appIs(obsidian) then
        hs.eventtap.keyStroke({ 'cmd', 'option', 'control' }, 'm')
    elseif appIs(omnifocus) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 's')
    end
end)

hs.urlevent.bind('navigateback', function()
    if (activeModal == nil) then
        if appIncludes({ bear, spotify }) then
            hs.eventtap.keyStroke({ 'cmd', 'option' }, 'left')
        elseif appIncludes({ finder, slack, brave }) then
            hs.eventtap.keyStroke({ 'cmd' }, '[')
        elseif appIncludes({ vscode }) then
            hs.eventtap.keyStroke({ 'cmd' }, 'k')
            hs.eventtap.keyStroke({ 'cmd' }, 'left')
            hs.eventtap.keyStroke({}, 'escape')
        elseif appIncludes({ obsidian }) then
            hs.eventtap.keyStroke({ 'cmd', 'option', 'control' }, 'a')
        elseif appIncludes({ iterm, alacritty }) then
            hs.eventtap.keyStroke({ 'control' }, 'h', 0)
        end
    elseif activeModal == 'windowM' then
        hs.eventtap.keyStroke({}, 'a')
    end
end)

hs.urlevent.bind('navigateforward', function()
    if appIncludes({ bear, spotify }) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'right')
    elseif appIncludes({ finder, slack, brave }) then
        hs.eventtap.keyStroke({ 'cmd' }, ']')
    elseif appIncludes({ vscode }) then
        hs.eventtap.keyStroke({ 'cmd' }, 'k')
        hs.eventtap.keyStroke({ 'cmd' }, 'right')
        hs.eventtap.keyStroke({}, 'escape')
    elseif appIncludes({ obsidian }) then
        hs.eventtap.keyStroke({ 'cmd', 'option', 'control' }, 'd')
    elseif appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'l', 0)
    end
end)

hs.urlevent.bind('navigateupward', function()
    if appIs(tableplus) then
        hs.eventtap.keyStroke({ 'cmd' }, '[')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({}, 'up')
    elseif appIncludes({ vscode }) then
        hs.eventtap.keyStroke({ 'control' }, '`')
        hs.eventtap.keyStroke({}, 'escape')
    elseif appIs(messages) then
        hs.eventtap.keyStroke({ 'control', 'shift' }, 'tab')
    elseif appIs(brave) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, ']')
    elseif appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'k', 0)
    elseif appIs(obsidian) then
        hs.eventtap.keyStroke({ 'cmd', 'option', 'control' }, 'w')
    else
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, '[')
    end
end)

hs.urlevent.bind('navigatedownward', function()
    if appIs(tableplus) then
        hs.eventtap.keyStroke({ 'cmd' }, ']')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({}, 'down')
    elseif appIncludes({ vscode }) then
        hs.eventtap.keyStroke({ 'control' }, '`')
    elseif appIs(messages) then
        hs.eventtap.keyStroke({ 'control' }, 'tab')
    elseif appIs(brave) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, '[')
    elseif appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'j', 0)
    elseif appIncludes({ obsidian }) then
        hs.eventtap.keyStroke({ 'cmd', 'option', 'control' }, 's')
    else
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, ']')
    end
end)

hs.urlevent.bind('opencommandpalette', function()
    if appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, 'p')
    elseif appIs(figma) then
        hs.eventtap.keyStroke({ 'cmd' }, '/') -- Figma Quick actions
    elseif appIs(teams) then
        hs.eventtap.keyStroke({ 'cmd' }, 'e')
        hs.eventtap.keyStroke({}, '/')
    elseif appIncludes({ obsidian }) then
        hs.eventtap.keyStroke({ 'cmd' }, 'p')
    elseif appIs(intellij) then
        hs.eventtap.keyStroke({ 'cmd', 'shift' }, 'a')
    end
end)

hs.urlevent.bind('openprojectselector', function()
    if appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'p')
    elseif appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'ctrl' }, 'a')
        hs.eventtap.keyStroke({}, 'f')
        hs.eventtap.keyStroke({}, 'return')
    end
end)

hs.urlevent.bind('copyanything', function()
    local text = getSelectedText(true)
    if text then
        -- Already in clipboard, do not reset
    elseif appIs(bear) then
        hs.eventtap.keyStroke({ 'cmd', 'option', 'shift' }, 'l') -- Copy link to note
    elseif appIs(brave) then
        hs.eventtap.keyStrokes('yy')                             -- Copy current URL
    end
end)

hs.urlevent.bind('tabprevious', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'a')
        hs.eventtap.keyStroke({}, 'p')
    elseif appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'left')
    end
end)

hs.urlevent.bind('tabnext', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'a')
        hs.eventtap.keyStroke({}, 'n')
    elseif appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'right')
    end
end)


hs.urlevent.bind('superduperleft', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'h')
    elseif appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'left')
    end
end)

hs.urlevent.bind('superduperright', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'l')
    elseif appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'right')
    end
end)

hs.urlevent.bind('superduperup', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'j')
    elseif appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'up')
    end
end)

hs.urlevent.bind('superduperdown', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'k')
    elseif appIs(vscode) then
        hs.eventtap.keyStroke({ 'cmd', 'option' }, 'down')
    end
end)

hs.urlevent.bind('splitvertically', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'a')
        hs.eventtap.keyStroke({ 'shift' }, '\\')
    elseif appIs(obsidian) then
        hs.eventtap.keyStroke({ 'cmd', 'option', 'control' }, '\\')
    end
end)

hs.urlevent.bind('splithorizontally', function()
    if appIncludes({ iterm, alacritty }) then
        hs.eventtap.keyStroke({ 'control' }, 'a')
        hs.eventtap.keyStroke({}, '-')
    elseif appIs(obsidian) then
        hs.eventtap.keyStroke({ 'cmd', 'option', 'control' }, '-')
    end
end)


hs.urlevent.bind('togglebreaktime', function()
    local status, response, description = hs.osascript.javascript([[
        breaktime = Application("BreakTime")
        breaktime.enabled = !breaktime.enabled()
        breaktime.enabled()
    ]])

    if status then       -- if the call to toggle BreakTime was successful
        if response then -- response is the updated status of BreakTime
            text = "BreakTime was Enabled."
        else
            text = "BreakTime was Disabled."
        end
        btNotify = hs.notify.new({ title = 'BreakTime', informativeText = text })
        btNotify:contentImage(hs.image.imageFromAppBundle(breaktime))
        btNotify:send()
    end
end)

----------------------------------------------------------------------------------------------------
-- Misc. Functions
--
-- Functions that I use in my Hammerspoon script, but don't feel the need
-- to break it out into a separate .lua file to import
------------------------------------------------------------------------------------------------------

-- none

--------------------------------------------------------------------------------
-- Attributions and Inspirations
--
-- Andrew Morgan: https://github.com/andrewmile/dotfiles/tree/master/hammerspoon
-- Jesse Leite: https://github.com/jesseleite/dotfiles/tree/master/hammerspoon
--------------------------------------------------------------------------------
