tween = require "tween"

tsize = 200 -- tile width, height is half that
t2 = tsize / 2
t4 = tsize / 4

R = function (n)
  return math.random(0, n)
end

function love.load()

  love.window.setMode(1024, 600, {resizable=false, vsync=true, minwidth=400, minheight=300})
  love.graphics.setNewFont(50)
  frame = 0
  wait = 0
  turn = 'player'
  Actors = {}
  Enemies = {}
  deaths = 0
  health = 0

  grid = {}

  glowShader = love.graphics.newShader [[ 
    vec4 effect (vec4 color, Image texture, vec2 coords, vec2 screen_coords) {

      float maxalpha = -2;
      float minalpha = 2;
      int size = 3;
      vec4 cpix;
      int ii; int jj;
      for (ii = -size; ii < size; ii++){
        for (jj = -size; jj < size; jj++){
          cpix = Texel(texture, vec2(coords[0]+ii, coords[1]+jj));
          if (cpix[3] < minalpha) minalpha = cpix[3];
          if (cpix[3] > maxalpha) maxalpha = cpix[3];
        }
      }
      if (minalpha == 0.0 && maxalpha > 0.0) return vec4(1.0, 1.0, 1.0, 1.0); 
      cpix = Texel(texture, coords);
      return cpix;
    }
  ]]

  shadowShader = love.graphics.newShader [[
    vec4 effect (vec4 color, Image texture, vec2 coords, vec2 screen_coords){
      vec4 cpix = Texel(texture, coords);
      return vec4(0.0, 0.0, 0.0, cpix[3]);
    }
  ]]

  jslancient = love.graphics.newFont('jancient.ttf', 300)
  jslancientsmall = love.graphics.newFont('jancient.ttf', 50)

  sounds = {
    smack = love.audio.newSource('sounds/smack.wav'), 
    redslime = love.audio.newSource('sounds/slime attack.wav'), 
    pinkslime = love.audio.newSource('sounds/slime attack.wav'), 
    greenslime = love.audio.newSource('sounds/slime attack.wav'), 
    yellowslime = love.audio.newSource('sounds/slime attack.wav'), 
    heal = love.audio.newSource('sounds/recover health.wav'),
    pickup = love.audio.newSource('sounds/pick up item.wav')
  }

  theme = love.audio.newSource('theme.wav')
  theme:setLooping(true)
  theme:play()

  for xx = 1, 8 do
    grid[xx] = {}
    for yy = 1, 8 do
      grid[xx][yy] = 1 + (yy % 2)
    end
  end

  dirs = {
    {x=-1, y=0},
    {x=1, y=0},
    {x=0, y=-1},
    {x=0, y=1}}
  --tiles = love.graphics.newImage('tileset_desert.png')
  --sprite1 = love.graphics.newQuad(0, 0, tsize, tsize / 2, tiles:getDimensions())
  --sprite2 = love.graphics.newQuad(0, tsize / 2, tsize, tsize / 2, tiles:getDimensions())

  dungeon = love.graphics.newImage('maps/dungeon.png')
  forest = love.graphics.newImage('maps/forest.png')
  swordroom = love.graphics.newImage('maps/sword-room.png')
  waterroom = love.graphics.newImage('maps/waterroom.png')
  bgs = {dungeon, forest, swordroom, waterroom}
  white = {0xff, 0xff, 0xff}
  black = {0, 0, 0}
  bgcolors = {white, white, white, white}

  bgi = 1

  -- monsters
  monsters = {
    --dragon = make_sprite('monsters/dragon1.png',648,1),
    --chimera = make_sprite('monsters/chimera.png',648,1),
    mimic = make_sprite('monsters/mimicclip.png',648,1),
    witch = make_sprite('monsters/pwitch_1.png',648,1),
    skeli1 = make_sprite('monsters/skeli1shadow.png',648,1),
    skeli2 = make_sprite('monsters/skeli2shadow.png',648,1),
    redslime = make_sprite('monsters/slime1clip.png',648,1),
    pinkslime = make_sprite('monsters/slime2.png',648,1),
    greenslime = make_sprite('monsters/slime3.png',648,1),
    yellowslime = make_sprite('monsters/slime4.png',648,1),
    ghost1 = make_sprite('monsters/ghost1.png',648,1),
    ghost2 = make_sprite('monsters/ghost2.png',648,1),
    were = make_sprite('monsters/were.png',648,1)
  }

  blocks = {
   make_sprite('monsters/rocks/rock1.png',648,1),
   make_sprite('monsters/rocks/rock2.png',648,1),
   make_sprite('monsters/rocks/rock3.png',648,1),
   make_sprite('monsters/rocks/rock4.png',648,1),
  }

  knight_stand = make_sprite('knight-stand.png', 540, 5)
  knight_attack = make_sprite('knight-attack.png', 540, 5)

  items = love.graphics.newImage('grid-items.png')
  iqs = {w = 368, h = 360}
  itemqs = {
    slimemeatgreen = love.graphics.newQuad(iqs.w * 0, iqs.h * 0, iqs.w, iqs.h, items:getDimensions()),
    slimemeatpink = love.graphics.newQuad(iqs.w * 1, iqs.h * 0, iqs.w, iqs.h, items:getDimensions()),
    slimemeatwhite = love.graphics.newQuad(iqs.w * 2, iqs.h * 0, iqs.w, iqs.h, items:getDimensions()),
    slimemeatred = love.graphics.newQuad(iqs.w * 3, iqs.h * 0, iqs.w, iqs.h, items:getDimensions()),
    slimeeyegreen = love.graphics.newQuad(iqs.w * 4, iqs.h * 0, iqs.w, iqs.h, items:getDimensions()),
    slimeeyepink = love.graphics.newQuad(iqs.w * 5, iqs.h * 0, iqs.w, iqs.h, items:getDimensions()),
    slimeeyewhite = love.graphics.newQuad(iqs.w * 0, iqs.h * 1, iqs.w, iqs.h, items:getDimensions()),
    slimeeyered = love.graphics.newQuad(iqs.w * 1, iqs.h * 1, iqs.w, iqs.h, items:getDimensions()),
    mask = love.graphics.newQuad(iqs.w * 2, iqs.h * 1, iqs.w, iqs.h, items:getDimensions()),
    scythe = love.graphics.newQuad(iqs.w * 3, iqs.h * 1, iqs.w, iqs.h, items:getDimensions()),
    map = love.graphics.newQuad(iqs.w * 4, iqs.h * 1, iqs.w, iqs.h, items:getDimensions()),
    lantern = love.graphics.newQuad(iqs.w * 5, iqs.h * 1, iqs.w, iqs.h, items:getDimensions()),
    whitebone = love.graphics.newQuad(iqs.w * 0, iqs.h * 2, iqs.w, iqs.h, items:getDimensions()),
    redbone = love.graphics.newQuad(iqs.w * 1, iqs.h * 2, iqs.w, iqs.h, items:getDimensions()),
    claw = love.graphics.newQuad(iqs.w * 2, iqs.h * 2, iqs.w, iqs.h, items:getDimensions()),
    snake = love.graphics.newQuad(iqs.w * 3, iqs.h * 2, iqs.w, iqs.h, items:getDimensions()),
    wisp = love.graphics.newQuad(iqs.w * 4, iqs.h * 2, iqs.w, iqs.h, items:getDimensions()),
    sword = love.graphics.newQuad(iqs.w * 5, iqs.h * 2, iqs.w, iqs.h, items:getDimensions()),
    chest = love.graphics.newQuad(iqs.w * 0, iqs.h * 3, iqs.w, iqs.h, items:getDimensions()),
    key = love.graphics.newQuad(iqs.w * 1, iqs.h * 3, iqs.w, iqs.h, items:getDimensions()),
    meat = love.graphics.newQuad(iqs.w * 2, iqs.h * 3, iqs.w, iqs.h, items:getDimensions()),
    chicken = love.graphics.newQuad(iqs.w * 3, iqs.h * 3, iqs.w, iqs.h, items:getDimensions()),
    wing = love.graphics.newQuad(iqs.w * 4, iqs.h * 3, iqs.w, iqs.h, items:getDimensions()),
    bone = love.graphics.newQuad(iqs.w * 5, iqs.h * 3, iqs.w, iqs.h, items:getDimensions()),
    cup = love.graphics.newQuad(iqs.w * 0, iqs.h * 4, iqs.w, iqs.h, items:getDimensions()),
    bottle = love.graphics.newQuad(iqs.w * 1, iqs.h * 4, iqs.w, iqs.h, items:getDimensions()),
  }

  blank = {}
  gray = {0xcc, 0xcc, 0xcc}
  slightlydifferentgray = {0xbb, 0xdd, 0xbb}
  red = {0xcc, 0x66, 0x66}
  pink = {0xff, 0xcc, 0xcc}
  purple = {0xff, 0xcc, 0xff}
  yellow = {0xff, 0xff, 0x66}
  orange = {0xff, 0xcc, 0x66}
  green = {0x66, 0xff, 0x66}
  lime  = {0xcc, 0xff, 0xcc}
  biotables = {
    redslime = { blank, blank, gray, red, blank, blank, gray, pink },
    greenslime = { blank, blank, gray, green, gray, lime },
    pinkslime = { blank, purple, gray, pink},
    yellowslime = { blank, blank, blank, blank, gray, yellow, gray, orange  },
    ghost1 = { blank, blank, purple, blank, pink },
    ghost2 = { blank, blank, orange, blank, red  },
    skeli1 = { blank, blank, gray, blank, blank, blank, slightlydifferentgray },
    skeli2 = { blank, blank, red, purple, red },
    witch = { gray, gray, gray, blank, orange, purple, red  },
    mimic = { gray, gray, blank, gray, lime, green, lime  },
  }

  lootlookup = { }
  lootlookup.redslime = {}
  lootlookup.redslime[red] = 'meat'
  lootlookup.redslime[pink] = 'orb'
  lootlookup.greenslime = {}
  lootlookup.greenslime[green] = 'orb'
  lootlookup.greenslime[lime] = 'meat'
  lootlookup.pinkslime = {}
  lootlookup.pinkslime[pink] = 'orb'
  lootlookup.pinkslime[purple] = 'meat'
  lootlookup.yellowslime = {}
  lootlookup.yellowslime[yellow] = 'orb'
  lootlookup.yellowslime[orange] = 'meat'
  lootlookup.ghost1 = {}
  lootlookup.ghost1[purple] = 'scythe'
  lootlookup.ghost2 = {}
  lootlookup.ghost2[red] = 'scythe'
  lootlookup.skeli1 = {}
  lootlookup.skeli1[gray] = 'bone'
  lootlookup.skeli1[slightlydifferentgray] = 'wing'
  lootlookup.skeli2 = {}
  lootlookup.skeli2[red] = 'bone'
  lootlookup.skeli2[purple] = 'wing'
  lootlookup.witch = {}
  lootlookup.witch[purple] = 'lantern'
  lootlookup.mimic = {}
  lootlookup.mimic[green] = 'chest'

  loot = {} -- this will save what the player has found
  freshloot = {} -- lot gotten this round

  healthbanner = {
    love.graphics.newImage('ui/hearts0.png'),
    love.graphics.newImage('ui/hearts1.png'),
    love.graphics.newImage('ui/hearts2.png'),
    love.graphics.newImage('ui/hearts3.png'),
    love.graphics.newImage('ui/hearts4.png'),
    love.graphics.newImage('ui/hearts5.png')
  }

  scroll = {
    {
      name = 'pinkslime',
      none = love.graphics.newImage('inv/slimes/pink/slime2_0%.png'),
      orb = love.graphics.newImage('inv/slimes/pink/slime2_orb.png'),
      meat = love.graphics.newImage('inv/slimes/pink/slime2_meat.png'),
      both = love.graphics.newImage('inv/slimes/pink/slime2_100%.png')
    },
    {
      name = 'greenslime',
      none = love.graphics.newImage('inv/slimes/green/slime3_0%.png'),
      orb = love.graphics.newImage('inv/slimes/green/slime3_invorb.png'),
      meat = love.graphics.newImage('inv/slimes/green/slime3_meat.png'),
      both = love.graphics.newImage('inv/slimes/green/slime3_100%.png')
    },
    {
      name = 'yellowslime',
      none = love.graphics.newImage('inv/slimes/yellow/slime4_0%.png'),
      orb = love.graphics.newImage('inv/slimes/yellow/slime 4_orb.png'),
      meat = love.graphics.newImage('inv/slimes/yellow/slime4_meat.png'),
      both = love.graphics.newImage('inv/slimes/yellow/slime 4_100%.png')
    },
    {
      name = 'redslime',
      none = love.graphics.newImage('inv/slimes/red/slime_inv_none.png'),
      orb = love.graphics.newImage('inv/slimes/red/slime_invorb.png'),
      meat = love.graphics.newImage('inv/slimes/red/slime_inv_meat.png'),
      both = love.graphics.newImage('inv/slimes/red/slime 100%.png')
    },
    {
      name = 'skeli1',
      none = love.graphics.newImage('inv/skeli 1/skeli 0%.png'),
      wing = love.graphics.newImage('inv/skeli 1/skeli wing.png'),
      bone = love.graphics.newImage('inv/skeli 1/skeli bone.png'),
      both = love.graphics.newImage('inv/skeli 1/skeli 100%.png')
    },
    {
      name = 'skeli2',
      none = love.graphics.newImage('inv/skeli 2/skeli2_0%.png'),
      wing = love.graphics.newImage('inv/skeli 2/skeli2_wing.png'),
      bone = love.graphics.newImage('inv/skeli 2/skeli2_bone.png'),
      both = love.graphics.newImage('inv/skeli 2/skeli2_100%.png')
    },
    {
      name = 'ghost1',
      none = love.graphics.newImage('inv/ghost 1/ghost 2 0%.png'),
      all = love.graphics.newImage('inv/ghost 1/ghost 2 100%.png')
    },
    {
      name = 'ghost2',
      none = love.graphics.newImage('inv/ghost 2/ghost2_0%.png'),
      all = love.graphics.newImage('inv/ghost 2/ghost2_100%.png')
    },
    {
      name = 'mimic',
      none = love.graphics.newImage('inv/mimic/mimic 0%.png'),
      all = love.graphics.newImage('inv/mimic/mimic_100%.png')
    },
    {
      name = 'witch',
      none = love.graphics.newImage('inv/witch/pitch_0%.png'),
      all = love.graphics.newImage('inv/witch/pwitch_100%.png')
    },

  }
  scrolli = 1

  scale = 0.75
  fbase = {x= 200 + love.graphics.getWidth() / (scale * 4), y= 80 + love.graphics.getHeight()/(scale*4)} 
  pbase = {x=fbase.x, y=fbase.y}
  mbase = {x=fbase.x, y=fbase.y}
  bbase = {x=fbase.x - t2 - 20, y=fbase.y}
  --player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
  --player.health = 3
  level = 0
