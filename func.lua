------------------------------------
-- Initial Version 0.1oz
-- Creator OzDeaDMeaT
------------------------------------
CMM = {}
------------------------------------
---@Function CMM.IsWarehouse
---@FunctionDescription     : Checks whether the supplied table represents a valid DCS warehouse object.
---@Syntax                  : CMM.IsWarehouse(<TBL>)
---@param WareH table       : Warehouse Object table
---@return boolean
---@Example                 : local isWh = CMM.IsWarehouse(Airbase.getByName("Akrotiri"):getWarehouse())
---@ExampleDescription      : Returns true if the argument is a warehouse; otherwise false.
function CMM.IsWarehouse(WareH)
    if(WareH == nil) then
        env.info("CMM.IsWarehouse: Warehouse supplied is a nil value, NOT a Warehouse!")
        return false
    else
        if type(WareH.addItem) == "function" then
            --env.info("CMM.IsWarehouse: Warehouse supplied is a Warehouse!")
            return true
        else
            env.info("CMM.IsWarehouse: Warehouse supplied is NOT a Warehouse!")
            return false
        end
    end
end
------------------------------------
---@Function CMM.IsAirbase
---@FunctionDescription     : Checks whether the supplied table represents a valid DCS airbase object.
---@Syntax                  : CMM.IsAirbase(<TBL>)
---@param AirB table        : Airbase Object table
---@return boolean
---@Example                 : local isBase = CMM.IsAirbase(Airbase.getByName("Akrotiri"))
---@ExampleDescription      : Returns true if the argument is an airbase; otherwise false.
function CMM.IsAirbase(AirB)
    if(AirB == nil) then
        env.info("CMM.IsAirbase: Airbase supplied is a nil value, NOT an Airbase!")
        return false
    else
        if(type(AirB.autoCaptureIsOn) == "function") then
            return true
        else
            env.info("CMM.IsAirbase: Airbase supplied is NOT an Airbase!")
            return false
        end
    end
end
------------------------------------
---@Function CMM.GetWarehouseByAirbase
---@Syntax                  : CMM.GetWarehouseByAirbase(<AirB>)
---@param AirB table|string : An Airbase object or the name of an airbase.
---@return table|nil        : Returns the warehouse data for the specified airbase, or nil if the argument is not a valid airbase.
---@Example                 : CMM.GetWarehouseByAirbase(Airbase.getByName("Akrotiri"))
---@ExampleDescription      : Retrieves the full warehouse object of the given airbase and logs the action.
function CMM.GetWarehouseByAirbase(AirB)
    local _airB = AirB
    local _wh
    if(CMM.IsAirbase(_airB) == true) then
        _wh = Airbase.getWarehouse(_airB)
        if(type(_wh) == 'table') then
            return _wh
        else
            env.info("CMM.GetWarehouse: Airbase supplied was an Airbase but there was an error when attempting to get the aiorbases warehouse table.")
            return nil
        end
    else
        if(type(_airB) == 'string') then
            env.info("CMM.GetWarehouseByAirbase: Airbase supplied was a string, attempting to get Airbase by name")
            local _abo = Airbase.getByName(_airB)
            if(CMM.IsAirbase(_abo) == true) then
                _wh = Airbase.getWarehouse(_abo)
                if(type(_wh) == 'table') then
                    return _wh
                else
                    env.info("CMM.GetWarehouse: Airbase name supplied was an Airbase but there was an error when attempting to get the aiorbases warehouse table.")
                    return nil
                end
            else
                env.info("CMM.GetWarehouse: Airbase supplied was not a valid airbase or airbase name string.")
                return nil
            end
        end
    end
    return nil
