-- rebound: a kinetic sequencer

local cs = require 'controlspec'
local MusicUtil = require 'mark_eats/musicutil'
local BeatClock = require 'beatclock'

local Rebound = {}
Rebound.__index = Rebound

function Rebound:new(impl)
  local r = {}
  setmetatable(r, self)

print("impl!!")
print(impl)
  r.impl = impl
  r.balls = {}
  r.cur_ball = 0
  r.note_queue = {}
  r.shift = false

  r.info_visible = false
  r.info_note_name = ""
  r.info_timer = metro.alloc()
  r.info_timer.callback = function() r.info_visible = false end

  return r
end

function Rebound:init()
  screen.aa(1)

  local u = metro.alloc()
  u.time = 1/60
  u.count = -1
  u.callback = function() self:update() end
  u:start()

  local clk = BeatClock.new()
  clk.on_step = function() self:play_notes() end
  clk.on_select_internal = function() clk:start() end
  clk:add_clock_params()

  print("huuu")
  print(self.impl)

  self.impl.add_params()

  params:bang()
end

function Rebound:show_info()
  self.info_visible = true
  self.info_timer:start(1, 1)
  local b = self.balls[self.cur_ball]
  info_note_name = self.impl.note_name(b.n)
end

function Rebound:redraw()
  screen.clear()
  if self.shift then
    screen.level(5)
    screen.line_width(1)
    screen.rect(1,1,126,62)
    screen.stroke()
  end
  for i=1,#self.balls do
    self:drawball(self.balls[i], i == self.cur_ball)
  end
  if self.info_visible and self.cur_ball > 0 then
    screen.level(15)
    screen.font_face(3)
    screen.font_size(16)
    screen.move(8,52)
    screen.text(self.cur_ball)
    screen.move(32,52)
    screen.text(self.info_note_name)
  end
  screen.update()
end

function Rebound:update()
  for i=1,#self.balls do
    self:updateball(self.balls[i])
  end
  self:redraw()
end

function Rebound:enc(n, d)
  if n == 1 and not self.shift and self.cur_ball > 0 then
    -- note
    local b = self.balls[self.cur_ball]
    b.n = math.min(math.max(b.n+d, self.impl.min_note), self.impl.max_note)
    self:show_info()
  elseif n == 2 then
    -- rotate
    for i=1,#self.balls do
      if self.shift or i == self.cur_ball then
        self.balls[i].a = self.balls[i].a - d/10
      end
    end
  elseif n == 3 then
    -- accelerate
    for i=1,#self.balls do
      if self.shift or i == self.cur_ball then
        self.balls[i].v = self.balls[i].v + d/10
      end
    end
  end
end

function Rebound:key(n, z)
  if n == 1 then
    -- shift
    self.shift = z == 1
  elseif n == 2 and z == 1 then
    if self.shift and self.cur_ball > 0 then
      -- remove ball
      table.remove(self.balls, self.cur_ball)
      if self.cur_ball > #self.balls then
        self.cur_ball = #self.balls
      end
    else
      -- add ball
      table.insert(self.balls, self:newball())
      self.cur_ball = #self.balls
    end
    self:show_info()
  elseif n == 3 and z == 1 and not self.shift and #self.balls > 0 then
    -- select next ball
    self.cur_ball = (self.cur_ball % #self.balls) + 1
    self:show_info()
  end
end

function Rebound:newball()
  return {
    x = 64,
    y = 32,
    v = 0.5*math.random()+0.5,
    a = math.random()*2*math.pi,
    n = math.floor(math.random()*(self.impl.max_rand_note-self.impl.min_rand_note)+self.impl.min_rand_note),
  }
end

function Rebound:drawball(b, hilite)
  screen.level(hilite and 15 or 5)
  screen.circle(b.x, b.y, hilite and 2 or 1.5)
  screen.fill()
end

function Rebound:updateball(b)
  b.x = b.x + math.sin(b.a)*b.v
  b.y = b.y + math.cos(b.a)*b.v

  local minx = 2
  local miny = 2
  local maxx = 126
  local maxy = 62
  if b.x >= maxx then
    b.x = maxx
    b.a = 2*math.pi - b.a
    Rebound:enqueue_note(b, 0)
  elseif b.x <= minx then
    b.x = minx
    b.a = 2*math.pi - b.a
    Rebound:enqueue_note(b, 1)
  elseif b.y >= maxy then
    b.y = maxy
    b.a = math.pi - b.a
    Rebound:enqueue_note(b, 2)
  elseif b.y <= miny then
    b.y = miny
    b.a = math.pi - b.a
    Rebound:enqueue_note(b, 3)
  end
end

function Rebound:enqueue_note(b, z)
  local n = b.n
  -- TODO: move this octave behavior to impl
  if z == 0 then
    n = n + 12
  elseif z == 1 then
    n = n - 12
  end
  n = math.max(self.impl.min_note, math.min(self.impl.max_note, n))
  table.insert(self.note_queue, n)
end

function Rebound:play_notes()
  -- play queued notes
  while #self.note_queue > 0 do
    self.impl.play_note(table.remove(self.note_queue))
  end
end

return Rebound