end

function level_name(bgi)
  local fronts = {"Fearsome", "Spooky", "Wretched", "Moist", "Fragrant", "Salty", "Haunted", "Sticky", "Piffle's"}
  local locations = {
    {"Dungeon", "Prison", "Keep", "Chamber", "Cell"},
    {"Forest", "Wood", "Wilds", "Meadow"},
    {"Amory", "Arena", "Torture Chamber", "Stash"},
    {"Arctic", "Tundra", "Frozen Waste"},
  }
  local backs = {"Doom", "Despair", "Tedium", "Stickiness", "Dyspepsia"}
  --return table.concat({pick(fronts), pick(locations[bgi]), 'of', pick(backs)}, ' ')
  return "Level " .. level
end

function lootcount()
  local ii = 0
  for key,val in pairs(loot) do
    ii = ii + 1
  end
  return ii
end

levels = {
  function () 
    bgi = 1 
    scrolli = 1
    player = make_actor('player', pbase, knight_stand, knight_attack, 1, 2)
    player.sound = sounds.smack
    health = math.min(health + 1, 5)
    make_enemy('pinkslime', 0, 0) 
    make_enemy('pinkslime', 3, 3) 
    make_enemy('pinkslime', 3, 0) 
    make_block(1,1)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 1 
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    health = math.min(health + 1, 5)
    scrolli = 2
    make_enemy('greenslime', 0, 0) 
    make_enemy('greenslime', 1, 1) 
    make_enemy('greenslime', 3, 1) 
    draw_title(level_name(level))
  end,
  function () 
    bgi = 1 -- dungeon
    scrolli = 3
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('yellowslime', 2, 1) 
    make_enemy('greenslime', 1, 1) 
    make_enemy('greenslime', 2, 2) 
    draw_title(level_name(level))
  end,
  function () 
    bgi = 2 -- woods 
    scrolli = 3
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('yellowslime', 3, 1) 
    make_enemy('yellowslime', 3, 2) 
    make_enemy('greenslime', 3, 3) 
    make_block(1,2)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 2 -- woods 
    scrolli = 4 
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('yellowslime', 2, 0) 
    make_enemy('pinkslime', 2, 1) 
    make_enemy('redslime', 3, 1) 
    make_block(1,0)
    make_block(3,3)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 2 -- woods 
    scrolli = 4 
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 2)
    player.sound = sounds.smack
    make_enemy('redslime', 3, 0) 
    make_enemy('redslime', 2, 0) 
    make_enemy('redslime', 3, 1) 
    make_block(1,0)
    make_block(3,3)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 3
    scrolli = 5
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 2)
    player.sound = sounds.smack
    make_enemy('skeli2', 3, 2) 
    make_enemy('skeli1', 2, 0) 
    make_enemy('skeli1', 3, 1) 
    make_block(2,1)
    make_block(1,3)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 3 
    scrolli = 7
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('skeli2', 3, 2) 
    make_enemy('ghost1', 2, 0) 
    make_enemy('ghost1', 3, 1) 
    make_block(2,1)
    make_block(0,2)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 3 
    scrolli = 8
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('skeli2', 3, 2) 
    make_enemy('ghost1', 3, 3) 
    make_enemy('ghost2', 2, 0) 
    make_enemy('ghost2', 3, 1) 
    make_block(1,1)
    make_block(2,2)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 4 
    scrolli = 6
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('skeli2', 3, 2) 
    make_enemy('skeli2', 2, 0) 
    make_enemy('mimic', 3, 1) 
    make_block(0,0)
    make_block(2,1)
    make_block(3,3)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 4 
    scrolli = 9
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('ghost2', 3, 2) 
    make_enemy('mimic', 2, 0) 
    make_enemy('witch', 3, 1) 
    make_block(2,1)
    make_block(1,3)
    draw_title(level_name(level))
  end,
  function () 
    bgi = 4 
    scrolli = 10
    player = make_actor('player', pbase, knight_stand, knight_attack, 0, 3)
    player.sound = sounds.smack
    make_enemy('witch', 3, 2) 
    make_enemy('witch', 2, 0) 
    make_enemy('witch', 3, 1) 
    make_block(1,0)
    make_block(1,1)
    draw_title(level_name(level))
  end
}

