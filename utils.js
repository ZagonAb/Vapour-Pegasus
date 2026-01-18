// Format play time from seconds to readable format
function formatPlayTime(seconds) {
    if (!seconds || seconds === 0) return "Not Played";

    var hours = Math.floor(seconds / 3600);
    var minutes = Math.floor((seconds % 3600) / 60);

    if (hours > 0) {
        return hours + "h " + minutes + "m";
    }
    return minutes + "m";
}

// Get the first collection name for a game
function getCollectionName(game) {
    if (!game || !game.collections || game.collections.count === 0) {
        return "Unknown";
    }
    return game.collections.get(0).name;
}

// Launch game and save state
function launchGame(game, api) {
    if (!game) return;

    // Save current game index before launching
    api.memory.set('lastGameIndex', api.allGames.toVarArray().indexOf(game));

    // Launch the game
    game.launch();
}


// Update filter based on index
function updateFilter(index, root) {
    switch(index) {
        case 0: // All
            root.currentCollection = api.allGames;
            root.collectionFilter = "all";
            root.showingCollections = false;
            break;

        case 1: // Favorites
            var favoritesModel = Qt.createQmlObject(
                'import SortFilterProxyModel 0.2; SortFilterProxyModel { sourceModel: api.allGames; filters: ValueFilter { roleName: "favorite"; value: true } }',
                root
            );
            root.currentCollection = favoritesModel;
            root.collectionFilter = "favorites";
            root.showingCollections = false;
            break;

        case 2: // Most Played
            var mostPlayedModel = Qt.createQmlObject(
                'import SortFilterProxyModel 0.2; SortFilterProxyModel { sourceModel: api.allGames; sorters: RoleSorter { roleName: "playCount"; sortOrder: Qt.DescendingOrder } }',
                root
            );
            root.currentCollection = mostPlayedModel;
            root.collectionFilter = "mostplayed";
            root.showingCollections = false;
            break;

        case 3: // Recently Played
            var recentModel = Qt.createQmlObject(
                'import SortFilterProxyModel 0.2; SortFilterProxyModel { sourceModel: api.allGames; sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder } }',
                root
            );
            root.currentCollection = recentModel;
            root.collectionFilter = "recent";
            root.showingCollections = false;
            break;

        case 4: // Collections
            root.collectionFilter = "collections";
            // Collections view será manejada automáticamente
            break;
    }

    // Reset current game to first item if collection exists
    if (root.currentCollection && root.currentCollection.count > 0) {
        root.currentGame = root.currentCollection.get(0);
        // NO intentar acceder a gameListView aquí
    }
}

// En utils.js, agregar esta función si no existe
function createAsyncImage(parent, source) {
    return Qt.createQmlObject(
        'import QtQuick 2.15; Image { asynchronous: true; cache: true; }',
        parent
    );
}

// Format date to locale string
function formatDate(date) {
    if (!date || date.getTime() === 0) {
        return "Never";
    }
    return Qt.formatDate(date, "dd/MM/yyyy");
}
