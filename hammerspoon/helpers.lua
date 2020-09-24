--------------------------------------------------------------------------------
-- Language Helpers
--------------------------------------------------------------------------------

function map(f, t)
  n = {}

  for k,v in pairs(t) do
    n[k] = f(v);
  end

  return n;
end

function sleep(milliseconds)
  hs.timer.usleep(milliseconds * 1000)
end

--------------------------------------------------------------------------------
-- Grid Helpers
--------------------------------------------------------------------------------

function moveApp(application, cell)
  local app = hs.application.get(application) or hs.application.open(application)
  if app == nil then
    return false
  end
  local window = hs.application.mainWindow(app)
  if window then
    hs.grid.set(window, cell, hs.screen.mainScreen())
    hs.application.unhide(app)
    hs.application.activate(app)
  end
end

function moveCurrentWindow(cell)
  hs.grid.set(hs.window.focusedWindow(), cell, hs.screen.mainScreen())
end

function snap()
  local window = hs.window.focusedWindow()
  hs.grid.snap(window)

  local application = hs.application.frontmostApplication():name()
  local cell = hs.grid.get(window)
  local position = string.format('%s,%s %sx%s', math.floor(cell.x), math.floor(cell.y), math.floor(cell.w), math.floor(cell.h))
  print(string.format('%s - %s', application, position))
end

function getPositions(sizes, leftOrRight, topOrBottom)
  local applyLeftOrRight = function (size)
    if type(positions[size]) == 'string' then
      return positions[size]
    end
    return positions[size][leftOrRight]
  end

  local applyTopOrBottom = function (position)
    local h = math.floor(string.match(position, 'x([0-9]+)') / 2)
    position = string.gsub(position, 'x[0-9]+', 'x'..h)
    if topOrBottom == 'bottom' then
      local y = math.floor(string.match(position, ',([0-9]+)') + h)
      position = string.gsub(position, ',[0-9]+', ','..y)
    end
    return position
  end

  if (topOrBottom) then
    return map(applyTopOrBottom, map(applyLeftOrRight, sizes))
  end

  return map(applyLeftOrRight, sizes)
end

--------------------------------------------------------------------------------
-- Screen Helpers
--------------------------------------------------------------------------------

function resetWhenSwitchingScreen(f)
  f()

  hs.screen.watcher.newWithActiveScreen(function ()
    f()
  end):start()
end

--------------------------------------------------------------------------------
-- Layout Helpers
--------------------------------------------------------------------------------

function setLayout(layout, saveCurrentLayout)
  if layout then
    layouts[layout]()
    if saveCurrentLayout then
      currentLayout = layout
    end
  elseif currentLayout then
    layouts[currentLayout]()
  end
end

function resetLayout()
  currentLayout = nil
end

--------------------------------------------------------------------------------
-- App/Window Helpers
--------------------------------------------------------------------------------

function has_value(tab, val)
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

function getBundleId()
    return hs.application.frontmostApplication():bundleID();
end

--------------------------------------------------------------------------------
-- Alfred Helpers
--------------------------------------------------------------------------------

function triggerAlfredSearch(search)
    hs.osascript.applescript('tell application id "com.runningwithcrayons.Alfred" to search "' .. search ..' "')
end

function triggerAlfredWorkflow(workflow, trigger, arg)
    if (arg) then
        hs.osascript.applescript('tell application id "com.runningwithcrayons.Alfred" to run trigger "' .. trigger .. '" in workflow "' .. workflow .. '" with argument "' .. arg .. ' "')
    else
        hs.osascript.applescript('tell application id "com.runningwithcrayons.Alfred" to run trigger "' .. trigger .. '" in workflow "' .. workflow .. '"')
    end
end

--------------------------------------------------------------------------------
-- Clipboard Helpers
--------------------------------------------------------------------------------

function getSelectedText(copying)
    local original = hs.pasteboard.getContents()
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({'cmd'}, 'C')
    local text = hs.pasteboard.getContents()
    local finderFileSelected = false
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
