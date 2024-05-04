ESX = exports['es_extended']:getSharedObject()

RegisterCommand("loot", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() == 'admin' then
        MySQL.Async.fetchAll('SELECT * FROM loot_prop_ressource', {}, function(ressourceResult)
            
            MySQL.Async.fetchAll('SELECT * FROM loot_prop_looting', {}, function(lootingResult)
                
                MySQL.Async.fetchAll('SELECT * FROM loot_prop_recuperable', {}, function(recuperableResult)
                    
                    MySQL.Async.fetchAll('SELECT * FROM loot_prop_zone', {}, function(zoneResult)
                        
                        -- Envoie des données au client
                        TriggerClientEvent('esx:looting:openNui', source, ressourceResult, lootingResult, recuperableResult, zoneResult)
                        
                    end)
                end)
            end)
        end)
    else
        TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas les droits pour utiliser cette commande.")
    end
end, false)

RegisterServerEvent('esx:looting:addPropsTable')
AddEventHandler('esx:looting:addPropsTable', function(tableName, model, label, required)
    local source = source -- Obtenez l'identifiant du joueur qui a déclenché l'événement

    -- Assurez-vous que tableName existe dans la configuration
    if Config.DataBase[tableName] then
        local dbTable = Config.DataBase[tableName] -- Obtenez le nom de la base de données correspondante

        -- -- Vérifiez si la base de données existe
        -- MySQL.Async.fetchScalar('SELECT 1 FROM ' .. dbTable .. ' LIMIT 1', {}, function(result)
        --     if result then
                -- La base de données existe, vous pouvez ajouter vos données ici
                local query = 'INSERT INTO ' .. dbTable .. ' (model, label, required, items) VALUES (@model, @label, @required, @items)'
                local params = {
                    ['@model'] = model,
                    ['@label'] = label,
                    ['@required'] = required,
                    ['@items'] = '[]' -- Mettez la valeur de l'élément 'item' sur '[]'
                }

                MySQL.Async.execute(query, params, function(affectedRows)
                    if affectedRows > 0 then
                        -- Les données ont été insérées avec succès
                        print('Données ajoutées à la base de données:', dbTable)
                        -- TriggerClientEvent('esx:looting:addPropsTableSuccess', source) -- Vous pouvez envoyer une réponse au client si nécessaire
                        -- Exécuter la commande /loot pour le joueur
                        -- ExecuteCommand('loot ' .. source)
                        if tableName ~= "ressourcePropsTable" then
                            TriggerClientEvent('esx:looting:refreshUI', source)
                        end

                        TriggerClientEvent('esx:looting:ClientRefreshLootingProps', source)
                    else
                        -- Une erreur s'est produite lors de l'insertion des données
                        print('Erreur lors de l\'insertion des données dans la base de données:', dbTable)
                        -- TriggerClientEvent('esx:looting:addPropsTableError', source) -- Vous pouvez envoyer une réponse d'erreur au client si nécessaire
                    end
                end)

            -- else
            --     -- La base de données n'existe pas
            --     print('Base de données non trouvée:', dbTable)
            --     TriggerClientEvent('esx:looting:addPropsTableError', source) -- Vous pouvez envoyer une réponse d'erreur au client si nécessaire
            -- end
        -- end)
    else
        -- tableName n'est pas configuré correctement
        print('Nom de table invalide:', tableName)
        TriggerClientEvent('esx:looting:addPropsTableError', source) -- Vous pouvez envoyer une réponse d'erreur au client si nécessaire
    end
end)

