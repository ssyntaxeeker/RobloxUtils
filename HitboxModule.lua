local function AngleBetween(vectorA, vectorB)
	return math.deg(math.acos(math.clamp(vectorA:Dot(vectorB), -1, 1)))
end

local HumanoidsDirectory = workspace

return function(Character : Model, MaxFieldOfView : Number, Range : Number)  
	local TargetsTable = {}
	local HRP = Character.HumanoidRootPart
	
	Range, MaxFieldOfView = Range or 3, MaxFieldOfView or 50

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {Character}

	for _,eCharacter in HumanoidsDirectory:GetChildren() do
		if eCharacter.Humanoid.Health <= 0 or eCharacter == Character then continue end
		local eHRP = eCharacter.HumanoidRootPart
		
		if AngleBetween(HRP.CFrame.LookVector, (eHRP.Position - HRP.CFrame.Position).unit) > MaxFieldOfView then continue end
		
		local ray = workspace:Raycast(HRP.CFrame.Position,-(HRP.CFrame.Position - eHRP.Position).unit 
			* (HRP.CFrame.Position - eHRP.Position).magnitude, params)

		if not ray or (ray.Instance.Position - eHRP.Position).Magnitude > 1.5 then continue end
		if (HRP.Position - eHRP.Position).Magnitude > Range then continue end

		table.insert(TargetsTable, eCharacter)                  
	end

	return TargetsTable
end
