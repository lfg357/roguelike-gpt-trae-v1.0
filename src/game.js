(() => {
  "use strict";

  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const menu = document.getElementById("menu");
  const overlay = document.getElementById("overlay");
  const codex = document.getElementById("codex");
  const diskSlots = document.getElementById("diskSlots");
  const inventoryPanel = document.getElementById("inventory");
  const buildText = document.getElementById("buildText");
  const startBtn = document.getElementById("startBtn");
  const closeDisk = document.getElementById("closeDisk");

  const W = canvas.width;
  const H = canvas.height;
  const ARENA = { x: 170, y: 92, w: 900, h: 548 };
  const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
  const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
  const rand = (min, max) => min + Math.random() * (max - min);
  const choice = (arr) => arr[Math.floor(Math.random() * arr.length)];
  const now = () => performance.now();

  const elementColor = {
    none: "#d8d0bf",
    metal: "#d9d9d6",
    wood: "#6fbf88",
    water: "#5d9bc7",
    fire: "#d86b54",
    earth: "#caa869",
  };

  const elementName = {
    none: "无",
    metal: "金",
    wood: "木",
    water: "水",
    fire: "火",
    earth: "土",
  };

  const RELICS = [
    { id: "ink_blade", name: "墨锋", rarity: "白", element: "none", tags: ["锐"], stats: { damage: 0.15 }, desc: "攻击伤害+15%" },
    { id: "swift_step", name: "疾风步", rarity: "白", element: "none", tags: ["迅"], stats: { speed: 0.1 }, desc: "移速+10%" },
    { id: "iron_body", name: "铁骨", rarity: "白", element: "metal", tags: ["厚"], stats: { reduction: 0.1 }, desc: "减伤+10%" },
    { id: "wood_heart", name: "木灵心", rarity: "白", element: "wood", tags: ["吸"], stats: { maxHp: 20 }, desc: "最大HP+20" },
    { id: "water_talisman", name: "水符", rarity: "白", element: "water", tags: ["冻"], stats: { slowChance: 0.1 }, desc: "攻击概率减速" },
    { id: "fire_pearl", name: "火珠", rarity: "白", element: "fire", tags: ["焚"], stats: { burn: 1 }, desc: "攻击附带灼烧" },
    { id: "earth_stone", name: "土魄石", rarity: "白", element: "earth", tags: ["厚"], stats: { reduction: 0.08 }, desc: "减伤+8%" },
    { id: "gold_ring", name: "金芒戒", rarity: "蓝", element: "metal", tags: ["锐", "裂"], stats: { crit: 0.08 }, desc: "暴击率+8%" },
    { id: "spirit_sword", name: "灵剑", rarity: "蓝", element: "metal", tags: ["锐", "焚"], stats: { damage: 0.25 }, desc: "攻击伤害+25%" },
    { id: "jade_pendant", name: "玉珮", rarity: "蓝", element: "wood", tags: ["吸", "魂"], stats: { regen: 1 }, desc: "每秒回复1HP" },
    { id: "black_ink", name: "玄墨", rarity: "蓝", element: "water", tags: ["冻", "蚀"], stats: { range: 0.2 }, desc: "攻击范围+20%" },
    { id: "flame_talisman", name: "烈焰符", rarity: "蓝", element: "fire", tags: ["焚", "裂"], stats: { burnPower: 0.5 }, desc: "燃烧伤害+50%" },
    { id: "mountain_stele", name: "山岳碑", rarity: "紫", element: "earth", tags: ["厚", "障"], stats: { reduction: 0.25, maxHp: 30 }, desc: "减伤+25%，最大HP+30" },
    { id: "five_elements", name: "五行令", rarity: "金", element: "none", tags: ["锐", "吸", "焚", "冻", "厚"], stats: { all: 0.1, resist: 0.2 }, desc: "全属性+10%" },
  ];

  const WEAPONS = [
    { id: "blank", name: "白板铁剑", type: "剑", rate: 1.5, mult: 1, range: 82, desc: "开局武器" },
    { id: "duanshui", name: "断水", type: "剑", rate: 2, mult: 0.7, range: 86, desc: "轻盈快速" },
    { id: "shuangren", name: "霜刃", type: "剑", rate: 1.5, mult: 1, range: 90, desc: "命中减速" },
    { id: "mohong", name: "墨虹", type: "剑", rate: 1.5, mult: 1, range: 100, desc: "第三段突刺更远" },
    { id: "lieshan", name: "裂山", type: "刀", rate: 1, mult: 1.8, range: 108, desc: "重击冲击波" },
    { id: "yinxue", name: "饮血", type: "刀", rate: 1.2, mult: 1.3, range: 98, desc: "攻击回血" },
  ];

  const ENEMY_TYPES = {
    blade: { name: "刀灵", hp: 25, damage: 10, speed: 180, ai: "chase", element: "metal", stone: 4, r: 15 },
    guard: { name: "铜甲", hp: 40, damage: 8, speed: 145, ai: "shielder", element: "metal", stone: 5, r: 18 },
    dart: { name: "镖手", hp: 20, damage: 12, speed: 150, ai: "ranged", element: "metal", stone: 4, r: 14 },
    elite: { name: "金甲将", hp: 105, damage: 16, speed: 178, ai: "charger", element: "metal", stone: 25, r: 21 },
    boss: { name: "金甲将军", hp: 420, damage: 18, speed: 150, ai: "boss", element: "metal", stone: 80, r: 34 },
  };

  const game = {
    state: "menu",
    keys: new Set(),
    mouse: { x: W / 2, y: H / 2, down: false },
    room: null,
    floor: 1,
    roomIndex: 0,
    seed: Math.floor(Math.random() * 999999),
    map: [],
    entities: [],
    projectiles: [],
    particles: [],
    texts: [],
    drops: [],
    slash: null,
    shake: 0,
    shakeTime: 0,
    hitStopUntil: 0,
    msgUntil: 0,
    msg: "",
    diskOpen: false,
    discovered: new Set(),
    lastTime: now(),
    selectedReward: null,
  };

  const player = {
    x: W / 2,
    y: H / 2,
    r: 18,
    hp: 100,
    maxHp: 100,
    baseSpeed: 230,
    speed: 230,
    damage: 10,
    facing: 0,
    combo: 0,
    comboExpire: 0,
    attackCd: 0,
    dodgeCd: 0,
    invuln: 0,
    hurt: 0,
    stones: 0,
    karma: 0,
    weapon: WEAPONS[0],
    inventory: [],
    disk: [null, null, null, null, null],
    stats: {},
    activePatterns: [],
    activeCombos: [],
  };

  function showMessage(text, seconds = 2.2) {
    game.msg = text;
    game.msgUntil = now() + seconds * 1000;
    overlay.textContent = text;
    overlay.classList.remove("hidden");
  }

  function hideMenu() {
    menu.classList.remove("active");
  }

  function startGame() {
    hideMenu();
    Object.assign(player, {
      x: W / 2,
      y: H / 2,
      hp: 100,
      maxHp: 100,
      speed: 230,
      stones: 0,
      karma: 0,
      weapon: WEAPONS[0],
      inventory: [RELICS[0], RELICS[3], RELICS[5]],
      disk: [null, null, null, null, null],
    });
    game.floor = 1;
    game.state = "prep";
    generateMap();
    evaluateBuild();
    showMessage("备战房间：WASD移动，J/鼠标攻击，Space闪避，Tab打开五行盘。按E出发。", 5);
  }

  function generateMap() {
    const cols = 6;
    const rows = 5;
    const cells = [];
    for (let y = 0; y < rows; y += 1) {
      for (let x = 0; x < cols; x += 1) {
        cells.push({ x, y, type: "empty", visited: false, cleared: false, links: [] });
      }
    }
    const at = (x, y) => cells[y * cols + x];
    let y = Math.floor(rows / 2);
    at(0, y).type = "START";
    for (let x = 0; x < cols - 1; x += 1) {
      const cur = at(x, y);
      const ny = clamp(y + choice([-1, 0, 1]), 0, rows - 1);
      const next = at(x + 1, ny);
      cur.links.push(next);
      next.links.push(cur);
      if (next.type === "empty") next.type = x + 1 === cols - 1 ? "BOSS" : "MONSTER";
      y = ny;
    }
    for (let i = 0; i < 9; i += 1) {
      const base = choice(cells.filter((c) => c.type !== "empty" && c.type !== "BOSS"));
      const dirs = [[1, 0], [0, 1], [0, -1], [-1, 0]];
      const [dx, dy] = choice(dirs);
      const nx = clamp(base.x + dx, 0, cols - 1);
      const ny = clamp(base.y + dy, 0, rows - 1);
      const n = at(nx, ny);
      if (n.type === "empty") {
        n.type = Math.random() < 0.12 ? "SHOP" : Math.random() < 0.28 ? "ELITE" : "MONSTER";
        base.links.push(n);
        n.links.push(base);
      }
    }
    cells.filter((c) => c.type !== "empty" && c.type !== "START" && c.type !== "BOSS").forEach((c, i) => {
      if (i === 2) c.type = "SHOP";
      if (i === 5) c.type = "ELITE";
    });
    const start = cells.find((c) => c.type === "START");
    start.visited = true;
    game.map = cells;
    game.room = start;
    enterRoom(start);
  }

  function enterRoom(room) {
    game.room = room;
    room.visited = true;
    game.roomIndex += 1;
    game.entities = [];
    game.projectiles = [];
    game.drops = [];
    player.x = ARENA.x + ARENA.w / 2;
    player.y = ARENA.y + ARENA.h / 2;
    if (room.type === "START") {
      room.cleared = true;
      game.state = game.state === "prep" ? "prep" : "explore";
      showMessage("START房：墨痕未干，前路已经显形。靠近右侧出口按E进入相邻房间。", 3.5);
    } else if (room.type === "SHOP") {
      game.state = "shop";
      showMessage("卦摊：按1购买遗物(35灵石)，按2刷新武器(45灵石)，按E离开。", 4);
    } else {
      game.state = "combat";
      spawnRoom(room.type);
    }
  }

  function spawnRoom(type) {
    const spawn = (kind, x, y) => game.entities.push(makeEnemy(kind, x, y));
    if (type === "BOSS") {
      spawn("boss", W / 2, ARENA.y + 160);
      showMessage("Boss战：金甲将军。闪避前摇，第三段连击能打出破势。", 4);
      return;
    }
    if (type === "ELITE") {
      spawn("elite", W / 2, ARENA.y + 160);
      spawn(choice(["blade", "guard", "dart"]), W / 2 - 160, ARENA.y + 330);
      showMessage("精英房：击败金甲将可保底获得武器。", 3);
      return;
    }
    const count = 2 + Math.floor(Math.random() * 3);
    for (let i = 0; i < count; i += 1) {
      spawn(choice(["blade", "guard", "dart"]), rand(ARENA.x + 90, ARENA.x + ARENA.w - 90), rand(ARENA.y + 90, ARENA.y + ARENA.h - 90));
    }
  }

  function makeEnemy(kind, x, y) {
    const data = ENEMY_TYPES[kind];
    return {
      kind,
      name: data.name,
      x,
      y,
      r: data.r,
      hp: data.hp * (1 + (game.floor - 1) * 0.28),
      maxHp: data.hp * (1 + (game.floor - 1) * 0.28),
      damage: data.damage,
      speed: data.speed,
      ai: data.ai,
      element: data.element,
      stone: data.stone,
      attackCd: rand(0.4, 1.2),
      hurt: 0,
      slow: 0,
      burn: 0,
      burnTick: 0,
      charge: 0,
    };
  }

  function tryMoveRoom() {
    if (game.state === "prep") {
      game.state = "explore";
      enterRoom(game.room);
      return;
    }
    if (!game.room.cleared && game.room.type !== "START" && game.room.type !== "SHOP") {
      showMessage("房门被墨锁封住，清完敌人才可离开。", 1.4);
      return;
    }
    const options = game.room.links.filter((r) => r.type !== "empty" && !r.cleared);
    if (!options.length) {
      const fallback = game.map.find((r) => r.type !== "empty" && !r.cleared);
      if (!fallback) {
        showMessage("本层已无可探索房间。", 1.8);
        return;
      }
      showMessage("墨径改道，送你前往尚未清理的节点。", 1.6);
      enterRoom(fallback);
      return;
    }
    const boss = options.find((r) => r.type === "BOSS");
    enterRoom(boss || options[0]);
  }

  function attack() {
    if (game.state !== "combat" || player.attackCd > 0 || player.hurt > 0) return;
    const t = now();
    player.combo = t < player.comboExpire ? (player.combo % 3) + 1 : 1;
    player.comboExpire = t + 2500;
    player.attackCd = 1 / player.weapon.rate;
    const baseRange = player.weapon.range * (1 + (player.stats.range || 0));
    const range = player.combo === 3 ? baseRange + (player.weapon.id === "mohong" ? 90 : 40) : baseRange;
    const arc = Math.PI * 0.72;
    const crit = Math.random() < (0.08 + (player.stats.crit || 0));
    const mult = player.weapon.mult * (player.combo === 3 ? 1.35 : 1) * (crit ? 1.7 : 1);
    const angle = player.facing;
    game.slash = { x: player.x, y: player.y, angle, range, ttl: 0.14, combo: player.combo };
    let hit = false;
    for (const e of game.entities) {
      const dx = e.x - player.x;
      const dy = e.y - player.y;
      const d = Math.hypot(dx, dy);
      const a = Math.atan2(dy, dx);
      const delta = Math.abs(Math.atan2(Math.sin(a - angle), Math.cos(a - angle)));
      if (d <= range + e.r && delta <= arc / 2) {
        hit = true;
        damageEnemy(e, player.damage * mult, crit);
        const push = player.combo === 3 ? 70 : 34;
        e.x += Math.cos(angle) * push;
        e.y += Math.sin(angle) * push;
      }
    }
    if (player.combo === 3) {
      player.x = clamp(player.x + Math.cos(angle) * 46, ARENA.x + player.r, ARENA.x + ARENA.w - player.r);
      player.y = clamp(player.y + Math.sin(angle) * 46, ARENA.y + player.r, ARENA.y + ARENA.h - player.r);
    }
    if (hit) {
      hitStop(crit ? 120 : 60);
      shake(crit ? 8 : 3, crit ? 0.2 : 0.15);
      spawnInk(player.x + Math.cos(angle) * range * 0.55, player.y + Math.sin(angle) * range * 0.55, crit ? 15 : 9, crit ? "#f0d27a" : "#171717");
    }
  }

  function dodge() {
    if (player.dodgeCd > 0 || player.hurt > 0) return;
    const dir = movementDir() || { x: Math.cos(player.facing), y: Math.sin(player.facing) };
    player.x = clamp(player.x + dir.x * 110, ARENA.x + player.r, ARENA.x + ARENA.w - player.r);
    player.y = clamp(player.y + dir.y * 110, ARENA.y + player.r, ARENA.y + ARENA.h - player.r);
    player.invuln = 0.5;
    player.dodgeCd = Math.max(0.55, 1.5 - (player.stats.cd || 0));
    spawnInk(player.x, player.y, 14, "#d9d1bf");
  }

  function damageEnemy(e, amount, crit = false, applyOnHit = true) {
    let dmg = amount * (1 + (player.stats.damage || 0) + (player.stats.all || 0));
    e.hp -= dmg;
    e.hurt = 0.18;
    addText(e.x, e.y - 24, Math.round(dmg).toString(), crit ? "#f4d26a" : "#eee4cf", crit ? 1.45 : 1);
    if (applyOnHit && player.stats.slowChance && Math.random() < player.stats.slowChance) e.slow = 2.2;
    if (applyOnHit && player.stats.burn) {
      e.burn = 3;
      e.burnTick = 0.2;
    }
    if (player.weapon.id === "yinxue") player.hp = Math.min(player.maxHp, player.hp + 1.2);
    if (e.hp <= 0) killEnemy(e);
  }

  function killEnemy(e) {
    game.entities = game.entities.filter((x) => x !== e);
    player.stones += e.stone;
    addText(e.x, e.y, `+${e.stone}灵石`, "#d9b35d", 1);
    spawnInk(e.x, e.y, e.kind === "boss" ? 28 : 14, "#111");
    if (player.stats.killHeal) player.hp = Math.min(player.maxHp, player.hp + player.maxHp * player.stats.killHeal);
    if (e.kind === "elite" || e.kind === "boss" || Math.random() < 0.28) dropReward(e);
    if (!game.entities.length) clearRoom();
  }

  function dropReward(e) {
    if (e.kind === "elite" || e.kind === "boss") {
      const weapon = choice(WEAPONS.slice(1));
      game.drops.push({ type: "weapon", item: weapon, x: e.x, y: e.y });
      showMessage(`发现武器：${weapon.name}。靠近按E拾取。`, 3);
    } else {
      const relic = randomRelic();
      game.drops.push({ type: "relic", item: relic, x: e.x, y: e.y });
      showMessage(`发现遗物：${relic.name}。靠近按E拾取。`, 2.6);
    }
  }

  function clearRoom() {
    game.room.cleared = true;
    game.state = "reward";
    if (game.room.type === "BOSS") {
      player.karma += 30 * game.floor;
      game.floor += 1;
      if (game.floor > 5) {
        showMessage(`通关！业力 ${player.karma}，Seed ${game.seed}。按R重开。`, 999);
        game.state = "victory";
      } else {
        player.hp = Math.min(player.maxHp, Math.max(player.hp, player.maxHp * 0.3) + player.maxHp * 0.18);
        showMessage(`第${game.floor - 1}层结算：HP部分回复，遗物保留。按E进入第${game.floor}层。`, 999);
        game.state = "floorClear";
      }
      return;
    }
    if (game.drops.length === 0) game.drops.push({ type: "relic", item: randomRelic(), x: player.x + 80, y: player.y });
    showMessage("房间已清理。拾取奖励后按E进入下一个相邻房间。", 3);
  }

  function randomRelic() {
    const roll = Math.random();
    const pool = roll > 0.95 ? RELICS.filter((r) => r.rarity === "金") :
      roll > 0.78 ? RELICS.filter((r) => r.rarity === "紫") :
      roll > 0.45 ? RELICS.filter((r) => r.rarity === "蓝") :
      RELICS.filter((r) => r.rarity === "白");
    return choice(pool);
  }

  function interact() {
    if (game.state === "floorClear") {
      generateMap();
      showMessage(`第${game.floor}层开始。敌人数值上升，保命优先。`, 3);
      return;
    }
    const near = game.drops.find((d) => Math.hypot(d.x - player.x, d.y - player.y) < 54);
    if (near) {
      if (near.type === "weapon") {
        player.weapon = near.item;
        showMessage(`装备 ${near.item.name}：${near.item.desc}`, 2.5);
      } else if (player.inventory.length < 8) {
        player.inventory.push(near.item);
        showMessage(`获得遗物 ${near.item.name}。Tab 打开五行盘放入槽位。`, 3);
      } else {
        showMessage("背包已满。打开五行盘调整后再拾取。", 2);
        return;
      }
      game.drops = game.drops.filter((d) => d !== near);
      refreshDiskUI();
      evaluateBuild();
      return;
    }
    if (game.state === "shop") {
      game.room.cleared = true;
      tryMoveRoom();
      return;
    }
    tryMoveRoom();
  }

  function shopBuy(key) {
    if (game.state !== "shop") return;
    if (key === "1") {
      if (player.stones < 35) return showMessage("灵石不足。", 1.2);
      if (player.inventory.length >= 8) return showMessage("背包已满。", 1.2);
      player.stones -= 35;
      const relic = randomRelic();
      player.inventory.push(relic);
      showMessage(`买入遗物：${relic.name}`, 2);
      refreshDiskUI();
    }
    if (key === "2") {
      if (player.stones < 45) return showMessage("灵石不足。", 1.2);
      player.stones -= 45;
      player.weapon = choice(WEAPONS.slice(1));
      showMessage(`换得武器：${player.weapon.name}`, 2);
    }
  }

  function evaluateBuild() {
    const stats = { damage: 0, speed: 0, reduction: 0, maxHp: 0, crit: 0, regen: 0, range: 0, slowChance: 0, burn: 0, burnPower: 0, all: 0, cd: 0, killHeal: 0 };
    const active = player.disk.filter(Boolean);
    for (const r of active) {
      for (const [k, v] of Object.entries(r.stats)) stats[k] = (stats[k] || 0) + v;
    }
    const counts = { metal: 0, wood: 0, water: 0, fire: 0, earth: 0 };
    for (const r of active) {
      if (counts[r.element] !== undefined) counts[r.element] += 1;
      if (r.id === "five_elements") Object.keys(counts).forEach((k) => counts[k] += 1);
    }
    const patterns = [];
    const elems = Object.entries(counts).filter(([, v]) => v > 0).map(([k]) => k);
    for (const [el, n] of Object.entries(counts)) {
      if (n >= 5) {
        patterns.push(`${elementName[el]}之极`);
        if (el === "metal") stats.crit += 0.1;
        if (el === "wood") { stats.maxHp += 15; stats.killHeal += 0.15; }
        if (el === "water") { stats.cd += 0.15; stats.slowChance += 0.2; }
        if (el === "fire") { stats.damage += 0.1; stats.burn += 1; }
        if (el === "earth") stats.reduction += 0.15;
      }
    }
    const has = (a, b) => counts[a] > 0 && counts[b] > 0;
    if (has("metal", "water")) { patterns.push("金水相生"); stats.crit += 0.08; }
    if (has("water", "wood")) { patterns.push("水木相生"); stats.regen += 1; }
    if (has("wood", "fire")) { patterns.push("木火相生"); stats.damage += 0.05; stats.burnPower += 0.4; }
    if (has("fire", "earth")) { patterns.push("火土相生"); stats.reduction += 0.08; }
    if (has("earth", "metal")) { patterns.push("土金相生"); stats.damage += 0.05; }
    if (elems.length >= 5) { patterns.push("五行圆满"); stats.all += 0.1; }

    const tags = active.flatMap((r) => r.tags);
    const combos = [];
    const tagHas = (a, b) => tags.includes(a) && tags.includes(b);
    if (tagHas("锐", "裂")) { combos.push("破甲墨锋"); stats.crit += 0.08; }
    if (tagHas("焚", "裂")) { combos.push("爆燃裂帛"); stats.burnPower += 0.6; }
    if (tagHas("吸", "魂")) { combos.push("摄魂回元"); stats.killHeal += 0.06; }
    if (tagHas("冻", "蚀")) { combos.push("寒蚀入骨"); stats.slowChance += 0.12; }
    if (tagHas("厚", "障")) { combos.push("山门不动"); stats.reduction += 0.08; }

    for (const name of [...patterns, ...combos]) {
      if (!game.discovered.has(name)) {
        game.discovered.add(name);
        showMessage(`发现格局：${name}`, 2.6);
      }
    }

    player.stats = stats;
    player.activePatterns = patterns;
    player.activeCombos = combos;
    player.maxHp = 100 + stats.maxHp;
    player.speed = player.baseSpeed * (1 + stats.speed + stats.all);
    player.damage = 10 * (1 + stats.all);
    player.hp = Math.min(player.hp, player.maxHp);
    refreshDiskUI();
  }

  function refreshDiskUI() {
    diskSlots.innerHTML = "";
    inventoryPanel.innerHTML = "";
    player.disk.forEach((r, i) => {
      const el = document.createElement("button");
      el.className = `slot ${r ? "active" : ""}`;
      el.type = "button";
      el.innerHTML = r ? itemHtml(r) : `<span class="meta">槽位 ${i + 1}</span>`;
      el.addEventListener("click", () => {
        if (r) {
          if (player.inventory.length >= 8) return showMessage("背包已满，无法取出。", 1.4);
          player.inventory.push(r);
          player.disk[i] = null;
          evaluateBuild();
        }
      });
      diskSlots.appendChild(el);
    });
    player.inventory.forEach((r, i) => {
      const el = document.createElement("button");
      el.className = "item";
      el.type = "button";
      el.innerHTML = itemHtml(r);
      el.addEventListener("click", () => {
        const slot = player.disk.findIndex((x) => !x);
        if (slot < 0) return showMessage("五行盘已满。点击盘内遗物可取回背包。", 1.6);
        player.disk[slot] = r;
        player.inventory.splice(i, 1);
        evaluateBuild();
      });
      inventoryPanel.appendChild(el);
    });
    const patterns = player.activePatterns.length ? player.activePatterns.join(" / ") : "暂无格局";
    const combos = player.activeCombos.length ? player.activeCombos.join(" / ") : "暂无标签组合";
    buildText.textContent = `当前格局：${patterns}。标签组合：${combos}。点击背包遗物放入五行盘，点击槽位取回。`;
  }

  function itemHtml(r) {
    return `<strong style="color:${elementColor[r.element]}">${r.name}</strong><span class="meta">${r.rarity} · ${elementName[r.element]} · ${r.tags.join("/")}</span><span class="meta">${r.desc}</span>`;
  }

  function toggleDisk(force) {
    game.diskOpen = force ?? !game.diskOpen;
    codex.classList.toggle("hidden", !game.diskOpen);
    refreshDiskUI();
  }

  function update(dt) {
    if (now() < game.hitStopUntil) return;
    if (game.msgUntil < now()) overlay.classList.add("hidden");
    player.attackCd = Math.max(0, player.attackCd - dt);
    player.dodgeCd = Math.max(0, player.dodgeCd - dt);
    player.invuln = Math.max(0, player.invuln - dt);
    player.hurt = Math.max(0, player.hurt - dt);
    if (player.stats.regen) player.hp = Math.min(player.maxHp, player.hp + player.stats.regen * dt);
    movePlayer(dt);
    if (game.state === "combat") updateCombat(dt);
    updateEffects(dt);
  }

  function movementDir() {
    const x = (game.keys.has("d") || game.keys.has("arrowright") ? 1 : 0) - (game.keys.has("a") || game.keys.has("arrowleft") ? 1 : 0);
    const y = (game.keys.has("s") || game.keys.has("arrowdown") ? 1 : 0) - (game.keys.has("w") || game.keys.has("arrowup") ? 1 : 0);
    if (!x && !y) return null;
    const m = Math.hypot(x, y);
    return { x: x / m, y: y / m };
  }

  function movePlayer(dt) {
    const dir = movementDir();
    if (dir && player.hurt <= 0) {
      player.x = clamp(player.x + dir.x * player.speed * dt, ARENA.x + player.r, ARENA.x + ARENA.w - player.r);
      player.y = clamp(player.y + dir.y * player.speed * dt, ARENA.y + player.r, ARENA.y + ARENA.h - player.r);
      player.facing = Math.atan2(dir.y, dir.x);
    } else {
      player.facing = Math.atan2(game.mouse.y - player.y, game.mouse.x - player.x);
    }
  }

  function updateCombat(dt) {
    for (const e of [...game.entities]) {
      e.hurt = Math.max(0, e.hurt - dt);
      e.slow = Math.max(0, e.slow - dt);
      if (e.burn > 0) {
        e.burn -= dt;
        e.burnTick -= dt;
        if (e.burnTick <= 0) {
          e.burnTick = 0.5;
          damageEnemy(e, 4 * (1 + (player.stats.burnPower || 0)), false, false);
          continue;
        }
      }
      const slowMult = e.slow > 0 ? 0.45 : 1;
      const dx = player.x - e.x;
      const dy = player.y - e.y;
      const d = Math.hypot(dx, dy) || 1;
      const nx = dx / d;
      const ny = dy / d;
      e.attackCd -= dt;
      if (e.ai === "ranged" && d < 250) {
        e.x -= nx * e.speed * 0.55 * dt;
        e.y -= ny * e.speed * 0.55 * dt;
      } else if (e.ai === "charger" && e.attackCd < 0.35 && e.attackCd > 0) {
        // Windup tell.
      } else if (e.ai !== "boss" || d > 80) {
        e.x += nx * e.speed * slowMult * dt;
        e.y += ny * e.speed * slowMult * dt;
      }
      e.x = clamp(e.x, ARENA.x + e.r, ARENA.x + ARENA.w - e.r);
      e.y = clamp(e.y, ARENA.y + e.r, ARENA.y + ARENA.h - e.r);
      if (e.ai === "ranged" && e.attackCd <= 0) {
        game.projectiles.push({ x: e.x, y: e.y, vx: nx * 280, vy: ny * 280, r: 6, damage: e.damage, ttl: 3 });
        e.attackCd = 1.8;
      } else if ((d < e.r + player.r + 6 || (e.ai === "boss" && d < 85)) && e.attackCd <= 0) {
        damagePlayer(e.damage, e);
        e.attackCd = e.ai === "boss" ? 1.05 : 1.2;
      }
    }
    for (const p of [...game.projectiles]) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.ttl -= dt;
      if (Math.hypot(p.x - player.x, p.y - player.y) < p.r + player.r) {
        damagePlayer(p.damage, p);
        p.ttl = 0;
      }
      if (p.ttl <= 0) game.projectiles = game.projectiles.filter((x) => x !== p);
    }
  }

  function damagePlayer(amount) {
    if (player.invuln > 0 || player.hurt > 0 || game.state !== "combat") return;
    const dmg = Math.max(1, amount * (1 - Math.min(0.7, (player.stats.reduction || 0) + (player.stats.all || 0))));
    player.hp -= dmg;
    player.hurt = 0.3;
    player.invuln = 0.3;
    addText(player.x, player.y - 30, `-${Math.round(dmg)}`, "#d86b54", 1.2);
    shake(5, 0.16);
    spawnInk(player.x, player.y, 10, "#9f302b");
    if (player.hp <= 0) {
      player.hp = 0;
      game.state = "dead";
      showMessage(`身陨墨渊。业力 ${player.karma}，灵石 ${player.stones}。按R重开。`, 999);
    }
  }

  function updateEffects(dt) {
    if (game.slash) {
      game.slash.ttl -= dt;
      if (game.slash.ttl <= 0) game.slash = null;
    }
    game.shakeTime = Math.max(0, game.shakeTime - dt);
    if (game.shakeTime <= 0) game.shake = 0;
    for (const p of [...game.particles]) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      p.vx *= 0.94;
      p.vy *= 0.94;
      if (p.life <= 0) game.particles = game.particles.filter((x) => x !== p);
    }
    for (const t of [...game.texts]) {
      t.y -= 34 * dt;
      t.life -= dt;
      if (t.life <= 0) game.texts = game.texts.filter((x) => x !== t);
    }
  }

  function hitStop(ms) {
    game.hitStopUntil = now() + ms;
  }

  function shake(amount, seconds) {
    game.shake = amount;
    game.shakeTime = seconds;
  }

  function spawnInk(x, y, count, color) {
    for (let i = 0; i < count; i += 1) {
      const a = rand(0, Math.PI * 2);
      const s = rand(40, 210);
      game.particles.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, life: rand(0.35, 0.9), size: rand(2, 8), color });
    }
  }

  function addText(x, y, text, color, scale) {
    game.texts.push({ x, y, text, color, scale, life: 0.9 });
  }

  function draw() {
    const ox = game.shake ? rand(-game.shake, game.shake) : 0;
    const oy = game.shake ? rand(-game.shake, game.shake) : 0;
    ctx.save();
    ctx.clearRect(0, 0, W, H);
    ctx.translate(ox, oy);
    drawBackground();
    drawArena();
    drawDrops();
    drawProjectiles();
    drawEntities();
    drawPlayer();
    drawSlash();
    drawParticles();
    drawTexts();
    ctx.restore();
    drawHud();
    drawMap();
  }

  function drawBackground() {
    const g = ctx.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, "#1c1a16");
    g.addColorStop(0.5, "#111417");
    g.addColorStop(1, "#1b1510");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, W, H);
    ctx.globalAlpha = 0.06;
    ctx.strokeStyle = "#e8dfcc";
    for (let x = 0; x < W; x += 80) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x - 80, H);
      ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }

  function drawArena() {
    ctx.fillStyle = "rgba(232,223,204,0.04)";
    ctx.strokeStyle = "rgba(232,223,204,0.18)";
    ctx.lineWidth = 2;
    ctx.fillRect(ARENA.x, ARENA.y, ARENA.w, ARENA.h);
    ctx.strokeRect(ARENA.x, ARENA.y, ARENA.w, ARENA.h);
    ctx.fillStyle = "rgba(217,179,93,0.12)";
    ctx.fillRect(ARENA.x + ARENA.w - 14, ARENA.y + ARENA.h / 2 - 52, 14, 104);
  }

  function drawPlayer() {
    ctx.save();
    ctx.translate(player.x, player.y);
    ctx.rotate(player.facing);
    ctx.globalAlpha = player.invuln > 0 ? 0.55 : 1;
    ctx.fillStyle = "#e8dfcc";
    ctx.beginPath();
    ctx.arc(0, 0, player.r, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#15120f";
    ctx.fillRect(0, -5, 28, 10);
    ctx.fillStyle = "#d9b35d";
    ctx.beginPath();
    ctx.arc(13, 0, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  function drawEntities() {
    for (const e of game.entities) {
      ctx.save();
      ctx.translate(e.x, e.y);
      ctx.fillStyle = e.hurt > 0 ? "#fff0c2" : elementColor[e.element];
      ctx.beginPath();
      if (e.ai === "ranged") {
        ctx.rect(-e.r, -e.r, e.r * 2, e.r * 2);
      } else {
        ctx.arc(0, 0, e.r, 0, Math.PI * 2);
      }
      ctx.fill();
      ctx.strokeStyle = "#15120f";
      ctx.lineWidth = 3;
      ctx.stroke();
      if (e.ai === "shielder") {
        ctx.strokeStyle = "#f0e8d8";
        ctx.lineWidth = 4;
        ctx.beginPath();
        ctx.arc(0, 0, e.r + 6, -1.1, 1.1);
        ctx.stroke();
      }
      ctx.restore();
      drawBar(e.x - 24, e.y - e.r - 15, 48, 5, e.hp / e.maxHp, "#c45a4a");
    }
  }

  function drawSlash() {
    if (!game.slash) return;
    const s = game.slash;
    ctx.save();
    ctx.translate(s.x, s.y);
    ctx.rotate(s.angle);
    ctx.globalAlpha = clamp(s.ttl / 0.14, 0, 1);
    ctx.strokeStyle = s.combo === 3 ? "#d9b35d" : "#e8dfcc";
    ctx.lineWidth = s.combo === 3 ? 20 : 13;
    ctx.beginPath();
    ctx.arc(0, 0, s.range, -0.42, 0.42);
    ctx.stroke();
    ctx.restore();
  }

  function drawProjectiles() {
    ctx.fillStyle = "#d9d9d6";
    for (const p of game.projectiles) {
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function drawDrops() {
    for (const d of game.drops) {
      ctx.fillStyle = d.type === "weapon" ? "#d9b35d" : elementColor[d.item.element];
      ctx.beginPath();
      ctx.moveTo(d.x, d.y - 16);
      ctx.lineTo(d.x + 16, d.y);
      ctx.lineTo(d.x, d.y + 16);
      ctx.lineTo(d.x - 16, d.y);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = "#e8dfcc";
      ctx.font = "14px Microsoft YaHei";
      ctx.textAlign = "center";
      ctx.fillText(d.item.name, d.x, d.y + 34);
    }
  }

  function drawParticles() {
    for (const p of game.particles) {
      ctx.globalAlpha = clamp(p.life * 1.8, 0, 1);
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  function drawTexts() {
    ctx.textAlign = "center";
    for (const t of game.texts) {
      ctx.globalAlpha = clamp(t.life, 0, 1);
      ctx.fillStyle = t.color;
      ctx.font = `${Math.round(18 * t.scale)}px Microsoft YaHei`;
      ctx.fillText(t.text, t.x, t.y);
    }
    ctx.globalAlpha = 1;
  }

  function drawHud() {
    drawBar(28, 28, 260, 18, player.hp / player.maxHp, "#c45a4a");
    ctx.fillStyle = "#e8dfcc";
    ctx.font = "16px Microsoft YaHei";
    ctx.textAlign = "left";
    ctx.fillText(`HP ${Math.ceil(player.hp)}/${player.maxHp}`, 34, 43);
    ctx.fillText(`灵石 ${player.stones}  业力 ${player.karma}`, 28, 78);
    ctx.fillText(`武器 ${player.weapon.name} · ${player.weapon.type}`, 28, 104);
    ctx.fillText(`连击 ${player.combo || 0}/3  闪避CD ${player.dodgeCd.toFixed(1)}s`, 28, 130);
    const build = [...player.activePatterns, ...player.activeCombos].slice(0, 3).join(" / ") || "未成格局";
    ctx.fillText(build, 28, 156);
    ctx.textAlign = "right";
    ctx.fillText("WASD移动 · J/鼠标攻击 · Space闪避 · E交互 · Tab五行盘 · R重开", W - 28, H - 26);
  }

  function drawMap() {
    const sx = W - 214;
    const sy = 26;
    const cell = 28;
    ctx.fillStyle = "rgba(12,13,14,0.66)";
    ctx.fillRect(sx - 12, sy - 12, 196, 166);
    for (const c of game.map) {
      if (c.type === "empty") continue;
      const x = sx + c.x * cell;
      const y = sy + c.y * cell;
      ctx.fillStyle = c === game.room ? "#d9b35d" : c.cleared ? "rgba(232,223,204,0.22)" : c.visited ? "rgba(232,223,204,0.55)" : "rgba(232,223,204,0.13)";
      ctx.fillRect(x, y, 22, 22);
      ctx.fillStyle = "#15120f";
      ctx.font = "11px Microsoft YaHei";
      ctx.textAlign = "center";
      ctx.fillText(c.type[0], x + 11, y + 15);
    }
  }

  function drawBar(x, y, w, h, pct, color) {
    ctx.fillStyle = "rgba(0,0,0,0.42)";
    ctx.fillRect(x, y, w, h);
    ctx.fillStyle = color;
    ctx.fillRect(x, y, w * clamp(pct, 0, 1), h);
    ctx.strokeStyle = "rgba(232,223,204,0.35)";
    ctx.strokeRect(x, y, w, h);
  }

  function loop(t) {
    const dt = Math.min(0.033, (t - game.lastTime) / 1000 || 0);
    game.lastTime = t;
    update(dt);
    draw();
    requestAnimationFrame(loop);
  }

  startBtn.addEventListener("click", startGame);
  closeDisk.addEventListener("click", () => toggleDisk(false));
  window.addEventListener("keydown", (e) => {
    const key = e.key.toLowerCase();
    game.keys.add(key);
    if (key === "j") attack();
    if (key === " " || key === "k") {
      e.preventDefault();
      dodge();
    }
    if (key === "e") interact();
    if (key === "tab" || key === "i") {
      e.preventDefault();
      toggleDisk();
    }
    if (key === "m") showMessage("右上角为当前迷宫：S起点，M战斗，E精英，B Boss，SHOP以S显示。", 2.8);
    if (key === "r") startGame();
    if (key === "1" || key === "2") shopBuy(key);
  });
  window.addEventListener("keyup", (e) => game.keys.delete(e.key.toLowerCase()));
  canvas.addEventListener("mousemove", (e) => {
    const rect = canvas.getBoundingClientRect();
    game.mouse.x = ((e.clientX - rect.left) / rect.width) * W;
    game.mouse.y = ((e.clientY - rect.top) / rect.height) * H;
  });
  canvas.addEventListener("mousedown", () => attack());

  refreshDiskUI();
  requestAnimationFrame(loop);
})();
