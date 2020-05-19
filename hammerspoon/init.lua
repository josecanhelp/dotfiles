bear = 'net.shinyfrog.bear'
chrome = 'com.google.Chrome'
finder = 'com.apple.finder'
firefox = 'org.mozilla.firefoxdeveloperedition'
iterm = 'com.googlecode.iterm2'
preview = 'com.apple.Preview'
slack = 'com.tinyspeck.slackmacgap'
spotify = 'com.spotify.client' 
tableplus = 'com.tinyapp.TablePlus'
vscode = 'com.microsoft.VSCode'
phpstorm = 'com.jetbrains.PhpStorm'
fork = 'com.DanPristupov.Fork'

gokuWatcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.config/karabiner.edn/', function ()
    output = hs.execute('/usr/local/bin/goku')
    hs.notify.new({title = 'Karabiner Config', informativeText = output}):send()
end):start()

hs.loadSpoon('ReloadConfiguration')
spoon.ReloadConfiguration:start()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded'}):send()

----------------------------------------------------------------------------------------------------
-- Add a menubar item to track currently enabled Mode
----------------------------------------------------------------------------------------------------
modeMenuBar = hs.menubar.new():setTitle('Normal');
changeModeMenuBar = function(modeName) modeMenuBar:setTitle(modeName) end

hs.loadSpoon("ModalMgr")

-- Define default Spoons which will be loaded later
if not hspoon_list then
    hspoon_list = {
        "WinWin",
    }
end

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0
hs.hints.style = 'vimperator'
hs.window.animationDuration = 0

----------------------------------------------------------------------------------------------------
-- Register modal keybindings environments.
----------------------------------------------------------------------------------------------------
-- Register windowHints (Register a keybinding which is NOT modal environment with modal supervisor)
-- This is done to deactivate all current modals to display the hints
hswhints_keys = hswhints_keys or {"alt", "j"}
if string.len(hswhints_keys[2]) > 0 then
    -- Show Window Hints
    spoon.ModalMgr.supervisor:bind(hswhints_keys[1], hswhints_keys[2], nil, function()
        spoon.ModalMgr:deactivateAll()
        hs.hints.windowHints()
    end)
end

----------------------------------------------------------------------------------------------------
spoon.ModalMgr:new("appM")
local cmodal = spoon.ModalMgr.modal_list["appM"]
cmodal:bind('', 'escape', 'Deactivate appM', function() spoon.ModalMgr:deactivate({"appM"}) end)
cmodal:bind('', 'Q', 'Deactivate appM', function() spoon.ModalMgr:deactivate({"appM"}) end)
cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)

local modeText = hs.styledtext.new("App", {
    color = {hex = "#FFFFFF", alpha = 1},
    backgroundColor = {hex = "#0000FF", alpha = 1},
})
cmodal.entered = function() changeModeMenuBar(modeText) end
cmodal.exited = function() changeModeMenuBar('Normal') end

if not hsapp_list then
    hsapp_list = {
        {key = 'a', name = 'Slack'},
        {key = 'c', name = 'Visual Studio Code'},
        {key = 'd', name = 'React Native Debugger'},
        {key = 'e', name = 'Finder'},
        {key = 'f', name = 'Firefox Developer Edition'},
        {key = 'i', name = 'iTerm'},
        {key = 'p', name = 'PhpStorm'},
        {key = 'm', name = 'Messages'},
        {key = 'n', id = 'com.apple.ActivityMonitor'},
        {key = 'r', name = 'Bear'},
        {key = 's', name = 'Simulator'},
        {key = 't', name = 'TablePlus'},
        {key = 'v', name = 'Visual Studio Code'},
        {key = 'x', name = 'Xcode'},
        {key = 'y', id = 'com.apple.systempreferences'},
    }
end
for _, v in ipairs(hsapp_list) do
    if v.id then
        local located_name = hs.application.nameForBundleID(v.id)
        if located_name then
            cmodal:bind('', v.key, located_name, function()
                hs.application.launchOrFocusByBundleID(v.id)
                spoon.ModalMgr:deactivate({"appM"})
            end)
        end
    elseif v.name then
        cmodal:bind('', v.key, v.name, function()
            hs.application.launchOrFocus(v.name)
            spoon.ModalMgr:deactivate({"appM"})
        end)
    end
end

-- Then we register some keybindings with modal supervisor
hsappM_keys = hsappM_keys or {"ctrl", "J"}
if string.len(hsappM_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hsappM_keys[1], hsappM_keys[2], nil, function()
        spoon.ModalMgr:deactivateAll()
        -- Show the keybindings cheatsheet once appM is activated
        spoon.ModalMgr:activate({"appM"}, "#0000FF", false)
    end)
end


