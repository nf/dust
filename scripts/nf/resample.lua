-- rebound: a kinetic sequencer
--
-- key1: shift^
-- key2: add/^remove orb
-- key3: select next orb
-- enc1: change orb note
-- enc2: rotate orb^s
-- enc3: accelerate orb^s

-- written by nf in august 2018
-- params and scales taken from tehn/awake, thanks

local cs = require 'controlspec'

engine.name = "Ack"

local ack = require 'jah/ack'

local balls = {}
local cur_ball = 0

local BeatClock = require 'beatclock'
local clk = BeatClock.new()

local num_channels = 16
local note_queue = {}

local shift = false

local info_visible = false
local info_timer = metro.alloc()
info_timer.callback = function() info_visible = false end
function show_info()
  info_visible = true
  info_timer:start(1, 1)
end

function init()
  screen.aa(1)

  local u = metro.alloc()
  u.time = 1/60
  u.count = -1
  u.callback = update
  u:start()

  clk.on_step = play_notes
  clk.on_select_internal = function() clk:start() end
  clk:add_clock_params()

  params:add_separator()

  for channel=1,num_channels do
    ack.add_channel_params(channel)
  end
  ack.add_effects_params()

  params:bang()
end

function redraw()
  screen.clear()
  if shift then
    screen.level(5)
    screen.line_width(1)
    screen.rect(1,1,126,62)
    screen.stroke()
  end
  for i=1,#balls do
    drawball(balls[i], i == cur_ball)
  end
  if info_visible and cur_ball > 0 then
    screen.level(15)
    screen.font_face(3)
    screen.font_size(16)
    screen.move(8,52)
    screen.text(cur_ball)
    screen.font_size(32)
    screen.move(32,52)
    screen.text(balls[cur_ball].n)
  end
  screen.update()
end

function update()
  for i=1,#balls do
    updateball(balls[i])
  end
  redraw()
end

function enc(n, d)
  if n == 1 and not shift and cur_ball > 0 then
    -- note
    balls[cur_ball].n = math.min(math.max(balls[cur_ball].n+d, 1), num_channels)
    show_info()
  elseif n == 2 then
    -- rotate
    for i=1,#balls do
      if shift or i == cur_ball then
        balls[i].a = balls[i].a - d/10
      end
    end
  elseif n == 3 then
    -- accelerate
    for i=1,#balls do
      if shift or i == cur_ball then
        balls[i].v = balls[i].v + d/10
      end
    end
  end
end

function key(n, z)
  if n == 1 then
    -- shift
    shift = z == 1
  elseif n == 2 and z == 1 then
    if shift then
      -- remove ball
      table.remove(balls, cur_ball)
      if cur_ball > #balls then
        cur_ball = #balls
      end
    else
      -- add ball
      table.insert(balls, newball())
      cur_ball = #balls
    end
    show_info()
  elseif n == 3 and z == 1 and not shift and #balls > 0 then
    -- select next ball
    cur_ball = cur_ball%#balls+1
    show_info()
  end
end

function newball()
  return {
    x = 64,
    y = 32,
    v = 0.5*math.random()+0.5,
    a = math.random()*2*math.pi,
    n = math.floor(math.random()*num_channels+1),
  }
end

function drawball(b, hilite)
  screen.level(hilite and 15 or 5)
  screen.circle(b.x, b.y, hilite and 2 or 1.5)
  screen.fill()
end

function updateball(b)
  b.x = b.x + math.sin(b.a)*b.v
  b.y = b.y + math.cos(b.a)*b.v

  local minx = 2
  local miny = 2
  local maxx = 126
  local maxy = 62
  if b.x >= maxx then
    b.x = maxx
    b.a = 2*math.pi - b.a
    enqueue_note(b, 0)
  elseif b.x <= minx then
    b.x = minx
    b.a = 2*math.pi - b.a
    enqueue_note(b, 1)
  elseif b.y >= maxy then
    b.y = maxy
    b.a = math.pi - b.a
    enqueue_note(b, 2)
  elseif b.y <= miny then
    b.y = miny
    b.a = math.pi - b.a
    enqueue_note(b, 3)
  end
end

function enqueue_note(b, z)
  table.insert(note_queue, b.n)
end

function play_notes()
  while #note_queue > 0 do
    engine.trig(table.remove(note_queue)-1)
  end
end
