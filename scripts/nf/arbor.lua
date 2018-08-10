-- arbor

engine.name = "PolyPerc"

local root = nil
local cur = nil

local num_steps = 16

local scale_degrees = {2,1,2,2,2,1,2}
local notes = {}
local freqs = {}

local shift = false

function init()
  screen.aa(1)

  build_scale()

  root = new_node(nil, 0, 0)
  cur = new_node(root, 0, 20)
  build_tree(cur, 0)

  local u = metro.alloc()
  u.time = 1/60
  u.count = -1
  u.callback = update
  u:start()
end

local frame = 0

function update()
  frame = frame+1
  update_node(root, (math.sin(frame/60)-0.5)*math.pi/64)
  redraw()
end

function build_tree(p, c)
  if c >= 5 then
    return
  end
  build_tree(random_node(p, c), c+1)
  if math.random() > 0.5 then
    build_tree(random_node(p, c), c+1)
  end
end

function random_node(p, c)
  local d = (math.random()-0.5)*math.pi/2
  local l = math.random()*20+10
  return new_node(p, d, l)
end

function build_scale()
  local scale = 5
  local trans = 0
  local n = 0
  for i=1,32 do
    notes[i] = n
    n = n + scale_degrees[(scale + i)%#scale_degrees + 1]
  end
  for i=1,#notes do
    freqs[i] = 55*2^((notes[i]+trans)/12)
  end
end 

function redraw()
  screen.clear()
  if shift then
    screen.level(5)
    screen.line_width(1)
    screen.rect(1,1,126,62)
    screen.stroke()
  end
  draw_node(root)
  screen.update()
end

function update_node(n, d)
  if not n then
    return
  end
  local p = n.parent
  if p then
    d = 1.2*d + n.d
    n.x = p.x + math.cos(d)*n.l
    n.y = p.y + math.sin(d)*n.l
  else
    n.x = 0
    n.y = 32
  end
  for i=1,#n.child do
    update_node(n.child[i], d)
  end
end

function draw_node(n)
  if not n then
    return
  end

  local p = n.parent
  if p then
    screen.level(5)
    screen.move(p.x, p.y)
    screen.line(n.x, n.y)
    screen.stroke()
  end

  for i=1,#n.child do
    draw_node(n.child[i])
  end

  screen.level(15)
  screen.circle(n.x, n.y, n == cur and 1.5 or 1)
  screen.fill()
end

function enc(n, d)
  if not cur then
    return
  end
  if n == 2 then
    cur.d = cur.d + d/50
  elseif n == 3 then
    cur.l = cur.l + d
  end
end

function key(n, z)
  if n == 1 then
    -- shift
    shift = z == 1
  elseif n == 3 and z == 1 then
    if cur and #cur.child > 0 then
      if shift then
        cur = #cur.child < 2 and new_node(cur) or cur.child[2]
      else 
        cur = cur.child[1]
      end
    else
      cur = new_node(cur, 0, 20)
    end
    if not root then
      root = cur
    end
  elseif n == 2 and z == 1 and cur then
    if cur.parent then
      cur = cur.parent
    end
  end
end

function new_node(p, d, l)
  local n = {
    d = d,
    l = l,
    parent = p,
    child = {},
  }
  if p then 
    table.insert(p.child, n)
  end
  return n
end
