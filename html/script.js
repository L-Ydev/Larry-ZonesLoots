let ressourcePropsData = [];
let lootingPropsData = [];
let recuperablePropsData = [];
let zoneListData = [];

let selectedModel = '';

window.onload = function() {
    document.body.style.display = 'none';

    window.addEventListener('message', function(event) {
        var data = event.data;
    
        switch(data.action) {
            case 'openLootNUI':
                // Affichage de l'interface
                document.body.style.display = 'block';
                
                // Traitement des données envoyées
                let ressourcePropsData = data.ressourceProps;
                let lootingPropsData = data.lootingProps;
                let recuperablePropsData = data.recuperableProps;
                let zoneListData = data.zoneList;
    
                // Insérez les données dans vos tables ou faites tout autre traitement nécessaire ici.
                populateTable('ressourcePropsTable', ressourcePropsData);
                populateTable('lootablePropsTable', lootingPropsData);
                populateTable('recupPropsTable', recuperablePropsData);
                populateTable('zoneLootTable', zoneListData);
                
                break;
    
            case 'closeLootNUI':
                document.body.style.display = 'none';
                break;
        }
    });
}

function populateTable(tableID, data) {
    let table = document.getElementById(tableID);
    let tbody = table.querySelector('tbody');

    // Vider la table actuelle
    tbody.innerHTML = '';

    data.forEach(row => {
        let tr = document.createElement('tr');

        // Créez trois boutons avec des icônes FontAwesome clicables pour chaque ligne
        // const editButton = createIconButton('fas fa-pencil-alt', () => {
        //     // Logique pour l'édition
        //     // alert('Vous pouvez implémenter la logique de modification ici.');
        // });

        const deleteButton = createIconButton('fas fa-trash-alt', () => {
            // Logique pour la suppression
            const tableName = tableID; // Le nom de la liste
            const model = row.model; // Le modèle à supprimer
    
            // Envoyer ces données au serveur via une requête Fetch
            sendDeleteRequestToServer(tableName, model);
        });
    
        const detailsButton = createIconButton('fas fa-info-circle', () => {
            // Logique pour les détails
            // Ouvrir le modal et remplir la liste des items
            openItemsModal(row.items, tableID, row.model); // row.items contient la liste des items à afficher
        });

        
        // Ajoutez les boutons à la cellule "Options"
        // Ajoutez les boutons à la cellule "Options"
        const optionsTd = document.createElement('td');
        optionsTd.className = 'options-column';
        optionsTd.appendChild(detailsButton);

        // Si la table est recupPropsTable et row.coords est défini, ajoutez un bouton "fas positions"
        if (row.coords && row.coords.length > 0) {
            const positionsButton = createIconButton('fas fa-map-marker-alt', () => {
                // Ajoutez ici la logique pour gérer le clic sur le bouton "positions"
                openCoordinatesModal(row.coords, tableID, row.model);
            });
            optionsTd.appendChild(positionsButton);
        }
        
        optionsTd.appendChild(deleteButton);

        // optionsTd.appendChild(editButton);
        optionsTd.appendChild(deleteButton);

        // Définissez une largeur fixe pour la colonne "Options" (par exemple, 100px)
        optionsTd.style.width = '100px';

        // Comptez le nombre d'articles dans la liste JSON
        const itemsCount = countItemsInJSON(row.items);

        // Ajoutez le nombre d'articles à la cellule "Items" avec une classe CSS
        const itemsTd = document.createElement('td');
        itemsTd.textContent = itemsCount;
        itemsTd.classList.add('items-column'); // Ajoutez cette classe
        itemsTd.style.width = '50px';

        // Ajoutez les autres valeurs de la ligne (sauf la colonne "Items")
        appendToRow(tr, [row.model, row.label, row.required]);

        // Ajoutez la cellule "Options" à la ligne
        tr.appendChild(itemsTd);
        tr.appendChild(optionsTd);


        // Ajoutez la ligne à la table
        tbody.appendChild(tr);
    });
}

