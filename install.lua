-- drmon installation script
-- Overhauled for ATM9 v1.1.1
--
 
local libURL = "https://raw.githubusercontent.com/furnero/drmon/master/lib/f.lua"
local startupURL = "https://raw.githubusercontent.com/furnero/drmon/master/drmon.lua"
local lib, startup
local libFile, startupFile
 
fs.makeDir("lib")
 
lib = http.get(libURL)
libFile = lib.readAll()
 
local file1 = fs.open("lib/f.lua", "w")
file1.write(libFile)
file1.close()
 
startup = http.get(startupURL)
startupFile = startup.readAll()
 
 
local file2 = fs.open("startup.lua", "w")
file2.write(startupFile)
file2.close()
