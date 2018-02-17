--SFX Editor

local sfxobj = require("Libraries.sfx") --The sfx object

local eapi = select(1,...) --The editors api

local sw, sh = screenSize() --The screensize
local volColors = {1,2,13,6,12,14,15,7}

local se = {} --sfx editor

local sfxSlots = 64 --The amount of sfx slots
local sfxNotes = 32 --The number of notes in each sfx

local defaultSpeed = 0.25 --The default speed
local speed = defaultSpeed --The current sfx speed

local selectedSlot = 0
local selectedWave = 0

local playingNote = -1

local pitchGrid = {0,9, sfxNotes*4,12*7, sfxNotes,12*7}
local volumeGrid = {0,sh-8-8*2-1, sfxNotes*4,8*2, sfxNotes,8}

--The SFXes datas.
local sfxdata = {}
for i=0,sfxSlots-1 do
  local sfx = sfxobj(sfxNotes, defaultSpeed)
  for i=0,sfxNotes-1 do
    sfx:setNote(i,1,1,0,0) --Octave 0 is hidden...
  end
  sfxdata[i] = sfx
end

local patternImage = imagedata("LK12;GPUIMG;2x6;770007700077;")
local pattern2Image = imagedata("LK12;GPUIMG;4x2;00070070;")

local function drawGraph()
  local x,y = pitchGrid[1], pitchGrid[2]-1
  local x2,y2 = volumeGrid[1], volumeGrid[2]
  local sfx = sfxdata[selectedSlot]
  
  --Pitch Rectangle
  rect(x,y,pitchGrid[3]+1,pitchGrid[4]+4,false,0)
  --Volume Rectangle
  rect(x2,y2-1,volumeGrid[3]+1,volumeGrid[4]+2,false,0)
  --Horizental Box (Style)
  rect(x,y+pitchGrid[4]+4, pitchGrid[3]+1+1, y2-1-y-pitchGrid[4]-4, false, 9)
  patternFill(patternImage)
  rect(x,y+pitchGrid[4]+4, pitchGrid[3]+1+1, y2-1-y-pitchGrid[4]-4, false, 4)
  patternFill()
  --Vertical Line (Style)
  rect(x+pitchGrid[3]+1,8, 4,sh-16, false, 9)
  patternFill(pattern2Image)
  rect(x+pitchGrid[3]+1,8, 4,sh-16, false, 4)
  patternFill()
  
  local playingNote = math.floor(playingNote)
  
  --Notes lines
  for i=0, sfxNotes-1 do
    local note,oct,wave,amp = sfx:getNote(i); note = note-1
    if wave >= 0 and amp > 0 then
      rect(x+1+i*4, y+12*8-(note+oct*12), 2, note+oct*12-9, false, (playingNote == i and 6 or 1))
      rect(x+1+i*4, y+12*8-(note+oct*12), 2, 2, false, 8+wave)
    end
    
    local vol = math.floor(amp*7)
    
    if wave < 0 then vol = 0 end
    
    rect(x2+1+i*4, y2+(7-vol)*2, 3,2, false, volColors[vol+1])
  end
end

local slotLeft, slotLeftDown = {sw-27,15,4,7}, false
local slotRight, slotRightDown = {sw-10,15,4,7}, false

function se:drawSlot()
  color(12)
  print("SLOT:",sw-54,16)
  if slotLeftDown then pal(9,4) end
  eapi.editorsheet:draw(164,slotLeft[1],slotLeft[2])
  pal()
  
  color(13)
  rect(sw-22,15,fontWidth()*2+3,fontHeight()+2, false, 6)
  print(selectedSlot, sw-21,16, fontWidth()*2+2, "right")
  
  if slotRightDown then pal(9,4) end
  eapi.editorsheet:draw(165,slotRight[1],slotRight[2])
  pal()
end

local speedLeft, speedLeftDown = {sw-26,27,4,7}, false
local speedRight, speedRightDown = {sw-9,27,4,7}, false

function se:drawSpeed()
  color(7)
  print("SPEED:",sw-56,28)
  if speedLeftDown then pal(9,4) end
  eapi.editorsheet:draw(164,speedLeft[1],speedLeft[2])
  pal()
  
  color(13)
  rect(sw-21,27,fontWidth()*2+3,fontHeight()+2, false, 6)
  print(speed/0.25, sw-20,28, fontWidth()*2+2, "right")
  
  if speedRightDown then pal(9,4) end
  eapi.editorsheet:draw(165,speedRight[1],speedRight[2])
  pal()
end