function openCoordinatesModal(coordinates, tableName, model) {
    const modal = document.getElementById('coordinatesModal');
    if (!modal) {
        console.error('Modal not found!');
        return;
    }

    const tableBody = modal.querySelector('#coordinatesTable tbody');
    if (!tableBody) {
        console.error('Table body not found!');
        return;
    }

    const modelNameDisplay = modal.querySelector('#coordModelNameDisplay');
    if (!modelNameDisplay) {
        console.error('Model name display not found!');
        return;
    }

    modelNameDisplay.textContent = model;
    tableBody.innerHTML = '';

    if (typeof coordinates === 'string') {
        try {
            coordinates = JSON.parse(coordinates);
        } catch (error) {
            console.error('Erreur lors de l\'analyse de la chaîne JSON:', error);
            return;
        }
    }

    if (!Array.isArray(coordinates)) {
        console.error('Coordinates is not an array:', coordinates);
        return;
    }

    const addButton = modal.querySelector('.add-button-coords');
    if (addButton) {
        addButton.onclick = function() {
            modal.style.display = 'none';

            // Logique pour ajouter de nouvelles coordonnées
            // Par exemple, afficher un formulaire pour saisir de nouvelles coordonnées
            // ou ouvrir un autre modal pour cela.
            fetch(`https://${GetParentResourceName()}/addCoordsToList`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    action: 'addCoordsToList',
                    tableName: tableName,
                    model: model
                })
            }).then(response => response.json()).then(data => {
                if (data && data.status && data.status !== 'ok') {
                    console.error('Erreur lors de l\'envoi du message NUI:', data);
                }
            })
        };
    } else {
        console.warn('Add button not found!');
    }

    coordinates.forEach(coord => {
        const tr = document.createElement('tr');

        ['PosX', 'PosY', 'PosZ', 'RotX', 'RotY', 'RotZ'].forEach(axis => {
            const td = document.createElement('td');
            td.textContent = coord[axis];
            tr.appendChild(td);
        });

        // Ajout de la cellule pour la distance
        const distanceTd = document.createElement('td');
        distanceTd.textContent = (coord['Distance'] !== undefined && coord['Distance'] !== null) ? coord['Distance'] : "N/A";
        tr.appendChild(distanceTd);


        const actionTd = document.createElement('td');
        const deleteButton = createIconButton('fas fa-trash-alt', () => {
            // Supprimer la ligne du tableau
            tr.remove();
        
            // Envoyer un message au client Lua via fetch et NUI
            // Remplacez 'YOUR_NUI_MESSAGE_NAME' par le nom de votre message NUI
            // et 'YOUR_DATA_TO_SEND' par les données que vous souhaitez envoyer.
            fetch(`https://${GetParentResourceName()}/removeCoordsFromModel`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    action: 'removeCoordsFromModel',
                    tableName: tableName,
                    model: model,
                    data: coord // Par exemple, vous pourriez envoyer l'ID de la coordonnée à supprimer
                })
            }).then(response => response.json()).then(data => {
                if (data && data.status && data.status !== 'ok') {
                    console.error('Erreur lors de l\'envoi du message NUI:', data);
                }
            })
        });
        actionTd.appendChild(deleteButton);
        tr.appendChild(actionTd);

        tableBody.appendChild(tr);
    });

    const closeButton = modal.querySelector('.close-button-coords');
    if (closeButton) {
        closeButton.onclick = function() {
            modal.style.display = 'none';
        };
    } else {
        console.warn('Close button not found!');
    }

    modal.style.display = 'block';
}