function pick(ll)
  return ll[math.random(#ll)]
end

function make_search_node(x, y, dir, depth)
  return {x=x, y=y, d=dir, depth=depth}
end

function make_grid(x,y,init)
  local g = {}
  for ii=1,x do
    g[ii] = {}
    for jj = 1,y do
      g[ii][jj] = init
    end
  end
  return g
end

function draw_title(words)
  title = {x=3000, y = 300, words = words}
  local ltween = tween.new(4, title, {x=-3000}, 'outInCubic')
  titletween = ltween
  return ltween
end

function gameover_title()
  title = {x=1500, y = 300, words = "You Died"}
  local ltween = tween.new(2, title, {x=30}, 'outCubic')
  titletween = ltween
  deaths = deaths + 1
  gameover = true
  return ltween
end

function win()
  title = {x=1500, y = 300, words = "You Win!"}
  local ltween = tween.new(2, title, {x=30}, 'outCubic')
  titletween = ltween
  gameover = true
  return ltween
end


function on_map(node)
  return node.x >= 0 and node.y >= 0 and node.x < 4 and node.y < 4
end

function actor_at(x,y)
  for ii,aa in ipairs(Actors) do
    if aa.x == x and aa.y == y then
      return aa
    end
  end
  return nil
end

function handle_facing(actor, dir)
  if dir.x < 0 or dir.y > 0 then
    actor.f = -1
  else
    actor.f = 1
  end
end

function step(actor, dir)
  if actor.willdie then
    return false
  end
  local dest = {
    x = actor.x + dir.x,
    y = actor.y + dir.y
  }
  if not on_map(dest) then return false end
  local ee = actor_at(dest.x, dest.y)
  if ee then
    if ee.team == actor.team then
      return false
    elseif ee.team == 'neutral' then
      return false
    elseif ee.team == 'player' then
      handle_facing(actor, dir)
      attack(actor, player)
      if health == 0 then
        gameover_title()
      end
      return true
    elseif ee.team == 'enemy' then
      -- todo check health etc.
      handle_facing(actor, dir)
      attack(actor, ee)
      return true
    end
  end

  handle_facing(actor, dir)

  actor.x = dest.x
  actor.y = dest.y
  return true
end

function bfs(actor)
  -- get direction to move to find nearest enemy
  local q = {}
  local visited = make_grid(4, 4, false)
  local sn = make_search_node
  local a = actor
  table.insert(q, sn(a.x-1,a.y,1,0))
  table.insert(q, sn(a.x+1,a.y,2,0))
  table.insert(q, sn(a.x,a.y-1,3,0))
  table.insert(q, sn(a.x,a.y+1,4,0))

  while true do
    local cn = q[1]
    if cn == nil then break end
    table.remove(q, 1)
    if (on_map(cn) and not visited[cn.x+1][cn.y+1]) then
      visited[cn.x+1][cn.y+1] = true
      local ee = actor_at(cn.x, cn.y)
      if ee then
        if ee.team ~= 'neutral' and ee.team ~= a.team then
          -- found a route to enemy, take a step
          return cn.d
        end
      else
        -- keep looking
        table.insert(q, sn(cn.x-1,cn.y,cn.d,cn.depth+1))
        table.insert(q, sn(cn.x+1,cn.y,cn.d,cn.depth+1))
        table.insert(q, sn(cn.x,cn.y-1,cn.d,cn.depth+1))
        table.insert(q, sn(cn.x,cn.y+1,cn.d,cn.depth+1))
      end
    end
  end
  -- no route to enemy, wait or do something else
  return false 
end

function make_sprite(imgpath, size, frames)
  local s = {}
  s.img = love.graphics.newImage(imgpath)
  s.quads = {}
  s.size = size
  s.frames = frames
  for ii = 1, frames do
    table.insert(s.quads, love.graphics.newQuad((ii - 1) * size, 0, size, size, s.img:getDimensions()))
  end
  return s
end

function shadow(source)
  local imgdata = source:getData()
  imgdata:mapPixel(function (x, y, r, g, b, a)
    --local avg = (r + b + g) / 3
    --return avg, avg, avg, a
    r = math.min(r * 1.5, 255)
    g = math.min(g * 1.5, 255)
    b = math.min(b * 1.5, 255)
    return r, g, b, a
  end)
  return love.graphics.newImage(imgdata)
end

function sepia(source)
  -- see here: https://alastaira.wordpress.com/2013/12/02/sepia-shader/
  local imgdata = source:getData()
  imgdata:mapPixel(function (x, y, r, g, b, a)
    nr = r * 0.393 + g * 0.769 + b * 0.189
    ng = r * 0.349 + g * 0.686 + b * 0.168
    nb = r * 0.272 + g * 0.534 + b * 0.131
    return nr, ng, nb, a
  end)
  return love.graphics.newImage(imgdata)
end

function copy_image_data(imgdata)
  local out = love.image.newImageData(imgdata:getWidth(), imgdata:getHeight())
  out:paste(imgdata, 0, 0, 0, 0, imgdata:getWidth(), imgdata:getHeight())
  return out
end

function make_block(x, y)
  local s = pick(blocks)
  return make_actor('neutral', bbase, s, s, x, y)
end

function make_actor(team, base, sprite, attack_sprite, x, y)
  -- copy sprite so we can modify it
  local ns = sprite
  ns.img = love.graphics.newImage(copy_image_data(sprite.img:getData()))

  local a = {
    team=team,
    base=base,
    x=x,
    y=y,
    s=sprite,
    ns=ns,
    as=attack_sprite,
    f=1,
    attacking=0,
    baseframe=0,
    health=1,
    bio = {}
  }
  table.insert(Actors, a)
  zsort()
  return a
end

function draw_actor(actor, frame)
  local  _, _, cx, cy = actor.s.quads[1]:getViewport()
  love.graphics.draw(actor.s.img, aframe(actor.s.quads, frame - actor.baseframe, 5), 
    actor.base.x + ( (actor.x - actor.y) * t2 ), 
    12 + actor.base.y - t4 + ( (actor.x + actor.y) * t4),
    0, actor.f, 1, cx/2, cy/2)
end

function love.update(dt)
  frame = frame + 1

  if level > 0 and #Enemies == 0 and not gameover then
    return next_level()
  end

  if titletween then 
    titletween:update(dt)
    if titletween.complete then
      --titletween = nil
      --title = nil
    end
  end

  for ii,actor in ipairs(Actors) do
    if actor.attacking > 0 then
      actor.s = actor.as
      actor.attacking = actor.attacking - 1
      if actor.attacking == 5 then
        screenshake = 10
        if actor.sound then
          actor.sound:play()
        end
      end
      if actor.attacking < 1 then
        actor.s = actor.ns
      end
    end

    if actor.willdie and actor.willdie > 0 then
      actor.willdie = actor.willdie - 1
      if actor.willdie < 1 then
        die(actor)
      end
    end
  end

  if wait > 0 then
    wait = wait - 1
  elseif turn == 'player' then
    -- handled in keypress 
  else -- enemy turn
    for ii, enemy in ipairs(Enemies) do
      move_enemy(enemy)
    end
    zsort()
    wait = 10
    turn = 'player'
  end
end

function move_enemy(e)
  if e.health <= 0 then return end
  local d = bfs(e)
  if d then
    step(e, dirs[d])
  end
  e.biooffset = 1 + (e.biooffset % #e.biotable)
  e.bio = e.biotable[e.biooffset]
end

function make_enemy(name, x, y)
  local e = make_actor('enemy', mbase, monsters[name], monsters[name], x, y)
  e.f = -1 -- start facing left
  table.insert(Enemies, e)
  e.sound = sounds[name]
  e.biotable = biotables[name]
  e.biooffset = math.random(#e.biotable)
  e.name = name
  return e
end

function aframe(quads, frame, delay)
  -- get quad given current frame
  local count = #quads
  local cframe = frame % (delay * count)
  return quads[ 1 + math.floor( cframe / delay ) ]
end

function attack(a, b)
  local duration = 25
  a.attacking = duration
  a.baseframe = frame
  b.health = b.health - 1
  if b == player then
    health = health - 1
  end
  if b ~= player and b.health <= 0 then
    b.willdie = duration
  end
  wait = duration
end

function next_level()
  level = level + 1
  health = math.min(health + 1, 5)

  for key, val in pairs(freshloot) do
    loot[key] = true
  end
  freshloot = {}

  if level > #levels then
    return win()
  end
  if level == 1 then
    gameover = false
    loot = {}
    health = 5
  end
  Actors = {}
  Enemies = {}
  levels[level]()
end

function love.keypressed(key)
  if level == 0 then
    if key == "z" then
      next_level()
    end
    return false
  end

  if gameover and key == "z" then
    -- todo reset inventory
    level = 0 -- too hard!
    --gameover = false
    --freshloot = {}
    --level = level - 1
    next_level()
  end

  if key == "]" then
    scrolli = 1 + (scrolli % #scroll)
  end
  if key == "[" then
    scrolli = scrolli - 1
    if scrolli == 0 then scrolli = #scroll end
  end

  --[[
  --- wasd debug
  local inc = 20
  if (key == "a")  then fbase.x = fbase.x - inc end
  if (key == "d") then fbase.x = fbase.x + inc end
  if (key == "w")    then fbase.y = fbase.y - inc end
  if (key == "s")  then fbase.y = fbase.y + inc end

  
  if key == "c" then
    titletween = draw_title('Level 1')
  end

  if key == "z" and not player.shadow then
    player.s.img = shadow(player.s.img)
    player.shadow = true
  end

  if key == "x"  and player.shadow then
    player.s.img = love.graphics.newImage(copy_image_data(player.ns.img))
    player.shadow = false
  end

  if key == "b" then
    bgi = 1 + (bgi % #bgs)
  end
  --]]

  if turn == 'player' and not gameover then
    local dir = nil
    if (key == "left")  then dir = 1 end
    if (key == "right") then dir = 2 end
    if (key == "up")    then dir = 3 end
    if (key == "down")  then dir = 4 end

    local stepped = nil
    if dir then 
      stepped = step(player, dirs[dir])
    end

    if stepped then
      wait = 10
      zsort()
      turn = 'enemy'
    end
  end

  local edge = 3
  if player.x < 0 then player.x = 0 end
  if player.y < 0 then player.y = 0 end
  if player.x > edge then player.x = edge end
  if player.y > edge then player.y = edge end
end

function getindex(tt, el)
  for ii, xx in ipairs(tt) do
    if xx == el then return ii end
  end
end

function die(a)
  table.remove(Actors, getindex(Actors, a))
  if a.team == 'enemy' then
    if lootlookup[a.name][a.bio] then
      loot[a.name .. '.' .. lootlookup[a.name][a.bio]] = true
      sounds.pickup:play()
    end
    table.remove(Enemies, getindex(Enemies, a))
  end
end

function zsort()
  -- get all actors sorted by z order for drawing
  table.sort(Actors, function (a, b)
    return a.x + a.y < b.x + b.y
  end)
end

function drawscroll()
  local cs = scroll[scrolli]
  local name = cs.name
  local orb = loot[name .. '.orb'] or freshloot[name .. '.orb']
  local meat = loot[name .. '.meat'] or freshloot[name .. '.meat']
  local bone = loot[name .. '.bone'] or freshloot[name .. '.bone']
  local wing = loot[name .. '.wing'] or freshloot[name .. '.wing']
  local lantern = loot[name .. '.lantern'] or freshloot[name .. '.lantern']
  local scythe = loot[name .. '.scythe'] or freshloot[name .. '.scythe']
  if meat and orb then return cs.both end
  if wing and bone then return cs.both end
  if scythe then return cs.all end
  if lantern then return cs.all end

  if orb and (not meat) then return cs.orb end
  if meat and (not orb) then return cs.orb end
  if bone and not wing then return cs.bone end
  if wing and not bone then return cs.bone end
  return cs.none --default
end

function love.draw()
  love.graphics.scale(scale)
  love.graphics.setColor(white)


  local oldfont = love.graphics.getFont()
  if level == 0 then
    love.graphics.setFont(jslancient)
    love.graphics.print('Isorogue', 40, 300)
    love.graphics.setFont(jslancientsmall)
    love.graphics.print("Push Z to begin", 60, 590)
    love.graphics.setFont(oldfont)
    return
  end

  if screenshake and screenshake > 0 then
    love.graphics.translate(20 - R(40), 20 - R(40))
    screenshake = screenshake - 1
  end


  love.graphics.push()
  love.graphics.draw(bgs[bgi], 
    fbase.x, 
    200 + love.graphics.getHeight()/(scale * 2), 
    0, 1, 1, bgs[bgi]:getWidth()/2, bgs[bgi]:getHeight()/2)
  love.graphics.pop()

  -- draw grid
  for xx = 1, 4 do
    for yy = 1, 4 do
      local fp = {x = fbase.x - t2 + ((xx - yy) * t2), y = fbase.y - t4 + ((xx + yy) * t4) }
        love.graphics.setColor(bgcolors[bgi])
      love.graphics.line(fp.x, fp.y, fp.x + t2, fp.y + t4, fp.x + tsize, fp.y, fp.x + t2, fp.y - t4, fp.x, fp.y)
      local mon = actor_at(xx-1, yy-1)
      if mon and mon.bio and #mon.bio == 3 then
        local r, g, b = unpack(mon.bio)
        love.graphics.setColor(r, g, b, math.sin(frame/10) * 255)
        love.graphics.polygon('fill', fp.x, fp.y, fp.x + t2, fp.y + t4, fp.x + tsize, fp.y, fp.x + t2, fp.y - t4, fp.x, fp.y)
      end
    end
  end
  love.graphics.setColor(white)

  for ii, actor in ipairs(Actors) do
    draw_actor(actor, frame)
  end

  love.graphics.draw(healthbanner[health + 1], 800, 20)
  local cscroll = drawscroll()
  love.graphics.draw(drawscroll(), 780, 100)

  --love.graphics.print("fps: " .. tostring(love.timer.getFPS()), 10, 10)
  --love.graphics.print("health: " .. player.health, 10, 60)
  if title then
    love.graphics.setColor(bgcolors[bgi])
    love.graphics.setFont(jslancient)
    love.graphics.print(title.words, title.x, title.y)
    if titletween and titletween:update(0)  and gameover then
      love.graphics.setFont(jslancientsmall)
      if health <= 0 then
        love.graphics.print("Push Z to retry", 60, 590)
      else
        love.graphics.print("Got " .. lootcount() .. "/16 monster parts", 60, 590)
        if #loot < 16 then
          love.graphics.print("See if you can get them all!", 60, 650)
        else
          love.graphics.print("Wow, you got them all! The secret word is \"poflax\"", 60, 650)
        end
      end
    end

    love.graphics.setFont(oldfont)
 
  end

  love.graphics.setColor(white)
  -- center guides
  -- love.graphics.line(1024,0,1024,2000)
  -- love.graphics.line(0,600,2000,600)
end