RegisterServerEvent('esx:looting:removePropTable')
AddEventHandler('esx:looting:removePropTable', function(tableName, model)
    local source = source -- Obtenez l'identifiant du joueur qui a déclenché l'événement

    -- Assurez-vous que tableName existe dans la configuration
    if Config.DataBase[tableName] then
        local dbTable = Config.DataBase[tableName] -- Obtenez le nom de la base de données correspondante

        -- Vérifiez si la base de données existe
        MySQL.Async.fetchScalar('SELECT 1 FROM ' .. dbTable .. ' LIMIT 1', {}, function(result)
            if result then
                -- La base de données existe, vous pouvez supprimer vos données ici
                local query = 'DELETE FROM ' .. dbTable .. ' WHERE model = @model'
                local params = {
                    ['@model'] = model
                }

                MySQL.Async.execute(query, params, function(affectedRows)
                    if affectedRows > 0 then
                        -- Les données ont été supprimées avec succès
                        print('Données supprimées de la base de données:', dbTable)
                        TriggerClientEvent('esx:looting:refreshUI', source) -- Rafraîchissez l'interface utilisateur du client
                        TriggerClientEvent('esx:looting:refreshProps', source)
                        TriggerClientEvent('esx:looting:ClientRefreshLootingProps', source)
                        -- Vous pouvez également envoyer une réponse de réussite au client si nécessaire
                    else
                        -- Aucune donnée n'a été supprimée (le modèle n'a pas été trouvé)
                        print('Aucune donnée à supprimer dans la base de données:', dbTable)
                        -- Vous pouvez envoyer une réponse d'erreur au client si nécessaire
                    end
                end)

            else
                -- La base de données n'existe pas
                print('Base de données non trouvée:', dbTable)
                -- Vous pouvez envoyer une réponse d'erreur au client si nécessaire
            end
        end)
    else
        -- tableName n'est pas configuré correctement
        print('Nom de table invalide:', tableName)
        -- Vous pouvez envoyer une réponse d'erreur au client si nécessaire
    end
end)

-- Cette fonction ajoute un élément à la liste items d'une table
RegisterServerEvent('esx:looting:addItemProps')
AddEventHandler('esx:looting:addItemProps', function(tableName, model, name, min, max, chance)
    local source = source

    -- Assurez-vous que tableName existe dans la configuration
    if Config.DataBase[tableName] then
        local dbTable = Config.DataBase[tableName] -- Obtenez le nom de la base de données correspondante

        -- Vérifiez si la base de données existe
        MySQL.Async.fetchScalar('SELECT 1 FROM ' .. dbTable .. ' LIMIT 1', {}, function(result)
            if result then
                -- La base de données existe, vous pouvez ajouter l'élément à la liste items
                local query = 'SELECT items FROM ' .. dbTable .. ' WHERE model = @model'
                local params = {
                    ['@model'] = model
                }

                MySQL.Async.fetchAll(query, params, function(data)
                    if data and #data > 0 then
                        local items = json.decode(data[1].items) -- Obtenez la liste items existante
                        local newItem = {
                            name = name,
                            min = min,
                            max = max,
                            chance = chance
                        }
                        table.insert(items, newItem) -- Ajoutez le nouvel élément à la liste

                        -- Mettez à jour la liste items dans la base de données
                        local updateQuery = 'UPDATE ' .. dbTable .. ' SET items = @items WHERE model = @model'
                        local updateParams = {
                            ['@model'] = model,
                            ['@items'] = json.encode(items)
                        }

                        MySQL.Async.execute(updateQuery, updateParams, function(affectedRows)
                            if affectedRows > 0 then
                                -- Les données ont été mises à jour avec succès
                                print('Nouvel élément ajouté à la liste items de la base de données:', dbTable)
                                TriggerClientEvent('esx:looting:refreshUI', source) -- Rafraîchissez l'interface utilisateur du client
                                TriggerClientEvent('esx:looting:ClientRefreshLootingProps', source)
                            else
                                -- Une erreur s'est produite lors de la mise à jour des données
                                print('Erreur lors de la mise à jour de la liste items de la base de données:', dbTable)
                            end
                        end)
                    else
                        -- Aucune donnée trouvée pour ce modèle
                        print('Aucune donnée trouvée pour le modèle dans la base de données:', dbTable)
                    end
                end)
            else
                -- La base de données n'existe pas
                print('Base de données non trouvée:', dbTable)
            end
        end)
    else
        -- tableName n'est pas configuré correctement
        print('Nom de table invalide:', tableName)
    end
end)