function openItemsModal(items, tableName, model) {
    const modal = document.getElementById('itemsModal');
    const tableBody = modal.querySelector('#itemsTable tbody');
    const modelNameDisplay = modal.querySelector('#modelNameDisplay');
    const addButton = modal.querySelector('.add-button'); // Sélectionnez le bouton Ajouter

    // Gestionnaire d'événements pour le bouton Ajouter
    addButton.onclick = function() {
        // Créez une nouvelle ligne (tr)
        const tr = document.createElement('tr');

        // Créez des cellules de données (td) avec des champs de saisie (inputs) pour chaque colonne
        const itemNameTd = createInputCell('text', 'Item Name');
        const minTd = createInputCell('number', 'Min');
        const maxTd = createInputCell('number', 'Max');
        const chanceTd = createInputCell('number', 'Chance');

        // Créez une cellule de données pour le bouton "Check" de validation
        const actionTd = document.createElement('td');
        const checkButton = createIconButton('fas fa-check', () => {
            // Récupérez les valeurs saisies
            const newItem = {
                name: itemNameTd.firstChild.value,
                min: parseFloat(minTd.firstChild.value),
                max: parseFloat(maxTd.firstChild.value),
                chance: parseFloat(chanceTd.firstChild.value),
            };
        
            // Ajoutez les nouvelles données à votre tableau
            items.push(newItem);
        
            // Envoyez les informations au client.lua via fetch
            fetch(`https://${GetParentResourceName()}/addItemToListModel`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    action: "sendInputData",
                    tableName: tableName,
                    model: model,
                    data: newItem
                })
            })

            // Supprimez la ligne d'édition
            tr.remove();
        
            // Créez une nouvelle ligne avec les informations récupérées
            const newTr = document.createElement('tr');
        
            const newNameTd = document.createElement('td');
            newNameTd.textContent = newItem.name;
        
            const newMinTd = document.createElement('td');
            newMinTd.textContent = newItem.min;
        
            const newMaxTd = document.createElement('td');
            newMaxTd.textContent = newItem.max;
        
            const newChanceTd = document.createElement('td');
            newChanceTd.textContent = newItem.chance;
        
            // Créez une cellule pour le bouton d'action (par exemple, supprimer l'item)
            const newActionTd = document.createElement('td');
            const newdeleteButton = createIconButton('fas fa-trash-alt', () => {
                // 1. Identifiez l'élément à supprimer
                const itemToDelete = newItem.name; // Supposons que le nom soit unique

                // 2. Supprimez l'élément de la liste `items`
                const index = items.findIndex(i => i.name === itemToDelete);
                if (index !== -1) {
                    items.splice(index, 1);
                }

                // 3. Envoyez une requête à `client.lua` pour informer le serveur que l'élément doit être supprimé
                fetch(`https://${GetParentResourceName()}/deleteItemFromListModel`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({
                        action: "deleteItem",
                        tableName: tableName,
                        model: model,
                        itemName: itemToDelete
                    })
                });

            // 4. Mettez à jour l'affichage pour refléter les changements
            newTr.remove();
            
            });
            newActionTd.appendChild(newdeleteButton);
        
            // Ajoutez toutes les cellules à la nouvelle ligne
            newTr.appendChild(newNameTd);
            newTr.appendChild(newMinTd);
            newTr.appendChild(newMaxTd);
            newTr.appendChild(newChanceTd);
            newTr.appendChild(newActionTd);
        
            // Ajoutez la nouvelle ligne au tableau
            tableBody.appendChild(newTr);
        });
        actionTd.appendChild(checkButton);

        // Ajoutez les cellules de données (inputs et bouton "Check") à la nouvelle ligne
        tr.appendChild(itemNameTd);
        tr.appendChild(minTd);
        tr.appendChild(maxTd);
        tr.appendChild(chanceTd);
        tr.appendChild(actionTd);

        // Ajoutez la nouvelle ligne au corps du tableau
        tableBody.appendChild(tr);
    };

    // Définissez le nom du modèle
    modelNameDisplay.textContent = model;

    // Effacez le contenu précédent de la liste des items
    tableBody.innerHTML = '';

    // Vérifiez si items est une chaîne JSON et essayez de la convertir en tableau
    if (typeof items === 'string') {
        try {
            items = JSON.parse(items);
        } catch (error) {
            console.error('Erreur lors de l\'analyse de la chaîne JSON:', error);
            return; // Quittez la fonction si l'analyse échoue
        }
    }

    // Vérifiez si items est maintenant un tableau
    if (!Array.isArray(items)) {
        console.error('items n\'est pas un tableau:', items);
        return; // Quittez la fonction si items n'est pas un tableau
    }

    // Remplissez le tableau avec les items
    items.forEach(item => {
        const tr = document.createElement('tr');

        // Créez des cellules pour chaque propriété de l'item
        const nameTd = document.createElement('td');
        nameTd.textContent = item.name;

        const minTd = document.createElement('td');
        minTd.textContent = item.min;

        const maxTd = document.createElement('td');
        maxTd.textContent = item.max;

        const chanceTd = document.createElement('td');
        chanceTd.textContent = item.chance;

        // Créez une cellule pour le bouton d'action (par exemple, supprimer l'item)
        const actionTd = document.createElement('td');
        const deleteButton = createIconButton('fas fa-trash-alt', () => {
            // 1. Identifiez l'élément à supprimer
            const itemToDelete = item.name; // Supposons que le nom soit unique

            // 2. Supprimez l'élément de la liste `items`
            const index = items.findIndex(i => i.name === itemToDelete);
            if (index !== -1) {
                items.splice(index, 1);
            }

            // 3. Envoyez une requête à `client.lua` pour informer le serveur que l'élément doit être supprimé
            fetch(`https://${GetParentResourceName()}/deleteItemFromListModel`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    action: "deleteItem",
                    tableName: tableName,
                    model: model,
                    itemName: itemToDelete
                })
            });

            // 4. Mettez à jour l'affichage pour refléter les changements
            tr.remove();
        });
        actionTd.appendChild(deleteButton);

        // Ajoutez toutes les cellules à la ligne
        tr.appendChild(nameTd);
        tr.appendChild(minTd);
        tr.appendChild(maxTd);
        tr.appendChild(chanceTd);
        tr.appendChild(actionTd);

        tableBody.appendChild(tr);
    });

    // Gestionnaire d'événements pour fermer le modal
    const closeButton = modal.querySelector('.close-button');
    closeButton.onclick = function() {
        modal.style.display = 'none';
    };

    // Affichez le modal
    modal.style.display = 'block';
}

