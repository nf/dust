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

-- TODO:
-- - ack-based version

engine.name = "PolyPerc"

-- XXX remove next line
package.loaded['nf/rebound'] = nil
local Rebound = require 'nf/rebound'
local MusicUtil = require 'mark_eats/musicutil'
local cs = require 'controlspec'

local scale_notes = {}

function build_scale()
  scale_notes = MusicUtil.generate_scale(params:get("root"), params:get("scale"), 9)
end 

local impl = {
  min_note = 0,
  max_note = 127,
  min_rand_note = 24,
  max_rand_note = 127-24,
  note_name = function(n)
    n = MusicUtil.snap_note_to_array(n, scale_notes)
    return MusicUtil.note_num_to_name(n, true)
  end,
  add_params = function()
    local scales = {}
    for i=1,#MusicUtil.SCALES do
      scales[i] = MusicUtil.SCALES[i].name
    end
    params:add_option("scale", scales)
    params:set_action("scale", build_scale)
  
    params:add_option("root", MusicUtil.NOTE_NAMES)
    params:set_action("root", build_scale)
  
    params:add_separator()
  
    cs.AMP = cs.new(0,1,'lin',0,0.5,'')
    params:add_control("amp",cs.AMP)
    params:set_action("amp",
    function(x) engine.amp(x) end) 
  
    cs.PW = cs.new(0,100,'lin',0,80,'%')
    params:add_control("pw",cs.PW)
    params:set_action("pw",
    function(x) engine.pw(x/100) end) 
  
    cs.REL = cs.new(0.1,3.2,'lin',0,0.2,'s') 
    params:add_control("release",cs.REL)
    params:set_action("release",
    function(x) engine.release(x) end) 
  
    cs.CUT = cs.new(50,5000,'exp',0,555,'hz')
    params:add_control("cutoff",cs.CUT)
    params:set_action("cutoff",
    function(x) engine.cutoff(x) end) 
  
    cs.GAIN = cs.new(0,4,'lin',0,1,'')
    params:add_control("gain",cs.GAIN)
    params:set_action("gain",
    function(x) engine.gain(x) end) 
  end,
  play_note = function(n)
    n = MusicUtil.snap_note_to_array(n, scale_notes)
    engine.hz(MusicUtil.note_num_to_freq(n))
  end
}

local rb = Rebound:new(impl)

function init() rb:init() end
function redraw() rb:redraw() end
function enc(n, d) rb:enc(n, d) end
function key(n, z) rb:key(n, z) end

-- function midistuff()
--   -- send note off for previously played notes
--   while #note_off_queue > 0 do
--     Midi.send_all({type='note_off', note=table.remove(note_off_queue)})
--   end
--   -- play queued notes
--   while #note_queue > 0 do
--     local n = table.remove(note_queue)
--     n = MusicUtil.snap_note_to_array(n, scale_notes)
--     engine.hz(MusicUtil.note_num_to_freq(n))
--     Midi.send_all({type='note_on', note=n})
--     table.insert(note_off_queue, n)
--   end
-- end
