function formatPlayTime(seconds) {
    if (!seconds || seconds === 0) return "Not Played";

    var hours = Math.floor(seconds / 3600);
    var minutes = Math.floor((seconds % 3600) / 60);

    if (hours > 0) {
        return hours + "h " + minutes + "m";
    }
    return minutes + "m";
}

function getCollectionName(game) {
    if (!game || !game.collections || game.collections.count === 0) {
        return "Unknown";
    }
    return game.collections.get(0).name;
}

function launchGame(game, api) {
    if (!game) return;
    api.memory.set('lastGameIndex', api.allGames.toVarArray().indexOf(game));
    game.launch();
}

function updateFilter(index, root) {
    switch(index) {
        case 0:
            root.currentCollection = api.allGames;
            root.collectionFilter = "all";
            root.showingCollections = false;
            break;

        case 1:
            var favoritesModel = Qt.createQmlObject(
                'import SortFilterProxyModel 0.2; SortFilterProxyModel { sourceModel: api.allGames; filters: ValueFilter { roleName: "favorite"; value: true } }',
                root
            );
            root.currentCollection = favoritesModel;
            root.collectionFilter = "favorites";
            root.showingCollections = false;
            break;

        case 2:
            var mostPlayedModel = Qt.createQmlObject(
                'import SortFilterProxyModel 0.2; SortFilterProxyModel { sourceModel: api.allGames; sorters: RoleSorter { roleName: "playCount"; sortOrder: Qt.DescendingOrder } }',
                root
            );
            root.currentCollection = mostPlayedModel;
            root.collectionFilter = "mostplayed";
            root.showingCollections = false;
            break;

        case 3:
            var recentModel = Qt.createQmlObject(
                'import SortFilterProxyModel 0.2; SortFilterProxyModel { sourceModel: api.allGames; sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder } }',
                root
            );
            root.currentCollection = recentModel;
            root.collectionFilter = "recent";
            root.showingCollections = false;
            break;

        case 4:
            root.collectionFilter = "collections";
            break;
    }

    if (root.currentCollection && root.currentCollection.count > 0) {
        root.currentGame = root.currentCollection.get(0);
    }
}

function createAsyncImage(parent, source) {
    return Qt.createQmlObject(
        'import QtQuick 2.15; Image { asynchronous: true; cache: true; }',
        parent
    );
}

function formatDate(date) {
    if (!date || date.getTime() === 0) {
        return "Never";
    }
    return Qt.formatDate(date, "dd/MM/yyyy");
}
