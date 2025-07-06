---@class VEMLogger
---@diagnostic disable-next-line: assign-type-mismatch
VEMLogger = class "VEMLogger"

function VEMLogger:__init(p_ClassName, p_ActivateLogging)
	if type(p_ClassName) ~= "string" then
		error("VEMLogger: Wrong arguments creating object, className is not a string. ClassName: " ..
		tostring(p_ClassName))
		return
	elseif type(p_ActivateLogging) ~= "boolean" then
		error("VEMLogger: Wrong arguments creating object, ActivateLogging is not a boolean. ActivateLogging: " ..
			tostring(p_ActivateLogging))
		return
	end

	-- print("Creating object with: "..p_ClassName..", "..tostring(p_ActivateLogging))
	self.debug = p_ActivateLogging
	self.className = p_ClassName
end

function VEMLogger:Write(p_Message)
	if not VEM_CONFIG.VEMLogger_ENABLED then
		return
	end

	if VEM_CONFIG.VEMLogger_PRINT_ALL == true and self.className ~= nil then
		goto continue
	elseif self.debug == false or
		self.debug == nil or
		self.className == nil then
		return
	end

	::continue::

	print("[" .. self.className .. "] " .. tostring(p_Message))
end

function VEMLogger:WriteTable(p_Table)
	if not VEM_CONFIG.VEMLogger_ENABLED then
		return
	end

	if VEM_CONFIG.VEMLogger_PRINT_ALL == true and self.className ~= nil then
		goto continue
	elseif self.debug == false or
		self.debug == nil or
		self.className == nil then
		return
	end

	::continue::

	print("[" .. self.className .. "] Table:")
	print(p_Table)
end

function VEMLogger:Warning(p_Message)
	if self.className == nil then
		return
	end

	print("[" .. self.className .. "] WARNING: " .. tostring(p_Message))
end

function VEMLogger:Error(p_Message)
	if self.className == nil then
		return
	end

	error("[" .. self.className .. "] " .. tostring(p_Message))
end

return VEMLogger
