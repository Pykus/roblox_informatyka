local TweenService=game:GetService("TweenService")
local Rules=require(script.Parent:WaitForChild("FutureSystemsRules"))
local FutureSystemsCity={}
local C={floor=Color3.fromRGB(30,38,45),dark=Color3.fromRGB(18,23,29),blue=Color3.fromRGB(66,155,234),green=Color3.fromRGB(67,218,121),yellow=Color3.fromRGB(242,190,61),purple=Color3.fromRGB(146,95,224),red=Color3.fromRGB(232,76,78),white=Color3.fromRGB(248,250,252)}
local function part(parent,name,size,pos,color,mat) local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos;p.Color=color;p.Material=mat or Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p end
local function label(target,text,face,minSize) local g=Instance.new("SurfaceGui");g.Face=face or Enum.NormalId.Front;g.LightInfluence=0;g.Brightness=1.2;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=34;g.Parent=target;local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=C.white;t.TextStrokeColor3=Color3.new();t.TextStrokeTransparency=.38;t.TextWrapped=true;t.TextScaled=true;t.Font=Enum.Font.GothamBold;t.Parent=g;local l=Instance.new("UITextSizeConstraint");l.MinTextSize=minSize or 18;l.MaxTextSize=32;l.Parent=t;return t end
local function prompt(target,action,obj,cb) local p=Instance.new("ProximityPrompt");p.ActionText=action;p.ObjectText=obj;p.MaxActivationDistance=12;p.RequiresLineOfSight=false;p.HoldDuration=.08;p.Parent=target;p.Triggered:Connect(cb);return p end
local function message(ctx,text,good) ctx.remote:FireClient(ctx.player,{kind="message",text=text,good=good}) end
local function hud(ctx,obj) ctx.state.objective=obj;ctx.remote:FireClient(ctx.player,{kind="hud",title=ctx.mission.name or ctx.lesson.topic,objective=obj,score=ctx.state.score}) end
function FutureSystemsCity.Run(model,origin,player,lesson,mission,remote,state,accent)
	local ctx={player=player,lesson=lesson,mission=mission,remote=remote,state=state,rules=Rules.NewState(),zones={}}
	part(model,"FutureCityFloor",Vector3.new(88,1,80),origin+Vector3.new(0,-.5,-5),C.floor,Enum.Material.Concrete)
	local sign=part(model,"FutureCitySign",Vector3.new(44,7,1),origin+Vector3.new(0,14,-42),C.blue,Enum.Material.Neon);label(sign,"FUTURE SYSTEMS CITY 2035\ntechnologia + prywatność + człowiek",Enum.NormalId.Front,19)
	local defs={
		{key="work",name="FutureWorkRobot",sem="robot",pos=Vector3.new(-25,5,-18),color=C.blue,text="WORK\nrobot wspiera pracę"},
		{key="home",name="FutureHomeTablet",sem="tablet",pos=Vector3.new(0,5,-18),color=C.yellow,text="HOME\nsmart sterowanie"},
		{key="city",name="FutureCityDrone",sem="drone",pos=Vector3.new(25,6,-18),color=C.purple,text="CITY\ndron monitoruje infrastrukturę"},
	}
	for _,d in ipairs(defs) do
		local zone=part(model,"FutureZone_"..d.key,Vector3.new(20,1,20),origin+Vector3.new(d.pos.X,.5,-18),C.dark,Enum.Material.Metal);ctx.zones[d.key]=zone;label(zone,string.upper(d.key),Enum.NormalId.Top,18)
		local device=part(model,d.name,Vector3.new(9,8,8),origin+d.pos,d.color,Enum.Material.Metal);device:SetAttribute("Important3DPlaceholder",true);label(device,d.text,Enum.NormalId.Front,16)
		prompt(device,"PODŁĄCZ SYSTEM","STREFA "..string.upper(d.key),function(tp)
			if tp~=player then return end
			local ok,res=Rules.Apply(ctx.rules,"system",d.key)
			if ok then ctx.state.score+=18;zone.Color=C.green;zone.Material=Enum.Material.Neon else ctx.state.score=math.max(0,ctx.state.score-3) end
			message(ctx,res.message,ok)
			hud(ctx,ctx.rules.stage==1 and "ETAP 1/3 • Uruchom WORK, HOME i CITY." or "ETAP 1/3 • Zabezpiecz dane i dodaj nadzór człowieka.")
		end)
	end
	local privacy=part(model,"FuturePrivacyControl",Vector3.new(12,5,8),origin+Vector3.new(-15,2.5,17),C.yellow,Enum.Material.Metal);privacy:SetAttribute("Important3DPlaceholder",true);label(privacy,"PRYWATNOŚĆ\nminimum danych",Enum.NormalId.Top,16)
	local human=part(model,"FutureHumanConsole",Vector3.new(12,7,8),origin+Vector3.new(0,3.5,17),C.dark,Enum.Material.Metal);human:SetAttribute("Important3DPlaceholder",true);label(human,"CZŁOWIEK\nSTOP / DECYZJA",Enum.NormalId.Front,16)
	local sim=part(model,"FutureSimulationConsole",Vector3.new(12,7,8),origin+Vector3.new(18,3.5,17),C.dark,Enum.Material.Metal);sim:SetAttribute("Important3DPlaceholder",true);local simText=label(sim,"SYMULUJ\nDZIEŃ 2035",Enum.NormalId.Front,17)
	local function act(action)
		local ok,res=Rules.Apply(ctx.rules,action)
		if ok then ctx.state.score+=18 else ctx.state.score=math.max(0,ctx.state.score-3) end
		message(ctx,res.message,ok)
		if action=="privacy" and ok then privacy.Color=C.green;privacy.Material=Enum.Material.Neon
		elseif action=="human" and ok then human.Color=C.green;human.Material=Enum.Material.Neon
		elseif action=="simulate" and ok and res.completed then
			ctx.state.done=true;ctx.state.score+=75;sim.Color=C.green;sim.Material=Enum.Material.Neon;simText.Text=string.format("CITY ONLINE\n%d%%",Rules.Efficiency(ctx.rules));sign.Color=C.green
			for _,z in pairs(ctx.zones) do TweenService:Create(z,TweenInfo.new(.35),{Color=C.green}):Play() end
		end
		if ctx.rules.completed then hud(ctx,"ETAP 2/3 • Future Systems City działa. Przejdź do RDZENIA MISJI.")
		elseif ctx.rules.stage==1 then hud(ctx,"ETAP 1/3 • Uruchom wszystkie 3 systemy.")
		elseif not ctx.rules.privacy then hud(ctx,"ETAP 1/3 • Włącz minimalizację danych i prywatność.")
		elseif not ctx.rules.humanControl then hud(ctx,"ETAP 1/3 • Dodaj kontrolę człowieka i możliwość STOP.")
		else hud(ctx,"ETAP 1/3 • Uruchom symulację dnia 2035.") end
	end
	prompt(privacy,"WŁĄCZ","PRYWATNOŚĆ",function(tp) if tp==player then act("privacy") end end)
	prompt(human,"AKTYWUJ","NADZÓR CZŁOWIEKA",function(tp) if tp==player then act("human") end end)
	prompt(sim,"SYMULUJ","DZIEŃ 2035",function(tp) if tp==player then act("simulate") end end)
	hud(ctx,"ETAP 1/3 • ZACZNIJ: podłącz technologię w strefie WORK.")
	return ctx
end
return FutureSystemsCity
