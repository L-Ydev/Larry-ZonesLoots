ESX = exports['es_extended']:getSharedObject()
local lib = exports['ox_lib']

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

RegisterNetEvent('esx:looting:refreshUI')
AddEventHandler('esx:looting:refreshUI', function()
    ExecuteCommand('loot')
end)

RegisterNetEvent('esx:looting:openNui')
AddEventHandler('esx:looting:openNui', function(ressourceProps, LootingProps, RecuperableProps, ZoneList)
    openLootNUI(ressourceProps, LootingProps, RecuperableProps, ZoneList)
end)

-- Ouvrir la NUI
function openLootNUI(ressourceProps, LootingProps, RecuperableProps, ZoneList)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openLootNUI",
        ressourceProps = ressourceProps,
        lootingProps = LootingProps,
        recuperableProps = RecuperableProps,
        zoneList = ZoneList
    })
end

-- Fermer la NUI
function closeLootNUI()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "closeLootNUI"
    })
end

-- Gérer les retours de la NUI
RegisterNUICallback('closeLootNUI', function()
    closeLootNUI()
end)

-------------------------------------------------------------------------------------
------------------------------------------------------ RESSOURCE

RegisterNUICallback('sendInputData', function(data, cb)
    -- Assurez-vous que tableName et inputData existent dans les données reçues
    if data.tableName and data.data then
        local tableName = data.tableName
        local inputData = data.data

        -- Affichez les données reçues dans la console (à des fins de débogage)
        print('Données reçues depuis la NUI:')
        print('Nom de la table:', tableName)

        -- Si inputData est une table, vous pouvez itérer sur ses éléments
        if type(inputData) == "table" then
            local model = inputData[1] -- Le modèle correspond à la clé 1
            local label = inputData[2] -- Le label correspond à la clé 2
            local required = inputData[3] -- Le required correspond à la clé 3

            print('Modèle:', model)
            print('Label:', label)
            print('Required:', required)

            TriggerServerEvent('esx:looting:addPropsTable', tableName, model, label, required)
            -- Vous pouvez effectuer des opérations avec ces valeurs ici

            if tableName == "ressourcePropsTable" then
                closeLootNUI()
                Wait(100)
    
                local input = lib:inputDialog('Choix de l\'animation', {
                    {type = 'input', label = 'Entrez le dict.'},
                    {type = 'input', label = 'Entrez le clip.'},
                    {type = 'input', label = 'Entrez le props.'},
                    {type = 'input', label = 'Coordonnée X du Props.'},
                    {type = 'input', label = 'Coordonnée Y du Props.'},
                    {type = 'input', label = 'Coordonnée Z du Props.'},
                    {type = 'input', label = 'Rotation X du Props.'},
                    {type = 'input', label = 'Rotation Y du Props.'},
                    {type = 'input', label = 'Rotation Z du Props.'},
                })
                
                if input then
                    -- Créer une liste pour les informations du prop
                    local propInfo = {
                        model = input[3],
                        coords = {
                            PosX = tonumber(input[4]),
                            PosY = tonumber(input[5]),
                            PosZ = tonumber(input[6]),
                            RotX = tonumber(input[7]),
                            RotY = tonumber(input[8]),
                            RotZ = tonumber(input[9])
                        }
                    }
                
                    -- Créer un objet contenant les informations nécessaires pour la sauvegarde côté serveur
                    local objectDataAnimation = {
                        model = model,
                        animDict = input[1],
                        animClip = input[2],
                        propInfo = propInfo
                    }
                
                    TriggerServerEvent('esx:looting:addPropsAnimation', objectDataAnimation, tableName)
                    ExecuteCommand('loot')
                else
                    ExecuteCommand('loot')
                end
            end        
        end
        -- Vous pouvez également renvoyer une réponse à la NUI si nécessaire
        local responseData = { message = "Données reçues avec succès côté client!" }
        cb(responseData)
    else
        print('Données invalides reçues depuis la NUI.')
    end
end)

