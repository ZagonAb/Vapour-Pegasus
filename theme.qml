import QtQuick 2.15
import QtGraphicalEffects 1.15
import QtMultimedia 5.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: root

    property string currentView: "home"
    property var currentGame: null
    property var currentCollection: api.allGames
    property string collectionFilter: "all"
    property bool showingCollections: false
    property int selectedCollectionIndex: 0
    property var detailsView: detailsViewComponent
    property var videoOverlay: videoOverlayComponent
    property string currentLetter: ""
    property var letterIndex: []
    property var focusManager: focusManager
    property var gameListView: gameViewLoader.item
    property var gameGridView: gameViewLoader.item
    property var favoritesFilter: favoritesFilterModel
    property var mostPlayedFilter: mostPlayedFilterModel
    property var recentlyPlayedFilter: recentlyPlayedFilterModel
    readonly property bool isGridViewMode: viewToggleButton.isGridView

    FavoritesFilter {
        id: favoritesFilterModel
    }

    MostPlayedFilter {
        id: mostPlayedFilterModel
    }

    RecentlyPlayedFilter {
        id: recentlyPlayedFilterModel
    }

    FocusManager {
        id: focusManager
        homeView: homeView
        detailsView: detailsViewComponent
        gameListView: gameViewLoader.item
        filterListView: unifiedFilterListView
        gameGridView: gameViewLoader.item
        themeRoot: root
    }

    Component.onCompleted: {
        if (api.allGames.count > 0) {
            currentGame = api.allGames.get(0)
        }
    }

    function buildLetterIndex() {
        letterIndex = []
        if (!currentCollection) return

            var letters = {}
            for (var i = 0; i < currentCollection.count; i++) {
                var game = currentCollection.get(i)
                var title = game.sortBy || game.title || ""
                var firstChar = title.charAt(0).toUpperCase()

                if (!letters[firstChar]) {
                    letters[firstChar] = i
                }
            }

            var sortedLetters = Object.keys(letters).sort()
            for (var j = 0; j < sortedLetters.length; j++) {
                letterIndex.push({
                    letter: sortedLetters[j],
                    index: letters[sortedLetters[j]]
                })
            }
    }

    function jumpToNextLetter() {
        if (letterIndex.length === 0 || !gameListView) return

            var currentIndex = gameListView.currentIndex
            for (var i = 0; i < letterIndex.length; i++) {
                if (letterIndex[i].index > currentIndex) {
                    gameListView.currentIndex = letterIndex[i].index
                    currentLetter = letterIndex[i].letter
                    letterTimer.restart()
                    return
                }
            }
            gameListView.currentIndex = letterIndex[0].index
            currentLetter = letterIndex[0].letter
            letterTimer.restart()
    }

    function jumpToPrevLetter() {
        if (letterIndex.length === 0 || !gameListView) return

            var currentIndex = gameListView.currentIndex
            for (var i = letterIndex.length - 1; i >= 0; i--) {
                if (letterIndex[i].index < currentIndex) {
                    gameListView.currentIndex = letterIndex[i].index
                    currentLetter = letterIndex[i].letter
                    letterTimer.restart()
                    return
                }
            }
            gameListView.currentIndex = letterIndex[letterIndex.length - 1].index
            currentLetter = letterIndex[letterIndex.length - 1].letter
            letterTimer.restart()
    }

    function validateCurrentFilter() {
        if (!showingCollections && !Utils.hasFilterGames(unifiedFilterListView.currentIndex, api)) {
            unifiedFilterListView.currentIndex = 0
            Utils.updateFilter(0, root)
            if (gameListView) {
                gameListView.currentIndex = 0
            }
            if (currentCollection.count > 0) {
                currentGame = currentCollection.get(0)
            }
        }
    }

    Rectangle {
        id: allOverlay
        anchors.fill: parent
        color: "transparent"

        Image {
            id: backgroundImage
            anchors.fill: parent
            source: {
                if (currentGame && currentGame.assets) {
                    if (currentGame.assets.background && currentGame.assets.background !== "") {
                        return currentGame.assets.background
                    }
                    if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") {
                        return currentGame.assets.screenshot
                    }
                }
                return ""
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: (currentView === "details" && videoOverlayComponent.isFullscreen) ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }

            onStatusChanged: {
                if (status === Image.Ready && !(currentView === "details" && videoOverlayComponent.isFullscreen)) {
                } else if (status === Image.Error) {
                    opacity = 0
                }
            }
        }

        VideoOverlay {
            id: videoOverlayComponent
            currentGame: root.currentGame
            z: 1
        }

        Rectangle {
            anchors.fill: parent
            z: 2
            opacity: (currentView === "details" && videoOverlayComponent.isFullscreen) ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.8; color: "#FF000000" }
                GradientStop { position: 1.0; color: "black" }
            }
        }
    }

    DetailsView {
        id: detailsViewComponent
        currentGame: root.currentGame
        themeRoot: root
        focusManager: focusManager
    }

    Rectangle {
        id: topBar
        width: parent.width
        height: vpx(50)
        color: "transparent"
        anchors.top: parent.top
        z: 10

        Row {
            id: contentRow
            anchors.right: parent.right
            anchors.rightMargin: vpx(30)
            anchors.verticalCenter: parent.verticalCenter
            spacing: vpx(15)

            Rectangle {
                id: viewToggleButton
                width: vpx(40)
                height: vpx(40)
                radius: vpx(4)
                color: "transparent"

                property bool isGridView: {
                    if (api.memory.has('viewMode')) {
                        return api.memory.get('viewMode') === 'grid'
                    }
                    return false
                }

                property bool hovered: false

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Image {
                    id: viewIcon
                    anchors.centerIn: parent
                    width: vpx(24)
                    height: vpx(24)
                    source: viewToggleButton.isGridView ?
                    "assets/icons/listview.svg" :
                    "assets/icons/gridview.svg"
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: vpx(8)
                        samples: 17
                        color: "#80000000"
                        spread: 0.2
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: viewToggleButton.isGridView ? "L" : "G"
                    font.pixelSize: vpx(18)
                    font.family: global.fonts.sans
                    font.bold: true
                    color: "#FFFFFF"
                    visible: viewIcon.status !== Image.Ready
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: vpx(8)
                        samples: 17
                        color: "#80000000"
                        spread: 0.2
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        viewToggleButton.hovered = true
                        viewToggleButton.color = "#20333333"
                    }

                    onExited: {
                        viewToggleButton.hovered = false
                        viewToggleButton.color = "transparent"
                    }

                    onClicked: {
                        var newViewMode = viewToggleButton.isGridView ? 'list' : 'grid'

                        api.memory.set('viewMode', newViewMode)

                        viewToggleButton.isGridView = (newViewMode === 'grid')

                        if (focusManager) {
                            if (newViewMode === 'grid') {
                                focusManager.gameListView = null
                                focusManager.gameGridView = gameViewLoader.item
                            } else {
                                focusManager.gameGridView = null
                                focusManager.gameListView = gameViewLoader.item
                            }
                            focusManager.setFocus("gameList")
                        }
                    }
                }
            }

            Image {
                id: pegasusLogo
                source: "assets/icons/pegasus.png"
                width: vpx(32)
                height: vpx(32)
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                mipmap: true
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 0
                    radius: vpx(12)
                    samples: 25
                    color: "#80000000"
                    spread: 0.3
                }
            }

            Text {
                id: timeText
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: vpx(18)
                font.family: global.fonts.sans
                color: "#FFFFFF"
                text: Qt.formatTime(new Date(), "hh:mm")
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 0
                    radius: vpx(12)
                    samples: 25
                    color: "#80000000"
                    spread: 0.3
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }
        }
    }

    Item {
        id: homeView
        anchors.fill: parent
        visible: currentView === "home"

        Component {
            id: starImageComponent
            Image {
                width: vpx(20)
                height: vpx(20)
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                asynchronous: true
                mipmap: true
            }
        }

        Component {
            id: playerIconComponent
            Image {
                width: vpx(25)
                height: vpx(25)
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                asynchronous: true
                mipmap: true
            }
        }

        Column {
            id: homeColumn
            anchors.left: parent.left
            anchors.leftMargin: vpx(60)
            anchors.top: parent.top
            anchors.topMargin: vpx(100)
            spacing: vpx(20)
            width: parent.width - vpx(120)
            opacity: isGridViewMode ? 0 : 1
            visible: opacity > 0
            z: 5

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }

            Item {
                width: vpx(400)
                height: vpx(150)

                readonly property var game: {
                    if (!currentGame) return null
                        if (showingCollections && currentCollection &&
                            gameListView && gameListView.currentIndex >= 0 &&
                            gameListView.currentIndex < currentCollection.count) {
                            return currentCollection.get(gameListView.currentIndex)
                            }
                            return currentGame
                }

                Image {
                    id: gameLogo
                    anchors.centerIn: parent
                    source: parent.game ? parent.game.assets.logo : ""
                    fillMode: Image.PreserveAspectFit
                    width: Math.min(implicitWidth, parent.width)
                    height: Math.min(implicitHeight, parent.height)
                    asynchronous: true
                    visible: status === Image.Ready && source !== ""
                }

                Text {
                    id: gameTitle
                    anchors.centerIn: parent
                    text: parent.game ? (parent.game.title || "") : ""
                    font.pixelSize: vpx(36)
                    font.family: global.fonts.sans
                    font.bold: true
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    width: parent.width
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    visible: gameLogo.status !== Image.Ready || gameLogo.source === ""
                }
            }

            Row {
                spacing: vpx(30)
                height: vpx(24)

                readonly property string displayTitle: {
                    if (showingCollections) {
                        if (currentCollection && currentCollection.count > 0 &&
                            gameListView && gameListView.currentIndex >= 0 &&
                            gameListView.currentIndex < currentCollection.count) {
                            var game = currentCollection.get(gameListView.currentIndex)
                            return game ? (Utils.cleanGameTitle(game.title) || "Unknown") : "No games"
                            }
                            return "No games"
                    }
                    if (currentGame && collectionFilter !== "all") {
                        return Utils.getCollectionName(currentGame)
                    }
                    return "All Games"
                }

                Text {
                    text: parent.displayTitle
                    font.pixelSize: vpx(18)
                    font.family: global.fonts.sans
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height
                }

                Text {
                    text: currentGame && currentGame.releaseYear > 0 ? currentGame.releaseYear : ""
                    font.pixelSize: vpx(18)
                    font.family: global.fonts.sans
                    color: "white"
                    visible: currentGame && currentGame.releaseYear > 0
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height
                }

                Row {
                    id: ratingRow
                    spacing: vpx(2)
                    visible: currentGame && currentGame.rating > 0
                    height: parent.height

                    readonly property real ratingValue: currentGame ? currentGame.rating : 0
                    readonly property int fullStars: Math.floor(ratingValue * 5)
                    readonly property bool hasHalfStar: (ratingValue * 5 - fullStars) >= 0.5
                    readonly property int emptyStars: 5 - fullStars - (hasHalfStar ? 1 : 0)

                    Repeater {
                        model: ratingRow.fullStars
                        delegate: Loader {
                            sourceComponent: starImageComponent
                            onLoaded: item.source = "assets/icons/star1.png"
                        }
                    }

                    Repeater {
                        model: ratingRow.hasHalfStar ? 1 : 0
                        delegate: Loader {
                            sourceComponent: starImageComponent
                            onLoaded: item.source = "assets/icons/star05.png"
                        }
                    }

                    Repeater {
                        model: ratingRow.emptyStars
                        delegate: Loader {
                            sourceComponent: starImageComponent
                            onLoaded: item.source = "assets/icons/star0.png"
                        }
                    }
                }

                Row {
                    id: playersRow
                    spacing: vpx(5)
                    visible: currentGame && currentGame.players > 1
                    height: parent.height

                    readonly property int count: currentGame ? currentGame.players : 1
                    readonly property var iconMap: {
                        var map = {}
                        map[1] = ["2.svg"]
                        map[2] = ["2.svg"]
                        map[3] = ["3.svg"]
                        map[4] = ["1.svg", "3.svg"]
                        map[5] = ["2.svg", "3.svg"]
                        map[6] = ["3.svg", "3.svg"]
                        map[7] = ["3.svg", "3.svg", "2.svg"]
                        map[8] = ["3.svg", "3.svg", "3.svg"]
                        return map
                    }

                    Repeater {
                        model: playersRow.count <= 8 && playersRow.iconMap[playersRow.count] ?
                        playersRow.iconMap[playersRow.count] : []

                        delegate: Loader {
                            sourceComponent: playerIconComponent
                            onLoaded: item.source = "assets/icons/" + modelData
                        }
                    }

                    Row {
                        spacing: vpx(2)
                        visible: playersRow.count > 8

                        Loader {
                            sourceComponent: playerIconComponent
                            onLoaded: item.source = "assets/icons/3.svg"
                        }

                        Text {
                            text: playersRow.count
                            font.pixelSize: vpx(14)
                            font.family: global.fonts.sans
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                        }
                    }
                }
            }
        }

        Loader {
            id: gameViewLoader
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.top: isGridViewMode ? filterContainer.bottom : undefined
            anchors.topMargin: isGridViewMode ? vpx(20) : undefined
            anchors.verticalCenter: isGridViewMode ? undefined : parent.verticalCenter
            anchors.verticalCenterOffset: isGridViewMode ? 0 : vpx(125)

            anchors.bottom: isGridViewMode ? keyHints.top : undefined
            anchors.bottomMargin: isGridViewMode ? vpx(10) : undefined

            height: isGridViewMode ? undefined : vpx(300)
            active: true
            z: 4

            sourceComponent: viewToggleButton.isGridView ? gridViewComponent : listViewComponent

            onLoaded: {
                if (item) {
                    item.anchors.fill = item.parent

                    if (viewToggleButton.isGridView) {
                        focusManager.gameGridView = item
                        focusManager.gameListView = null
                    } else {
                        focusManager.gameListView = item
                        focusManager.gameGridView = null
                    }

                    if (currentView === "home" && focusManager.currentFocus === "gameList") {
                        item.forceActiveFocus()
                    }
                }
            }
        }

        Component {
            id: listViewComponent
            GameListView {
                currentCollection: root.currentCollection
                currentGameRef: root.currentGame
                showingCollections: root.showingCollections
                focusManagerRef: focusManager
                detailsViewRef: detailsViewComponent
                currentView: root.currentView
                themeRoot: root

                onGameChanged: {
                    root.currentGame = game
                }

                onLetterIndexRequested: {
                    root.buildLetterIndex()
                }

                onFilterValidationRequested: {
                    root.validateCurrentFilter()
                }

                Component.onCompleted: {
                    focusManager.gameListView = this
                    focusManager.gameGridView = null
                }
            }
        }

        Component {
            id: gridViewComponent
            GameGridView {
                currentCollection: root.currentCollection
                currentGameRef: root.currentGame
                showingCollections: root.showingCollections
                focusManagerRef: focusManager
                detailsViewRef: detailsViewComponent
                currentView: root.currentView
                themeRoot: root

                property int columns: 7
                property real aspectRatio: 1.5
                cellWidth: width / columns
                cellHeight: cellWidth * aspectRatio

                onGameChanged: {
                    root.currentGame = game
                }

                onLetterIndexRequested: {
                    root.buildLetterIndex()
                }

                onFilterValidationRequested: {
                    root.validateCurrentFilter()
                }

                Component.onCompleted: {
                    focusManager.gameGridView = this
                    focusManager.gameListView = null
                }
            }
        }

        Item {
            id: filterContainer
            width: showingCollections ? root.width * 0.8 : Math.min(parent.width - vpx(120), vpx(800))
            height: vpx(50)
            z: 6

            x: showingCollections ?
            (parent.width - width) / 2 :
            (parent.width - width) / 2 + vpx(60)

            y: isGridViewMode ? (topBar.height - vpx(20)) : (parent.height - keyHints.height - vpx(62))

            ListView {
                id: unifiedFilterListView
                objectName: "unifiedFilterListView"
                anchors.centerIn: parent
                width: showingCollections ? parent.width : vpx(800)
                height: vpx(50)
                orientation: ListView.Horizontal
                spacing: vpx(30)
                focus: currentView === "home" && focusManager.currentFocus === "filterSelector"
                visible: currentView === "home"
                clip: showingCollections
                interactive: false
                highlightMoveDuration: 250
                highlightFollowsCurrentItem: true
                highlightRangeMode: showingCollections ? ListView.ApplyRange : ListView.NoHighlightRange
                preferredHighlightBegin: showingCollections ? width * 0.2 : 0
                preferredHighlightEnd: showingCollections ? width * 0.8 : width

                property var currentModel: showingCollections ? api.collections : filterModel
                property var filterModel: ["All", "Favorites", "Most Played", "Recently Played", "Collections"]
                property var focusManagerRef: focusManager

                model: currentModel

                Rectangle {
                    id: slidingIndicator
                    height: vpx(40)
                    radius: vpx(8)
                    color: "#FFFFFF"
                    visible: !showingCollections && unifiedFilterListView.focus
                    z: -1

                    Behavior on x {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    function updatePosition() {
                        if (unifiedFilterListView.currentItem) {
                            var item = unifiedFilterListView.currentItem
                            var mappedPos = item.mapToItem(unifiedFilterListView, 0, 0)
                            slidingIndicator.x = mappedPos.x
                            slidingIndicator.width = item.width
                            slidingIndicator.y = (unifiedFilterListView.height - slidingIndicator.height) / 2
                        }
                    }

                    Component.onCompleted: updatePosition()
                }

                Rectangle {
                    id: bottomLineIndicator
                    height: vpx(2)
                    radius: vpx(1)
                    color: "#376f94"
                    visible: !showingCollections && !unifiedFilterListView.focus
                    opacity: 0.7
                    z: -1

                    Behavior on x {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    function updatePosition() {
                        if (unifiedFilterListView.currentItem) {
                            var item = unifiedFilterListView.currentItem
                            var mappedPos = item.mapToItem(unifiedFilterListView, 0, 0)
                            bottomLineIndicator.x = mappedPos.x
                            bottomLineIndicator.width = item.width
                            bottomLineIndicator.y = unifiedFilterListView.height - vpx(10)
                        }
                    }

                    Component.onCompleted: updatePosition()
                }

                onCurrentItemChanged: {
                    if (!showingCollections) {
                        slidingIndicator.updatePosition()
                        bottomLineIndicator.updatePosition()
                    }
                }

                onCurrentModelChanged: {
                    if (!showingCollections) {
                        Qt.callLater(function() {
                            slidingIndicator.updatePosition()
                            bottomLineIndicator.updatePosition()
                        })
                    }
                }

                delegate: Item {
                    id: unifiedDelegate
                    width: delegateContainer.width
                    height: vpx(50)

                    property bool isCurrent: unifiedFilterListView.currentIndex === index
                    property string itemName: {
                        if (showingCollections) {
                            return (typeof modelData === 'object' && modelData && modelData.name) ? modelData.name : ""
                        } else {
                            return (typeof modelData === 'string') ? modelData : ""
                        }
                    }
                    property bool hasFocus: unifiedFilterListView.focus
                    property bool isEnabled: {
                        if (showingCollections) {
                            return true
                        }
                        if (typeof index === 'number' && index >= 0) {
                            return Utils.hasFilterGames(index, api)
                        }
                        return false
                    }

                    opacity: isEnabled ? 1.0 : 0.4

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    Item {
                        id: delegateContainer
                        width: delegateText.implicitWidth + vpx(30)
                        height: vpx(40)
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            color: "#FFFFFF"
                            radius: vpx(8)
                            visible: showingCollections && isCurrent && hasFocus
                            z: -1

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: vpx(2)
                            width: parent.width
                            height: vpx(2)
                            color: "#376f94"
                            radius: vpx(1)
                            visible: showingCollections && isCurrent && !hasFocus
                            opacity: 0.7
                            z: -1

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        Text {
                            id: delegateText
                            text: itemName
                            font.pixelSize: vpx(18)
                            font.family: global.fonts.sans
                            color: {
                                if (!unifiedDelegate.isEnabled) {
                                    return "#666666"
                                }
                                if (isCurrent && hasFocus) {
                                    return "#000000"
                                } else if (isCurrent && !hasFocus) {
                                    return "#376f94"
                                } else {
                                    return "#FFFFFF"
                                }
                            }
                            font.bold: isCurrent && hasFocus
                            anchors.centerIn: parent

                            layer.enabled: !(isCurrent && hasFocus)
                            layer.effect: DropShadow {
                                horizontalOffset: 0
                                verticalOffset: 0
                                radius: vpx(15)
                                samples: 25
                                color: "#99000000"
                                spread: 0.3
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (showingCollections && currentItem) {
                        selectedCollectionIndex = currentIndex
                        var collection = api.collections.get(currentIndex)
                        currentCollection = collection.games
                        if (gameListView) {
                            gameListView.currentIndex = 0
                        }
                        if (currentCollection.count > 0) {
                            currentGame = currentCollection.get(0)
                        }
                    } else if (!showingCollections) {
                        if (currentIndex === 4) {
                            showingCollections = true
                            unifiedFilterListView.currentIndex = 0
                            if (api.collections.count > 0) {
                                currentCollection = api.collections.get(0).games
                                if (currentCollection.count > 0) {
                                    currentGame = currentCollection.get(0)
                                }
                            }
                            if (gameListView) {
                                gameListView.currentIndex = 0
                            }
                            focusManager.enterCollectionsView()
                        } else {
                            Utils.updateFilter(currentIndex, root)
                            var filterNames = ["All", "Favorites", "Most Played", "Recently Played"];
                            if (currentIndex < filterNames.length) {
                            }
                        }
                    }
                }

                Keys.onPressed: {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true
                        if (!showingCollections) {
                            var newIndex = Utils.getNextValidFilterIndex(
                                unifiedFilterListView.currentIndex,
                                "prev",
                                api
                            )
                            unifiedFilterListView.currentIndex = newIndex
                        } else {
                            if (unifiedFilterListView.currentIndex > 0) {
                                unifiedFilterListView.currentIndex--
                            } else {
                                unifiedFilterListView.currentIndex = unifiedFilterListView.count - 1
                            }
                        }
                    }
                    else if (event.key === Qt.Key_Right) {
                        event.accepted = true
                        if (!showingCollections) {
                            var newIndex = Utils.getNextValidFilterIndex(
                                unifiedFilterListView.currentIndex,
                                "next",
                                api
                            )
                            unifiedFilterListView.currentIndex = newIndex
                        } else {
                            if (unifiedFilterListView.currentIndex < unifiedFilterListView.count - 1) {
                                unifiedFilterListView.currentIndex++
                            } else {
                                unifiedFilterListView.currentIndex = 0
                            }
                        }
                    }
                    else if (api.keys.isNextPage(event)) {
                        event.accepted = true
                        if (showingCollections) {
                            if (unifiedFilterListView.currentIndex < unifiedFilterListView.count - 1) {
                                unifiedFilterListView.currentIndex++
                            } else {
                                unifiedFilterListView.currentIndex = 0
                            }
                        }
                    }
                    else if (api.keys.isPrevPage(event)) {
                        event.accepted = true
                        if (showingCollections) {
                            if (unifiedFilterListView.currentIndex > 0) {
                                unifiedFilterListView.currentIndex--
                            } else {
                                unifiedFilterListView.currentIndex = unifiedFilterListView.count - 1
                            }
                        }
                    }
                    else if (event.key === Qt.Key_Up) {
                        event.accepted = true
                        if (!isGridViewMode) {
                            focusManager.handleUp()
                        }
                    }
                    else if (event.key === Qt.Key_Down) {
                        event.accepted = true
                        console.log("FilterListView: Down pressed, isGridViewMode:", root.isGridViewMode)

                        if (root.isGridViewMode) {
                            console.log("Passing focus to gameList")
                            if (focusManager) {
                                focusManager.setFocus("gameList")
                            }
                        } else {
                            console.log("Normal down behavior")
                            if (focusManager) {
                                focusManager.handleDown()
                            }
                        }
                    }
                    else if (api.keys.isFilters(event)) {
                        event.accepted = true
                        if (!showingCollections) {
                            showingCollections = true
                            unifiedFilterListView.currentIndex = 0
                            if (api.collections.count > 0) {
                                currentCollection = api.collections.get(0).games
                                if (currentCollection.count > 0) {
                                    currentGame = currentCollection.get(0)
                                }
                            }
                            if (gameListView) {
                                gameListView.currentIndex = 0
                            }
                            focusManager.enterCollectionsView()
                        } else {
                            showingCollections = false
                            unifiedFilterListView.currentIndex = 0
                            currentCollection = api.allGames
                            if (gameListView) {
                                gameListView.currentIndex = 0
                            }
                            if (currentCollection.count > 0) {
                                currentGame = currentCollection.get(0)
                            }
                            focusManager.exitCollectionsView()
                        }
                    }
                    else if (api.keys.isCancel(event)) {
                        event.accepted = true
                        if (showingCollections) {
                            showingCollections = false
                            unifiedFilterListView.currentIndex = 0
                            currentCollection = api.allGames
                            if (gameListView) {
                                gameListView.currentIndex = 0
                            }
                            if (currentCollection.count > 0) {
                                currentGame = currentCollection.get(0)
                            }
                            focusManager.exitCollectionsView()
                        } else {
                            event.accepted = false
                        }
                    }
                }

                Component.onCompleted: {
                    unifiedFilterListView.currentIndex = 0
                }
            }
        }

        Row {
            id: keyHints
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: vpx(12)
            spacing: vpx(50)
            z: 7

            Row {
                spacing: vpx(10)
                Image {
                    source: "assets/icons/a.svg"
                    width: vpx(24)
                    height: vpx(24)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "View game"
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    color: "#CCCCCC"
                }
            }

            Row {
                spacing: vpx(10)
                Image {
                    source: "assets/icons/x.svg"
                    width: vpx(24)
                    height: vpx(24)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Switch view"
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    color: "#CCCCCC"
                }
            }

            Row {
                spacing: vpx(10)

                Rectangle {
                    width: vpx(21)
                    height: vpx(21)
                    radius: vpx(20)
                    color: "transparent"
                    border.color: "#FFFFFF"
                    border.width: vpx(1)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "LB"
                        font.pixelSize: vpx(12)
                        font.family: global.fonts.sans
                        font.bold: true
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                    }
                }

                Text {
                    text: "Filter by letter"
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    color: "#CCCCCC"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: vpx(21)
                    height: vpx(21)
                    radius: vpx(20)
                    color: "transparent"
                    border.color: "#FFFFFF"
                    border.width: vpx(1)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "RB"
                        font.pixelSize: vpx(12)
                        font.family: global.fonts.sans
                        font.bold: true
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                    }
                }
            }

            Row {
                spacing: vpx(10)
                Image {
                    source: "assets/icons/y.svg"
                    width: vpx(24)
                    height: vpx(24)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: showingCollections ? "Back to Filters" : "View Collections"
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    color: "#CCCCCC"
                }
            }

            Row {
                spacing: vpx(10)
                Image {
                    source: "assets/icons/b.svg"
                    width: vpx(24)
                    height: vpx(24)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Back"
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    color: "#CCCCCC"
                }
            }
        }
    }

    Item {
        id: letterOverlay
        anchors.fill: parent
        visible: opacity > 0
        opacity: currentLetter !== "" ? 1 : 0
        z: 1000

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        FastBlur {
            id: blurEffect
            anchors.fill: parent
            source: root
            radius: letterOverlay.opacity > 0 ? 64 : 0
            cached: false

            Behavior on radius {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#CC000000"
            opacity: parent.opacity
        }

        Item {
            anchors.centerIn: parent
            width: vpx(200)
            height: vpx(200)
            scale: letterOverlay.opacity * 0.9 + 0.1

            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }

            Rectangle {
                id: letterBox
                anchors.centerIn: parent
                width: vpx(150)
                height: vpx(150)
                radius: vpx(20)
                color: "#1A1A1A"
                border.color: "#4A9FD8"
                border.width: vpx(3)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: vpx(3)
                    radius: parent.radius - vpx(3)
                    color: "transparent"
                    border.color: "#2A5A7A"
                    border.width: vpx(1)
                    opacity: 0.5
                }

                layer.enabled: true
                layer.effect: Glow {
                    samples: 17
                    color: "#4A9FD8"
                    spread: 0.2
                    radius: vpx(8)
                }
            }

            Text {
                id: mainLetter
                anchors.centerIn: parent
                text: currentLetter
                font.pixelSize: vpx(80)
                font.family: global.fonts.sans
                font.bold: true
                color: "#FFFFFF"

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: vpx(2)
                    radius: vpx(8)
                    samples: 17
                    color: "#CC000000"
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: letterBox.bottom
                anchors.topMargin: vpx(15)
                text: "L1 / R1"
                font.pixelSize: vpx(14)
                font.family: global.fonts.sans
                color: "#AAAAAA"
                opacity: parent.opacity
            }
        }

        Timer {
            id: letterTimer
            interval: 1000
            running: currentLetter !== ""
            onTriggered: currentLetter = ""
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.visible
            onClicked: {}
        }
    }
}