end
------------------------------------
---@Function CMM.GetAirbaseBasicInfo
---@FunctionDescription     : This function returns basic information about an Airbase (id, owner, airbase category, displayname, position, if autocapture is enabled)
---@Syntax                  : CMM.GetAirbaseBasicInfo(<Airbase Object Table>)
---@param AirB string|table : Airbase Object or Airbase name string or AirbaseID #
---@return table            : Returns a table of information about the Airbase
---@Example                 : CMM.GetAirbaseBasicInfo("Kutasi")
---@ExampleDecription       : This will return a table of information about the Kutasi Airbase
---@return nil
function CMM.GetAirbaseBasicInfo(AirB)
    local AB
    if(type(AirB) == 'string') then
        AB = Airbase.getByName(AirB)
    elseif(type(AirB) == 'table') then
        if(AirB.id_ ~= nil) then
            if(CMM.IsAirbase(AirB) == true) then
                AB = AirB
            else
                env.error("CMM.GetAirbaseBasicInfo: AIRBASE PROVIDED NOT AN AIRBASE!!")
            end
        else
            env.error("CMM.GetAirbaseBasicInfo: AIRBASE PROVIDED NOT A VALID AIRBASE TABLE!!")
        end
    end
    if(AB ~= nil) then
        local bs = {}
        local Description   = Airbase.getDesc(AB)
        local _point
        if(Description.category == 0) then
            local _tmp = Airbase.getDispatcherTowerPos(AB)
            _point = _tmp.pos
            --CMM.dump.JSONTable(_point,"_point.json")
        else
            _point = Airbase.getPoint(AB)
            --CMM.dump.JSONTable(_point,"_point.json")
        end
        bs.object           = AB
        bs.id               = Airbase.getID(AB)
        bs.coalition        = Airbase.getCoalition(AB)
        bs.category         = Description.category
        bs.displayName      = Description.displayName
        bs.point            = _point
        bs.objectname       = tostring(AB:getName()) or Description.displayName
        bs.AutoCaptureIsOn  = Airbase.autoCaptureIsOn(AB)
        return bs
    else
        env.error("CMM.GetAirbaseBasicInfo: AIRBASE PROVIDED NOT FOUND!!")
    end