RegisterServerEvent('esx:looting:deleteItemProps')
AddEventHandler('esx:looting:deleteItemProps', function(tableName, model, itemName)
    local source = source

    -- Assurez-vous que tableName existe dans la configuration
    if Config.DataBase[tableName] then
        local dbTable = Config.DataBase[tableName] -- Obtenez le nom de la base de données correspondante

        -- Récupérez la liste items pour le modèle spécifié
        local query = 'SELECT items FROM ' .. dbTable .. ' WHERE model = @model'
        local params = {
            ['@model'] = model
        }

        MySQL.Async.fetchAll(query, params, function(data)
            if data and #data > 0 then
                local items = json.decode(data[1].items) -- Obtenez la liste items existante

                -- Trouvez l'index de l'élément à supprimer
                for i, item in ipairs(items) do
                    if item.name == itemName then
                        table.remove(items, i) -- Supprimez l'élément de la liste
                        break
                    end
                end

                -- Mettez à jour la liste items dans la base de données
                local updateQuery = 'UPDATE ' .. dbTable .. ' SET items = @items WHERE model = @model'
                local updateParams = {
                    ['@model'] = model,
                    ['@items'] = json.encode(items)
                }

                MySQL.Async.execute(updateQuery, updateParams, function(affectedRows)
                    if affectedRows > 0 then
                        -- Les données ont été mises à jour avec succès
                        print('Élément supprimé de la liste items de la base de données:', dbTable)
                        TriggerClientEvent('esx:looting:refreshUI', source) -- Rafraîchissez l'interface utilisateur du client
                        TriggerClientEvent('esx:looting:refreshProps', source)
                        TriggerClientEvent('esx:looting:ClientRefreshLootingProps', source)
                    else
                        -- Une erreur s'est produite lors de la mise à jour des données
                        print('Erreur lors de la mise à jour de la liste items de la base de données:', dbTable)
                    end
                end)
            else
                -- Aucune donnée trouvée pour ce modèle
                print('Aucune donnée trouvée pour le modèle dans la base de données:', dbTable)
            end
        end)
    else
        -- tableName n'est pas configuré correctement
        print('Nom de table invalide:', tableName)
    end
end)

RegisterServerEvent('esx:looting:removeCoordsFromModel')
AddEventHandler('esx:looting:removeCoordsFromModel', function(tableName, model, coordsToRemove)
    local source = source

    -- Assurez-vous que tableName existe dans la configuration
    if Config.DataBase[tableName] then
        local dbTable = Config.DataBase[tableName] -- Obtenez le nom de la base de données correspondante

        -- Récupérez la colonne coords pour le modèle spécifié
        local query = 'SELECT coords FROM ' .. dbTable .. ' WHERE model = @model'
        local params = {
            ['@model'] = model
        }

        MySQL.Async.fetchAll(query, params, function(data)
            if data and #data > 0 then
                local coordsList = json.decode(data[1].coords) -- Obtenez la liste coords existante

                -- Trouvez l'index de la coordonnée à supprimer
                for i, coord in ipairs(coordsList) do
                    if coord.PosX == coordsToRemove.PosX and coord.PosY == coordsToRemove.PosY and coord.PosZ == coordsToRemove.PosZ then
                        table.remove(coordsList, i) -- Supprimez la coordonnée de la liste
                        break
                    end
                end

                -- Mettez à jour la colonne coords dans la base de données
                local updateQuery = 'UPDATE ' .. dbTable .. ' SET coords = @coords WHERE model = @model'
                local updateParams = {
                    ['@model'] = model,
                    ['@coords'] = json.encode(coordsList)
                }

                MySQL.Async.execute(updateQuery, updateParams, function(affectedRows)
                    if affectedRows > 0 then
                        -- Les données ont été mises à jour avec succès
                        print('Coordonnée supprimée de la liste coords de la base de données:', dbTable)
                        TriggerClientEvent('esx:looting:refreshUI', source) -- Rafraîchissez l'interface utilisateur du client
                        TriggerClientEvent('esx:looting:refreshProps', source)
                    else
                        -- Une erreur s'est produite lors de la mise à jour des données
                        print('Erreur lors de la mise à jour de la liste coords de la base de données:', dbTable)
                    end
                end)
            else
                -- Aucune donnée trouvée pour ce modèle
                print('Aucune donnée trouvée pour le modèle dans la base de données:', dbTable)
            end
        end)
    else
        -- tableName n'est pas configuré correctement
        print('Nom de table invalide:', tableName)
    end
end)

