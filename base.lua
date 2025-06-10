dreya = {}
startUpArgs = { 'blank', 'private' }; do
    if LPH_OBFUSCATED then
        startUpArgs[2] = 'production'
    else
        LPH_JIT_MAX = function(...) return (...) end
        LPH_NO_VIRTUALIZE = function(...) return (...) end
        LPH_NO_UPVALUES = function(...) return (...) end
        LPH_CRASH = function(...) return (...) end
    end
end

library = loadstring(request({ Url = 'https://raw.githubusercontent.com/dauntIess/dreya-ui/refs/heads/main/library.lua', Method = 'GET' }).Body)()

local folders = {
    main = 'dreya',
    assets = 'dreya/assets',
    sounds = 'dreya/assets/sounds',
    configs = ('dreya/games/%s/configs'):format(startUpArgs[1]),
    scripts = ('dreya/games/%s/scripts'):format(startUpArgs[1])
}

-- first-time executors duh
for _, folder in pairs(folders) do
    if not isfolder(folder) then
        makefolder(folder)
        library:notify({ title = 'dreya', text = ('\'%s\' not found, creating..'):format(folder), time = 7 })
    end
end

if not isfile(folders['assets'] .. '/settings.lua') then
    writefile(folders['assets'] .. '/settings.lua', [[
local assets = {
    tracers = {
        Default = ''
    },
    textures = {
        Default = '',
    },
    skyboxes = {
        Cache = {
            SkyboxBk = 'rbxassetid://220513302',
            SkyboxDn = 'rbxassetid://213221473',
            SkyboxFt = 'rbxassetid://220513328',
            SkyboxLf = 'rbxassetid://220513318',
            SkyboxRt = 'rbxassetid://220513279',
            SkyboxUp = 'rbxassetid://220513345'
        }
    },
}
    
return assets]])
    library:notify({ title = 'dreya', text = ('\'%s\' not found, creating..'):format(folders['assets'] .. '/settings.lua'), time = 7 })
end

local assets = loadfile(folders['assets'] .. '/settings.lua')()

local ContentProvider = game:GetService('ContentProvider')
local QueueSize = ContentProvider.RequestQueueSize do
    if QueueSize > 10 then
        local init = library:notify({ text = 'waiting for the game to load (?)', time = 10 })
        repeat task.wait()
        until QueueSize <= 10
    end
end
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local oldName = LocalPlayer.Name
local oldDisplayName = LocalPlayer.DisplayName
local oldUserId = tostring(LocalPlayer.UserId)

dreya.userinfo = { id = oldUserId, username = oldName, displayname = oldDisplayName }

local init = tick()

