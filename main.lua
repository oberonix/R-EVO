--globals
WIDTH = 1024
HEIGHT = 768
SHIP_HALF_WIDTH = 16
SHOT_HALF_WIDTH = 3
SHOT_HALF_HEIGHT = 9
ENEMY_HALF_WIDTH = 8
MAX_X = WIDTH / 2 - SHIP_HALF_WIDTH
MAX_Y = HEIGHT / 2 - SHIP_HALF_WIDTH
fullScreen = false
gameOver = false
enemies = {}
shots = {}
frames = 0
lastShot = -100
shooting = false

--setup window
MOAISim.openWindow('ColorBlaster', WIDTH, HEIGHT)
viewport = MOAIViewport.new()
viewport:setSize(WIDTH, HEIGHT)
viewport:setScale(WIDTH, HEIGHT)
local color = MOAIColor.new()
color:setColor(1, 1, 1, 1)
MOAIGfxDevice.setClearColor(color)

--setup layers
gameLayer = MOAILayer2D.new()
gameLayer:setViewport(viewport)
MOAISim.pushRenderPass(gameLayer)

--setup textures
shipGfx = MOAIGfxQuad2D.new ()
shipGfx:setTexture ( "Assets\\Textures\\Ship.png" )
shipGfx:setRect ( -SHIP_HALF_WIDTH, -SHIP_HALF_WIDTH, SHIP_HALF_WIDTH, SHIP_HALF_WIDTH )
enemyGfx = MOAIGfxQuad2D.new ()
enemyGfx:setTexture ( "Assets\\Textures\\Enemy.png" )
enemyGfx:setRect ( -ENEMY_HALF_WIDTH, -ENEMY_HALF_WIDTH, ENEMY_HALF_WIDTH, ENEMY_HALF_WIDTH )
shotGfx = MOAIGfxQuad2D.new ()
shotGfx:setTexture ( "Assets\\Textures\\Shot.png" )
shotGfx:setRect ( -SHOT_HALF_WIDTH, -SHOT_HALF_HEIGHT, SHOT_HALF_WIDTH, SHOT_HALF_HEIGHT )

function spawnShip ()
    ship = MOAIProp2D.new ()
    ship:setDeck ( shipGfx )
    gameLayer:insertProp ( ship )
    function ship:destroy ()
        gameLayer:removeProp ( self )
        self = nil
    end
end

function spawnShot ()
    local shot = MOAIProp2D.new ()
    shot:setDeck ( shotGfx )
    gameLayer:insertProp ( shot )
    function shot:destroy ()
        gameLayer:removeProp ( self )
        self = nil
    end
    local shipX, shipY = ship:getLoc()
    shot:setLoc(shipX, shipY + SHIP_HALF_WIDTH + SHOT_HALF_HEIGHT)
    table.insert(shots, {
        ["prop"] = shot,
        ["x"] = shipX,
        ["y"] = shipY + 16
    })
end

function spawnEnemy()
    local enemy = MOAIProp2D.new()
    xPos = math.random(-MAX_X, MAX_X)

    enemy:setDeck ( enemyGfx )
    enemy:setLoc(xPos, HEIGHT / 2 - ENEMY_HALF_WIDTH)
    gameLayer:insertProp ( enemy )
    function enemy:destroy ()
        gameLayer:removeProp ( self )
        self = nil
    end

    local r = math.random()
    local g = math.random()
    local b = math.random()
    local a = 1 --math.random(0, 255)
    enemy:setColor(r, g, b)
    table.insert(enemies, {
        ["prop"] = enemy,
        ["color"] = {a, r, g, b },
        ["xSpeed"] = 1,
        ["ySpeed"] = 1,
        ["accuracy"] = math.random(1, 10)
    })
end

function updateShots()
    --checkCollisions
    for i, s in ipairs(shots) do
        x, y = s["prop"]:getLoc()
        if y > MAX_Y + 16 then
            table.remove(shots, i)
            gameLayer:removeProp(s["prop"])
        else
            s["prop"]:setLoc(x, y + 16)
        end
    end
    if frames - lastShot > 5 and shooting then
        spawnShot()
        lastShot = frames
    end
end

function updateEnemies()
    --checkCollisions
    shipX, shipY = ship:getLoc()
    for i, e in ipairs(enemies) do
        moveEnemy(e, shipX, shipY)
    end
end

function updateCollisions()
    for i, e in ipairs(enemies) do
        for j, s in ipairs(shots) do
            x, y = s["prop"]:getLoc()
            locX, locY = e["prop"]:getLoc()
            if math.abs(x - locX) < SHOT_HALF_WIDTH + ENEMY_HALF_WIDTH and math.abs(y - locY) < SHOT_HALF_HEIGHT + ENEMY_HALF_WIDTH then
                table.remove(shots, j)
                gameLayer:removeProp(s["prop"])
                table.remove(enemies, i)
                gameLayer:removeProp(e["prop"])
            end
        end
    end
end

function moveEnemy(e, shipX, shipY)
    diceRoll = math.random(0, 100)
    diceRoll2 = math.random(0, 100)
    --get dist
    --get angle
    locX, locY = e["prop"]:getLoc()
    xMove = e["xSpeed"]
    yMove = e["ySpeed"]
    accuracy = e["accuracy"]

    if diceRoll % 2 == 1 then
        xMove = -xMove
    end
    if diceRoll2 % 2 == 1 then
        yMove = -yMove
    end
    if xMove > 0 and shipX < locX and diceRoll < accuracy then
        xMove = -xMove
    end
    if yMove > 0 and shipY < locY and diceRoll < accuracy then
        yMove = -yMove
    end

    locX = math.max(math.min(locX + xMove, MAX_X), -MAX_X)
    locY = math.max(math.min(locY + yMove, MAX_Y), -MAX_Y)
    e["prop"]:setLoc(locX, locY)
end

function getBoundedMousePosition(x, y)
    mouseX, mouseY = gameLayer:wndToWorld(x, y)
    if mouseX > MAX_X then
        mouseX = MAX_X
    end
    if mouseX < -MAX_X then
        mouseX = -MAX_X
    end
    if mouseY > MAX_Y then
        mouseY = MAX_Y
    end
    if mouseY < -MAX_Y then
        mouseY = -MAX_Y
    end
    return mouseX, mouseY
end

function bindKeyboard()
    if MOAIInputMgr.device.keyboard then
        MOAIInputMgr.device.keyboard:setCallback(
            function(key, down)
                if down then
                    if key == 27 then
                        os.exit()
                    elseif key == 102 then
                        if fullScreen then
                            MOAISim.exitFullscreenMode()
                        else
                            MOAISim.enterFullscreenMode()
                        end
                        fullScreen = not fullScreen
                    end
                    print(key)
                end
            end
        )
    end
end

function bindMouse()
    if MOAIInputMgr.device.pointer then
        MOAIInputMgr.device.pointer:setCallback(
            function(x, y)
                ship:setLoc(getBoundedMousePosition(x, y))
            end
        )
        MOAIInputMgr.device.mouseLeft:setCallback(
            function(down)
                if down then
                    shooting = true
                else
                    shooting = false
                end
            end
        )
    end
end

bindKeyboard()
bindMouse()
spawnShip()
for i = 0, 100 do
    spawnEnemy()
end

mainThread = MOAIThread.new ()
mainThread:run (
    function ()
        while not gameOver do
            coroutine.yield ()
            frames = frames + 1
            updateEnemies()
            updateShots()
            updateCollisions()
        end
    end
)