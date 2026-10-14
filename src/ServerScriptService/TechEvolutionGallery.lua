local Rules = require(script.Parent:WaitForChild("TechEvolutionRules"))
local TechEvolutionGallery = {}

local C={floor=Color3.fromRGB(54,48,43),wall=Color3.fromRGB(87,77,65),dark=Color3.fromRGB(27,27,29),gold=Color3.fromRGB(225,179,70),blue=Color3.fromRGB(66,147,224),green=Color3.fromRGB(68,212,119),red=Color3.fromRGB(230,75,75),white=Color3.fromRGB(248,247,243),purple=Color3.fromRGB(147,93,217)}

local function part(parent,name,size,pos,color,material)
	local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function label(target,text,face,minSize)
	local gui=Instance.new("SurfaceGui");gui.Face=face or Enum.NormalId.Front;gui.LightInfluence=0;gui.Brightness=1.2;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=34;gui.Parent=target
	local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=C.white;t.TextStrokeColor3=Color3.new();t.TextStrokeTransparency=.38;t.TextWrapped=true;t.TextScaled=true;t.Font=Enum.Font.GothamBold;t.Parent=gui
	local lim=Instance.new("UITextSizeConstraint");lim.MinTextSize=minSize or 18;lim.MaxTextSize=32;lim.Parent=t;return t
end
local function prompt(target,action,obj,cb)
	local p=Instance.new("ProximityPrompt");p.ActionText=action;p.ObjectText=obj;p.MaxActivationDistance=12;p.RequiresLineOfSight=false;p.HoldDuration=.08;p.Parent=target;p.Triggered:Connect(cb);return p
end
local function message(ctx,text,good) ctx.remote:FireClient(ctx.player,{kind="message",text=text,good=good}) end
local function hud(ctx,obj) ctx.state.objective=obj;ctx.remote:FireClient(ctx.player,{kind="hud",title=ctx.mission.name or ctx.lesson.topic,objective=obj,score=ctx.state.score}) end

function TechEvolutionGallery.Run(model,origin,player,lesson,mission,remote,state,accent)
	local ctx={player=player,lesson=lesson,mission=mission,remote=remote,state=state,rules=Rules.NewState(),slots={}}
	part(model,"TechEvolutionFloor",Vector3.new(86,1,76),origin+Vector3.new(0,-.5,-7),C.floor,Enum.Material.WoodPlanks)
	part(model,"TechEvolutionBackWall",Vector3.new(86,20,2),origin+Vector3.new(0,10,-45),C.wall,Enum.Material.Brick)
	local sign=part(model,"TechEvolutionSign",Vector3.new(44,7,1),origin+Vector3.new(0,14,-43.8),C.gold,Enum.Material.Neon);label(sign,"TECH EVOLUTION GALLERY\nmainframe → PC → internet → mobile/AI",Enum.NormalId.Front,19)
	local archive=part(model,"TechEvolutionArchiveShelf",Vector3.new(66,10,5),origin+Vector3.new(0,5,-31),C.dark,Enum.Material.Metal);archive:SetAttribute("Important3DPlaceholder",true)

	local defs={
		{key="mainframe",name="TechEvolutionArtifact_Mainframe",sem="serverRack",x=-27,text="MAINFRAME"},
		{key="pc",name="TechEvolutionArtifact_PC",sem="desktop",x=-9,text="PC"},
		{key="internet",name="TechEvolutionArtifact_Internet",sem="router",x=9,text="INTERNET"},
		{key="mobile_ai",name="TechEvolutionArtifact_MobileAI",sem="phone",x=27,text="MOBILE + AI"},
	}
	for i,d in ipairs(defs) do
		local a=part(model,d.name,Vector3.new(10,8,7),origin+Vector3.new(d.x,6,-30),i==1 and C.gold or C.blue,Enum.Material.Metal);a:SetAttribute("Important3DPlaceholder",true);label(a,d.text,Enum.NormalId.Front,16)
		local slot=part(model,"TechEvolutionTimelineSlot_"..i,Vector3.new(13,3,10),origin+Vector3.new(-27+(i-1)*18,1.5,-7),C.dark,Enum.Material.Metal);ctx.slots[i]=slot;label(slot,tostring(i),Enum.NormalId.Top,18)
		prompt(a,"UMIEŚĆ NA OSI",d.text,function(tp)
			if tp~=player then return end
			local ok,res=Rules.Apply(ctx.rules,"era",d.key)
			if ok then ctx.state.score+=16;slot.Color=C.green;slot.Material=Enum.Material.Neon else ctx.state.score=math.max(0,ctx.state.score-3) end
			message(ctx,res.message,ok)
			hud(ctx,ctx.rules.stage==1 and "ETAP 1/3 • Ułóż 4 epoki od mainframe do mobile/AI." or "ETAP 1/3 • Połącz 3 przełomy z ich skutkami.")
		end)
	end

	local links={
		{key="internet_network",text="INTERNET → SIEĆ",x=-18},
		{key="mobile_everywhere",text="MOBILE → WSZĘDZIE",x=0},
		{key="ai_assist",text="AI → WSPARCIE",x=18},
	}
	for _,d in ipairs(links) do
		local b=part(model,"TechEvolutionLinkControl_"..d.key,Vector3.new(12,4,8),origin+Vector3.new(d.x,2,20),C.purple,Enum.Material.Metal);b:SetAttribute("Important3DPlaceholder",true);label(b,d.text,Enum.NormalId.Top,16)
		prompt(b,"POŁĄCZ",d.text,function(tp)
			if tp~=player then return end
			local ok,res=Rules.Apply(ctx.rules,"link",d.key)
			if ok then ctx.state.score+=18;b.Color=C.green;b.Material=Enum.Material.Neon else ctx.state.score=math.max(0,ctx.state.score-3) end
			if ok and res.completed then ctx.state.done=true;ctx.state.score+=75;sign.Color=C.green end
			message(ctx,res.message,ok)
			hud(ctx,ctx.rules.completed and "ETAP 2/3 • Oś rozwoju działa. Przejdź do RDZENIA MISJI." or "ETAP 1/3 • Połącz internet, mobilność i AI z właściwym skutkiem.")
		end)
	end
	hud(ctx,"ETAP 1/3 • ZACZNIJ: umieść MAINFRAME jako pierwszą epokę osi.")
	return ctx
end
return TechEvolutionGallery