local window = library:new({ name = 'dreya', sub = `.{startUpArgs[1]}`, size = Vector2.new(650, 700)}) do

    local watermark = library:createwatermark()
    local serverlist = window:server_list({ flag = 'selected server' })
    local playerlist = window:player_list({ flag = 'selected player' })

    -- scripts
    local scripts_tab = window:page({ name = 'scripts' }) do
        dreya.tab = scripts_tab
    end

    -- options
    local options_tab = window:page({ name = 'options', default = true  }) do
        local main = options_tab:section({ name = 'files', size = '565' }) do
            main:divider({ name = 'configurations' })
            local configlist = main:dropdown({ name = 'available configs', flag = 'selected config', ignoreflag = true, options = {}, scrollable = true, scrollingmax = 4})
            local function update_configs()
                local tbl = {}
                for i, v in next, listfiles(folders['configs']) do
                    tbl[#tbl + 1] = v:match('.*\\(.-)%.dreya$')
                end
                configlist:refresh(tbl);
                library:notify({ title = 'file service', text = 'all available configs have been refreshed', time = 5 })
            end
            --
            main:button({ name = 'load', confirm = true, callback = function()
                if library.flags['selected config'] ~= nil and isfile(folders['configs'] .. '/'..library.flags['selected config']..'.dreya') then
                    library:load_config(folders['configs'] .. '/'..library.flags['selected config']..'.dreya');
                    library:notify({ title = 'file service', text = string.format('successfully loaded \'%s\'', library.flags['selected config']), time = 7 })
                end
            end})
            main:button({ name = 'save', confirm = true, callback = function()
                local file = library.flags['selected config']
                if file ~= nil and isfile(string.format(folders['configs'] .. '/%s.dreya', file)) then
                    writefile(string.format(folders['configs'] .. '/%s.dreya', file), library:get_config());
                    library:notify({ title = 'file service', text = string.format('successfully saved \'%s\'', file), time = 7 })
                end
            end}):button({ name = 'delete', confirm = true, callback = function()
                if library.flags['selected config'] ~= nil and isfile(folders['configs'] .. '/'..library.flags['selected config']..'.dreya') then
                    local file = library.flags['selected config']
                    delfile(folders['configs'] .. '/'..file..'.dreya');
                    library:notify({ title = 'file service', text = string.format('successfully deleted \'%s\'', file), time = 7 })
                    update_configs();
                end
            end})
            main:textbox({ placeholder = 'file name', flag = 'config name', default = '', ignoreflag = true, middle = true})
            main:button({ name = 'create', confirm = true, callback = function()
                local name = library.flags['config name']
                if library.flags['config name'] == '' then
                    return library:notify({ title = 'file service', text = string.format('failed (name can\'t be blank)', name), time = 7 })
                end
                if isfile(string.format(folders['configs'] .. '/%s.dreya', name)) then
                    return library:notify({ title = 'file service', text = string.format('failed (\'%s.dreya\' already exists)', name), time = 7 })
                end
                writefile(string.format(folders['configs'] .. '/%s.dreya', name), library:get_config());
                update_configs();
                library:notify({ title = 'file service', text = string.format('successfully created file \'%s.dreya\'', name), time = 7 })
            end })
            update_configs()
            main:divider({ name = 'scripts' }) do
                local scriptlist = main:dropdown({ name = 'available scripts', flag = 'selected script', options = {}, scrollable = true, scrollingmax = 6 }) do
                    local function update_scripts()
                        local tbl = {}
                        for i, v in next, listfiles(folders['scripts']) do
                            tbl[#tbl + 1] = v:match('.*\\(.-%.lua)')
                        end
                        scriptlist:refresh(tbl)
                        scriptlist:set(tbl[1])
                        library:notify({ title = 'file service', text = 'all available scripts have been refreshed', time = 5 })
                    end
                    local function load_script()
                        local file = library.flags['selected script']
                        if table.find(dreya.loaded_scripts, file) then
                            return library:notify({ title = 'file service', text = ('failed (\'%s\' has been executed previously.)'):format(file), time = 5 })
                        end

                        library:notify({ title = 'file service', text = ('attempting to load script \'%s\''):format(file), time = 10 })
                        file = '/'..library.flags['selected script']
                        dofile(folders['scripts'] .. file)

                        table.insert(dreya.loaded_scripts, library.flags['selected script'])
                        library:notify({ title = 'file service', text = ('successfully loaded script \'%s\''):format(library.flags['selected script']), time = 5 })
                    end
                    main:button({ name = 'load', confirm = true, callback = load_script }):button({ name = 'refresh', confirm = true, callback = update_scripts })
                    update_scripts()
                end
            end
        end
        local options = options_tab:section({ name = 'data', side = 'right', size = '275' }) do

            if userdata then
                local pfp = request({
                    Url = `https://cdn.discordapp.com/avatars/{userdata.discord_info.id}/{userdata.discord_info.avatar}.png`,
                    Method = 'GET'
                }).Body

                local infographic = options:infographic({
                    info = `uid {userdata.UID} ({userdata.discord_info.username})\nexpires in: 9y, 9m`,
                    image = pfp })
                options:toggle({ name = 'hide', flag = 'hide userinfo', callback = function(bool)
                    infographic:hide(bool)
                end})
            end
            options:toggle({ name = 'watermark', flag = 'watermark', callback = function(state)
                watermark.setstate(state)
            end })
            options:multibox({ flag = 'watermark text', options = { '{fps}', '{fpsavg}', '{ping}', '{date}', '{time}', '{uid}', '{build}', '{game}', '{memory}', '{netreceived}', '{netoutgoing}' }, default = { '{build}', '{fpsavg}'}, max = 5, callback = function(tbl)
                watermark.title = table.concat(tbl, ', ')
            end})
            options:slider({ name = 'refresh rate', flag = 'watermark refresh rate', min = 10, max = 1000, suffix = 'ms', float = 1, default = 250, callback = function(v)
                watermark.refreshrate = v
            end})
        end
        local options = options_tab:section({ name = 'options', side = 'right', size = '275' }) do
            options:divider({ name = 'menu options' }) do
                options:keybind({ name = 'menu', flag = 'menu toggle', default = Enum.KeyCode.Minus, mode = 'Toggle', callback = function() library:set_open(not library.open) end})
                options:keybind({ name = 'player list', flag = 'player list toggle', default = Enum.KeyCode.LeftBracket, mode = 'Toggle', callback = function(state) playerlist:setopen(not playerlist.open) end})
                options:keybind({ name = 'server list', flag = 'server list toggle', default = Enum.KeyCode.LeftBracket, mode = 'Toggle', callback = function(state) serverlist:setopen(not serverlist.open) end })
            end
            options:divider({ name = 'personalization' }) do
                options:colorpicker({ name = 'accent', flag = 'menu accent', default = Color3.fromRGB(117, 163, 125), callback = function(s) library:change_theme_color('Accent', s) end})
            end
        end

    end
end

library:notify({text = string.format('loaded, took %.2fs', tostring(math.floor(tick() - init))), time = 10})
