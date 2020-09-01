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

----------------------------------------------------------------------------------------------------
-- Local State
----------------------------------------------------------------------------------------------------

local activeModal = nil
local hsapp_list = nil
local hspoon_list = nil

----------------------------------------------------------------------------------------------------
-- Generic Settings
----------------------------------------------------------------------------------------------------

hs.hotkey.alertDuration = 0
hs.window.animationDuration = 0

----------------------------------------------------------------------------------------------------
-- Configuration File Auto-Reload
----------------------------------------------------------------------------------------------------

-- Goku
hs.pathwatcher.new(os.getenv('HOME') .. '/.config/karabiner.edn/', function ()
    local output = hs.execute('/usr/local/bin/goku')
    hs.notify.new({title = 'Karabiner Config', informativeText = output}):send()
end):start()

-- Hammerspoon
hs.loadSpoon('ReloadConfiguration')
spoon.ReloadConfiguration:start()
hs.notify.new({title = 'Hammerspoon', informativeText = 'Config loaded'}):send()

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
-- Add a menubar item to track currently enabled Mode (Modal)
----------------------------------------------------------------------------------------------------

local modeMenuBar = hs.menubar.new():setTitle('Normal');

----------------------------------------------------------------------------------------------------
-- App Modal
--
-- This modal is used to open apps that are accessed semi-often:
-- Not often enough to warrant a direct hyper-key shortcut but
-- often enough that I don't want to use Alfred to open them
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
        {key = 'a', name = 'Slack'},
        {key = 'b', name = 'Brave Browser'},
        {key = 'd', name = 'React Native Debugger'},
        {key = 'e', name = 'Finder'},
        {key = 'i', name = 'iTerm'},
        {key = 'k', name = 'Keynote'},
        {key = 'm', name = 'Messages'},
        {key = 'n', id = 'com.apple.ActivityMonitor'},
        {key = 'p', name = 'Paw'},
        {key = 'r', name = 'Bear'},
        {key = 's', name = 'Simulator'},
        {key = 't', name = 'TablePlus'},
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

hs.urlevent.bind('openAppModal', function()
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({"appM"}, "#0000FF", false)
end)

----------------------------------------------------------------------------------------------------
-- Window Modal
--
-- This modal is used to manage the positioning of my application windows.
-- Is utilizes chaining to allow for toggling of 1/3, 1/2, 2/3
-- placement by hitting the same key multiple times.
----------------------------------------------------------------------------------------------------

hs.grid.setGrid('30x20')

resetWhenSwitchingScreen(function ()
  hs.grid.setMargins('20x30')
end)

positions = {
  full     = '0,0 30x20',

  center = {
    wide   = '2,1 26x18',
    normal = '6,1 18x18',
    narrow = '10,1 10x18',
  },

  thirds = {
    left   = '0,0 10x20',
    center = '10,0 10x20',
    right  = '20,0 10x20',
  },

  halves = {
    left   = '0,0 15x20',
    right  = '15,0 15x20',
  },

  twoThirds = {
    left   = '0,0 20x20',
    right  = '10,0 20x20',
  },

  fourFifths = {
    left   = '0,0 24x20',
    center = '3,0 24x20',
    right  = '6,0 24x20',
  },
}

