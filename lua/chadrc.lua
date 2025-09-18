-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
vim.g.tokyonight_style = "night"

---@type ChadrcConfig
local M = {}
M.base46 = {
	--theme = "cappuccin2",
	--theme = "bearded-arc",
	--theme = "doomchad",
	--theme = "gruvchad",
	theme = "tokyonight",
	-- theme = "catppuccin2",
	dashboard = true,
	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- -------------------------------------------------------------------- --
-- 2.  Weather component that never goes blank
-- -------------------------------------------------------------------- --
local ok_weather, weather = pcall(require, "weather")
if ok_weather then
	-- Subscribe only once per NVim session
	if not vim.g._weather_subscribed then
		vim.g._weather_last_temp = "⏳" -- nothing until first success
		weather:subscribe("lualine_persist", function(update)
			if update.success and update.success.data then
				local d = update.success.data
				-- vim.g._weather_last_temp = (d.condition_icon or "") .. (d.temp or "")
				vim.g._weather_last_temp = (d.temp or "")
			end
			-- trigger an immediate status‑line refresh
			vim.schedule(function()
				vim.cmd("redrawstatus!")
			end)
		end)
		vim.g._weather_subscribed = true
	end
end

-- The Lualine component
local function weather_component()
	return vim.g._weather_last_temp or "" -- never nil/empty
end

local function time_component()
	return os.date("%H:%M") -- 24-hour format like 21:45
end

-- -------------------------------------------------------------------- --
-- 3.  WakaTime component for today's coding time
-- -------------------------------------------------------------------- --

-- Initialize only once
if not vim.g._wakatime_timer_started then
	vim.g._wakatime_today = "📊 ⏳"

	local function update_wakatime()
		local sysname = vim.loop.os_uname().sysname
		local home = os.getenv("HOME") or os.getenv("USERPROFILE") -- make sure home is defined
		local wakatimepath

		if sysname == "Linux" or sysname == "Darwin" then
			wakatimepath = home .. "/.wakatime/wakatime-cli"
		elseif sysname == "Windows_NT" then
			wakatimepath = "C:\\Program Files\\WakatimeCLI\\wakatime-cli.exe"
		else
			vim.g._wakatime_today = "📊 unsupported OS"
			return
		end

		local cmd
		if sysname == "Windows_NT" then
			cmd = { wakatimepath, "--today" }
		else
			cmd = { "sh", "-c", wakatimepath .. " --today | sed 's/,.*//; s/ Coding//'" }
		end

		vim.fn.jobstart(cmd, {
			stdout_buffered = true,
			on_stdout = function(_, data)
				local output = vim.tbl_filter(function(line) return line and line ~= "" end, data or {})
				if #output > 0 then
					-- strip ", ..." and " Coding" manually in Lua
					local line = output[1]:match("^[^,]+") -- everything before the first comma
					line = line:gsub(" Coding", "")
					vim.g._wakatime_today = "Coding Today: " .. line .. " "
				else
					vim.g._wakatime_today = "📊 no data"
				end
				vim.schedule(function() vim.cmd("redrawstatus!") end)
			end,
			env = { HOME = home },
		})
	end


	-- Start and refresh every 60 seconds
	local wakatime_timer = vim.loop.new_timer()
	wakatime_timer:start(0, 60000, vim.schedule_wrap(update_wakatime))
	vim.g._wakatime_timer_started = true
end

-- Lualine component
local function wakatime_component()
	return vim.g._wakatime_today or ""
end

M.ui = {
	statusline = {
		theme = "default",
		separator_style = "default",
		order = { "mode", "file", "git", "%=", "time", "%=", "wakatime", "%=", "weather", "lsp", "cwd" },
		modules = {
			weather = weather_component,
			time = time_component,
			wakatime = wakatime_component,
		},
	},
}
return M