RegisterNUICallback('deletePropInList', function(data, cb)
    -- Récupérez les informations envoyées depuis l'interface utilisateur
    local tableName = data.tableName -- Le nom de la liste
    local model = data.model -- Le modèle à supprimer

    -- Affichez les informations dans la console serveur
    print("Suppression de l'élément dans la table :", tableName)
    print("Modèle à supprimer :", model)

    -- Envoie les informations au serveur avec un TriggerEvent
    TriggerServerEvent('esx:looting:removePropTable', tableName, model)    
end)

RegisterNUICallback('addItemToListModel', function(data, cb)
    local tableName = data.tableName
    local model = data.model
    local itemData = data.data -- Ici, nous récupérons l'objet "data" que vous avez envoyé

    local itemName = itemData.name
    local min = itemData.min
    local max = itemData.max
    local chance = itemData.chance

    -- Traitez les données ici
    -- Vous pouvez les insérer dans votre base de données ou effectuer d'autres opérations

    -- Une fois le traitement terminé, envoyez les données au serveur en utilisant TriggerServerEvent
    TriggerServerEvent('esx:looting:addItemProps', tableName, model, itemName, min, max, chance)

    -- N'oubliez pas de renvoyer une réponse au NUI si nécessaire
    cb('OK')
end)

RegisterNUICallback('deleteItemFromListModel', function(data, cb)
    local tableName = data.tableName
    local model = data.model
    local itemName = data.itemName -- Ici, nous récupérons l'objet "data" que vous avez envoyé

    -- Déclenchez l'événement côté serveur
    TriggerServerEvent('esx:looting:deleteItemProps', tableName, model, itemName)
end)

RegisterNUICallback('removeCoordsFromModel', function(data, cb)
    -- Récupération des données envoyées depuis le JavaScript
    local action = data.action
    local tableName = data.tableName
    local model = data.model
    local coords = data.data

    -- Affichage des données pour vérification
    print("Action:", action)
    print("Table Name:", tableName)
    print("Model:", model)
    print("Coords:", coords.PosX, coords.PosY, coords.PosZ, coords.RotX, coords.RotY, coords.RotZ, coords.Distance)

    -- Votre logique pour traiter les données reçues
    -- Par exemple, supprimer une coordonnée de votre base de données
    -- Envoi des données au serveur
    TriggerServerEvent('esx:looting:removeCoordsFromModel', tableName, model, coords)

    cb({ status = 'ok' })
end)

RegisterNUICallback('addCoordsToList', function(data, cb)
    -- Récupération des données envoyées depuis le JavaScript
    local action = data.action
    local tableName = data.tableName
    local model = data.model

    -- Affichage des données pour vérification
    print("Action:", action)
    print("Table Name:", tableName)
    print("Model:", model)

    -- Votre logique pour traiter les données reçues
    if tableName == 'recupPropsTable' then
        -- Logique pour la table recupPropsTable
        print("Traite les données pour recupPropsTable")
        closeLootNUI()

        TriggerEvent('esx:looting:startPlaceModel', model, tableName)

    elseif tableName == 'ressourcePropsTable' then
        -- Logique pour la table recupPropsTable
        print("Traite les données pour ressourcePropsTable")
        closeLootNUI()

        TriggerEvent('esx:looting:startPlaceModel', model, tableName)
    elseif tableName == 'zoneLootTable' then
        -- Logique pour la table zoneLootTable
        print("Traite les données pour zoneLootTable")
        closeLootNUI()

        local input = lib:inputDialog('Enregistrement des Coords.', {
            {type = 'number', label = 'Distance.', description = "Ecrivez ci-dessous la distance.", placeholder = 5, required = true},
        })

        if input and input[1] then
            -- Récupération des coordonnées du joueur
            local playerPed = GetPlayerPed(-1)
            local pos = GetEntityCoords(playerPed)
            local rot = GetEntityRotation(playerPed)

            local distance = input[1]

            local coords = {
                PosX = pos.x,
                PosY = pos.y,
                PosZ = pos.z,
                RotX = rot.x,
                RotY = rot.y,
                RotZ = rot.z,
                Distance = distance
            }

            TriggerServerEvent('esx:looting:addCoordsToList', tableName, model, coords)
        end
    else
        -- Logique pour d'autres tables ou une erreur
        print("Nom de table non reconnu:", tableName)
    end

    -- Envoi des données au serveur
    cb({ status = 'ok' })
end)