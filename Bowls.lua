-----------------------------------------
-- Himalayan Singing Bowl              --
-- Team: Biqiao Zhang                  --
--       Zachary Boulanger             --
--       Antonio D. de Carvalho J.     --
--                                     --
-- Page 1 interface: Boulanger         --
-- Page 2 sketches: de Carvalho J.     --
-- Page 2 interface: Zhang             --
-- Network interaction: de Carvalho J. --
-----------------------------------------
SetPage(1)
FreeAllRegions()
FreeAllFlowboxes()
SetPage(2)
FreeAllRegions()
SetPage(1)
DPrint("")

--function DocumentPath(path)
--    return SystemPath(path)
--end

-----------------------------------------
--              Variables              --
-----------------------------------------

log = math.log

allpitch =
{32.7, 34.65, 36.71, 38.89, 41.2, 43.65, 46.25, 49, 51.91, 55, 58.27, 61.74,
    65.41, 69.3, 73.42, 77.78, 82.41, 87.31, 92.5, 98, 103.83, 110, 116.54, 123.47,
    130.81, 138.59, 146.83, 155.56, 164.81, 174.61, 185, 196, 207.65, 220, 233.08, 246.94,
    261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392, 415.3, 440, 466.16, 493.88,
    523.25, 554.37, 587.33, 622.25, 659.25, 698.46, 739.99, 783.99, 830.61, 880, 932.33, 987.77,
    1046.5, 1108.73, 1174.66, 1244.51, 1318.51, 1396.91, 1479.98, 1567.98, 1661.22, 1760, 1864.66, 1975.53,
    2093, 2217.46, 2349.32, 2489.02, 2637.02, 2793.83, 2959.96, 3135.96, 3322.44, 3520, 3729.31, 3951.07,
    4186.01, 4434.92, 4698.63, 4978.03, 5274.04, 5587.65, 5919.91, 6271.93, 6644.88, 7040, 7458.62, 7902.13}

key_index = {1,3,5,6,8,10,12}
currentamp = 0
currentoct = 3
currentkey = 1
currentidx = 1
currentmode = 1

-- flowboxes
-- to start sound, use push:Push(pitch here)
dac = FlowBox(FBDac)

push_f1 = FlowBox(FBPush)
push_f2_1 = FlowBox(FBPush)
push_f2_2 = FlowBox(FBPush)
push_f3_1 = FlowBox(FBPush)
push_f3_2 = FlowBox(FBPush)

push_f1A = FlowBox(FBPush)
push_f2_1A = FlowBox(FBPush)
push_f2_2A = FlowBox(FBPush)
push_f3_1A = FlowBox(FBPush)
push_f3_2A = FlowBox(FBPush)

sinosc_f1 = FlowBox(FBSinOsc)
sinosc_f2_1 = FlowBox(FBSinOsc)
sinosc_f2_2 = FlowBox(FBSinOsc)
sinosc_f3_1 = FlowBox(FBSinOsc)
sinosc_f3_2 = FlowBox(FBSinOsc)

asymp1 = FlowBox(FBAsymp)
asymp2 = FlowBox(FBAsymp)
asymp3 = FlowBox(FBAsymp)
asymp4 = FlowBox(FBAsymp)
asymp5 = FlowBox(FBAsymp)

push_f1.Out:SetPush(sinosc_f1.Freq)
push_f2_1.Out:SetPush(sinosc_f2_1.Freq)
push_f2_2.Out:SetPush(sinosc_f2_2.Freq)
push_f3_1.Out:SetPush(sinosc_f3_1.Freq)
push_f3_2.Out:SetPush(sinosc_f3_2.Freq)

push_f1A.Out:SetPush(asymp1.In)
push_f2_1A.Out:SetPush(asymp2.In)
push_f2_2A.Out:SetPush(asymp3.In)
push_f3_1A.Out:SetPush(asymp4.In)
push_f3_2A.Out:SetPush(asymp5.In)