----------------------------------------------------------------------------------------------------
-- windowM modal environment
if spoon.WinWin then
    spoon.ModalMgr:new("windowM")
    local cmodal = spoon.ModalMgr.modal_list["windowM"]
    local modeText = hs.styledtext.new("Window", {
        color = {hex = "#FFFFFF", alpha = 1},
        backgroundColor = {hex = "#FFA500", alpha = 1},
    })
    cmodal.entered = function() changeModeMenuBar(modeText) end
    cmodal.exited = function() changeModeMenuBar('Normal') end
    cmodal:bind('', 'escape', 'Deactivate windowM', function() spoon.ModalMgr:deactivate({"windowM"}) end)
    cmodal:bind('', 'Q', 'Deactivate windowM', function() spoon.ModalMgr:deactivate({"windowM"}) end)
    cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)
    cmodal:bind('', 'A', 'Move Leftward', function() spoon.WinWin:stepMove("left") end, nil, function() spoon.WinWin:stepMove("left") end)
    cmodal:bind('', 'D', 'Move Rightward', function() spoon.WinWin:stepMove("right") end, nil, function() spoon.WinWin:stepMove("right") end)
    cmodal:bind('', 'W', 'Move Upward', function() spoon.WinWin:stepMove("up") end, nil, function() spoon.WinWin:stepMove("up") end)
    cmodal:bind('', 'S', 'Move Downward', function() spoon.WinWin:stepMove("down") end, nil, function() spoon.WinWin:stepMove("down") end)
    cmodal:bind('', 'H', 'Lefthalf of Screen', function()  spoon.WinWin:moveAndResize("halfleft") end)
    cmodal:bind('', 'L', 'Righthalf of Screen', function()  spoon.WinWin:moveAndResize("halfright") end)
    cmodal:bind('', 'K', 'Uphalf of Screen', function()  spoon.WinWin:moveAndResize("halfup") end)
    cmodal:bind('', 'J', 'Downhalf of Screen', function()  spoon.WinWin:moveAndResize("halfdown") end)
    cmodal:bind('', 'Y', 'NorthWest Corner', function()  spoon.WinWin:moveAndResize("cornerNW") end)
    cmodal:bind('', 'O', 'NorthEast Corner', function()  spoon.WinWin:moveAndResize("cornerNE") end)
    cmodal:bind('', 'U', 'SouthWest Corner', function()  spoon.WinWin:moveAndResize("cornerSW") end)
    cmodal:bind('', 'I', 'SouthEast Corner', function()  spoon.WinWin:moveAndResize("cornerSE") end)
    cmodal:bind('', 'F', 'Fullscreen', function()  spoon.WinWin:moveAndResize("maximize") end)
    cmodal:bind('', 'C', 'Center Window', function()  spoon.WinWin:moveAndResize("center") end)
    cmodal:bind('', '=', 'Stretch Outward', function() spoon.WinWin:moveAndResize("expand") end, nil, function() spoon.WinWin:moveAndResize("expand") end)
    cmodal:bind('', '-', 'Shrink Inward', function() spoon.WinWin:moveAndResize("shrink") end, nil, function() spoon.WinWin:moveAndResize("shrink") end)
    cmodal:bind('shift', 'H', 'Resize Leftward', function() spoon.WinWin:stepResize("left") end, nil, function() spoon.WinWin:stepResize("left") end)
    cmodal:bind('shift', 'L', 'Resize Rightward', function() spoon.WinWin:stepResize("right") end, nil, function() spoon.WinWin:stepResize("right") end)
    cmodal:bind('shift', 'K', 'Resize Upward', function() spoon.WinWin:stepResize("up") end, nil, function() spoon.WinWin:stepResize("up") end)
    cmodal:bind('shift', 'J', 'Resize Downward', function() spoon.WinWin:stepResize("down") end, nil, function() spoon.WinWin:stepResize("down") end)
    cmodal:bind('', 'left', 'Move to Left Monitor', function()  spoon.WinWin:moveToScreen("left") end)
    cmodal:bind('', 'right', 'Move to Right Monitor', function()  spoon.WinWin:moveToScreen("right") end)
    cmodal:bind('', 'up', 'Move to Above Monitor', function()  spoon.WinWin:moveToScreen("up") end)
    cmodal:bind('', 'down', 'Move to Below Monitor', function()  spoon.WinWin:moveToScreen("down") end)
    cmodal:bind('', 'space', 'Move to Next Monitor', function()  spoon.WinWin:moveToScreen("next") end)
    cmodal:bind('', '[', 'Undo Window Manipulation', function() spoon.WinWin:undo() end)
    cmodal:bind('', ']', 'Redo Window Manipulation', function() spoon.WinWin:redo() end)
    cmodal:bind('', '`', 'Center Cursor', function() spoon.WinWin:centerCursor() end)

    -- Register windowM with modal supervisor
    hsresizeM_keys = hsresizeM_keys or {"ctrl", "K"}
    if string.len(hsresizeM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(hsresizeM_keys[1], hsresizeM_keys[2], "Enter windowM Environment", function()
            -- Deactivate some modal environments or not before activating a new one
            spoon.ModalMgr:deactivateAll()
            -- Show an status indicator so we know we're in some modal environment now
            spoon.ModalMgr:activate({"windowM"}, "#FFA500")
        end)
    end
end

----------------------------------------------------------------------------------------------------
-- Finally we initialize ModalMgr supervisor
spoon.ModalMgr.supervisor:enter()

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function appIs(bundle)
    return hs.application.frontmostApplication():bundleID() == bundle
end

function appIncludes(bundles)
    return has_value(bundles, hs.application.frontmostApplication():bundleID())
end

function focusedWindowIs(bundle)
    return hs.window:focusedWindow():application():bundleID() == bundle
end

function getSelectedText(copying)
    original = hs.pasteboard.getContents()
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({'cmd'}, 'C')
    text = hs.pasteboard.getContents()
    finderFileSelected = false
    for k,v in pairs(hs.pasteboard.contentTypes()) do
        if v == 'public.file-url' then
            finderFileSelected = true
        end
    end

    if not copying and finderFileSelected then
        text = 'finderFileSelected'
    end

    if not copying then
        hs.pasteboard.setContents(original)
    end

    return text
end

function triggerAlfredSearch(search)
    hs.osascript.applescript('tell application id "com.runningwithcrayons.Alfred" to search "' .. search ..' "')
end

function triggerAlfredWorkflow(workflow, trigger)
    hs.osascript.applescript('tell application id "com.runningwithcrayons.Alfred" to run trigger "' .. trigger .. '" in workflow "' .. workflow .. '"')
end

hs.urlevent.bind('openAnything', function()
    if appIncludes({vscode, tableplus, fork}) then
        hs.eventtap.keyStroke({'cmd'}, 'p')
    elseif appIs(slack) then
        hs.eventtap.keyStroke({'cmd'}, 'k')
    elseif appIs(phpstorm) then
        hs.eventtap.keyStroke({'cmd, shift'}, 'o')
    elseif appIs(finder) then
        triggerAlfredSearch('o')
    elseif appIncludes({chrome, firefox}) then
        triggerAlfredSearch('bm')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({'cmd', 'shift'}, 'f')
    end
end)

hs.urlevent.bind('toggleSidebar', function()
    if appIs(vscode) then
        hs.eventtap.keyStroke({'cmd'}, 'b', 0)
        hs.eventtap.keyStroke({'cmd'}, 'h', 0)
    elseif appIs(bear) then
        hs.eventtap.keyStroke({'control'}, '1')
    elseif appIs(phpstorm) then
        hs.eventtap.keyStroke({'cmd'}, '1')
    end
end)

hs.urlevent.bind('navigateBack', function()
    if appIncludes({bear, spotify}) then
        hs.eventtap.keyStroke({'cmd', 'option'}, 'left')
    elseif appIncludes({finder, chrome, slack, iterm}) then
        hs.eventtap.keyStroke({'cmd'}, '[')
    end
end)

hs.urlevent.bind('navigateForward', function()
    if appIncludes({bear, spotify}) then
        hs.eventtap.keyStroke({'cmd', 'option'}, 'right')
    elseif appIncludes({finder, chrome, slack, iterm}) then
        hs.eventtap.keyStroke({'cmd'}, ']')
    end
end)

hs.urlevent.bind('goToPreviousTab', function()
    if appIs(tableplus) then
        hs.eventtap.keyStroke({'cmd'}, '[')
    else
        hs.eventtap.keyStroke({'cmd', 'shift'}, '[')
    end
end)

hs.urlevent.bind('goToNextTab', function()
    if appIs(tableplus) then
        hs.eventtap.keyStroke({'cmd'}, ']')
    else
        hs.eventtap.keyStroke({'cmd', 'shift'}, ']')
    end
end)

hs.urlevent.bind('openCommandPalette', function()
    if appIs(vscode) then
        hs.eventtap.keyStroke({'cmd', 'shift'}, 'p')
    else
        triggerAlfredWorkflow('com.tedwise.menubarsearch', 'menubarsearch')
    end
end)

hs.urlevent.bind('copyAnything', function()
    text = getSelectedText(true)
    if text then
        -- Already in clipboard, do not reset
    elseif appIs(spotify) then
        hs.osascript.applescript([[
            tell application "Spotify"
                set theTrack to name of the current track
                set theArtist to artist of the current track
                set theAlbum to album of the current track
                set track_id to id of current track
            end tell
            set AppleScript's text item delimiters to ":"
            set track_id to third text item of track_id
            set AppleScript's text item delimiters to {""}
            set realurl to ("https://open.spotify.com/track/" & track_id)
            set theString to theTrack & " by " & theArtist & ": " & realurl
            set the clipboard to theString
        ]])
    elseif appIs(bear) then
        hs.eventtap.keyStroke({'cmd', 'option', 'shift'}, 'l')
    elseif appIs(chrome) then
        hs.eventtap.keyStrokes('yy')
    elseif appIs(vscode) then
        hs.eventtap.keyStroke({'cmd', 'option', 'control'}, 'y')
    end
end)