RegisterServerEvent('esx:looting:addCoordsToList')
AddEventHandler('esx:looting:addCoordsToList', function(tableName, model, newCoords)
    local source = source

    -- Assurez-vous que tableName existe dans la configuration
    if Config.DataBase[tableName] then
        local dbTable = Config.DataBase[tableName] -- Obtenez le nom de la base de données correspondante

        -- Récupérez la colonne coords pour le modèle spécifié
        local query = 'SELECT coords FROM ' .. dbTable .. ' WHERE model = @model'
        local params = {
            ['@model'] = model
        }

        MySQL.Async.fetchAll(query, params, function(data)
            if data and #data > 0 then
                local coordsList = json.decode(data[1].coords) -- Obtenez la liste coords existante

                -- Ajoutez la nouvelle coordonnée à la liste
                table.insert(coordsList, newCoords)

                -- Mettez à jour la colonne coords dans la base de données
                local updateQuery = 'UPDATE ' .. dbTable .. ' SET coords = @coords WHERE model = @model'
                local updateParams = {
                    ['@model'] = model,
                    ['@coords'] = json.encode(coordsList)
                }

                MySQL.Async.execute(updateQuery, updateParams, function(affectedRows)
                    if affectedRows > 0 then
                        -- Les données ont été mises à jour avec succès
                        print('Nouvelle coordonnée ajoutée à la liste coords de la base de données:', dbTable)
                        TriggerClientEvent('esx:looting:refreshUI', source) -- Rafraîchissez l'interface utilisateur du client
                    else
                        -- Une erreur s'est produite lors de la mise à jour des données
                        print('Erreur lors de l\'ajout de la nouvelle coordonnée à la liste coords de la base de données:', dbTable)
                    end
                end)
            else
                -- Aucune donnée trouvée pour ce modèle
                print('Aucune donnée trouvée pour le modèle dans la base de données:', dbTable)
            end
        end)
    else
        -- tableName n'est pas configuré correctement
        print('Nom de table invalide:', tableName)
    end
end)

RegisterServerEvent('esx:looting:addPropsLoc')
AddEventHandler('esx:looting:addPropsLoc', function(objectData, tableName)
    local source = source

    if objectData and objectData.model then
        local dbTable = Config.DataBase[tableName]

        -- Vérifiez d'abord si le modèle existe déjà
        local checkQuery = 'SELECT coords FROM ' .. dbTable .. ' WHERE model = @model'
        local params = {
            ['@model'] = objectData.model
        }

        MySQL.Async.fetchAll(checkQuery, params, function(data)
            if data and #data > 0 then
                -- Le modèle existe déjà, ajoutez les nouvelles coordonnées à la liste existante
                local coordsList = json.decode(data[1].coords)
                table.insert(coordsList, {
                    PosX = objectData.position.x,
                    PosY = objectData.position.y,
                    PosZ = objectData.position.z,
                    RotX = objectData.rotation.x,
                    RotY = objectData.rotation.y,
                    RotZ = objectData.rotation.z
                })

                -- Mettez à jour la base de données avec la nouvelle liste
                local updateQuery = 'UPDATE ' .. dbTable .. ' SET coords = @coords WHERE model = @model'
                local updateParams = {
                    ['@model'] = objectData.model,
                    ['@coords'] = json.encode(coordsList)
                }

                MySQL.Async.execute(updateQuery, updateParams, function(affectedRows)
                    if affectedRows > 0 then
                        print('Coordonnées mises à jour pour le modèle dans la base de données:', dbTable)
                        TriggerClientEvent('esx:looting:refreshUI', source)
                        TriggerClientEvent('esx:looting:refreshProps', source)
                    else
                        print('Erreur lors de la mise à jour des coordonnées pour le modèle dans la base de données:', dbTable)
                    end
                end)
            end
        end)
    else
        print('Données d\'objet non valides reçues:', objectData)
    end
end)

local propsRecuperes = {}