sinosc_f1.Amp:SetPull(asymp1.Out)
sinosc_f2_1.Amp:SetPull(asymp2.Out)
sinosc_f2_2.Amp:SetPull(asymp3.Out)
sinosc_f3_1.Amp:SetPull(asymp4.Out)
sinosc_f3_2.Amp:SetPull(asymp5.Out)

-----------------------------------------
--              Functions              --
-----------------------------------------

function calcF(keynum, octnum)
    local pitchnum = octnum*12+keynum
    local multi = 1;
    while pitchnum > 96 do
        pitchnum = pitchnum - 12
        multi = multi*2
    end

    local pitchharm = allpitch[pitchnum]*multi
    return 12.0/96.0*log(pitchharm/55)/log(2)
end

function calcFharm(keynum, octnum, weight)
    local pitchnum = octnum*12+keynum
    local multi = 1;
    while pitchnum > 95 do
        pitchnum = pitchnum - 12
        multi = multi*2
    end

    local pitchharm = (1-weight)*allpitch[pitchnum]*multi+weight*allpitch[pitchnum+1]*multi
    return 12.0/96.0*log(pitchharm/55)/log(2)
end

function npow2ratio(n)
    local npow=1
    while npow<n do
        npow = npow*2
    end
    return n/npow
end

function switchpage1(self)
    SetPage(1)

    if currentamp == 0 then
        currentamp = .5
    end
    changeSound(0.05)
end

function switchpage2(self)
    SetPage(2)
end


--rounds num to idp places
--e.g. round(122.2245, 2) = 122.22
--and  round(122, -1) = 120
function round(num, idp)
    local mult = 10^(idp or 0)
    local newVal = math.floor(num * mult + 0.5) / mult

    --this part makes sure the rounding in the mapper doesn't go over 255
    if (newVal > 255) then
        newVal = 255
    end
    return newVal
end

--maps x (a value in the range of [min,max])
--to a value in the range of [0,255]
function mapper(x, max, min)
    return round((255*(x-min)/(max-min)),-1)
end

-----------------------------------------
--              Color Page             --
-----------------------------------------

--update amplitude with y accel and weight with x accel
function changeAmpWeight(x, y)
    --local possibleAmp = (1-y/2)
    --local possibleAmp = math.pow((1-y/2),2)*0.4
    local possibleAmp = math.pow((2-y), 2)/10
    local possibleX = 0
    if x < -1 then
        possibleX = 0
    elseif x > 1 then
        possibleX = 0.1
    else
        possibleX = .1*(x)/(2) + 0.05
    end

    if not (currentamp == possibleAmp) or not (possibleX == newx) then
        currentamp = possibleAmp
        newx = possibleX
        changeSound(newx)
    end
end

--updates the color of the big region
function changeColor(self, x, y, z)
    local tex = 0

    x = round(x*3, 0)/3  -- rounds the value to the nearest 1/3
    y = round((y+1)*6, 0)/6 -- rounds the value to the nearest 1/6

    changeAmpWeight(x, y)

    y = mapper(y, 2, 0)


    if (x < -.75) then
        tex = mapper(1+x,.25,0)
        bg.t:SetTexture(255,0,tex,255)
    elseif (x < -.45) then
        tex = mapper(-x,.75,.45)
        bg.t:SetTexture(tex,0,255,255)
    elseif (x < .15) then
        tex = mapper(x+.45,.6,0)
        bg.t:SetTexture(0,tex,255,255)
    elseif (x < .45) then
        tex = mapper(1-x,.85,.55)
        bg.t:SetTexture(0,255,tex,255)
    elseif (x < .75) then
        tex = mapper(x,.75,.45)
        bg.t:SetTexture(tex,255,0,255)
    else
        tex = mapper(1-x,.25,0)
        bg.t:SetTexture(255,tex,0,255)
    end

    --change darkness/brightness
    cover.t:SetTexture(0,0,0,y)
end

