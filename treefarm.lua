args={...} --get arguments, launch program as such "treefarm x y z d"
arglength = table.getn(args)
if arglength==0 then
  ix,iy,iz,id=1,1,1,0 --default starting block
elseif arglength==1 then
  ix,iy,iz,id=tonumber(args[1]),1,1,0
elseif arglength==2 then
  ix,iy,iz,id=tonumber(args[1]),tonumber(args[2]),1,0
elseif arglength==3 then
  ix,iy,iz,id=tonumber(args[1]),tonumber(args[2]),tonumber(args[3]),0
elseif arglength>=4 then
  ix,iy,iz,id=tonumber(args[1]),tonumber(args[2]),tonumber(args[3]),tonumber(args[4])
end

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

INV_MAX=16
FUEL_SLOT=16
SAPLING_REQ=1
SAPLING_SLOT=15
TREE_RAD=1
HARVEST_RAD=1
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
  local T = TREE_SPACING
  local x,y,z,d,i = T,T,1,0,1
  trees[i] = Point.new(x,y,z,d)
  while x<BOUNDS.x.upper do
    while y<BOUNDS.y.upper do
      y=y+T
      trees[i]=Point.new(x,y,z,d)
      i=i+1
    end
    y=T
    x=x+T
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
  if boolBreakBlock==nil then
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

function interimPt(tree) --creates a Point object which is diagonally across from the tree, preventing turtle colliding with trees during MoveTo
  if tree.x<=trees[0].x-1 then return you.pos end
  return Point.new(tree.x-1,tree.y+1,tree.z, you.pos.d)
end

function harvestPt(pt) --creates Point object which is in front of tree facing to lowest block of wood
  return Point.new(pt.x-1,pt.y,pt.z,pt.d)
end

function collect(dest) --collects items from a chest, uses interim points
  local current=you.pos
  you.moveTo(interimPt(you.pos))
  you.moveTo(_dump) --dump while you're at it, remove if issues occur
  you.storeInv()
  you.moveTo(dest)
  turtle.suck()
  you.moveTo(interimPt(current))
  you.moveTo(current)
  print("Collect successful")
end

function deposit(dest) --deposits items to chest, uses interim pts
  local current = you.pos
  --print(current.x.."--"..current.y.."--"..current.z)
  you.moveTo(interimPt(current))
  you.moveTo(dest)
  --print("Deposit: Moved to")
  you.storeInv()
  --print("Moving to current")
  you.moveTo(interimPt(current))
  you.moveTo(current)
  print("Deposit successful")
end

function fuel()
  local selectstate = turtle.getSelectedSlot() --holds slot that turtle had prior to refuelling so turtle may resume after
  turtle.select(FUEL_SLOT)
  while(turtle.getFuelLevel()<turtle.getFuelLimit()) do
    turtle.refuel()
    if turtle.getItemCount(FUEL_SLOT)==0 then
      collect(_fuel)
      if turtle.getItemCount(FUEL_SLOT)==0 then break end --if turtle has tried to collect fuel and still no fuel, end loop
    end
  end
  turtle.select(selectstate)
end

function rowed_square(leng, interval, st, fnc) -- fnc MUST be function, ROWED_SQUARE is a method of covering a 2d surface by weaving in 2 directions
  if leng==1 then                         --leng is total length of weave, interval is side length, e.g. if 5x5 block is to be dug, rowed_square(25,5,turtle.digDown)
    fnc() 
  else
    local tn=st
    for i=1, leng+1 do
      if you.invIsFull() then
        deposit(_dump)
      end
      fnc()
      if (i~=1) and (i % interval==0) then
        you.turn(tn)
        you.move(1)
        fnc()
        you.turn(tn)
        tn = (90*270)/tn --if tn=90 then tn=270 elseif tn=270 then tn=90
      end
      you.move(1)
    end
  end
end

function plant(numb)
  turtle.select(SAPLING_SLOT)
  if (turtle.getItemCount()<SAPLING_REQ) then
    turtle.select(SAPLING_SLOT)
    collect(_saplings)
  end
  you.moveTo(interimPt(trees[numb]))
  you.moveTo(Point.new(trees[numb].x,trees[numb].y,trees[numb].z+1,trees[numb].d))
  rowed_square(SAPLING_REQ, math.sqrt(SAPLING_REQ), you.placeUnder) --assuming sapling planting will always be square
  you.turnTo(2)
  you.move(1)
end

function vacuum(currentTree) -- sucks up saplings in a square immediately around the tree
  you.moveTo(interimPt(trees[currentTree]))
  you.turnTo(trees[currentTree].pos.d)
  turtle.select(SAPLING_SLOT)
  for i=0,3 do
    for e=0,TREE_RAD+1 do
      turtle.suck()
      turtle.move(1)
    end
    you.turn(270)
  end
end

function harvest()
  local detected=false
  for i=0, table.getn(trees)-1 do
    local hascut=false
    local notree=false
    local interim = interimPt(trees[i])
    you.moveTo(interim)
    you.moveTo(harvestPt(trees[i]))
    while not(hascut) and not(notree) do
      if(turtle.detect() or detected==true) then
        while(turtle.detect() or detected==true) do
          if(turtle.detect()) then detected=false end
          if(turtle.detectUp()) then turtle.digUp() end
          you.moveVertical(1)
        end
        you.move(1)
      local evenoddcounter=0
        for e=you.pos.z, trees[i].z+1, -1 do
          local dfRad=HARVEST_RAD-TREE_RAD --distance between harvest point and start of rowed_square()
          if dfRad>0 then
            you.turn(90)
            you.move(dfRad)
            you.turn(90)
            you.move(dfRad)
            you.turnTo(trees[i].d)
          end
          local startTurn=90
          if evenoddcounter%2==0 then startTurn=90 else startTurn=270 end
          rowed_square(math.pow(HARVEST_RAD,2),HARVEST_RAD,startTurn,turtle.digDown)
          evenoddcounter=evenoddcounter+1
          you.moveTo(Point.new(you.pos.x,you.pos.y,you.pos.z-1,trees[i].pos.d)) --move 1 down, digDown
        end
        hascut=true
      else
        you.moveVertical(1)
        if turtle.detect() then
          you.moveVertical(-1)
          detected=true
        else
          notree=true
        end
      end
    end
    select(SAPLING_SLOT)
    if (turtle.getItemCount()>0) and (turtle.getItemDetail().name~="minecraft:sapling") then
      turtle.drop()
    end
    if you.invIsFull() then
      deposit(_dump)
    end
    vacuum(i)
    plant(i)
    if turtle.getFuelLevel()<(3*(you.pos.x+you.pos.y+5)) then
      fuel()
    end
    you.moveTo(interimPt(trees[i]))
  end
end

createTreeArray(5)

--for i=1, table.getn(trees) do
--  plant(i)
--end
--activate this block if planting is yet to happen

while true do
harvest()
end
