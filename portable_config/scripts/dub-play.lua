-- dub-play.lua — DubPlay: ghép audio lồng tiếng + phụ đề cho video đang mở.
--
-- Hai cách ghép lồng tiếng:
--   1. TỰ ĐỘNG: đặt file "dub_audio*.wav" (xuất từ extension / Studio) cùng
--      thư mục với video → nạp làm track tiếng thứ hai, đồng bộ sẵn.
--   2. THỦ CÔNG ngay trong app: nhấn "a" → duyệt chọn audio lồng tiếng
--      (WAV/MP3...), "s" → phụ đề (SRT/VTT/ASS...), "o" → mở video khác.
--      Trình duyệt là menu của uosc ngay trên player (gõ để tìm kiếm nhanh),
--      điều hướng bằng chuột hoặc phím mũi tên — KHÔNG mở cửa sổ ngoài,
--      không console nháy, chạy giống hệt trên Windows và macOS.
--
-- Trải nghiệm như extension trên YouTube: tiếng GỐC tự nhỏ xuống khi giọng
-- DUB nói (sidechaincompress theo tín hiệu dub), im lặng thì tiếng gốc về
-- 100%. Thông số đã hiệu chuẩn bằng đo thực tế (gap = 0dB, speech ~ -13dB).
--
-- Phím tắt:
--   a / s / o  : duyệt audio lồng tiếng / phụ đề / video khác
--   d / D      : đậm / nhạt độ duck của tiếng gốc
--   x / X      : nhỏ / to âm lượng giọng dub

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local SCRIPT = mp.get_script_name()
local PLATFORM = mp.get_property_native("platform") or "unknown"

local duck_ratio = 8.0   -- lớn hơn = tiếng gốc bị nén đậm hơn khi dub nói
local dub_gain = 1.0     -- âm lượng giọng dub (1.0 = nguyên bản)
local graph_applied = false

-- ============ Filter graph (đã kiểm chứng bằng số liệu) ============
-- aid1 = tiếng gốc của video, aid2 = WAV dub. alimiter chống clip peak.
local function build_graph()
  return string.format(
    "[aid2]asplit=2[sc][premix];" ..
    "[premix]volume=%.2f[mix];" ..
    "[aid1][sc]sidechaincompress=threshold=0.02:ratio=%.1f:attack=20:release=400[duck];" ..
    "[duck][mix]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.95[ao]",
    dub_gain, duck_ratio)
end

local function audio_track_count()
  local n = 0
  for _, t in ipairs(mp.get_property_native("track-list") or {}) do
    if t.type == "audio" then n = n + 1 end
  end
  return n
end

-- Chỉ áp graph khi đủ 2 track tiếng (gốc + dub). Video không có tiếng gốc
-- → dub phát bình thường, không cần duck.
local function apply_graph(force)
  if graph_applied and not force then return end
  if audio_track_count() < 2 then return end
  local ok = mp.set_property("lavfi-complex", build_graph())
  if ok then
    graph_applied = true
    msg.info(("graph applied (duck_ratio=%.1f dub_gain=%.2f)"):format(duck_ratio, dub_gain))
  else
    msg.error("khong ap duoc lavfi-complex graph")
  end
end

-- ============ Tìm file cạnh video ============
local function dirname(p) return (p:gsub("[^/\\]+$", "")) end
local function basename_noext(p)
  local b = p:match("[^/\\]+$") or p
  return b:gsub("%.[^%.]+$", "")
end

-- WAV dub: ưu tiên "dub_audio*.wav" mới nhất (tên chuẩn extension xuất ra),
-- kế đến "<tên video>*.wav" nếu ai đó đổi tên theo video.
local function find_dub_wav(video_path)
  local dir = dirname(video_path)
  local base = basename_noext(video_path):lower()
  local files = utils.readdir(dir, "files") or {}
  local best, best_time = nil, -1
  for _, f in ipairs(files) do
    local fl = f:lower()
    local escaped = base:gsub("%W", "%%%0")
    local is_dub = fl:match("^dub_audio.*%.wav$") or (base ~= "" and fl:match("^" .. escaped .. ".*%.wav$"))
    if is_dub then
      local st = utils.file_info(dir .. f)
      local t = st and st.mtime or 0
      if t >= best_time then best, best_time = dir .. f, t end
    end
  end
  return best
end