-- change sound
function changeSound(weight)
    offset = 0
    key2 = currentkey + 5
    if key2 > 12 then
        offset = 1
        key2 = key2-12
    end

    if currentmode == 1 then
        push_f1:Push(calcF(currentkey, currentoct))
        push_f1A:Push(currentamp)

        push_f2_1A:Push(0)
        push_f2_2A:Push(0)
        push_f3_1A:Push(0)
        push_f3_2A:Push(0)

    elseif currentmode == 2 then
        push_f2_1:Push(calcF(key2, currentoct+1+offset))
        push_f2_2:Push(calcFharm(key2, currentoct+1+offset, weight))

        push_f1A:Push(0)
        push_f2_1A:Push(currentamp)
        push_f2_2A:Push(currentamp)
        push_f3_1A:Push(0)
        push_f3_2A:Push(0)

    elseif currentmode == 3 then
        push_f3_1:Push(calcF(key2, currentoct+2+offset))
        push_f3_2:Push(calcFharm(key2, currentoct+2+offset, weight))
        push_f1A:Push(0)
        push_f2_1A:Push(0)
        push_f2_2A:Push(0)
        push_f3_1A:Push(currentamp)
        push_f3_2A:Push(currentamp)

    else
        push_f1:Push(calcF(currentkey, currentoct))
        push_f2_1:Push(calcF(key2, currentoct+1+offset))
        push_f2_2:Push(calcFharm(key2, currentoct+1+offset, weight))
        push_f3_1:Push(calcF(key2, currentoct+2+offset))
        push_f3_2:Push(calcFharm(key2, currentoct+2+offset, weight))

        push_f1A:Push(currentamp)
        push_f2_1A:Push(currentamp)
        push_f2_2A:Push(currentamp)
        push_f3_1A:Push(currentamp)
        push_f3_2A:Push(currentamp)
    end
end

--Key change
function changeKey(self)
    --check if it comes from the network
    if type(self) == "number" then
        if self == currentidx then return end
        self = key[self]
    else
        sendNote(self.i*10+currentoct)
    end
    key[currentidx].t:SetSolidColor(255,255,255,200)
    key[currentidx].t:SetBlendMode("BLEND")
    self.t:SetSolidColor(255,100,100,200)
    self.t:SetBlendMode("BLEND")
    currentidx = self.i
    currentkey = key_index[currentidx]
    textnote:SetLabel(keyvalue[currentidx]..currentoct)
    textnote:SetColor(0,0,0,255)
    textnote:SetFontHeight(30)

    changeSound(.05)
end

--Octave change
function changeOctave(self)
    --check if it comes from the network
    if type(self) == "number" then
        if self == currentoct then return end
        self = octave[self]
    else
        sendNote(currentidx*10+self.i)
    end
    --for i=1,maxr do
    octave[currentoct].t:SetSolidColor(255,255,255,200)
    octave[currentoct].t:SetBlendMode("BLEND")
    --end
    self.t:SetSolidColor(255,100,100,200)
    self.t:SetBlendMode("BLEND")
    currentoct = self.i
    textnote:SetLabel(keyvalue[currentidx]..currentoct)

    changeSound(.05)
end

--Mode change
function changeMode(self)
    --for i=1,maxr do
    mode[currentmode].t:SetTexture(DocumentPath('buttonoff.png'))
    mode[currentmode].t:SetBlendMode("BLEND")
    --end
    self.t:SetTexture(DocumentPath('buttonon.png'))
    self.t:SetBlendMode("BLEND")
    currentmode = self.i

    changeSound(.05)
end

SetPage(1)
--make screen-covering region
bg = Region()
bg.t = bg:Texture()
bg:Show()
bg.t:SetTexture(255,0,0,255)
bg:SetWidth(ScreenWidth())
bg:SetHeight(ScreenHeight())
--handles the OnAccelerate event to trigger the color change of the region
bg:Handle("OnAccelerate", changeColor)

--region to control darkness/brightness
cover = Region()
cover.t = cover:Texture()
cover:Show()
cover.t:SetTexture(0,0,0,255)
cover:SetWidth(ScreenWidth())
cover:SetHeight(ScreenHeight())
cover.t:SetBlendMode("BLEND")
--handle: swichpage onDoubleTap
cover:Handle("OnDoubleTap",switchpage2)
cover:EnableInput(true)


