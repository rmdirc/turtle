Point={}

Point.__index=Point

Point.new = function(x, y, z, d)
  local pnt={}
  setmetatable(pnt, Point)
  pnt.x=x
  pnt.y=y
  pnt.z=z
  pnt.d=d
  return pnt
end

BOUNDS={
        x:{lower:0,upper:39},
        y:{lower:0,upper:40},
        z:{lower:1,upper:12}
      } -- defines out of bounds
_home=Point.new(1,1,1,0)
_dump = Point.new(1,1,1,2)
_saplings = Point.new(1,3,1,2)
_fuel = Point.new(1,5,1,2)
trees = {}

you={}

you.pos=Point.new(ix,iy,iz,id)

you.direction=function(x)
  return math.abs(x%4)
end

function ERR_RESTART(msg)
  print(msg)
  shell.run("tr",you.pos.x,you.pos.y,you.pos.z,you.pos.d)
end

function createTreeArray(TREE_SPACING)
  local x,y,z,d,i = 5,5,1,0,1
  trees[i] = Point.new(x,y,z,d)
  while x<BOUNDS.x.upper do
    while y<BOUNDS.y.upper do
      y=y+TREE_SPACING
      trees[i]=Point.new(x,y,z,d)
      i=i+1
    end
    y=5
    x=x+5
  end
end

you.invIsFull = function()
  for i=1, INV_MAX do
    if turtle.getItemSpace(i)>0 and i~=SAPLING_SLOT then
      return false
    end
  end
  return true
end

you.invIsEmpty = function()
  for i=1, INV_MAX do
    if turtle.getItemCount(i)>0 and i~=SAPLING_SLOT then
      return false
    end
  end
  return true
end

you.turn = function(degrees)
  local i=0
  while i<degrees do
    if degrees>180 and degrees<360 then
      turtle.turnRight()
      you.pos.d=you.direction(you.pos.d-1)
      i=degrees
    else
      turtle.turnLeft()
      you.pos.d=you.direction(you.pos.d+1)
      i=i+90
    end
  end
end

you.turnTo=function(dir)
  while dir~=you.pos.d do
    you.turn(90)
  end
  print("Completed turnto. turned to "..you.pos.d)
end

you.move = function(count, boolBreakBlock)
  if boolBreakBlock=="" then
    boolBreakBlock=true
  end
  for i=0, count-1 do
    local tries=0
    while not turtle.forward() do
      while turtle.getFuelLevel()==0 do
        if tries<1 then print("Refuel") end
        turtle.select(FUEL_SLOT)
        turtle.refuel()
      end
      if tries>3 and boolBreakBlock then
        turtle.dig()
      else
        os.sleep(1)
        tries=tries+1
      end
    end
    if you.pos.d==0 then
      you.pos.x=you.pos.x+1
    elseif you.pos.d==2 then
      you.pos.x=you.pos.x-1
    elseif you.pos.d==1 then
      you.pos.y=you.pos.y+1
    elseif you.pos.d==3 then
      you.pos.y=you.pos.y-1
    end
  end
  if you.pos.x<BOUNDS.x.lower or you.pos.x>BOUNDS.x.upper then ERR_RESTART("Out of Bounds: X") end
  if you.pos.y<BOUNDS.y.lower or you.pos.y>BOUNDS.y.upper then ERR_RESTART("Out of Bounds: Y") end
end

you.moveVertical = function(count)
  print("Moving Vertical")
  if count>0 then
    for i=0, count-1 do
      if you.pos.z>BOUNDS.z.upper then ERR_RESTART("Out of Bounds: Z high") end
      turtle.up()
      you.pos.z=you.pos.z+1
    end
  else
    for i=count, -1, 1 do
      if you.pos.z<BOUNDS.z.lower then ERR_RESTART("Out of Bounds: Z low") end
      turtle.down()
      you.pos.z=you.pos.z-1
    end
  end
end

you.placeUnder = function()
  while not turtle.placeDown() then
    turtle.digDown()
  end
end

you.storeInv=function()
  for i=1, INV_MAX do
    turtle.select(i)
    turtle.drop()
  end
end

you.moveTo = function(_point)
  print("moveTo inited")
  local destX = _point.x
  print("Destx="..destX)
  local destY = _point.y
  print("Desty="..destY)
  local destZ = _point.z
  print("DestZ="..destZ)
  local destD = _point.d
  print("DestD="..destD)
  if you.pos.z < destZ then
    for i=you.pos.z, destZ-1 do
      if turtle.detectUp() and not(you.pos.z == destZ) then turtle.digUp() end
      you.moveVertical(1)
      print(you.pos.x..", "..you.pos.y..", "..you.pos.z)
    end
  elseif you.pos.z > destZ  then
    for i=you.pos.z, destZ+1, -1 do
      if turtle.detectDown() and not (you.pos.z == destZ) then turtle.digDown() end
      you.moveVertical(-1)
      print(you.pos.x..", "..you.pos.y..", "..you.pos.z)
    end
  end
  if you.pos.x < destX then
    you.turnTo(0)
    for i=you.pos.x, destX-1 do
      you.move(1)
      print(you.pos.x..", "..you.pos.y)
    end
  elseif you.pos.x > destX then
    you.turnTo(2)
    print("initing for, posx>destx")
    for i=you.pos.x, destX+1, -1 do
      you.move(1)
      print(you.pos.x..", "..you.pos.y)
    end
  end
  if you.pos.y < destY then
    you.turnTo(1)
    for i=you.pos.y, destY-1 do
      you.move(1)
      print(you.pos.x..", "..you.pos.y)
    end
  elseif you.pos.y > destY then
    you.turnTo(3)
    for i=you.pos.y, destY+1, -1 do
      you.move(1)
      print(you.pos.x..", "..you.pos.y)
    end
  end
  you.turnTo(destD)
  print("MovedTo successful")
end

function treeholes(a,f)
  local arr={Point.new(a.x,a.y-1,a.z,a.d),Point.new(a.x,a.y+1,a.z,a.d)}
  return arr[f]
end

function placeTorch()
  turtle.select(1)
  while turtle.getItemCount()==0 do
    turtle.select(turtle.getSelectedSlot()%4+1)
  end
  turtle.placeDown()
end

createTreeArray(5)
for i=0,table.getn(trees) do
  local a=trees[i]
  you.moveTo(Point.new(a.x,a.y-1,a.z,a.d))
  turtle.digDown()
  placeTorch()
  you.moveTo(Point.new(a.x,a.y+1,a.z,a.d))
  turtle.digDown()
  placeTorch()
end
