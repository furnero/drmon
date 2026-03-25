local reactor = "back"
local outputFluxGate = "flow_gate_0"
local inputFluxGate = "flow_gate_1"

local targetStrength = 30
local maxTemperature = 8000
local safeTemperature = 4000
local lowestFieldPercent = 12

local activateOnCharged = 1

os.loadAPI("lib/f.lua")

local version = "0.3"
local autoInputGate = 1
local curInputGate = 222000

local mon, monitor, monX, monY
local ri

local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

monitor = f.periphSearch("monitor")
inputFluxGate = peripheral.wrap(inputFluxGate)
outputFluxGate = peripheral.wrap(outputFluxGate)
reactor = peripheral.wrap(reactor)

if monitor == nil then
error("No valid monitor was found")
end

if outputFluxGate == nil then
error("No valid fluxgate for output was found")
end

if reactor == nil then
error("No valid reactor was found")
end

if inputFluxGate == nil then
error("No valid fluxgate for input was found")
end

monX, monY = monitor.getSize()
mon = {}
mon.monitor, mon.X, mon.Y = monitor, monX, monY

function save_config()
sw = fs.open("config.txt", "w")
sw.writeLine(version)
sw.writeLine(autoInputGate)
sw.writeLine(curInputGate)
sw.close()
end

function load_config()
sr = fs.open("config.txt", "r")
version = sr.readLine()
autoInputGate = tonumber(sr.readLine())
curInputGate = tonumber(sr.readLine())
sr.close()
end

if fs.exists("config.txt") == false then
save_config()
else
load_config()
end

local event, side, xPos, yPos

function buttons()
while true do
event, side, xPos, yPos = os.pullEvent("monitor_touch")

if yPos == 8 then
local cFlow = outputFluxGate.getSignalLowFlow()
if xPos >= 2 and xPos <= 4 then
cFlow = cFlow - 1000
elseif xPos >= 6 and xPos <= 9 then
cFlow = cFlow - 10000
elseif xPos >= 10 and xPos <= 12 then
cFlow = cFlow - 100000
elseif xPos >= 17 and xPos <= 19 then
cFlow = cFlow + 100000
elseif xPos >= 21 and xPos <= 23 then
cFlow = cFlow + 10000
elseif xPos >= 25 and xPos <= 27 then
cFlow = cFlow + 1000
end
outputFluxGate.setSignalLowFlow(cFlow)
end

if yPos == 10 and autoInputGate == 0 and xPos ~= 14 and xPos ~= 15 then
if xPos >= 2 and xPos <= 4 then
curInputGate = curInputGate - 1000
elseif xPos >= 6 and xPos <= 9 then
curInputGate = curInputGate - 10000
elseif xPos >= 10 and xPos <= 12 then
curInputGate = curInputGate - 100000
elseif xPos >= 17 and xPos <= 19 then
curInputGate = curInputGate + 100000
elseif xPos >= 21 and xPos <= 23 then
curInputGate = curInputGate + 10000
elseif xPos >= 25 and xPos <= 27 then
curInputGate = curInputGate + 1000
end
inputFluxGate.setSignalLowFlow(curInputGate)
save_config()
end

if yPos == 10 and (xPos == 14 or xPos == 15) then
if autoInputGate == 1 then
autoInputGate = 0
else
autoInputGate = 1
end
save_config()
end
end
end

function drawButtons(y)
f.draw_text(mon, 2, y, " < ", colors.white, colors.gray)
f.draw_text(mon, 6, y, " <<", colors.white, colors.gray)
f.draw_text(mon, 10, y, "<<<", colors.white, colors.gray)

f.draw_text(mon, 17, y, ">>>", colors.white, colors.gray)
f.draw_text(mon, 21, y, ">> ", colors.white, colors.gray)
f.draw_text(mon, 25, y, " > ", colors.white, colors.gray)
end

function update()
while true do
ri = reactor.getReactorInfo()

if ri == nil then
error("reactor has an invalid setup")
end