-----------------------------------------
--            Settings Page            --
-----------------------------------------

--Setting Page
SetPage(2)
bg2 = Region()
bg2.t = bg2:Texture(DocumentPath('bowl.jpg'))
bg2:Show()
bg2:SetWidth(ScreenWidth())
bg2:SetHeight(ScreenHeight())
bg2.t:SetTexCoord(0,npow2ratio(bg2.t:Width()),npow2ratio(bg2.t:Height()),0)
--handle: swichpage onDoubleTap
bg2:Handle("OnDoubleTap",switchpage1)
bg2:EnableInput(true)

--Title
title = Region()
title:SetAnchor("TOPLEFT",bg2,'TOPLEFT')
title:SetWidth(ScreenWidth())
title:SetHeight(0.15*ScreenHeight())
title.t = title:Texture(255,255,255,0)
title.t:SetBlendMode("BLEND")
texttitle = title:TextLabel()
texttitle:SetLabel("Himalayan Singing Bowl")
texttitle:SetColor(255,50,50,255)
texttitle:SetFontHeight(20)
title:Show()

--Current Fundamental Freq
freqdisp = Region()
freqdisp:SetAnchor("TOPLEFT",bg2,'TOPLEFT',0.12*ScreenWidth(),-0.18*ScreenHeight())
freqdisp:SetWidth(0.4*ScreenWidth())
freqdisp:SetHeight(0.12*ScreenHeight())
freqdisp.t = freqdisp:Texture(255,255,255,200)
freqdisp.t:SetBlendMode("BLEND")
textfreq = freqdisp:TextLabel()
textfreq:SetLabel("Fundamental")
textfreq:SetColor(0,0,0,255)
textfreq:SetFontHeight(18)
freqdisp:Show()

--Note
note = Region()
note:SetAnchor("TOPLEFT",bg2,'TOPLEFT',0.56*ScreenWidth(),-0.18*ScreenHeight())
note:SetWidth(0.3*ScreenWidth())
note:SetHeight(0.12*ScreenHeight())
note.t = note:Texture(255,255,255,200)
note.t:SetBlendMode("BLEND")
textnote = note:TextLabel()
textnote:SetLabel("C3")
textnote:SetColor(0,0,0,255)
textnote:SetFontHeight(30)
note:Show()

--keyname
key = {}
textkey = {}
keyvalue = {"C","D","E","F","G","A","B"}
currentkey = 1
currentidx = 1
local maxr = 7
for i=1,maxr do
    key[i] = Region()
    key[i].i = i
    key[i]:SetAnchor("TOPLEFT",bg2,'TOPLEFT',0.13*ScreenWidth()*i-0.08*ScreenWidth(),-0.35*ScreenHeight())
    key[i]:SetWidth(0.12*ScreenWidth())
    key[i]:SetHeight(0.12*ScreenWidth())
    key[i].t = key[i]:Texture(255,255,255,200)
    key[i].t:SetBlendMode("BLEND")
    textkey[i] = key[i]:TextLabel()
    textkey[i]:SetLabel(keyvalue[i])
    textkey[i]:SetColor(0,0,0,255)
    textkey[i]:SetFontHeight(24)
    key[i]:Show()
    key[i]:Handle("OnTouchDown",changeKey)
    key[i]:EnableInput(true)
end

--octave
octave = {}
textoct = {}
octvalue = {"1","2","3"}
currentoct = 3
maxr = 3
for i=1,maxr do
    octave[i] = Region()
    octave[i].i = i
    octave[i]:SetAnchor("TOPLEFT",bg2,'TOPLEFT',0.22*ScreenWidth()*i,-0.45*ScreenHeight())
    octave[i]:SetWidth(0.12*ScreenWidth())
    octave[i]:SetHeight(0.12*ScreenWidth())
    octave[i].t = octave[i]:Texture(255,255,255,200)
    octave[i].t:SetBlendMode("BLEND")
    textoct[i] = octave[i]:TextLabel()
    textoct[i]:SetLabel(octvalue[i])
    textoct[i]:SetColor(0,0,0,255)
    textoct[i]:SetFontHeight(24)
    octave[i]:Show()
    octave[i]:Handle("OnTouchDown",changeOctave)
    octave[i]:EnableInput(true)
