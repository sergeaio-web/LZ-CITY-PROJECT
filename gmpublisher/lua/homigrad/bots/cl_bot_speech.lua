--[[
	Tarkov AI - Speech, client side

	Reads what the speech bridge (hg_speech_bridge.py, running on THIS
	computer) wrote to garrysmod/data/hg_speech.txt and sends the text to
	the server. The file looks like "<number>|<text>"; a new number means a
	new phrase. The phrase that is already in the file when the game loads
	is ignored, so nothing from last session is replayed.
]]

if not CLIENT then return end

local cv_on   = CreateClientConVar("hg_bot_speech_client", "1", true, false, "Send what the speech bridge hears to the server")
local cv_echo = CreateClientConVar("hg_bot_speech_echo",   "1", true, false, "Show what was heard in the chat box")

local FILE = "hg_speech.txt"

local function Read()
	if not file.Exists(FILE, "DATA") then return nil, nil end

	local raw = file.Read(FILE, "DATA")

	if not raw or raw == "" then return nil, nil end

	local id, text = string.match(raw, "^%s*(%d+)|(.-)%s*$")

	return id, text
end

local last = Read() -- whatever is there now is old

timer.Create("HG_Bots_SpeechPoll", 0.4, 0, function()
	if not cv_on:GetBool() then return end

	local id, text = Read()

	if not id or id == last then return end

	last = id

	text = string.Trim(text or "")

	if text == "" then return end

	text = string.sub(text, 1, 200)

	net.Start("hg_bot_speech")
	net.WriteString(text)
	net.SendToServer()

	if cv_echo:GetBool() then chat.AddText(Color(120, 200, 255), "[voice] ", color_white, text) end
end)
