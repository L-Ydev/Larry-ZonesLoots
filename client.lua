ESX = exports['es_extended']:getSharedObject()
local lib = exports['ox_lib']

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true

    TriggerServerEvent('esx:looting:refreshProps')
    TriggerServerEvent('esx:looting:refreshLootingProps')
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

RegisterNetEvent('esx:looting:refreshProps')
AddEventHandler('esx:looting:refreshProps', function()
    TriggerServerEvent('esx:looting:refreshProps')
end)

RegisterNetEvent('esx:looting:ClientRefreshLootingProps')
AddEventHandler('esx:looting:ClientRefreshLootingProps', function()
    TriggerServerEvent('esx:looting:refreshLootingProps')
end)

------------------------------------------------------------------
------------------------------ RECUPERABLE LOOT

local object = nil -- Variable globale pour stocker l'objet
local objectHeightOffset = 0.0 -- Offset pour ajuster la hauteur de l'objet

RegisterNetEvent('esx:looting:startPlaceModel')
AddEventHandler('esx:looting:startPlaceModel', function(model, tableName)
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local yawOffset = 0.0 -- current yaw offset (rotation)

    local x = pos.x + 2.3 * math.cos(math.rad(heading) - 4.9)
    local y = pos.y + 2.3 * math.sin(math.rad(heading) - 4.9)
    local z = pos.z

    object = CreateObject(GetHashKey(model), x, y, z, false, false, false)
    PlaceObjectOnGroundProperly(object)
    SetEntityHeading(object, heading)

    -- Désactiver les collisions et rendre l'objet transparent
    SetEntityCollision(object, false, false)
    SetEntityAlpha(object, 160, false) -- 150 pour une transparence partielle, 0 pour complètement transparent
    

    Citizen.CreateThread(function()
        while object do
            local ped = GetPlayerPed(-1)
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            
            local x = pos.x + 1.3 * math.cos(math.rad(heading) - 4.9)
            local y = pos.y + 1.3 * math.sin(math.rad(heading) - 4.9)
            local z = pos.z + objectHeightOffset

            SetEntityCoordsNoOffset(object, x, y, z, true, true, true)

            if IsControlPressed(0, 172) then -- Flèche du haut
                objectHeightOffset = objectHeightOffset + 0.005
            elseif IsControlPressed(0, 173) then -- Flèche du bas
                objectHeightOffset = objectHeightOffset - 0.005
            elseif IsControlPressed(0, 174) then -- Arrow Left
                yawOffset = yawOffset - 0.35 -- adjust this to change the rotation speed
            elseif IsControlPressed(0, 175) then -- Arrow Right
                yawOffset = yawOffset + 0.35 -- adjust this to change the rotation speed
            end

            SetEntityHeading(object, yawOffset)


            if IsControlJustPressed(0, 201) then -- Entrée
                -- Obtenir les coordonnées finales de l'objet local
                local finalCoords = GetEntityCoords(object)
                local finalRotation = GetEntityRotation(object)

                FreezeEntityPosition(object, true) -- Gèle l'objet

                -- Supprimer l'objet local
                DeleteObject(object)
                
                local model = model

                -- Créer un objet contenant les informations nécessaires pour la sauvegarde côté serveur
                local objectData = {
                    model = model,
                    position = finalCoords,
                    rotation = finalRotation,
                }

                -- TriggerServerEvent('esx:construct:addProps', objectData)
                TriggerServerEvent('esx:looting:addPropsLoc', objectData, tableName)

                object = nil -- Réinitialise l'objet pour arrêter de le suivre
            end

            Citizen.Wait(0)
        end
    end)
end)

Citizen.CreateThread(function()
    if ESX.PlayerData then
        TriggerServerEvent('esx:looting:refreshProps')
        TriggerServerEvent('esx:looting:refreshLootingProps')
    end
end)

------------------------------------------------------------------
------------------------------ RECUPERABLE PROPS

-- Liste globale pour stocker les objets spawnés
local spawnedObjects = {}

local itemNames = {}
 
for item, data in pairs(exports.ox_inventory:Items()) do
    itemNames[item] = data.label
end