if spoon.WinWin then
    spoon.ModalMgr:new("windowM")
    local cmodal = spoon.ModalMgr.modal_list["windowM"]
    local modeText = hs.styledtext.new("Window", {
        color = {hex = "#FFFFFF", alpha = 1},
        backgroundColor = {hex = "#FFA500", alpha = 1},
    })

    local splits = { 'thirds', 'halves', 'twoThirds', }

    cmodal.entered = function()
      activeModal = 'windowM'
      modeMenuBar:setTitle(modeText)
    end

    cmodal.exited = function()
      activeModal = nil
      modeMenuBar:setTitle('Normal')
    end

    cmodal:bind('', 'escape', 'Deactivate windowM', function() spoon.ModalMgr:deactivate({"windowM"}) end)
    cmodal:bind('', 'Q', 'Deactivate windowM', function() spoon.ModalMgr:deactivate({"windowM"}) end)
    cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)
    cmodal:bind('', 'F', 'Full Screen', chain({positions.full}))
    cmodal:bind('', 'H', 'Left Splits', chain(getPositions(splits, 'left')))
    cmodal:bind('', 'L', 'Right Splits', chain(getPositions(splits, 'right')))
    cmodal:bind('', 'J', 'Bottom Splits', chain(getPositions(splits, 'center', 'bottom')))
    cmodal:bind('', 'K', 'Top Splits', chain(getPositions(splits, 'center', 'top')))
    cmodal:bind('', 'M', 'Center Middle', chain(getPositions(splits, 'center')))
    cmodal:bind('', 'Y', 'Upper Left Corner', chain(getPositions(splits, 'left', 'top')))
    cmodal:bind('', 'U', 'Upper Right Corner', chain(getPositions(splits, 'right', 'top')))
    cmodal:bind('', 'B', 'Bottom Left Corner', chain(getPositions(splits, 'left', 'bottom')))
    cmodal:bind('', 'N', 'Bottom Right Corner', chain(getPositions(splits, 'right', 'bottom')))

    cmodal:bind('', 'W', 'Move Upward', function() spoon.WinWin:stepMove("up") end, nil, function() spoon.WinWin:stepMove("up") end)
    cmodal:bind('', 'A', 'Move Leftward', function() spoon.WinWin:stepMove("left") end, nil, function() spoon.WinWin:stepMove("left") end)
    cmodal:bind('', 'S', 'Move Downward', function() spoon.WinWin:stepMove("down") end, nil, function() spoon.WinWin:stepMove("down") end)
    cmodal:bind('', 'D', 'Move Rightward', function() spoon.WinWin:stepMove("right") end, nil, function() spoon.WinWin:stepMove("right") end)
    cmodal:bind('', 'C', 'Center Window', function()  spoon.WinWin:moveAndResize("center") end)

    cmodal:bind('', '-', 'Shrink Inward', function() spoon.WinWin:moveAndResize("shrink") end, nil, function() spoon.WinWin:moveAndResize("shrink") end)
    cmodal:bind('shift', 'H', 'Resize Leftward', function() spoon.WinWin:stepResize("left") end, nil, function() spoon.WinWin:stepResize("left") end)
    cmodal:bind('shift', 'L', 'Resize Rightward', function() spoon.WinWin:stepResize("right") end, nil, function() spoon.WinWin:stepResize("right") end)
    cmodal:bind('shift', 'K', 'Resize Upward', function() spoon.WinWin:stepResize("up") end, nil, function() spoon.WinWin:stepResize("up") end)
    cmodal:bind('shift', 'J', 'Resize Downward', function() spoon.WinWin:stepResize("down") end, nil, function() spoon.WinWin:stepResize("down") end)
    cmodal:bind('', 'left', 'Move to Left Monitor', function()  spoon.WinWin:moveToScreen("left") end)
    cmodal:bind('', 'right', 'Move to Right Monitor', function()  spoon.WinWin:moveToScreen("right") end)
    cmodal:bind('', 'space', 'Move to Next Monitor', function()  spoon.WinWin:moveToScreen("next") end)
    cmodal:bind('', '`', 'Center Cursor', function() spoon.WinWin:centerCursor() end)
    cmodal:bind('shift', 'S', 'Snap To Grid', function() snap() end)

    hs.urlevent.bind('openWindowModal', function()
        spoon.ModalMgr:deactivateAll()
        spoon.ModalMgr:activate({"windowM"}, "#FFA500")
    end)
end

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
-- alfred: Open URL Action -> hammerspoon://hitMe
-- bash: open -g hammerspoon://hitMe
-- browser: go to hammerspoon://hitMe
-- goku/karabiner: hyper + h -> [:hs "hitMe"]
--
-- The true power here is in having each callback do something different
-- depending on the app in focus at the time of invocation.
----------------------------------------------------------------------------------------------------

-- This is almost unfair
hs.urlevent.bind('quickSlackReactEmoji', function()
    refocus = false

    if not focusedWindowIs(slack) then
        refocus = true
        focusedApp = hs.window:focusedWindow():application():bundleID()
        hs.application.launchOrFocus("slack")
    end

    hs.eventtap.keyStrokes('+:wave::skin-tone-4:')
    hs.eventtap.keyStroke({}, 'return')

    if refocus then
        hs.application.launchOrFocusByBundleID(focusedApp)
    end
end)

hs.urlevent.bind('debug-menu', function()
    if  appIs(simulator) then
        hs.eventtap.keyStroke({'ctrl, cmd'}, 'z')
    end
end)

