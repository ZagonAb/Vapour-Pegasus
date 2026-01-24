function hasFilterGames(filterIndex, api) {
    switch(filterIndex) {
        case 0:
            return api.allGames.count > 0;

        case 1:
            for (var i = 0; i < api.allGames.count; i++) {
                if (api.allGames.get(i).favorite) {
                    return true;
                }
            }
            return false;

        case 2:
            for (var i = 0; i < api.allGames.count; i++) {
                if (api.allGames.get(i).playCount > 0) {
                    return true;
                }
            }
            return false;

        case 3:
            for (var i = 0; i < api.allGames.count; i++) {
                var game = api.allGames.get(i);
                var lastPlayed = game.lastPlayed;
                if (lastPlayed &&
                    lastPlayed.getTime &&
                    lastPlayed.getTime() > 0) {
                    return true;
                    }
            }
            return false;

        case 4:
            return api.collections.count > 0;

        default:
            return false;
    }
}

function getNextValidFilterIndex(currentIndex, direction, api) {
    var filterCount = 5;
    var attempts = 0;
    var newIndex = currentIndex;

    while (attempts < filterCount) {
        if (direction === "next") {
            newIndex = (newIndex + 1) % filterCount;
        } else {
            newIndex = (newIndex - 1 + filterCount) % filterCount;
        }

        if (hasFilterGames(newIndex, api)) {
            return newIndex;
        }

        attempts++;
    }

    return currentIndex;
}


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
    var collection = game.collections.get(0);
    if (collection && collection.name) {
        return collection.name;
    }
    return "Unknown";
}

function launchGame(game, api) {
    if (!game) {
        return;
    }
    var originalGame = findOriginalGame(game, api);

    if (!originalGame) {
        return;
    }

    /*api.memory.set('lastGameIndex', api.allGames.toVarArray().indexOf(originalGame));*/

    originalGame.launch();
}

function updateFilter(index, root) {
    switch(index) {
        case 0:
            root.currentCollection = api.allGames;
            root.collectionFilter = "all";
            root.showingCollections = false;
            break;

        case 1:
            root.currentCollection = root.favoritesFilter;
            root.collectionFilter = "favorites";
            root.showingCollections = false;
            break;

        case 2:
            root.currentCollection = root.mostPlayedFilter;
            root.collectionFilter = "mostplayed";
            root.showingCollections = false;
            break;

        case 3:
            root.currentCollection = root.recentlyPlayedFilter;
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

function cleanGameTitle(title) {
    if (!title || typeof title !== 'string') {
        return title || '';
    }

    const patterns = [
        /\s*\([^)]*(?:USA|NGM|Euro|Europe|Japan|World|Japan, USA|Korea|Asia|Brazil|Germany|France|Italy|Spain|UK|Australia|Canada|rev|sitdown|set|Hispanic|China|Ver|ver|US|68k|bootleg|Nintendo|Taiwan|Hong Kong|Latin America|Mexico|Russia|Sweden|Netherlands|Belgium|Portugal|Greece|Finland|Norway|Denmark|Poland|Czech|Slovak|Hungary|Romania|Bulgaria|Croatia|Serbia|Turkey|Israel|UAE|Saudi Arabia|South Africa|Egypt|Philippines|Indonesia|Malaysia|Singapore|Thailand|Vietnam)[^)]*\)/gi,
        /\s*\([^)]*(?:Rev \d+|Version \d+|v\d+\.\d+|Update \d+|Beta|Alpha|Demo|Prototype|Unl|Sample|Preview|Trial)[^)]*\)/gi,
        /\s*\([^)]*(?:NES|SNES|N64|GC|Wii|Switch|GB|GBC|GBA|DS|3DS|PS1|PS2|PS3|PS4|PS5|PSP|Vita|Xbox|Xbox 360|Xbox One|Genesis|Mega Drive|Saturn|Dreamcast|Arcade|MAME|FBA|Neo Geo)[^)]*\)/gi,
        /\s*-\s*(?:USA|EUR|JPN|KOR|ASI|BRA|GER|FRA|ITA|SPA|UK|AUS|CAN|CHN|TWN|HKG|LAT|MEX|RUS)[\s\-]*/gi,
        /\s*\[[^\]]*(?:Rev \d+|v\d+\.\d+)[^\]]*\]/gi,
        /\s*\[[^\]]*(?:Good|Bad|Overdump|Underdump|Verified|Trurip|No-Intro|Redump)[^\]]*\]/gi,
        /\s*\[[^\]]*(?:Crack|Trainer|Cheat|Hack|Patch|Fixed|Translated)[^\]]*\]/gi,
        /\s*\[[^\]]*(?:!\?|!\s*|\(\?\))[^\]]*\]/gi,
        /\s*\(Disk \d+ of \d+\)/gi,
        /\s*\(Side [A-B]\)/gi,
        /\s*\(Track \d+\)/gi,
        /\s*\([\d\s]+in[\d\s]+\)/gi,
        /\s*\(\d{4}[-\.]\d{2}[-\.]\d{2}\)/,
        /\s*\(\s*\d{4}\s*\)/gi
        ];

        let cleanedTitle = title;

        patterns.forEach(pattern => {
            cleanedTitle = cleanedTitle.replace(pattern, '');
        });

        cleanedTitle = cleanedTitle
        .replace(/ZZZ\(notgame\):\s*/gi, '')
        .replace(/ZZZ\(notgame\):#\s*/gi, '');

        cleanedTitle = cleanedTitle
        .replace(/^\s+|\s+$/g, '')
        .replace(/\s{2,}/g, ' ')
        .replace(/^[-\s]+|[-\s]+$/g, '')
        .replace(/,\s*$/, '')
        .replace(/\.\s*$/, '');

        if (!cleanedTitle || cleanedTitle.trim() === '') {
            return title.trim();
        }

        return cleanedTitle.trim();
}