local inputRate = inputFluxGate.getSignalLowFlow()
local outputRate = outputFluxGate.getSignalLowFlow()
local netGeneration = ri.generationRate - inputRate

for k, v in pairs(ri) do
print(k .. ": " .. tostring(v))
end
print("Output Gate: ", outputRate)
print("Input Gate: ", inputRate)
print("Net Generation: ", netGeneration)

local statusColor = colors.red

if ri.status == "running" then
statusColor = colors.green
elseif ri.status == "cold" then
statusColor = colors.gray
elseif ri.status == "warming_up" then
statusColor = colors.orange
end

f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)
f.draw_text_lr(mon, 2, 4, 1, "Net Output", f.format_int(netGeneration) .. " rf/t", colors.white, colors.lime, colors.black)

local tempColor = colors.red
if ri.temperature <= 5000 then tempColor = colors.green end
if ri.temperature >= 5000 and ri.temperature <= 6500 then tempColor = colors.orange end
f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(ri.temperature) .. "C", colors.white, tempColor, colors.black)

f.draw_text_lr(mon, 2, 7, 1, "Output Gate", f.format_int(outputRate) .. " rf/t", colors.white, colors.blue, colors.black)

drawButtons(8)

f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputRate) .. " rf/t", colors.white, colors.blue, colors.black)

if autoInputGate == 1 then
f.draw_text(mon, 14, 10, "AU", colors.white, colors.gray)
else
f.draw_text(mon, 14, 10, "MA", colors.white, colors.gray)
drawButtons(10)
end

local satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000) * .01

f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercent .. "%", colors.white, colors.white, colors.black)
f.progress_bar(mon, 2, 12, mon.X - 2, satPercent, 100, colors.blue, colors.gray)

local fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000) * .01
local fieldColor = colors.red

if fieldPercent >= 50 then fieldColor = colors.green end
if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end

if autoInputGate == 1 then
f.draw_text_lr(mon, 2, 14, 1, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
else
f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
end
f.progress_bar(mon, 2, 15, mon.X - 2, fieldPercent, 100, fieldColor, colors.gray)

local fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000) * .01
local fuelColor = colors.red
if fuelPercent >= 70 then fuelColor = colors.green end
if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end

f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
f.progress_bar(mon, 2, 18, mon.X - 2, fuelPercent, 100, fuelColor, colors.gray)

f.draw_text_lr(mon, 2, 19, 1, "Action ", action, colors.gray, colors.gray, colors.black)

if emergencyCharge == true then
reactor.chargeReactor()
end

if ri.status == "warming_up" then
inputFluxGate.setSignalLowFlow(900000)
emergencyCharge = false
end

if emergencyTemp == true and ri.status == "stopping" and ri.temperature < safeTemperature then
reactor.activateReactor()
emergencyTemp = false
end

local activate = ri.status == "warming_up" and activateOnCharged == 1 and fieldPercent >= 50 and satPercent >= 50 and ri.temperature >= 2000 and ri.temperature <= 2005
if activate then
reactor.activateReactor()
end

if ri.status == "running" then
if autoInputGate == 1 then
local fluxval = ri.fieldDrainRate / (1 - (targetStrength / 100))
print("Target Gate: " .. fluxval)
inputFluxGate.setSignalLowFlow(fluxval)
else
inputFluxGate.setSignalLowFlow(curInputGate)
end
end

if fuelPercent <= 10 then
reactor.stopReactor()
action = "Fuel below 10%, refuel"
end

if fieldPercent <= lowestFieldPercent and ri.status == "running" then
action = "Field Str < " .. lowestFieldPercent .. "%"
reactor.stopReactor()
reactor.chargeReactor()
emergencyCharge = true
end

if ri.temperature > maxTemperature then
reactor.stopReactor()
action = "Temp > " .. maxTemperature
emergencyTemp = true
end

sleep(0.05)
end
end

parallel.waitForAny(buttons, update)