function se:entered()
  eapi:drawUI()
  drawGraph()
  self:drawSlot()
  self:drawSpeed()
end

function se:leaved()
  
end

function se:pitchMouse(state,x,y,button,istouch)
  local cx,cy = whereInGrid(x,y,pitchGrid)
  if cx and isMDown(1) then
    local sfx = sfxdata[selectedSlot]
    cx, cy = cx-1, 12*8-cy+1
    local note = cy%12
    local oct = math.floor(cy/12)
    local _,_,_,amp = sfx:getNote(cx)
    sfx:setNote(cx,note,oct,selectedWave,amp == 0 and 5/7 or amp)
    drawGraph()
  end
end

function se:volumeMouse(state,x,y,button,istouch)
  local cx,cy = whereInGrid(x,y,volumeGrid)
  if cx and isMDown(1) then
    local sfx = sfxdata[selectedSlot]
    local note, oct, wave = sfx:getNote(cx-1)
    if wave < 0 and cy < 8 then wave = selectedWave end
    sfx:setNote(cx-1,false,false,wave,(8-cy)/7)
    drawGraph()
  end
end

function se:slotMouse(state,x,y,button,istouch)
  if state == "pressed" then
    if isInRect(x,y,slotLeft) then
      slotLeftDown = true
      self:drawSlot()
    end
    
    if isInRect(x,y,slotRight) then
      slotRightDown = true
      self:drawSlot()
    end
  elseif state == "moved" then
    if not isInRect(x,y,slotLeft) and slotLeftDown then
      slotLeftDown = false
      self:drawSlot()
    end
    
    if not isInRect(x,y,slotRight) and slotRightDown then
      slotRightDown = false
      self:drawSlot()
    end
  else
    if isInRect(x,y,slotLeft) and slotLeftDown then
      selectedSlot = math.max(selectedSlot-1,0)
      speed = sfxdata[selectedSlot]:getSpeed()
    end
    slotLeftDown = false
    
    if isInRect(x,y,slotRight) and slotRightDown then
      selectedSlot = math.min(selectedSlot+1,sfxSlots-1)
      speed = sfxdata[selectedSlot]:getSpeed()
    end
    slotRightDown = false
    
    drawGraph() self:drawSlot() self:drawSpeed()
  end
end

function se:speedMouse(state,x,y,button,istouch)
  if state == "pressed" then
    if isInRect(x,y,speedLeft) then
      speedLeftDown = true
      self:drawSpeed()
    end
    
    if isInRect(x,y,speedRight) then
      speedRightDown = true
      self:drawSpeed()
    end
  elseif state == "moved" then
    if not isInRect(x,y,speedLeft) and speedLeftDown then
      speedLeftDown = false
      self:drawSpeed()
    end
    
    if not isInRect(x,y,speedRight) and speedRightDown then
      speedRightDown = false
      self:drawSpeed()
    end
  else
    if isInRect(x,y,speedLeft) then
      speed = math.max(speed-0.25,0.25)
      sfxdata[selectedSlot]:setSpeed(speed)
    end
    speedLeftDown = false
    
    if isInRect(x,y,speedRight) then
      speed = math.min(speed+0.25,255*0.25)
      sfxdata[selectedSlot]:setSpeed(speed)
    end
    speedRightDown = false
    
    drawGraph() self:drawSlot() self:drawSpeed()
  end
end

se.keymap = {
  ["space"] = function()
    sfxdata[selectedSlot]:play()
    playingNote = 0
  end
}

function se:update(dt)
  if playingNote >= 0 then
    playingNote = playingNote + (dt*sfxNotes)/speed
    if playingNote >= sfxNotes then
      playingNote = -1
    end
    drawGraph()
  end
end

function se:mousepressed(x,y,button,istouch)
  self:pitchMouse("pressed",x,y,button,istouch)
  self:volumeMouse("pressed",x,y,button,istouch)
  self:slotMouse("pressed",x,y,button,istouch)
  self:speedMouse("pressed",x,y,button,istouch)
end

function se:mousemoved(x,y,button,istouch)
  self:pitchMouse("moved",x,y,dx,dy,istouch)
  self:volumeMouse("moved",x,y,dx,dy,istouch)
  self:slotMouse("moved",x,y,dx,dy,istouch)
  self:speedMouse("moved",x,y,dx,dy,istouch)
end

function se:mousereleased(x,y,button,istouch)
  self:pitchMouse("released",x,y,button,istouch)
  self:volumeMouse("released",x,y,button,istouch)
  self:slotMouse("released",x,y,button,istouch)
  self:speedMouse("released",x,y,button,istouch)
end

return se