hs.urlevent.bind('expose', function()
    if  appIs(simulator) then
        hs.eventtap.keyStroke({'ctrl, shift, cmd'}, 'h')
    end
end)

hs.urlevent.bind('createAnything', function()
    if appIs(omnifocus) then
        hs.eventtap.keyStroke({'ctrl', 'option'}, 'space')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({'cmd'}, 'n')
    elseif appIs(brave) then
        hs.eventtap.keyStroke({'cmd'}, 't')
    end
end)

hs.urlevent.bind('deleteAnything', function()
    if appIs(bear) then
        -- Delete the currently opened note and go back to default screen
        hs.eventtap.keyStroke({'shift', 'cmd', 'option'}, 'i')
        local noteId = hs.pasteboard.getContents();
        hs.urlevent.openURL('bear://x-callback-url/trash?id=' .. noteId)
        hs.urlevent.openURL('bear://x-callback-url/search')
    end
end)

hs.urlevent.bind('closeAnything', function()
    if appIncludes({brave}) then
        hs.eventtap.keyStroke({'cmd'}, 'w')
    end
end)

hs.urlevent.bind('openAnything', function()
    if appIncludes({vscode, tableplus, fork}) then
        hs.eventtap.keyStroke({'cmd'}, 'p')
    elseif appIs(simulator) then
        hs.eventtap.keyStroke({'ctrl, shift, cmd'}, 'h')
    elseif appIncludes({slack, discord}) then
        hs.eventtap.keyStroke({'cmd'}, 'k')
    elseif appIs(phpstorm) then
        hs.eventtap.keyStroke({'cmd, shift'}, 'o')
    elseif appIs(finder) then
        triggerAlfredSearch('o')
    elseif appIncludes({brave}) then
        hs.eventtap.keyStroke({'shift'}, 't') -- Open Vomnibar in Vimium
    elseif appIs(omnifocus) then
        hs.eventtap.keyStroke({'cmd'}, 'o')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({'cmd', 'shift'}, 'f')
    elseif appIs(sketch) then
        triggerAlfredWorkflow('com.tedwise.menubarsearch', 'menubarsearch', 'open recent')
    elseif true then
        bundleId = getBundleId();
        hs.notify.new(function() hs.pasteboard.setContents(bundleId) end, {title = 'Hammerspoon', informativeText = 'Open Anything not set up', actionButtonTitle = 'Copy Bundle ID', alwaysShowAdditionalActions = true, hasActionButton = true}):send()
    end
end)

hs.urlevent.bind('toggleSidebar', function()
    if appIs(vscode) then
        hs.eventtap.keyStroke({'cmd'}, 'b', 0)
        hs.eventtap.keyStroke({'cmd'}, 'h', 0)
    elseif appIs(bear) then
        hs.eventtap.keyStroke({'control'}, '3')
    elseif appIs(phpstorm) then
        hs.eventtap.keyStroke({'cmd'}, '1')
    elseif appIs(sketch) then
        hs.eventtap.keyStroke({'cmd', 'option'}, '1')
        hs.eventtap.keyStroke({'cmd', 'option'}, '2')
    elseif appIs(omnifocus) then
        hs.eventtap.keyStroke({'cmd', 'option'}, 's')
    end
end)

hs.urlevent.bind('navigateBack', function()
    if(activeModal == nil) then
      if appIncludes({bear, spotify}) then
          hs.eventtap.keyStroke({'cmd', 'option'}, 'left')
      elseif appIncludes({finder, slack, brave}) then
          hs.eventtap.keyStroke({'cmd'}, '[')
      elseif appIs(iterm) then
          hs.eventtap.keyStroke({'control'}, 'w', 0)
          hs.eventtap.keyStroke({}, 'h')
      end
    elseif activeModal == 'windowM' then
        hs.eventtap.keyStroke({}, 'a')
    end
end)

hs.urlevent.bind('navigateForward', function()
    if appIncludes({bear, spotify}) then
        hs.eventtap.keyStroke({'cmd', 'option'}, 'right')
    elseif appIncludes({finder, slack, brave}) then
        hs.eventtap.keyStroke({'cmd'}, ']')
    elseif appIs(iterm) then
        hs.eventtap.keyStroke({'control'}, 'w', 0)
        hs.eventtap.keyStroke({}, 'l')
    end
end)