-- Phụ đề: cùng tên với video trước, không có thì .srt/.vtt đầu tiên.
local function find_sub(video_path)
  local dir = dirname(video_path)
  local base = basename_noext(video_path)
  local files = utils.readdir(dir, "files") or {}
  local by_name, first = nil, nil
  for _, f in ipairs(files) do
    local fl = f:lower()
    if fl:match("%.srt$") or fl:match("%.vtt$") then
      if not first then first = dir .. f end
      if not by_name and fl:sub(1, #base + 1) == base:lower() .. "." then by_name = dir .. f end
    end
  end
  return by_name or first
end

-- Gỡ track dub cũ (nếu có) rồi thêm track mới + áp lại graph.
local function add_dub_track(path)
  for _, t in ipairs(mp.get_property_native("track-list") or {}) do
    if t.type == "audio" and t.title == "Dub" then
      mp.commandv("audio-remove", tostring(t.id))
    end
  end
  mp.commandv("audio-add", path, "auto", "Dub")
  graph_applied = false
  mp.set_property("lavfi-complex", "")
  msg.info("dub audio: " .. path)
end

-- ============ Trình duyệt file TRONG APP (menu uosc) ============
-- Trước đây chọn file qua powershell/osascript: mỗi lần bấm là một process
-- mới + console nháy lên. Giờ duyệt file bằng chính menu của uosc: mở tại
-- thư mục video, ".." để lên cấp, bấm thư mục để vào, bấm file để nạp.
local BROWSE = {
  audio = { title = "Audio lồng tiếng", icon = "library_music", color = "F7C34F",
    exts = { wav = 1, mp3 = 1, m4a = 1, ogg = 1, aac = 1, flac = 1, opus = 1, wma = 1 } },
  sub   = { title = "Phụ đề", icon = "subtitles", color = "4FD5FF",
    exts = { srt = 1, vtt = 1, ass = 1, ssa = 1, sub = 1, smi = 1 } },
  video = { title = "Video", icon = "movie", color = "84C781",
    exts = { mp4 = 1, mkv = 1, avi = 1, webm = 1, mov = 1, wmv = 1, flv = 1, m4v = 1, ts = 1, mpg = 1, mpeg = 1 } },
}
-- Màu icon (hex BGR — định dạng ASS của uosc) để phân biệt loại trong nháy mắt.
local C = {
  folder = "4DB7FF", -- cam   (RGB FFB74D)
  drive  = "7373E5", -- đỏ   (RGB E57373)
  quick  = "E1D04D", -- cyan (RGB 4DD0E1)
}
local last_dir = {} -- thư mục duyệt gần nhất theo loại (trong phiên)

local function video_dir()
  local p = mp.get_property("path") or ""
  return (p:gsub("[^/\\]+$", ""))
end

local function join_path(dir, name)
  if dir:match("[\\/]$") then return dir .. name end
  return dir .. (dir:match("\\") and "\\" or "/") .. name
end

local function human_size(n)
  if not n or n <= 0 then return nil end
  if n >= 1073741824 then return ("%.1f GB"):format(n / 1073741824) end
  if n >= 1048576 then return ("%.1f MB"):format(n / 1048576) end
  return ("%.0f KB"):format(n / 1024)
end

-- Mở đầu: thư mục video đang mở; không có video thì thư mục duyệt lần trước,
-- cuối cùng là danh sách ổ đĩa (Windows) / home (macOS, Linux) — KHÔNG mở ở
-- profile user nữa: chỗ đó toàn thư mục, 0 file media, nhìn như "file bị ẩn".
local DRIVES = "DP-DRIVES" -- sentinel báo "đang ở danh sách ổ đĩa", không phải đường dẫn

local function start_dir_for(kind)
  local vd = video_dir()
  if vd ~= "" then return vd end
  if last_dir[kind] then return last_dir[kind] end
  if PLATFORM == "windows" then return DRIVES end
  return os.getenv("HOME") or "/"
end

-- Trang "Ổ đĩa · Chỗ nhanh" ("This PC"): chỗ hay dùng trước, ổ đĩa sau.
-- Ghim trên đầu MỌI menu duyệt file nên đổi ổ chỉ tốn đúng 1 lần bấm.
local function open_drives_menu(kind)
  local items = {}
  local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
  -- Mac dùng ~/Movies thay cho ~/Videos của Windows — chọn theo nền tảng.
  local movies = PLATFORM == "darwin" and "Movies" or "Videos"
  local places = {
    { title = "Thư mục người dùng", icon = "home", path = home },
    { title = "Downloads",  icon = "download",        path = home .. "/Downloads" },
    { title = "Desktop",    icon = "desktop_windows", path = home .. "/Desktop" },
    { title = movies,       icon = "video_library",   path = home .. "/" .. movies },
    { title = "Documents",  icon = "folder_open",     path = home .. "/Documents" },
  }
  for _, pl in ipairs(places) do
    local ok = pl.path ~= "" and (utils.file_info(pl.path) ~= nil
      or utils.file_info(pl.path:gsub("/", "\\")) ~= nil)
    if ok then
      items[#items + 1] = { title = pl.title, icon = pl.icon, icon_color = C.quick,
        hint = pl.path,
        value = { "script-message-to", SCRIPT, "dp-nav", kind, pl.path, "dir" } }
    end
  end

  items[#items + 1] = { title = "Ổ đĩa", value = "ignore", muted = true,
    italic = true, selectable = false, align = "center" }
  local ndrives = 0
  if PLATFORM == "windows" then
    for b = string.byte("A"), string.byte("Z") do
      local root = string.char(b) .. ":\\"
      if utils.file_info(root) then
        ndrives = ndrives + 1
        items[#items + 1] = { title = string.char(b) .. ":", icon = "storage",
          icon_color = C.drive, hint = "Ổ đĩa",
          value = { "script-message-to", SCRIPT, "dp-nav", kind, root, "dir" } }
      end
    end
  else
    -- macOS: ổ hệ thống "/" không nằm trong /Volumes nên thêm riêng.
    if PLATFORM == "darwin" then
      ndrives = ndrives + 1
      items[#items + 1] = { title = "Macintosh HD", icon = "storage", icon_color = C.drive,
        hint = "/", value = { "script-message-to", SCRIPT, "dp-nav", kind, "/", "dir" } }
    end
    local mnt = PLATFORM == "darwin" and "/Volumes" or "/"
    for _, d in ipairs(utils.readdir(mnt, "dirs") or {}) do
      ndrives = ndrives + 1
      items[#items + 1] = { title = d, icon = "storage", icon_color = C.drive,
        value = { "script-message-to", SCRIPT, "dp-nav", kind, mnt .. "/" .. d, "dir" } }
    end
  end
  msg.info(("browse drives: %d cho nhanh, %d o dia"):format(#items - ndrives - 1, ndrives))
  mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json({
    type = "dubplay-browse",
    title = "Ổ đĩa · Chỗ nhanh",
    icon = "storage",
    items = items,
  }))
end

local function open_browser(kind, dir)
  local cfg = BROWSE[kind]
  if not cfg then return end
  dir = dir or start_dir_for(kind)
  if dir == DRIVES then
    open_drives_menu(kind)
    return
  end
  last_dir[kind] = dir
  local base = dir:gsub("[\\/]+$", "")
  local items = {}

  -- GHIM ĐẦU MENU: nhay sang o dia / cho nhanh chi bang 1 lan bam —
  -- khoi phai ".." lan lan tu sau lung de doi o.
  items[#items + 1] = { title = "Ổ đĩa · Chỗ nhanh", icon = "storage", icon_color = C.drive,
    hint = "1 bước sang ổ khác",
    value = { "script-message-to", SCRIPT, "dp-nav", kind, DRIVES, "dir" } }

  -- Đứng ở góc ổ đĩa (C:\, N:\...): ".." lên danh sách ổ đĩa để đổi ổ.
  local parent
  if base:match("^%a:\\?$") then
    parent = DRIVES
  else
    parent = dirname(base)
    if parent == "" or parent == base then parent = nil end
  end
  if parent then
    items[#items + 1] = { title = "..", icon = "arrow_upward",
      hint = parent == DRIVES and "Danh sách ổ đĩa" or "Thư mục cha",
      value = { "script-message-to", SCRIPT, "dp-nav", kind, parent, "dir" } }
  end

  -- FILE LÊN TRƯỚC: file là mục tiêu cần chọn (WAV/sub/video cạnh video),
  -- phải hiện ngay trong vùng nhìn thấy. Thư mục chỉ để điều hướng — trước
  -- đây xếp trên đầu khiến folder nhiều thư mục con chôn file dưới đáy,
  -- nhìn như "file bị ẩn".
  local nfiles = 0
  local files = utils.readdir(dir, "files") or {}
  table.sort(files, function(a, b) return a:lower() < b:lower() end)
  for _, f in ipairs(files) do
    local ext = f:match("%.(%w+)$")
    if ext and cfg.exts[ext:lower()] then
      nfiles = nfiles + 1
      local st = utils.file_info(join_path(dir, f))
      items[#items + 1] = { title = f, icon = cfg.icon, icon_color = cfg.color,
        hint = human_size(st and st.size),
        value = { "script-message-to", SCRIPT, "dp-nav", kind, join_path(dir, f), "file" } }
    end
  end

  local dirs = utils.readdir(dir, "dirs") or {}
  table.sort(dirs, function(a, b) return a:lower() < b:lower() end)
  local ndirs = 0
  for _, d in ipairs(dirs) do
    if not d:match("^%.") then ndirs = ndirs + 1 end
  end
  if ndirs > 0 then
    items[#items + 1] = { title = "Thư mục con", value = "ignore", muted = true,
      italic = true, selectable = false, align = "center" }
  end
  for _, d in ipairs(dirs) do
    if not d:match("^%.") then
      items[#items + 1] = { title = d, icon = "folder", icon_color = C.folder,
        value = { "script-message-to", SCRIPT, "dp-nav", kind, join_path(dir, d), "dir" } }
    end
  end

  msg.info(("browse %s: %d file khop, %d thu muc (%s)"):format(kind, nfiles, ndirs, dir))
  local short = #base > 48 and ("…" .. base:sub(-46)) or base
  mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json({
    type = "dubplay-browse",
    title = cfg.title .. "  •  " .. short,
    icon = cfg.icon,
    items = items,
  }))
end

-- uosc chạy value của mục được chọn = lệnh script-message-to quay về đây.
mp.register_script_message("dp-nav", function(kind, path, what)
  if what == "dir" then
    open_browser(kind, path)
    return
  end
  local name = path:match("[^/\\]+$") or path
  if kind == "audio" then
    add_dub_track(path)
    mp.osd_message("🔊 Đã nạp: " .. name .. "\nTiếng gốc sẽ tự nhỏ khi dub nói", 4)
  elseif kind == "sub" then
    mp.commandv("sub-add", path, "select", "Phụ đề")
    mp.osd_message("💬 Đã nạp phụ đề: " .. name, 3)
  elseif kind == "video" then
    mp.commandv("loadfile", path)
  end
end)

-- ============ Sự kiện ============
mp.register_event("file-loaded", function()
  graph_applied = false
  mp.set_property("lavfi-complex", "")
  local path = mp.get_property("path")
  if not path or path:find("^http") then return end

  local wav = find_dub_wav(path)
  if wav then
    mp.commandv("audio-add", wav, "auto", "Dub")
    msg.info("dub audio: " .. wav)
  end

  local sub = find_sub(path)
  if sub then
    mp.commandv("sub-add", sub, "auto", "Phụ đề")
    msg.info("sub: " .. sub)
  end

  -- Hướng dẫn ngay trên màn hình — người mới biết đường mà dùng.
  -- Đuôi (v9) để nhận diện phiên bản script đang chạy.
  if wav then
    mp.osd_message("🔊 Đã ghép lồng tiếng ✓ (v12)\nChuột phải: menu · a: audio · s: phụ đề", 5)
  else
    mp.osd_message("Chưa thấy dub_audio*.wav cạnh video (v12)\nNhấn a (hoặc chuột phải) để chọn file lồng tiếng", 5)
  end
end)

-- audio-add bất đồng bộ — theo dõi track-list, ap graph khi đủ 2 track.
mp.observe_property("track-list", nil, function()
  if not graph_applied and audio_track_count() >= 2 then
    apply_graph(true)
  end
end)

-- ============ Phím tắt ============
mp.add_key_binding("a", "dubplay_pick_audio", function() open_browser("audio") end)
mp.add_key_binding("s", "dubplay_pick_sub", function() open_browser("sub") end)
mp.add_key_binding("o", "dubplay_open_video", function() open_browser("video") end)

mp.add_key_binding("d", "dubplay_duck_more", function()
  duck_ratio = math.min(20, duck_ratio + 2)
  apply_graph(true)
  mp.osd_message(("Tiếng gốc khi dub: đậm hơn (ratio %.0f)"):format(duck_ratio), 2)
end)
mp.add_key_binding("D", "dubplay_duck_less", function()
  duck_ratio = math.max(2, duck_ratio - 2)
  apply_graph(true)
  mp.osd_message(("Tiếng gốc khi dub: nhạt hơn (ratio %.0f)"):format(duck_ratio), 2)
end)
mp.add_key_binding("x", "dubplay_dub_quieter", function()
  dub_gain = math.max(0, dub_gain - 0.1)
  apply_graph(true)
  mp.osd_message(("Âm lượng dub: %d%%"):format(dub_gain * 100), 2)
end)
mp.add_key_binding("X", "dubplay_dub_louder", function()
  dub_gain = math.min(2, dub_gain + 0.1)
  apply_graph(true)
  mp.osd_message(("Âm lượng dub: %d%%"):format(dub_gain * 100), 2)
end)

-- Mở player KHÔNG kèm video (Start Menu / double-click DubPlay): mở luôn
-- trình duyệt trong app để chọn ngay — bắt đầu từ danh sách ổ đĩa.
mp.add_timeout(0.4, function()
  if not mp.get_property("path") then
    open_browser("video", start_dir_for("video"))
  end
end)

msg.info("dub-play.lua loaded")
