-- Constants
local HTTP_REQUEST = (syn and syn.request) or http and http.request or http_request or (fluxus and fluxus.request) or request
local STOP_COMMAND = ">stop"
local LYRICS_COMMAND = ">play "

-- Variables
local songName, plr
local debounce = false
local stopped = false

-- Function to send a message
local function sendMessage(text)
	game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(text, "All")
end

-- Function to fetch lyrics for a song
local function fetchLyrics(songName)
	local url = "https://lyrist.vercel.app/api/" .. songName
	local response = HTTP_REQUEST({
		Url = url,
		Method = "GET",
	})

	if response.StatusCode == 200 then
		return game:GetService("HttpService"):JSONDecode(response.Body)
	else
		return { error = "Lyrics Not found" }
	end
end

-- Function to play an ad for Echo Hub
local function playAd()
	sendMessage("📢 | Check out Echo Hub for the best products for your Roblox game! Join now at kord/echo")
	sendMessage("📢 | To add your ad here, join our Discord to learn more.")
end


-- Event handler for incoming chat messages
game:GetService('ReplicatedStorage').DefaultChatSystemChatEvents:WaitForChild('OnMessageDoneFiltering').OnClientEvent:Connect(function(msgdata)
	if debounce or not string.match(msgdata.Message, LYRICS_COMMAND) or string.gsub(msgdata.Message, LYRICS_COMMAND, '') == '' or game:GetService('Players')[msgdata.FromSpeaker] == game:GetService('Players').LocalPlayer then
		return
	end

	debounce = true
	local speaker = msgdata.FromSpeaker
	local msg = string.lower(msgdata.Message):gsub(LYRICS_COMMAND, ''):gsub('"', ''):gsub(' by ','/')
	local speakerDisplay = game:GetService('Players')[speaker].DisplayName
	plr = game:GetService('Players')[speaker].Name
	songName = string.gsub(msg, " ", ""):lower()

	local success, lyricsData = pcall(fetchLyrics, songName)

	if success then
		if lyricsData.error and lyricsData.error == "Lyrics Not found" then
			sendMessage('Lyrics were not found')
			task.wait(3)
			debounce = false
			return
		end

		local lyricsTable = {}
		for line in string.gmatch(lyricsData.lyrics, "[^\n]+") do
			table.insert(lyricsTable, line)
		end

		sendMessage('Fetched lyrics')
		task.wait(2)
		sendMessage('Playing song requested by ' .. speakerDisplay .. '. They can stop it by saying ">stop"')
		task.wait(3)

		for i, line in ipairs(lyricsTable) do
			if stopped then
				stopped = false
				break
			end
			sendMessage('🎙️ | ' .. line)
			task.wait(4.7)
		end

		task.wait(3)
		debounce = false
		sendMessage('Ended. You can request songs again.')
		task.wait(2)
		playAd()
	else
		sendMessage('Unexpected error, please retry')
		task.wait(3)
		debounce = false
		return
	end
end)

-- Background task to periodically remind users about the bot's functionality
task.spawn(function()
	while task.wait(60) do
		if not debounce then
			sendMessage('I am a music bot called BloxRhythm! Type ">play Song name" and I will play the song for you!')
			task.wait(2)
			if not debounce then
				sendMessage('You can also do ">play song name by Author"')
			end
		end
	end
end)

-- Introduction message
sendMessage('I am a music bot called BloxRhythm! Type ">play song name" and I will play the song for you!')
task.wait(2)
sendMessage('You can also do ">play song name by Author"')