RegisterServerEvent('esx:looting:propRecovered')
AddEventHandler('esx:looting:propRecovered', function(model, coord)
    local source = source

    local itemGiven = false  -- Variable pour suivre si un objet a été donné

    -- Ajoutez le prop à la liste propsRecuperes
    table.insert(propsRecuperes, {
        model = model,
        coords = coord
    })

    local query = 'SELECT items FROM loot_prop_recuperable WHERE model = @model'
    MySQL.Async.fetchAll(query, {['@model'] = model}, function(result)
        if result and #result > 0 then
            local items = json.decode(result[1].items)
            for _, item in ipairs(items) do
                local chance = math.random(1, 100)
                if chance <= item.chance then
                    local quantity = math.random(item.min, item.max)
                    -- Donnez l'élément au joueur
                    local xPlayer = ESX.GetPlayerFromId(source)
                    xPlayer.addInventoryItem(item.name, quantity)
                    itemGiven = true  -- Marquez qu'un objet a été donné
                end
            end

            if not itemGiven then
                -- Si aucun objet n'a été donné, informez le joueur
                TriggerClientEvent('esx:showNotification', source, "Vous n'avez trouvé aucun objet.")
            end
        end
    end)

    TriggerClientEvent('esx:looting:refreshProps', source)
end)

-- Table pour stocker les données du butin
local recupPropsTable = {}

-- Chargement des données au démarrage du script
MySQL.Async.fetchAll('SELECT model, coords, required, label FROM loot_prop_recuperable', {}, function(data)
    if data and #data > 0 then
        for _, row in ipairs(data) do
            table.insert(recupPropsTable, {
                model = row.model,
                coords = json.decode(row.coords),
                required = row.required,
                label = row.label -- En supposant que les items sont stockés au format JSON dans la base de données
            })
        end
    else
        print('Aucune donnée trouvée dans la base de données: recupPropsTable')
    end
end)

local lastExecutionRefreshProps = 0

-- Côté serveur
RegisterServerEvent('esx:looting:refreshProps')
AddEventHandler('esx:looting:refreshProps', function()
    local currentTime = os.time()

    if currentTime - lastExecutionRefreshProps < 3 then
        -- print("Vous devez attendre avant de rafraîchir à nouveau.")
        return
    end

    lastExecutionRefreshProps = currentTime

    local propsDataToSend = {}

    for _, row in ipairs(recupPropsTable) do
        local coordsFiltrees = {}

        for _, coord in ipairs(row.coords) do
            local estRecupere = false

            for _, propRecupere in ipairs(propsRecuperes) do
                if propRecupere.model == row.model and 
                   propRecupere.coords.PosX == coord.PosX and 
                   propRecupere.coords.PosY == coord.PosY and 
                   propRecupere.coords.PosZ == coord.PosZ then
                    estRecupere = true
                    break
                end
            end

            if not estRecupere then
                table.insert(coordsFiltrees, coord)
            end
        end

        if #coordsFiltrees > 0 then
            table.insert(propsDataToSend, {
                model = row.model,
                label = row.label,
                coords = coordsFiltrees,
                required = row.required
            })
        end
    end

    -- Récupérez tous les xPlayer avec ESX
    local xPlayers = ESX.GetPlayers()
    TriggerClientEvent('esx:looting:spawnAllProps', -1, propsDataToSend)
end)

-- Table pour stocker les données du butin
local lootingPropsData = {}

-- Chargement des données au démarrage du script
MySQL.Async.fetchAll('SELECT model, label, required, items FROM loot_prop_looting', {}, function(data)
    if data and #data > 0 then
        for _, row in ipairs(data) do
            table.insert(lootingPropsData, {
                model = row.model,
                label = row.label,
                required = row.required,
                items = json.decode(row.items) -- En supposant que les items sont stockés au format JSON dans la base de données
            })
        end
    else
        print('Aucune donnée trouvée dans la base de données: loot_prop_looting')
    end
end)

RegisterServerEvent('esx:looting:refreshLootingProps')
AddEventHandler('esx:looting:refreshLootingProps', function()
    local _source = source
    TriggerClientEvent('esx:looting:refreshLootingProps', _source, lootingPropsData)
end)

Stashes = {}

local function isNear(coords1, coords2, distance)
    local dx = coords1.x - coords2.x
    local dy = coords1.y - coords2.y
    local dz = coords1.z - coords2.z

    return (dx * dx + dy * dy + dz * dz) < (distance * distance)
end