// Fonction utilitaire pour créer une cellule de données avec un champ de saisie
function createInputCell(type, placeholder) {
    const td = document.createElement('td');
    const input = document.createElement('input');
    input.type = type;
    input.placeholder = placeholder;
    input.style.width = '95%'; // Utilisez 95% de la largeur de la cellule pour laisser un peu d'espace
    td.appendChild(input);
    return td;
}

// Fonction utilitaire pour créer un bouton d'action avec une icône
function createIconButton(iconClass, clickHandler) {
    const button = document.createElement('button');
    button.classList.add('custom-action-button');
    const icon = document.createElement('i');
    icon.className = iconClass;
    button.appendChild(icon);
    button.addEventListener('click', clickHandler);
    return button;
}

// Fonction pour envoyer une requête de suppression au serveur
function sendDeleteRequestToServer(tableName, model) {
    fetch(`https://${GetParentResourceName()}/deletePropInList`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            action: "deletePropInList",
            tableName: tableName,
            model: model
        })
    }).then(response => {
        if (response.ok) {
            // La suppression a réussi, vous pouvez gérer la réponse ici
            alert('Suppression réussie!');
        } else {
            // La suppression a échoué, vous pouvez gérer l'erreur ici
            alert('Échec de la suppression.');
        }
    }).catch(error => {
        console.error('Erreur lors de la suppression :', error);
    });
}