hs.urlevent.bind('navigateUpward', function()
    if appIs(tableplus) then
        hs.eventtap.keyStroke({'cmd'}, '[')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({''}, 'up')
    elseif appIs(messages) then
        hs.eventtap.keyStroke({'control', 'shift'}, 'tab')
    elseif appIs(brave) then
        hs.eventtap.keyStroke({'cmd', 'shift'}, ']')
    elseif appIs(iterm) then
        hs.eventtap.keyStroke({'control'}, 'w', 0)
        hs.eventtap.keyStroke({}, 'k')
    else
        hs.eventtap.keyStroke({'cmd', 'shift'}, '[')
    end
end)

hs.urlevent.bind('navigateDownward', function()
    if appIs(tableplus) then
        hs.eventtap.keyStroke({'cmd'}, ']')
    elseif appIs(bear) then
        hs.eventtap.keyStroke({''}, 'down')
    elseif appIs(messages) then
        hs.eventtap.keyStroke({'control'}, 'tab')
    elseif appIs(brave) then
        hs.eventtap.keyStroke({'cmd', 'shift'}, '[')
    elseif appIs(iterm) then
        hs.eventtap.keyStroke({'control'}, 'w', 0)
        hs.eventtap.keyStroke({}, 'j')
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
    local text = getSelectedText(true)
    if text then
        -- Already in clipboard, do not reset
    elseif appIs(bear) then
        hs.eventtap.keyStroke({'cmd', 'option', 'shift'}, 'l') -- Copy link to note
    elseif appIs(brave) then
        hs.eventtap.keyStrokes('yy') -- Copy current URL
    end
end)

hs.urlevent.bind('toggleBreakTime', function()
    local status, response, description = hs.osascript.javascript([[
        breaktime = Application("BreakTime")
        breaktime.enabled = !breaktime.enabled()
        breaktime.enabled()
    ]])

    if status then -- if the call to toggle BreakTime was successful
        if response then -- response is the updated status of BreakTime
            text = "BreakTime was Enabled."
        else
            text = "BreakTime was Disabled."
        end
        btNotify = hs.notify.new({title = 'BreakTime', informativeText = text})
        btNotify:contentImage(hs.image.imageFromAppBundle(breaktime))
        btNotify:send()
    end
end)

hs.urlevent.bind('createOmniEODTask', function(hsFnName, payload)
    hs.urlevent.openURL('omnifocus:///add?name=Write%20EOD%20&due=today%206pm&project=Tighten%3A%20Admin&reveal-new-item=false&autosave=true&note=hammerspoon://hitMe')
end)

hs.urlevent.bind('enablePlayOnNoise', function()
    listener = hs.speech.listener.new("SpeechToPlay")
    listener:commands({'start', 'stop', 'back', 'forward'})
    listener:setCallback(togglePlayOnNoise)
    listener:start()
end)

hs.urlevent.bind('disablePlayOnNoise', function()
    if listener and listener:isListening() then
        listener:stop()
    end
end)

----------------------------------------------------------------------------------------------------
-- Misc. Functions
--
-- Functions that I use in my Hammerspoon script, but don't feel the need
-- to break it out into a separate .lua file to import
------------------------------------------------------------------------------------------------------

-- Temporarily focus on Brave Browser and press the spacebar
-- Pressing the spacebar is usually the command to start or stop video playback
function togglePlayOnNoise(recognizerObject, command)
    local refocus = false
    local focusedApp = nil

    if not focusedWindowIs(brave) then
        refocus = true
        local focusedApp = hs.window:focusedWindow():application():bundleID()
        hs.application.launchOrFocusByBundleID(brave)
    end

    if command == 'start' or command == 'stop' then
        hs.eventtap.keyStroke({}, 'space')
    elseif command == 'back' then
        hs.eventtap.keyStroke({}, 'left')
    elseif command == 'forward' then
        hs.eventtap.keyStroke({}, 'right')
    end

    if refocus then
        hs.application.launchOrFocusByBundleID(focusedApp)
    end
end

--------------------------------------------------------------------------------
-- Attributions and Inspirations
--
-- Andrew Morgan: https://github.com/andrewmile/dotfiles/tree/master/hammerspoon
-- Jesse Leite: https://github.com/jesseleite/dotfiles/tree/master/hammerspoon
--------------------------------------------------------------------------------