RegisterServerEvent('esx:looting:useTargetLoot')
AddEventHandler('esx:looting:useTargetLoot', function(coords, propData)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    local propModel = propData.model
    local stashId = "stash_" .. tostring(coords.x) .. "_" .. tostring(coords.y)

    local isNearStash = false
    for id, stashCoords in pairs(Stashes) do
        if isNear(coords, stashCoords, 2.0) then 
            stashId = id
            isNearStash = true
            break
        end
    end

    local registeredItems = exports.ox_inventory:Items()

    if not isNearStash then
        exports.ox_inventory:RegisterStash(stashId, 'Recherche..', 10, 25000, nil, nil, coords)
        Stashes[stashId] = coords

        for _, rewardData in ipairs(propData.items) do
            if math.random(100) <= rewardData.chance then
                local itemCount = math.random(rewardData.min, rewardData.max)
                if registeredItems[rewardData.name] then
                    local success, response = exports.ox_inventory:AddItem(stashId, rewardData.name, itemCount)
                    if not success then
                        print("Erreur lors de l'ajout de l'item:", response)
                    end
                else
                    print("L'élément", rewardData.name, "n'est pas enregistré dans l'inventaire.")
                end
            end
        end
    end

    TriggerClientEvent('ox_inventory:openInventory', _source, 'stash', stashId)
end)

-- Table pour stocker les données du butin
local ressourcePropsData = {}

-- Chargement des données au démarrage du script
MySQL.Async.fetchAll('SELECT model, label, required, items, coords, AnimDict, AnimClip, AnimProp FROM loot_prop_ressource', {}, function(data)
    if data and #data > 0 then
        for _, row in ipairs(data) do
            local decodedAnimProp = json.decode(row.AnimProp)

            local propPos = nil
            local propRot = nil

            if decodedAnimProp and decodedAnimProp.coords then
                propPos = {
                    x = decodedAnimProp.coords.PosX,
                    y = decodedAnimProp.coords.PosY,
                    z = decodedAnimProp.coords.PosZ
                }
                propRot = {
                    x = decodedAnimProp.coords.RotX,
                    y = decodedAnimProp.coords.RotY,
                    z = decodedAnimProp.coords.RotZ
                }
            end
            
            table.insert(ressourcePropsData, {
                model = row.model,
                label = row.label,
                required = row.required,
                items = json.decode(row.items), -- En supposant que les items sont stockés au format JSON dans la base de données
                coords = json.decode(row.coords),
                AnimDict = row.AnimDict,
                AnimClip = row.AnimClip,
                AnimProp = decodedAnimProp,
                PropPos = propPos,
                PropRot = propRot
            })
        end
    else
        print('Aucune donnée trouvée dans la base de données: loot_prop_ressource')
    end
end)

Citizen.CreateThread(function()
    while true do
        -- Attendez 10 secondes (10000 millisecondes)
        Citizen.Wait(30000)

        -- Mettre à jour les props
        local propsDataToSend = {}

        for _, row in ipairs(ressourcePropsData) do
            local propPos = nil
            local propRot = nil

            if row.AnimProp and row.AnimProp.coords then
                propPos = {
                    x = row.AnimProp.coords.PosX,
                    y = row.AnimProp.coords.PosY,
                    z = row.AnimProp.coords.PosZ
                }
                propRot = {
                    x = row.AnimProp.coords.RotX,
                    y = row.AnimProp.coords.RotY,
                    z = row.AnimProp.coords.RotZ
                }
            end

            table.insert(propsDataToSend, {
                model = row.model,
                label = row.label,
                coords = row.coords,
                required = row.required,
                AnimDict = row.AnimDict,
                AnimClip = row.AnimClip,
                AnimProp = row.AnimProp,
                PropPos = propPos,
                PropRot = propRot
            })
        end

        -- Récupérez tous les xPlayer avec ESX
        local xPlayers = ESX.GetPlayers()
        TriggerClientEvent('esx:looting:refreshRessourceProps', -1, propsDataToSend)
    end
end)