end


--mode tag
tag = {}
texttag = {}
tagvalue = {"F1","F2","F3","All"}
maxr = 4
for i=1,maxr do
    tag[i] = Region()
    tag[i]:SetAnchor("TOPLEFT",bg2,'TOPLEFT',0.22*ScreenWidth()*i-0.12*ScreenWidth(),-0.6*ScreenHeight())
    tag[i]:SetWidth(0.15*ScreenWidth())
    tag[i]:SetHeight(0.15*ScreenWidth())
    tag[i].t = tag[i]:Texture(255,255,255,0)
    tag[i].t:SetBlendMode("BLEND")
    texttag[i] = tag[i]:TextLabel()
    texttag[i]:SetLabel(tagvalue[i])
    texttag[i]:SetColor(255,255,255,255)
    texttag[i]:SetFontHeight(24)
    tag[i]:Show()
    tag[i]:EnableInput(true)
end

--mode
mode = {}
currentmode = 1
maxr = 4
for i=1,maxr do
    mode[i] = Region()
    mode[i].i = i
    mode[i]:SetAnchor("TOPLEFT",bg2,'TOPLEFT',0.22*ScreenWidth()*i-0.12*ScreenWidth(),-0.7*ScreenHeight())
    mode[i]:SetWidth(0.15*ScreenWidth())
    mode[i]:SetHeight(0.15*ScreenWidth())
    mode[i].t = mode[i]:Texture(DocumentPath('buttonoff.png'))
    mode[i].t:SetBlendMode("BLEND")
    mode[i]:Show()
    mode[i]:Handle("OnTouchDown",changeMode)
    mode[i]:EnableInput(true)
end


currentidx = 2
currentoct = 2

--final setup
changeKey(1)
changeOctave(3)
changeMode(mode[1])

dac.In:SetPull(sinosc_f1.Out)
dac.In:SetPull(sinosc_f2_1.Out)
dac.In:SetPull(sinosc_f2_2.Out)
dac.In:SetPull(sinosc_f3_1.Out)
dac.In:SetPull(sinosc_f3_2.Out)


-----------------------------------------
--             Networking              --
-----------------------------------------


local myIP, myPort = HTTPServer()

friends = {}

-- endPoint is the position of the "third point" at an IP: 10.1.100.2 has 9 as endPoint
-- this method can be improved
endPoint = string.find(myIP, '.', string.find(myIP, '.',string.find(myIP, '.',1, true)+1, true)+1, true)
local ownId = tonumber(string.sub(myIP, endPoint+1))

local function NewConnection(self, name)
    table.insert(friends, name)
end

local function LostConnection(self, name)
    for k,v in pairs(friends) do
        if v == name then
            table.remove(friends,k)
        end
    end
end

function sendNote(noteToSend)
    for indexIp = 1, table.getn(friends) do
        ip = friends[indexIp]
        SendOSCMessage(ip,8888,"/urMus/numbers",noteToSend, ownId)
    end
end

function gotOSC(self, noteReceived, senderId)
    if senderId ~= ownId then
        local newOctave = noteReceived % 10
        local newKey = (noteReceived-newOctave)/10
        if newKey ~= currentidx then changeKey(newKey) end
        if newOctave ~= currentoct then changeOctave(newOctave) end
    end
end


bg:Handle("OnNetConnect", NewConnection)
bg2:Handle("OnNetConnect", NewConnection)

bg:Handle("OnNetDisconnect", LostConnection)
bg2:Handle("OnNetDisconnect", LostConnection)

StartNetAdvertise("singingbowls",8889)
StartNetDiscovery("singingbowls")

bg:Handle("OnOSCMessage",gotOSC)
bg2:Handle("OnOSCMessage",gotOSC)

SetOSCPort(8888)
host, port = StartOSCListener()



