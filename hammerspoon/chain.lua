--------------------------------------------------------------------------------
-- Chain the specified grid movement positions on the focused window
--
-- Courtesy of: https://github.com/wincent/wincent/blob/master/roles/dotfiles/files/.hammerspoon/init.lua
--------------------------------------------------------------------------------

-- This is like the "chain" feature in Slate, but with a couple of enhancements:
--
--  - Chains always start on the screen the window is currently on.
--  - A chain will be reset after 2 seconds of inactivity, or on switching from
--    one chain to another, or on switching from one app to another, or from one
--    window to another.

-- All three are file-scoped and shared by every chain the factory below
-- returns. That sharing is the point: starting a different chain, or moving to
-- another window, resets the sequence.
--
-- lastSeenAt was missing from this list, so it was a global. Two separate
-- problems, fixed together:
--
--   1. It leaked into _G.
--   2. `lastSeenAt < now - chainResetInterval` reads it before anything
--      assigns it, and comparing nil to a number is an error in Lua. That
--      never fired only because `or` short-circuits: on the first call
--      `lastSeenChain ~= movements` is already true, so the comparison is
--      never reached. Correct by accident, and it would break the moment the
--      conditions were reordered.
--
-- Seeding it to 0 rather than nil fixes the second: 0 is always less than
-- `now - 2`, so a first call resets the sequence, which is what the
-- short-circuit was already producing.
local lastSeenChain = nil
local lastSeenWindow = nil
local lastSeenAt = 0

return (function(movements)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

  return function()
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local now = hs.timer.secondsSinceEpoch()
    local screen = win:screen()

    if
      lastSeenChain ~= movements or
      lastSeenAt < now - chainResetInterval or
      lastSeenWindow ~= id
    then
      sequenceNumber = 1
      lastSeenChain = movements
--  elseif (sequenceNumber == 1) then
--    -- At end of chain, restart chain on next screen.
--    screen = screen:next()
    end
    lastSeenAt = now
    lastSeenWindow = id

    hs.grid.set(win, movements[sequenceNumber], screen)
    sequenceNumber = sequenceNumber % cycleLength + 1
  end
end)
