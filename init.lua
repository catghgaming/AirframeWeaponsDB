CMM = {}                                                            -- Initialisation of the CMM table
CMM.dcsErrorBox         = false                                     -- Enables the DCS Scripting Error Box (recommended to leave as FALSE)
env.setErrorMessageBoxEnabled(CMM.dcsErrorBox)

env.info("LOADING CUSTOM SCRIPTS FOR AirframeWeaponsDB ...")
env.info(" - LOADING func.lua")
dofile(AirframeWeaponsDB_PATH .. "func.lua")

env.info(" - LOADING AirframeWeaponsDB.lua")
CMM.AirframeWeaponsDB   = dofile(AirframeWeaponsDB_PATH .. "AirframeWeaponsDB.lua")  or {}  -- Airframe to Weapon TypeDB

-- Code below is a demostration of how you could use the script within Caucusus-01 Mission

--We will modify the weapons at Anapa
local _WeaponTBL = {["Clusters"] = 0, ["Rockets"] = true, ["AGMissiles"] = 5000, ["AAMissiles"] = true, ["Bombs"] = true, ["LBombs"] = 500, ["GBombs"] = 150, ["GunPods"] = true, ["Pods"] = 100, ["Tanks"] = true}
CMM.LoadAirframeWeapons(Airbase.getByName("Anapa-Vityazevo"), 100, _WeaponTBL, true)
trigger.outText("Anapa Airbase Warehouse has been loaded!", 30)