// Fonction pour compter le nombre d'articles dans la liste JSON
function countItemsInJSON(itemsJSON) {
    try {
        const itemsArray = JSON.parse(itemsJSON);
        return itemsArray.length;
    } catch (error) {
        console.error('Erreur lors de l\'analyse de la liste d\'articles JSON :', error);
        return 0; // En cas d'erreur, renvoie 0
    }
}

// Fonction utilitaire pour créer un bouton avec une icône FontAwesome
function createIconButton(iconClass, clickHandler) {
    const button = document.createElement('button');
    button.className = 'custom-icon-button'; // Appliquez la classe définie dans votre CSS
    const icon = document.createElement('i');
    icon.className = iconClass;
    button.appendChild(icon);
    button.addEventListener('click', clickHandler);
    return button;
}

function appendToRow(tr, values) {
    values.forEach(val => {
        let td = document.createElement('td');
        td.textContent = val;
        tr.appendChild(td);
    });
}

document.addEventListener('keydown', function(event) {
    // Échap
    if (event.key === "Escape" && document.body.style.display == 'block') {
        fetch(`https://${GetParentResourceName()}/closeLootNUI`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                action: "closeLootNUI"
            })
        });
        document.body.style.display = 'none';
    }
});

document.addEventListener('DOMContentLoaded', function() {
    const modal = document.getElementById('itemsModal');
    // const closeModalButton = modal.querySelector('.itemsModal-close');

    // closeModalButton.addEventListener('click', function() {
    //     // Masquez le modal en modifiant son style
    //     modal.style.display = 'none';
    // });

    // Sélectionnez tous les boutons de navigation
    const navButtons = document.querySelectorAll('.nav-btn');
    const actionButtons = document.getElementById('actionButtons');

    // Ajoutez un écouteur d'événements à chaque bouton
    navButtons.forEach(function(button) {
        button.addEventListener('click', function() {
            // Cache tous les contenus
            const contents = document.querySelectorAll('.content');
            contents.forEach(content => {
                content.style.display = 'none';
            });

            // Affiche le contenu correspondant
            const targetContent = document.getElementById(this.getAttribute('data-target'));
            targetContent.style.display = 'block';

            // Affiche les boutons d'action
            actionButtons.style.display = 'flex';
        });
    });

    const addButton = document.querySelector('.action-buttons .action-btn');
    let isEditing = false; // Variable pour suivre l'état d'édition
    
    addButton.addEventListener('click', function() {
        // 1. Trouver le contenu actuellement affiché
        const displayedContent = document.querySelector('.content[style="display: block;"]');
        if (displayedContent) {
            // 2. Identifier la table dans ce contenu
            const table = displayedContent.querySelector('table tbody');
            if (table) {
                // Vérifier si une ligne est déjà en cours d'édition
                if (isEditing) {
                    // Si une édition est en cours, changez le texte du bouton en "Ajouter"
                    addButton.textContent = "Ajouter";
                    // Retirez la classe "retirer" du bouton
                    addButton.classList.remove('retirer');
                    isEditing = false;
                    // Retirer la dernière ligne (en mode ajout)
                    table.lastElementChild.remove();
                } else {
                    // Si aucune édition en cours, changez le texte du bouton en "Retirer"
                    addButton.textContent = "Retirer";
                    // Ajoutez la classe "retirer" au bouton pour le stylage CSS
                    addButton.classList.add('retirer');
                    // Créez une nouvelle ligne pour l'ajout
                    const tr = document.createElement('tr');
                    let values = [];
    
                    switch (table.parentElement.id) {
                        case 'ressourcePropsTable':
                        case 'recupPropsTable':
                        case 'lootablePropsTable':
                            values = ["", "", ""];
                            break;
                        case 'zoneLootTable':
                            values = ["", "", ""];
                            break;
                    }
    
                    // Ajouter des éléments éditables à chaque cellule
                    values.forEach(val => {
                        const td = document.createElement('td');
                        const input = document.createElement('input');
                        input.value = val;
                        input.type = "text";
                        input.className = 'custom-input'; // Appliquez le style défini
                        td.appendChild(input);
                        tr.appendChild(td);
                    });
    
                    // Ajouter une cellule pour "Items" avec le texte '[]'
                    const itemsTd = document.createElement('td');
                    itemsTd.textContent = '[]';
                    tr.appendChild(itemsTd);

                    
    
                    // Créer un bouton
                    const checkButton = document.createElement('button');
                    checkButton.className = 'custom-check-button'; // Utilisez la classe définie dans votre CSS
    
                    // Ajouter une cellule pour "Options" avec une icône "check" enveloppée dans un bouton
                    const optionsTd = document.createElement('td');
    
                    const checkIcon = document.createElement('i');
                    checkIcon.className = 'fas fa-check';
    
                    // Insérez l'icône dans le bouton
                    checkButton.appendChild(checkIcon);
    
                    // Ajoutez l'écouteur d'événements au bouton
                    // Ajoutez l'écouteur d'événements au bouton
                    checkButton.addEventListener('click', function() {
                        const row = this.closest('tr');
                        const inputs = row.querySelectorAll('input');
                        let inputData = [];

                        inputs.forEach(input => {
                            inputData.push(input.value);
                        });

                        const tableName = table.parentElement.id;
                        sendInputDataToClient(tableName, inputData);

                        // Ajouter les données à la liste
                        addDataToList(tableName, inputData);

                        // Notification ou message de confirmation
                        // alert('Données ajoutées avec succès à la liste!');

                        // Remettre la ligne en mode d'édition
                        row.remove();

                        // Ajouter une nouvelle ligne avec les données en mode affichage
                        let tr = document.createElement('tr');

                        if (tableName === "ressourcePropsTable" || tableName === "recupPropsTable" || tableName === "lootablePropsTable") {
                            appendToRow(tr, [inputData[0], inputData[1], inputData[2], "[]", "Options"]);
                        } else if (tableName === "zoneLootTable") {
                            appendToRow(tr, [inputData[0], inputData[1], inputData[2], "[]", "Options"]);
                        }

                        table.appendChild(tr);

                        // Remettre le bouton sur "Ajouter" après l'ajout
                        addButton.textContent = "Ajouter";
                        // Retirez la classe "retirer" du bouton
                        addButton.classList.remove('retirer');

                        // Remettre l'état d'édition à faux après l'ajout
                        isEditing = false;
                    });    

                    optionsTd.appendChild(checkButton);
                    tr.appendChild(optionsTd);
    
                    // 4. Insérer la nouvelle ligne dans la table
                    table.appendChild(tr);
    
                    // Mettre l'état d'édition à vrai lorsque vous commencez à éditer
                    isEditing = true;
                }
            }
        }
    });
    
    const closeButton = document.querySelector('.close-btn');
    closeButton.addEventListener('click', function() {
        fetch(`https://${GetParentResourceName()}/closeLootNUI`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                action: "closeLootNUI"
            })
        });
        document.body.style.display = 'none';    
    });
});

function sendInputDataToClient(tableName, inputData) {
    fetch(`https://${GetParentResourceName()}/sendInputData`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            action: "sendInputData",
            tableName: tableName,
            data: inputData
        })
    });
}

function addDataToList(tableName, data) {
    switch (tableName) {
        case 'ressourcePropsTable':
            ressourcePropsData.push({
                model: data[0],
                label: data[1],
                required: data[2],
                items: "[]"
            });
            break;
        case 'lootablePropsTable':
            lootingPropsData.push({
                model: data[0],
                label: data[1],
                required: data[2],
                items: "[]"
            });
            break;
        case 'recupPropsTable':
            recuperablePropsData.push({
                model: data[0],
                label: data[1],
                required: data[2],
                items: "[]"
            });
            break;
        case 'zoneLootTable':
            zoneListData.push({
                label: data[0],
                position: data[1],
                distance: data[2],
                items: "[]"
            });
            break;
    }
}