RegisterNetEvent('esx:looting:spawnAllProps')
AddEventHandler('esx:looting:spawnAllProps', function(data)
    local ped = GetPlayerPed(-1)

    if not data then
        print('Aucune donnée fournie à l\'événement esx:looting:spawnAllProps.')
        return
    end

    local newSpawnedObjects = {}

    for _, prop in ipairs(data) do
        for _, coord in ipairs(prop.coords) do
            local existingObject = nil
            for _, spawnedObj in ipairs(spawnedObjects) do
                if spawnedObj.model == prop.model and spawnedObj.x == coord.PosX and spawnedObj.y == coord.PosY and spawnedObj.z == coord.PosZ then
                    existingObject = spawnedObj
                    break
                end
            end

            if existingObject then
                table.insert(newSpawnedObjects, existingObject)
            else
                local hash = GetHashKey(prop.model)
                RequestModel(hash)
                while not HasModelLoaded(hash) do
                    Wait(500)
                end
            
                local objEntity = CreateObject(hash, coord.PosX, coord.PosY, coord.PosZ, false, false, false)
                SetEntityHeading(objEntity, coord.RotX)
                FreezeEntityPosition(objEntity, true)
            
                -- Ajout de ox_target pour l'objet
                exports.ox_target:addLocalEntity(objEntity, {
                    label = prop.label,
                    icon = "fas fa-search", -- Vous pouvez choisir n'importe quelle icône de Font Awesome
                    distance = 2.0, -- La distance maximale pour afficher l'option (ajustez selon vos besoins)
                    onSelect = function(data)
                        -- Votre logique lorsque l'utilisateur sélectionne l'objet
                        print("Objet sélectionné:", prop)

                        -- Récupérez tous les items du joueur
                        local playerItems = exports.ox_inventory:GetPlayerItems()

                        -- Vérifiez si le joueur a l'item requis pour ramasser le prop
                        local hasRequiredItem = false
                        for _, item in ipairs(playerItems) do
                            if item.name == prop.required then
                                hasRequiredItem = true
                                break
                            end
                        end

                        if hasRequiredItem or prop.required == '' or prop.required == nil then
                            if lib:progressCircle({
                                duration = 2000,
                                position = 'bottom',
                                useWhileDead = false,
                                canCancel = true,
                                disable = {
                                    car = true,
                                    move = true
                                },
                                anim = {
                                    dict = 'pickup_object',
                                    clip = 'putdown_low'
                                },
                            }) then 
                                -- Après avoir réussi à récupérer le prop, envoyez les données du prop au serveur
                                TriggerServerEvent('esx:looting:propRecovered', prop.model, coord)
                            end

                            ResetPedMovementClipset(ped, 0)
                        else
                            -- Informez le joueur qu'il n'a pas l'item requis pour ramasser le prop
                            TriggerEvent('esx:showNotification', "Vous n'avez pas de: " .. itemNames[prop.required])
                        end
                    end
                })            

                table.insert(newSpawnedObjects, {
                    entity = objEntity,
                    model = prop.model,
                    x = coord.PosX,
                    y = coord.PosY,
                    z = coord.PosZ
                })
            end
        end
    end

    -- Supprimez les props qui ne sont plus dans la nouvelle liste
    for _, spawnedObj in ipairs(spawnedObjects) do
        local found = false
        for _, newObj in ipairs(newSpawnedObjects) do
            if spawnedObj.entity == newObj.entity then
                found = true
                break
            end
        end

        if not found then
            DeleteEntity(spawnedObj.entity)
        end
    end

    spawnedObjects = newSpawnedObjects
end)


------------------------------------------------------------------
------------------------------ LOOTABLE PROPS

-- Côté client
-- Côté client
RegisterNetEvent('esx:looting:refreshLootingProps')
AddEventHandler('esx:looting:refreshLootingProps', function(lootingPropsData)
    refreshLootingProps(lootingPropsData)
end)

-- Liste globale pour stocker les modèles enregistrés
local registeredModels = {}

function refreshLootingProps(lootingPropsData)
    -- Afficher la liste lootingPropsData
    print("Liste des props reçus :")
    for _, propData in ipairs(lootingPropsData) do
        print("Modèle:", propData.model, "Label:", propData.label)
    end

    if exports.ox_target then
        print("ox_target est accessible")
    else
        print("ox_target n'est pas accessible")
    end    

    -- Liste temporaire pour stocker les modèles actuellement reçus
    local currentModels = {}

    -- Parcourir tous les props reçus du serveur
    for _, propData in ipairs(lootingPropsData) do
        exports.ox_target:removeModel(propData.model)
        table.insert(currentModels, propData.model)

        local options = {
            label = "Fouiller",
            icon = "fas fa-search",
            distance = 1.4,
            onSelect = function(data)
                -- Votre logique pour gérer la sélection du prop ici
                -- Par exemple, donner les récompenses au joueur
                -- Récupérez tous les items du joueur
                local playerItems = exports.ox_inventory:GetPlayerItems()

                -- Vérifiez si le joueur a l'item requis pour ramasser le prop
                local hasRequiredItem = false
                for _, item in ipairs(playerItems) do
                    if item.name == propData.required then
                        hasRequiredItem = true
                        break
                    end
                end

                if hasRequiredItem or propData.required == '' or propData.required == nil then
                    local playerPed = PlayerPedId() -- Obtenez l'ID du péd du joueur
                    local coords = GetEntityCoords(playerPed) -- Obtenez les coordonnées du péd du joueur            
                    TriggerServerEvent('esx:looting:useTargetLoot', coords, propData)    
                else
                    -- Informez le joueur qu'il n'a pas l'item requis pour ramasser le prop
                    TriggerEvent('esx:showNotification', "Vous n'avez pas de: " .. itemNames[propData.required])
                end

            end
        }

        -- Ajouter le prop à ox_target en utilisant addModel
        exports.ox_target:addModel(propData.model, {options})
    end

    -- Supprimer les modèles qui ne font plus partie de la nouvelle liste
    for _, model in ipairs(registeredModels) do
        if not tableContains(currentModels, model) then
            exports.ox_target:removeModel(model)
        end
    end

    -- Mettre à jour la liste globale registeredModels avec les modèles actuels
    registeredModels = currentModels