-- Fonction pour convertir une table en chaîne de caractères
function tableToString(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        table.insert(result, k .. ": " .. tostring(v))
    end
    return table.concat(result, ", ")
end

RegisterServerEvent('esx:looting:addPropsAnimation')
AddEventHandler('esx:looting:addPropsAnimation', function(objectData, tableName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local tableName = Config.DataBase[tableName]

    -- Vérifiez si le joueur a les permissions nécessaires pour ajouter une animation (si nécessaire)
    -- if xPlayer.getGroup() ~= 'admin' then
    --     TriggerClientEvent('esx:showNotification', _source, "Vous n'avez pas la permission de faire cela!")
    --     return
    -- end

    -- Mettez à jour les données dans la base de données pour le modèle spécifié
    local query = string.format('UPDATE %s SET animDict = @animDict, animClip = @animClip, AnimProp = @AnimProp WHERE model = @model', tableName)

    MySQL.Async.execute(query, {
        ['@model'] = objectData.model,
        ['@animDict'] = objectData.animDict,
        ['@animClip'] = objectData.animClip,
        ['@AnimProp'] = json.encode(objectData.propInfo) -- Ici, nous utilisons json.encode pour convertir les informations du prop en format JSON pour le stockage.
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', _source, "Animation mise à jour avec succès!")
        else
            TriggerClientEvent('esx:showNotification', _source, "Erreur lors de la mise à jour de l'animation!")
        end
    end)
end)

local pointUsage = {} -- Tableau pour stocker le nombre d'utilisations de chaque point

-- Définir une variable pour stocker l'intervalle
local reloadInterval = 20 * 60 * 1000 -- 20 minutes en millisecondes

-- Fonction pour charger les loots
local function loadLoot()
    pointUsage = {}
    Stashes = {}
    propsRecuperes = {}

    -- Ceci est exécuté une fois que la base de données est prête
        MySQL.Async.execute('DELETE FROM ox_inventory WHERE name LIKE @namePattern', {
            ['@namePattern'] = 'stash_%'
        }, function(rowsChanged)
            if rowsChanged > 0 then
                print(('^1[INFO]^0 %s entrées avec "stash_" dans le nom ont été supprimées de la table ox_inventory.'):format(rowsChanged))
            else
                print('^1[INFO]^0 Aucune entrée avec "stash_" dans le nom trouvée dans la table ox_inventory.')
            end
        end)
    -- Code pour récupérer les données des propriétés à envoyer
    local propsDataToSend = {}

    for _, row in ipairs(recupPropsTable) do
        local coordsFiltrees = {}

        for _, coord in ipairs(row.coords) do
            local estRecupere = false

            for _, propRecupere in ipairs(propsRecuperes) do
                if propRecupere.model == row.model and 
                   propRecupere.coords.PosX == coord.PosX and 
                   propRecupere.coords.PosY == coord.PosY and 
                   propRecupere.coords.PosZ == coord.PosZ then
                    estRecupere = true
                    break
                end
            end

            if not estRecupere then
                table.insert(coordsFiltrees, coord)
            end
        end

        if #coordsFiltrees > 0 then
            table.insert(propsDataToSend, {
                model = row.model,
                label = row.label,
                coords = coordsFiltrees,
                required = row.required
            })
        end
    end

    -- Récupérer tous les xPlayer avec ESX
    local xPlayers = ESX.GetPlayers()
    TriggerClientEvent('esx:looting:spawnAllProps', -1, propsDataToSend)

end

-- Appeler la fonction de chargement des loots toutes les 20 minutes
Citizen.CreateThread(function()
    while true do
        loadLoot()
        Citizen.Wait(reloadInterval)
    end
end)

RegisterCommand("reloadloot", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() == 'admin' then
        pointUsage = {}
        Stashes = {}
        propsRecuperes = {}

        -- Ceci est exécuté une fois que la base de données est prête
        MySQL.Async.execute('DELETE FROM ox_inventory WHERE name LIKE @namePattern', {
            ['@namePattern'] = 'stash_%'
        }, function(rowsChanged)
            if rowsChanged > 0 then
                print(('^1[INFO]^0 %s entrées avec "stash_" dans le nom ont été supprimées de la table ox_inventory.'):format(rowsChanged))
            else
                print('^1[INFO]^0 Aucune entrée avec "stash_" dans le nom trouvée dans la table ox_inventory.')
            end
        end)

        --------------------------------------------
        local propsDataToSend = {}

        for _, row in ipairs(recupPropsTable) do
            local coordsFiltrees = {}
    
            for _, coord in ipairs(row.coords) do
                local estRecupere = false
    
                for _, propRecupere in ipairs(propsRecuperes) do
                    if propRecupere.model == row.model and 
                       propRecupere.coords.PosX == coord.PosX and 
                       propRecupere.coords.PosY == coord.PosY and 
                       propRecupere.coords.PosZ == coord.PosZ then
                        estRecupere = true
                        break
                    end
                end
    
                if not estRecupere then
                    table.insert(coordsFiltrees, coord)
                end
            end
    
            if #coordsFiltrees > 0 then
                table.insert(propsDataToSend, {
                    model = row.model,
                    label = row.label,
                    coords = coordsFiltrees,
                    required = row.required
                })
            end
        end
    
        -- Récupérez tous les xPlayer avec ESX
        local xPlayers = ESX.GetPlayers()
        TriggerClientEvent('esx:looting:spawnAllProps', -1, propsDataToSend)

        
        TriggerClientEvent('esx:showNotification', source, "Les loot viennent d'être réinitialiser.")
    else
        TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas les droits pour utiliser cette commande.")
    end

end, false)

-- Fonction pour obtenir la distance entre deux points
function getDistance(pointA, pointB)
    return math.sqrt((pointA.x - pointB.x)^2 + (pointA.y - pointB.y)^2 + (pointA.z - pointB.z)^2)
end

-- Fonction pour obtenir le point le plus proche
function getClosestPoint(x, y, z)
    local closestPoint = nil
    local closestDistance = 3.5 -- distance maximale pour considérer un point comme "proche"

    for key, _ in pairs(pointUsage) do
        local coords = stringsplit(key, ",")
        local distance = getDistance({x = x, y = y, z = z}, {x = tonumber(coords[1]), y = tonumber(coords[2]), z = tonumber(coords[3])})

        if distance < closestDistance then
            closestDistance = distance
            closestPoint = key
        end
    end

    return closestPoint
end

RegisterServerEvent('esx:ressources:finish')
AddEventHandler('esx:ressources:finish', function(x, y, z, model)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    -- Trouver le point le plus proche
    local closestPointKey = getClosestPoint(x, y, z)
    if closestPointKey then
        pointKey = closestPointKey
    else
        pointKey = x .. "," .. y .. "," .. z
    end

    -- Initialiser le compteur pour ce point s'il n'existe pas encore
    if not pointUsage[pointKey] then
        pointUsage[pointKey] = 0
    end

    -- Augmenter le compteur pour ce point
    pointUsage[pointKey] = pointUsage[pointKey] + 1

    if pointUsage[pointKey] < 3 then
        -- Récupérez les items pour la ressource spécifiée
        local query = 'SELECT items FROM loot_prop_ressource WHERE model = @model'
        MySQL.Async.fetchScalar(query, { ['@model'] = model }, function(items)
            if items then
                local itemsList = json.decode(items)
                for _, item in ipairs(itemsList) do
                    local ItemChance = item.chance
                    if ItemChance >= math.random(100) then
                        local itemCount = math.random(item.min, item.max)
                        if xPlayer.canCarryItem(item.name, itemCount) then
                            xPlayer.addInventoryItem(item.name, itemCount)
                        end
                        -- TriggerClientEvent('esx:showNotification', _source, "Vous avez reçu " .. itemCount .. " " .. item.name)
                    end
                end
            end
        end)
    end
end)


ESX.RegisterServerCallback('esx:ressources:checkPointUsage', function(source, cb, x, y, z, ressource)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Trouver le point le plus proche
    local closestPointKey = getClosestPoint(x, y, z)
    if closestPointKey then
        pointKey = closestPointKey
    else
        pointKey = x .. "," .. y .. "," .. z
    end

    -- Vérifier si le point a été utilisé 3 fois ou plus
    if pointUsage[pointKey] and pointUsage[pointKey] >= 2 then
        TriggerClientEvent('esx:showNotification', source, "La ressource a déjà été utilisé.")
        return
    end

    cb({success = true})
end)

-- Fonction utilitaire pour diviser une chaîne en un tableau
function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

MySQL.Async.execute('DELETE FROM ox_inventory WHERE name LIKE @namePattern', {
    ['@namePattern'] = 'stash_%'
}, function(rowsChanged)
    if rowsChanged > 0 then
        print(('^1[INFO]^0 %s entrées avec "stash_" dans le nom ont été supprimées de la table ox_inventory.'):format(rowsChanged))
    else
        print('^1[INFO]^0 Aucune entrée avec "stash_" dans le nom trouvée dans la table ox_inventory.')
    end
end)