function findOriginalGame(game, api) {
    if (!game || !api || !api.allGames) {
        return null;
    }

    var allGamesArray = api.allGames.toVarArray();

    for (var i = 0; i < allGamesArray.length; i++) {
        var originalGame = allGamesArray[i];

        if (originalGame.title === game.title &&
            originalGame.sortBy === game.sortBy) {
            return originalGame;
            }
    }

    return null;
}

function toggleFavorite(game, api, root) {
    if (!game || !api) {
        return false;
    }

    var originalGame = findOriginalGame(game, api);

    if (!originalGame) {
        return false;
    }

    var wasInFavorites = root && root.collectionFilter === "favorites";
    var wasLastFavorite = false;

    if (wasInFavorites && originalGame.favorite) {
        var favoriteCount = 0;
        for (var i = 0; i < api.allGames.count; i++) {
            if (api.allGames.get(i).favorite) {
                favoriteCount++;
            }
        }
        wasLastFavorite = (favoriteCount === 1);
    }

    originalGame.favorite = !originalGame.favorite;

    if (wasLastFavorite && !originalGame.favorite && root) {
        Qt.callLater(function() {
            root.collectionFilter = "all";
            root.currentCollection = api.allGames;
            root.showingCollections = false;

            if (root.gameListView) {
                root.gameListView.currentIndex = 0;
            }

            var filterListView = root.children[0];
            for (var i = 0; i < root.children.length; i++) {
                var child = root.children[i];
                if (child.objectName === "unifiedFilterListView") {
                    child.currentIndex = 0;
                    break;
                }
            }
        });
    }

    return originalGame.favorite;
}

function isFavorite(game, api) {
    if (!game || !api) {
        return false;
    }

    var originalGame = findOriginalGame(game, api);

    if (!originalGame) {
        return false;
    }

    return originalGame.favorite;
}


/*function debugCollection(collection, name) {
    console.log("=== " + name + " ===");
    console.log("Count:", collection.count);
    if (collection.count > 0) {
        for (var i = 0; i < Math.min(collection.count, 5); i++) {
            var game = collection.get(i);
            console.log(i + ":", game.title,
                        "- playTime:", game.playTime + "s (" + formatPlayTime(game.playTime) + ")",
                        "- playCount:", game.playCount,
                        "- favorite:", game.favorite,
                        "- lastPlayed:", game.lastPlayed ? game.lastPlayed.toString() : "Never");
        }
    }
    console.log("=================");
}

function debugFilterCounts(api) {
    console.log("=== Filter Debug ===");
    console.log("Total games:", api.allGames.count);

    var favCount = 0;
    var playedCount = 0;
    var recentCount = 0;

    for (var i = 0; i < api.allGames.count; i++) {
        var game = api.allGames.get(i);
        if (game.favorite) favCount++;
        if (game.playCount > 0) playedCount++;

        var lp = game.lastPlayed;
        if (lp && lp.getTime && lp.getTime() > 0) {
            recentCount++;
            console.log("Recently played:", game.title, "at", lp);
        }
    }

    console.log("Favorites:", favCount);
    console.log("Most Played:", playedCount);
    console.log("Recently Played:", recentCount);
    console.log("==================");
}*/