end

-- Fonction utilitaire pour vérifier si une table contient une valeur spécifique
function tableContains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

------------------------------------------------------------------
------------------------------ RESSOURCES PROPS

RegisterNetEvent('esx:looting:refreshRessourceProps')
AddEventHandler('esx:looting:refreshRessourceProps', function(lootingPropsData)
    refreshRessourceProps(lootingPropsData)
end)

-- Liste globale pour stocker les objets créés
local spawnedProps = {}

function refreshRessourceProps(lootingPropsData)
    -- Supprimer tous les props précédemment créés
    for _, prop in ipairs(spawnedProps) do
        DeleteEntity(prop.entity)
    end

    -- Réinitialiser la liste
    spawnedProps = {}

    -- Parcourir tous les props reçus du serveur
    for _, propData in ipairs(lootingPropsData) do
        local hash = GetHashKey(propData.model)
        RequestModel(hash)
        
        while not HasModelLoaded(hash) do
            Wait(500)
        end

        exports.ox_target:removeModel(propData.model)

        -- Parcourir toutes les coordonnées pour le propData actuel
        for _, coord in ipairs(propData.coords) do
            local objEntity = CreateObject(hash, coord.PosX, coord.PosY, coord.PosZ, false, false, false)
            FreezeEntityPosition(objEntity, true) -- Si vous souhaitez que l'objet reste immobile

            -- Ajouter l'objet à la liste
            table.insert(spawnedProps, {
                model = propData.model,
                entity = objEntity
            })
        end

        -- Ajouter un "target" à l'objet
        local options = {
            label = propData.label,
            icon = "fas fa-arrow-right",
            distance = 1.4,
            onSelect = function(data)
                local ped = GetPlayerPed(-1)
                local pos = GetEntityCoords(ped)
            
                ESX.TriggerServerCallback('esx:ressources:checkPointUsage', function(response)
                    if response.success then
                        -- Votre logique pour gérer la sélection de l'objet ici
                        -- Récupérez tous les items du joueur
                        local playerItems = exports.ox_inventory:GetPlayerItems()

                        -- Vérifiez si le joueur a l'item requis pour ramasser le prop
                        local hasRequiredItem = false
                        for _, item in ipairs(playerItems) do
                            if item.name == propData.required then
                                hasRequiredItem = true
                                break
                            end
                        end

                        if hasRequiredItem or propData.required == '' or propData.required == nil then
                            print(propData.AnimProp.model)
                
                            if lib:progressCircle({
                                duration = 10000,
                                position = 'bottom',
                                useWhileDead = false,
                                canCancel = true,
                                disable = {
                                    car = true,
                                    move = true
                                },
                                anim = {
                                    dict = propData.AnimDict,
                                    clip = propData.AnimClip
                                },
                                prop = {
                                    model = GetHashKey(propData.AnimProp.model),
                                    bone = 57005,
                                    pos = {x= propData.PropPos.x, y= propData.PropPos.y, z= propData.PropPos.z},
                                    rot = {x= propData.PropRot.x, y= propData.PropRot.y, z= propData.PropRot.z}
                                }
                            }) then 
                                -- Après avoir réussi à récupérer le prop, envoyez les données du prop au serveur
                                -- TriggerServerEvent('esx:looting:propRecovered', prop.model, coord)
                                local ped = GetPlayerPed(-1)
                                local pos = GetEntityCoords(ped)                
                                TriggerServerEvent('esx:ressources:finish', pos.x, pos.y, pos.z, propData.model)
                            end
                            
                            ResetPedMovementClipset(ped, 0)
                        else
                            -- Informez le joueur qu'il n'a pas l'item requis pour ramasser le prop
                            TriggerEvent('esx:showNotification', "Vous n'avez pas de: " .. itemNames[propData.required])
                        end
                    end
                end, pos.x, pos.y, pos.z, propData.model)
            end
        }

        exports.ox_target:addModel(propData.model, {options})
        -- Vous pouvez ajouter d'autres propriétés ou actions pour l'objet ici si nécessaire
    end
end