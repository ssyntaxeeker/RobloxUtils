local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local PlayerGui = localPlayer:WaitForChild("PlayerGui")

local InventoryUI = PlayerGui:WaitForChild("Inventory")
local ScrollingFrame = InventoryUI.Main.ScrollingFrame
local ItemTemplate = ScrollingFrame.ItemTemplate

local Inventory = {}
Inventory.__index = Inventory

Inventory.ItemData = {
	Sword = {Weight = 5},
	Potion = {Weight = 1},
	Apple = {Weight = 1},
	Gem = {Weight = 2},
}


function Inventory.new()
	local self = setmetatable({}, Inventory)

	self.items = {} -- a mapping of the items = item quantty
	self.selected = nil -- just keeping a selected variable for things like selection states

	return self
end

function Inventory:HasItem(itemName)
	return self.items[itemName] ~= nil
end

function Inventory:AddItem(itemName, amount)
	amount = amount or 1 -- if no amount passed then set it to 1

	self.items[itemName] = (self.items[itemName] or 0) + amount -- add amount to the item quantity (and if there's no item quantity yet then add amount to 0)
	self:RefreshUI() -- refresh the UI to show the new quantity
end

function Inventory:RemoveItem(itemName, amount)
	local current = self.items[itemName]
	if not current then return end -- if there's no item then there's nothing to remove

	self.items[itemName] = current - amount
	
	if self.items[itemName] <= 0 then -- if there's <= 0 of the item then remove it from inventory
		self.items[itemName] = nil

		if self.selected == itemName then -- clear the selection incase we had that item selected
			self.selected = nil
		end
	end

	self:RefreshUI() -- same old refresh to show changes lol
end

-- these next 3 functions r self-explanatory i believe

function Inventory:Clear() 
	table.clear(self.items)
	self.selected = nil
	
	self:RefreshUI()
end

function Inventory:GetWeight() -- overall just a debug for future purposes. calculates the "weight" of ur inventory based on the data at the top of the script
	local total = 0
	
	for itemName, amount in self.items do
		local data = self.ItemData[itemName]
		if data then
			total += data.Weight * amount
		end
	end
	
	return total
end

function Inventory:SelectItem(itemName)
	self.selected = itemName
	
	self:RefreshUI()
end

function Inventory:Unselect()
	self.selected = nil
	
	self:RefreshUI()
end

function Inventory:RefreshUI()
	for _, child in ScrollingFrame:GetChildren() do
		if not child:IsA("Frame") or child.Name == "ItemTemplate" then continue end -- cause there's things we dont wanna remove like the template for example
		
		child:Destroy()
	end
	
	print("Weight:", self:GetWeight())
	
	local layoutIndex = 0

	for itemName, count in self.items do -- creating a slot for each item in the player's inventory
		local slot = ItemTemplate:Clone()
		slot.Visible = true -- the template wasnt visible before so..
		slot.Name = itemName
		slot.LayoutOrder = layoutIndex
		layoutIndex += 1

		local label = slot:FindFirstChild("TextLabel")
		if label then
			local displayName = itemName:match("^(.-)#%d+$") or itemName -- what this does is basically remove the "#d+"(d+ is any number) part if it exists
			label.Text = displayName .. " x" .. count
		end

		local hint = Instance.new("TextLabel")
		hint.Text = "[Shift+Click] Split"
		hint.Size = UDim2.new(1, 0, 0, 12)
		hint.Position = UDim2.new(0, 0, 1, -12) 
		hint.BackgroundTransparency = 1
		hint.TextColor3 = Color3.fromRGB(200, 200, 200)
		hint.Font = Enum.Font.GothamBold
		hint.TextSize = 10
		hint.ZIndex = 2 -- to be on top of the item slot ofc
		hint.Parent = slot

		local function onHoverStart()
			TweenService:Create(slot, TweenInfo.new(0.15), {
				Size = UDim2.new(0, 105, 0, 105),
				BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			}):Play()
		end

		local function onHoverEnd()
			local isSelected = (self.selected == itemName)
			TweenService:Create(slot, TweenInfo.new(0.15), {
				Size = UDim2.new(0, 100, 0, 100),
				BackgroundColor3 = isSelected
					and Color3.fromRGB(100, 100, 150)
					or Color3.fromRGB(50, 50, 50)
			}):Play()
		end

		local function onClick(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

				if shiftHeld then -- splitting stack
					local total = self.items[itemName]
					if total and total > 1 then
						local half = math.floor(total / 2) -- flooring it to get a whole number so that it doesn't get floats
						self.items[itemName] = total - half

						local base = itemName:match("^(.-)#%d+$") or itemName -- once again removing the "#d+" part of the name since now the number is gonna be different for the new item
						local newKey = base
						local suffix = 1

						while self.items[newKey] do -- basically gonna keep checking keys until we find one that doesnt exist. like Apple#1, Apple#2, until Apple#N doesn't exist in the inventory yet
							suffix += 1
							newKey = base .. "#" .. suffix 
						end


						self.items[newKey] = half

						self:RefreshUI() -- re-render it all
						return
					end
				end

				-- if shift isnt held so we're not splitting then just toggle selection
				if self.selected == itemName then
					self:Unselect()
				else
					self:SelectItem(itemName)
				end

			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then 
				Inventory:RemoveItem(itemName, 1) -- pretty self explanatory, if u right click u lose 1 item. for testing purposes basically
			end
		end

		slot.MouseEnter:Connect(onHoverStart)
		slot.MouseLeave:Connect(onHoverEnd)
		slot.InputBegan:Connect(onClick)
		
		-- this is just to set the default size, color and possible stroke (if selected)
		if self.selected == itemName then 
			slot.Size = UDim2.new(0, 105, 0, 105)
			slot.BackgroundColor3 = Color3.fromRGB(100, 100, 150)

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(170, 170, 255)
			stroke.Thickness = 2
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = slot
		else
			slot.Size = UDim2.new(0, 100, 0, 100)
			slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		end

		slot.Parent = ScrollingFrame
	end

	local total = layoutIndex
	local slotHeight = 100
	local spacing = 10
	local padding = 10
	
	local totalHeight = (slotHeight + spacing) * total + padding -- for each slot we're adding slotHeight + spacing and at the end we add +padding
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight) -- setting the frame's "real"(canvas) size to the totalheight
end

local playerInventory = Inventory.new() -- creating the player's inventory finally

local inventoryVisible = false 

local function toggleInventory()
	inventoryVisible = not inventoryVisible 
	InventoryUI.Enabled = true 

	local newPos = inventoryVisible
		and UDim2.new(0.5, 0, 0.5, 0)
		or UDim2.new(0.5, 0, -1, 0)

	TweenService:Create(InventoryUI.Main, TweenInfo.new(0.3), {
		Position = newPos
	}):Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- just so u dont open the inventory accidentally when typing

	if input.KeyCode == Enum.KeyCode.E then
		toggleInventory() -- toggle inv on "E"
	end
end)

local function SpawnTestItem(name, position)
	local itemPart = Instance.new("Part")
	itemPart.Name = name
	itemPart.Size = Vector3.new(2, 2, 2)
	itemPart.Position = position
	itemPart.Anchored = true 
	itemPart.CanCollide = true
	itemPart.Parent = workspace
	-- itemPart is just gonna be a base for the prompt dw abt it
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = name 
	prompt.ActionText = "Pick up " .. name 
	prompt.KeyboardKeyCode = Enum.KeyCode.Q 
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10 
	prompt.Parent = itemPart

	prompt.Triggered:Connect(function()
		local randomAmount = math.random(1, 3)
		
		playerInventory:AddItem(name, randomAmount)
	end)
end

local function SpawnAllDemos()
	local startPos = Vector3.new(0, 3, 0)
	local spacing = 6 
	local itemNames = {
		"Sword", "Potion", "Gem", "Apple"
	}

	for i, name in itemNames do
		local offset = Vector3.new((i - 1) * spacing, 0, 0) -- simple formula to offset the item spawn position so its not always on the same coordinates. they're 6 studs apart due to teh spacing variable
		SpawnTestItem(name, startPos + offset)
	end
end

SpawnAllDemos()

print("[Inventory] Ready to use")