end
------------------------------------
---@Function CMM.LoadAirframeWeapons
---@FunctionDescription     : Load weapons based on the airframes present at the airbase with a multiplier for weapon types
---@Syntax                  : CMM.LoadAirframeWeapons(AB <table|string>,MaxAF,WeaponTBL,ClearUnlisted)
---@param AB table|string   : An Airbase object or the name of an airbase.
---@param MaxAF number|nil  : Maximum number of airframes to consider (default 1)
---@param WeaponTBL table   : Table containing multipliers for different weapon types. Keys can include "Clusters", "Rockets", "AGMissiles", "AAMissiles", "Bombs", "LBombs", "GBombs", "GunPods", "Pods", "Tanks". If value is above _maxMultiplier for any of these weapon types it will be treated as an absolute value instead of a multiplier.
---@param ClearUnlisted boolean|nil: If a weapon is not listed but in the warehouse it will clear that weapon from the warehouse inventory. [default = false]
---@return nil              : Modifies the airbase's warehouse inventory; does not return a value.
---@Example                 : CMM.LoadAirframeWeapons(Airbase.getByName("Kutasi"), 50, WeaponTBL)
---@ExampleDescription      : Sets the weapons inventory of the Kutasi airbase's warehouse to the quantities defined in the "DefaultWeapons" table, multiplied by 2.
function CMM.LoadAirframeWeapons(AB,MaxAF,WeaponTBL, ClearUnlisted)
-- local _WeaponTBL = {["Clusters"] = 0, ["Rockets"] = true, ["AGMissiles"] = 100, ["AAMissiles"] = false, ["Bombs"] = true, ["LBombs"] = 5, ["GBombs"] = 2, ["GunPods"] = true, ["Pods"] = 1, ["Tanks"] = true}
-- CMM.LoadAirframeWeapons(Airbase.getByName("Anapa-Vityazevo"), 100, _WeaponTBL, true)

    local _unlimited = 1073741823
    local _maxMultiplier = 50
    local _maxAF = MaxAF or _unlimited
    local _weaponTBL = WeaponTBL or {}
    local _clearUnlisted = ClearUnlisted
    if(_clearUnlisted == nil) then
        _clearUnlisted = false
    end
    local _typeTable = {"Clusters", "Rockets", "AGMissiles", "AAMissiles", "Bombs", "LBombs", "GBombs", "GunPods", "Pods", "Tanks"}
    local _valueTable = {}

    local _ab = AB
    if(CMM.IsAirbase(_ab) ~= true) then
        env.error("CMM.LoadAirframeWeapons: Supplied AB is not a valid airbase, exiting!")
        return nil
    end

    for _idx, _weaponType in ipairs(_typeTable) do
        local _multiplier = _weaponTBL[_weaponType]
        if(_multiplier == nil) then
            _multiplier = 1
        end
        if(type(_multiplier) ~= "number") then
            if(type(_multiplier) == "boolean" and _multiplier == true) then
                _multiplier = _unlimited
            elseif(type(_multiplier) == "boolean" and _multiplier == false) then
                _multiplier = 0
            elseif(_weaponType == "Tanks") then
                _multiplier = _unlimited
            else
                _multiplier = 1
            end
        end
        _valueTable[_idx] = _multiplier
    end

    local _abData = CMM.GetAirbaseBasicInfo(_ab)
    local _abName = _abData.displayName
    local _warehouse = CMM.GetWarehouseByAirbase(AB)
    if(CMM.IsWarehouse(_warehouse) ~= true) then
        env.error("CMM.LoadAirframeWeapons: Could not find warehouse for the supplied airbase '" .. tostring(_abName) .. "', exiting!")
        return nil
    end
    local _inventory = _warehouse:getInventory()
    local _aircraft = _inventory.aircraft

    env.info("CMM.LoadAirframeWeapons: Setting LAU-88's to unlimited for airbase '" .. tostring(_abName) .. "'")

    local _newInventory ={
        ["F-15E_LAU-117"] = _unlimited,
        ["weapons.adapters.lau-88"] = _unlimited,
        ["weapons.adapters.F-15E_LAU-88"] = _unlimited,
        ["weapons.adapters.HB_ORD_LAU-88"] = _unlimited
    }

    for _airFrame, _count in pairs(_aircraft) do
        if(CMM.AirframeWeaponsDB[_airFrame]) then
            if(_count > _maxAF) then
                _count = _maxAF
            end
            for _idx, _weaponType in ipairs(_typeTable) do
                local _dbType = _weaponType
                local _multiplier = _valueTable[_idx]
                if(type(CMM.AirframeWeaponsDB[_airFrame][_dbType]) == 'table' and _multiplier > 0) then
                    for _type, _c in pairs(CMM.AirframeWeaponsDB[_airFrame][_dbType]) do
                        local _itemType = tostring(_type)
                        if(_multiplier == _unlimited) then
                            _newInventory[_itemType] = _unlimited
                        elseif(_multiplier > _maxMultiplier) then
                            if(_newInventory[_itemType] ~= _unlimited) then
                                _newInventory[_itemType] = _multiplier
                            end
                        else
                            local _newValue = (_count * _multiplier) * _c
                            if(type(_newInventory[_itemType]) == 'number' and _newInventory[_itemType] ~= _unlimited) then
                                _newInventory[_itemType] = _newInventory[_itemType] + _newValue
                            elseif(_newInventory[_itemType] ~= _unlimited) then
                                _newInventory[_itemType] = _newValue
                            end
                        end
                    end
                end
            end
        else
            env.warning("CMM.LoadAirframeWeapons: Airframe '" .. tostring(_airFrame) .. "' was not found in CMM.AirframeWeaponsDB table, skipping...")
        end
    end

    if(_clearUnlisted == true and type(_inventory.weapon) == "table") then
        env.info("CMM.LoadAirframeWeapons: Commencing Wartehouse clearing of unlisted items")
        for _item, _value in pairs(_inventory.weapon) do
            if(type(_value) == "number" and _newInventory[_item] == nil) then
                _warehouse:setItem(_item, 0)
                env.info("CMM.LoadAirframeWeapons: Cleared unlisted item '" .. tostring(_item) .. "'")
            end
        end
    end

    for _item, _value in pairs(_newInventory) do
        if(type(_value) == 'number' and _value > 0) then
            if(_value > _unlimited) then
                _value = _unlimited
            end
            _value = math.floor(_value)
            _warehouse:setItem(_item, _value)
            env.info("CMM.LoadAirframeWeapons: Item '" .. tostring(_item) .. "' quantity set to " .. tostring(_value))
        end
    end
end
