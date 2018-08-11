-- acid

engine.name = "Acid"

local scale_degrees = {2,1,2,2,2,1,2}
local notes = {}
local freqs = {}

local BeatClock = require 'beatclock'
local clk = BeatClock.new()

local keys = {
  "note",
  "cutoff",
}
local step = 1
local edit = {
  step=1,
  keyidx=1,
  key=keys[1],
}
local pattern = {}

function init()
  screen.aa(0)
  engine.hz(110)
  build_scale()

  for i=1,16 do
    pattern[i]={
      note=math.floor(math.random()*16)+1,
      on=math.random()>0.6,
      cutoff=math.floor(math.random()*16)+1,
    }
  end

  clk.on_step = on_step
  clk.on_select_internal = function() clk:start() end
  clk:add_clock_params()

  params:bang()
end

function build_scale()
  local scale = 5
  local trans = 0
  local n = 0
  for i=1,16 do
    notes[i] = n
    n = n + scale_degrees[(scale + i)%#scale_degrees + 1]
  end
  for i=1,#notes do
    freqs[i] = 55*2^((notes[i]+trans)/12)
  end
end 

local gateMetro = metro.alloc()
gateMetro.callback = function() engine.gate(0) end

function on_step()
  step = step%16 + 1 

  local pv = pattern[step]
  if pv.on then
    engine.hz(freqs[pv.note])
    engine.cutoff(pv.cutoff*100)
    engine.gate(1)
    gateMetro:start(1/100, 1)
  end

  redraw()
end

function redraw()
  screen.clear()
  screen.level(1)
  drawgrid(edit.key)
  screen.update()
end

function drawgrid(key)
  for i=1,16 do
    for st=1,16 do
      local hl1 = edit.step==st and 5 or 2
      local hl2 = edit.step==st and 3 or 1
      local pv = pattern[st]
      screen.level((pv[key] == i and pv.on) and 15 or step == st and hl1 or hl2)
      screen.rect(st*8-7, 65-i*4, 6, 2)
      screen.close()
      screen.fill()
    end
  end
end

function key(n, z)
  if n == 3 and z == 1 then
    pattern[edit.step].on = not pattern[edit.step].on
  end
  redraw()
end

function enc(n, d)
  local st = edit.step
  if n == 1 then
    edit.keyidx = math.max(math.min(edit.keyidx+d,#keys),1)
    edit.key = keys[edit.keyidx]
  end
  if n == 2 then
    edit.step = math.max(math.min(st+d,16),1)
  end
  if n == 3 and pattern[st].on then
    pattern[st][edit.key] = math.max(math.min(pattern[st][edit.key]+d,16),1)
  end
  redraw()
end
