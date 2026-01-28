import QtQuick 2.15
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils

Item {
    id: detailsView
    anchors.fill: parent
    visible: false
    focus: visible

    property var currentGame: null
    property var themeRoot: null
    property var focusManager: null
    property bool videoFullscreen: false
    property bool allowEscape: true
    property int currentButtonIndex: 0
    property int totalButtons: 6
    property bool videoHasStarted: false
    property bool currentGameFavorite: currentGame ? Utils.isFavorite(currentGame, api) : false

    onCurrentGameChanged: {
        if (currentGame) {
            currentGameFavorite = Utils.isFavorite(currentGame, api)
            if (favoriteButton) {
                favoriteButton.isFavorite = currentGameFavorite
            }
        }
    }

    function show() {
        visible = true
        allowEscape = true
        currentButtonIndex = 0
        videoHasStarted = false

        if (currentGame) {
            currentGameFavorite = Utils.isFavorite(currentGame, api)
        }

        if (themeRoot) {
            themeRoot.currentView = "details"
        }
        if (focusManager) {
            focusManager.switchView("details")
        }
        if (themeRoot && themeRoot.videoOverlay) {
            themeRoot.videoOverlay.fullscreenChanged.connect(handleFullscreenChanged)
            themeRoot.videoOverlay.muteStateChanged.connect(handleMuteChanged)
            themeRoot.videoOverlay.videoFinished.connect(handleVideoFinished)
        }
    }

    function hide() {
        visible = false

        if (themeRoot && themeRoot.videoOverlay) {
            themeRoot.videoOverlay.stop()
            if (videoFullscreen) {
                videoFullscreen = false
                themeRoot.videoOverlay.isFullscreen = false
            }
        }

        if (themeRoot) {
            themeRoot.currentView = "home"
        }
        if (focusManager) {
            focusManager.switchView("home")
        }
        if (themeRoot && themeRoot.videoOverlay) {
            themeRoot.videoOverlay.fullscreenChanged.disconnect(handleFullscreenChanged)
            themeRoot.videoOverlay.muteStateChanged.disconnect(handleMuteChanged)
            themeRoot.videoOverlay.videoFinished.disconnect(handleVideoFinished)
        }
    }

    function handleFullscreenChanged(fullscreen) {
        videoFullscreen = fullscreen
        currentButtonIndex = 0
    }

    function handleMuteChanged(muted) {
        muteButton.isMuted = muted
    }

    function handleVideoFinished() {
        allowEscape = true
        videoHasStarted = false
        currentButtonIndex = 0
    }

    Connections {
        target: themeRoot ? themeRoot.videoOverlay : null

        function onIsPlayingChanged() {
            if (themeRoot && themeRoot.videoOverlay) {
                allowEscape = !themeRoot.videoOverlay.isPlaying

                if (themeRoot.videoOverlay.isPlaying && !videoHasStarted) {
                    videoHasStarted = true
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: vpx(60)

        Column {
            id: leftColumn
            anchors.left: parent.left
            anchors.leftMargin: vpx(80)
            anchors.top: parent.top
            anchors.topMargin: vpx(100)
            spacing: vpx(15)
            width: parent.width * 0.5

            Text {
                text: currentGame ? currentGame.title : ""
                font.pixelSize: vpx(48)
                font.family: global.fonts.sans
                font.bold: true
                color: "#FFFFFF"
                wrapMode: Text.Wrap
                width: detailsView.width
                opacity: videoFullscreen ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            Row {
                spacing: vpx(20)
                height: vpx(24)
                opacity: videoFullscreen ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                Text {
                    text: currentGame && Utils.getCollectionName(currentGame) ?
                    Utils.getCollectionName(currentGame) : ""
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    color: "#AAAAAA"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: vpx(6)
                    height: vpx(6)
                    radius: width / 2
                    color: "#939393"
                    visible: currentGame && (ratingRow.visible || playersRow.visible)
                    anchors.verticalCenter: parent.verticalCenter
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
                        delegate: Image {
                            source: "assets/icons/star1.png"
                            width: vpx(20)
                            height: vpx(20)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            mipmap: true
                        }
                    }

                    Repeater {
                        model: ratingRow.hasHalfStar ? 1 : 0
                        delegate: Image {
                            source: "assets/icons/star05.png"
                            width: vpx(20)
                            height: vpx(20)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            mipmap: true
                        }
                    }

                    Repeater {
                        model: ratingRow.emptyStars
                        delegate: Image {
                            source: "assets/icons/star0.png"
                            width: vpx(20)
                            height: vpx(20)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            mipmap: true
                        }
                    }
                }

                Rectangle {
                    width: vpx(6)
                    height: vpx(6)
                    radius: width / 2
                    color: "#939393"
                    visible: currentGame && (ratingRow.visible || playersRow.visible)
                    anchors.verticalCenter: parent.verticalCenter
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

                        delegate: Image {
                            source: "assets/icons/" + modelData
                            width: vpx(25)
                            height: vpx(25)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            mipmap: true
                        }
                    }

                    Row {
                        spacing: vpx(2)
                        visible: playersRow.count > 8

                        Image {
                            source: "assets/icons/3.svg"
                            width: vpx(25)
                            height: vpx(25)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            mipmap: true
                        }

                        Text {
                            text: playersRow.count
                            font.pixelSize: vpx(14)
                            font.family: global.fonts.sans
                            color: "#AAAAAA"
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                        }
                    }
                }
            }

            Row {
                spacing: vpx(15)
                topPadding: vpx(20)
                opacity: videoFullscreen ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                Rectangle {
                    id: playButton
                    width: vpx(160)
                    height: vpx(50)
                    color: currentButtonIndex === 0 && !videoFullscreen ? "#4a8ab5" : "#376f94"
                    radius: vpx(2)

                    border.width: currentButtonIndex === 0 && !videoFullscreen ? vpx(3) : 0
                    border.color: "#FFFFFF"

                    property bool hovered: false

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Behavior on border.width {
                        NumberAnimation { duration: 150 }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: vpx(12)

                        Image {
                            id: playGameIcon
                            source: "assets/icons/play-game.svg"
                            width: vpx(20)
                            height: vpx(20)
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            visible: status === Image.Ready
                            mipmap: true
                        }

                        Text {
                            text: "▶"
                            font.pixelSize: vpx(18)
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                            visible: playGameIcon.status !== Image.Ready
                        }

                        Text {
                            text: "Play"
                            font.pixelSize: vpx(18)
                            font.family: global.fonts.sans
                            font.bold: true
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: playButton.hovered = true
                        onExited: playButton.hovered = false
                        onClicked: {
                            if (currentGame) {
                                Utils.launchGame(currentGame, api)
                            }
                        }
                    }
                }

                Rectangle {
                    id: favoriteButton
                    width: vpx(50)
                    height: vpx(50)
                    color: currentButtonIndex === 5 && !videoFullscreen ? "#4a505a" : "#31383a"
                    radius: vpx(2)

                    border.width: currentButtonIndex === 5 && !videoFullscreen ? vpx(3) : 0
                    border.color: "#FFFFFF"

                    property bool isFavorite: detailsView.currentGameFavorite

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Behavior on border.width {
                        NumberAnimation { duration: 150 }
                    }

                    Image {
                        id: favoriteIcon
                        source: favoriteButton.isFavorite ? "assets/icons/favorite-yes.svg" : "assets/icons/favorite-no.svg"
                        width: vpx(24)
                        height: vpx(24)
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        asynchronous: true
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Text {
                        text: favoriteButton.isFavorite ? "★" : "☆"
                        font.pixelSize: vpx(22)
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                        visible: favoriteIcon.status !== Image.Ready
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (currentGame) {
                                var newState = Utils.toggleFavorite(currentGame, api, themeRoot)
                                detailsView.currentGameFavorite = newState
                                favoriteButton.isFavorite = newState
                            }
                        }
                    }
                }

                Rectangle {
                    id: pauseButton
                    width: vpx(50)
                    height: vpx(50)
                    color: currentButtonIndex === 1 && !videoFullscreen ? "#4a505a" : "#31383a"
                    radius: vpx(2)

                    border.width: currentButtonIndex === 1 && !videoFullscreen ? vpx(3) : 0
                    border.color: "#FFFFFF"

                    property bool isPlaying: themeRoot ? themeRoot.videoOverlay.isPlaying : false

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Behavior on border.width {
                        NumberAnimation { duration: 150 }
                    }

                    Image {
                        id: pauseVideoIcon
                        source: pauseButton.isPlaying ? "assets/icons/pause-video.svg" : "assets/icons/play-video.svg"
                        width: vpx(24)
                        height: vpx(24)
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        asynchronous: true
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Text {
                        text: pauseButton.isPlaying ? "⏸" : "▶"
                        font.pixelSize: vpx(22)
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                        visible: pauseVideoIcon.status !== Image.Ready
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (themeRoot && themeRoot.videoOverlay) {
                                themeRoot.videoOverlay.togglePlayPause()
                            }
                        }
                    }
                }

                Rectangle {
                    id: stopButton
                    width: vpx(50)
                    height: vpx(50)
                    color: currentButtonIndex === 2 && !videoFullscreen ? "#4a505a" : "#31383a"
                    radius: vpx(2)

                    border.width: currentButtonIndex === 2 && !videoFullscreen ? vpx(3) : 0
                    border.color: "#FFFFFF"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Behavior on border.width {
                        NumberAnimation { duration: 150 }
                    }

                    Image {
                        id: stopVideoIcon
                        source: "assets/icons/stop-video.svg"
                        width: vpx(24)
                        height: vpx(24)
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        asynchronous: true
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Text {
                        text: "⏹"
                        font.pixelSize: vpx(22)
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                        visible: stopVideoIcon.status !== Image.Ready
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (themeRoot && themeRoot.videoOverlay) {
                                themeRoot.videoOverlay.stop()
                            }
                        }
                    }
                }

                Rectangle {
                    id: maximizeButton
                    width: vpx(50)
                    height: vpx(50)
                    color: currentButtonIndex === 3 && !videoFullscreen ? "#4a505a" : "#31383a"
                    radius: vpx(2)

                    border.width: currentButtonIndex === 3 && !videoFullscreen ? vpx(3) : 0
                    border.color: "#FFFFFF"

                    opacity: videoHasStarted ? 1.0 : 0.3

                    property bool isFullscreen: videoFullscreen

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Behavior on border.width {
                        NumberAnimation { duration: 150 }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    Image {
                        id: maximizeVideoIcon
                        source: maximizeButton.isFullscreen ? "assets/icons/maximize-video.svg" : "assets/icons/full-video.svg"
                        width: vpx(24)
                        height: vpx(24)
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        asynchronous: true
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Text {
                        text: "⛶"
                        font.pixelSize: vpx(22)
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                        visible: maximizeVideoIcon.status !== Image.Ready
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (themeRoot && themeRoot.videoOverlay) {
                                themeRoot.videoOverlay.toggleFullscreen()
                            }
                        }
                    }
                }

                Rectangle {
                    id: muteButton
                    width: vpx(50)
                    height: vpx(50)
                    color: currentButtonIndex === 4 && !videoFullscreen ? "#4a505a" : "#31383a"
                    radius: vpx(2)

                    border.width: currentButtonIndex === 4 && !videoFullscreen ? vpx(3) : 0
                    border.color: "#FFFFFF"

                    opacity: videoHasStarted ? 1.0 : 0.3

                    property bool isMuted: themeRoot ? themeRoot.videoOverlay.isMuted : false

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Behavior on border.width {
                        NumberAnimation { duration: 150 }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    Image {
                        id: muteVideoIcon
                        source: muteButton.isMuted ? "assets/icons/mute.svg" : "assets/icons/volume.svg"
                        width: vpx(24)
                        height: vpx(24)
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        asynchronous: true
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Text {
                        text: muteButton.isMuted ? "🔇" : "🔊"
                        font.pixelSize: vpx(20)
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                        visible: muteVideoIcon.status !== Image.Ready
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (themeRoot && themeRoot.videoOverlay) {
                                themeRoot.videoOverlay.toggleMute()
                                muteButton.isMuted = themeRoot.videoOverlay.isMuted
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: bottomSection
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: leftColumn.bottom
            anchors.topMargin: vpx(50)
            anchors.leftMargin: vpx(80)
            anchors.rightMargin: vpx(80)
            opacity: videoFullscreen ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Item {
                id: scrollContainer
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.5 - vpx(20)
                height: vpx(250)
                clip: true

                PegasusUtils.AutoScroll {
                    id: autoscroll
                    anchors.fill: parent
                    pixelsPerSecond: 15
                    scrollWaitDuration: 3000

                    Item {
                        width: autoscroll.width
                        height: descripText.height

                        Text {
                            id: descripText
                            width: parent.width
                            text: currentGame ? currentGame.description : ""
                            wrapMode: Text.WordWrap
                            lineHeight: 1.5
                            font {
                                family: global.fonts.sans
                                pixelSize: vpx(15)
                            }
                            color: "#CCCCCC"
                        }
                    }
                }
            }

            Item {
                id: detailsInfoContainer
                anchors {
                    left: scrollContainer.right
                    leftMargin: vpx(80)
                    top: scrollContainer.top
                    bottom: scrollContainer.bottom
                    right: parent.right
                }

                Column {
                    id: detailsInfoLeft
                    anchors {
                        left: parent.left
                        top: parent.top
                    }
                    width: vpx(180)
                    spacing: vpx(20)

                    InfoRow {
                        width: parent.width
                        label: "Time Played"
                        value: currentGame ? Utils.formatPlayTime(currentGame.playTime) : "Not Played"
                    }

                    InfoRow {
                        width: parent.width
                        label: "Play Count"
                        value: currentGame && currentGame.playCount > 0 ? currentGame.playCount.toString() : "0"
                    }

                    Item {
                        width: parent.width
                        height: childrenRect.height

                        Column {
                            width: parent.width
                            spacing: vpx(8)

                            Text {
                                text: currentGame ? Math.round(currentGame.rating * 100) + "%" : "0%"
                                font.pixelSize: vpx(14)
                                font.family: global.fonts.sans
                                color: "#9099a1"
                            }

                            Rectangle {
                                width: vpx(150)
                                height: vpx(4)
                                color: "#2a2e33"

                                Rectangle {
                                    width: parent.width * (currentGame ? currentGame.rating : 0)
                                    height: parent.height
                                    color: "#FFFFFF"
                                }
                            }
                        }
                    }
                }

                Row {
                    id: rightColumnsContainer
                    anchors {
                        left: detailsInfoLeft.right
                        leftMargin: vpx(40)
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                    }
                    spacing: 0

                    Column {
                        id: detailsInfoCenter
                        width: vpx(100)
                        spacing: vpx(20)

                        InfoRow {
                            width: parent.width
                            label: "Last Played"
                            value: currentGame ? Utils.formatDate(currentGame.lastPlayed) : "Never"
                        }

                        InfoRow {
                            width: parent.width
                            label: "Release Date"
                            value: currentGame ? Utils.formatDate(currentGame.release) : "Unknown"
                        }
                    }

                    Rectangle {
                        id: dividerLine
                        width: vpx(1)
                        height: parent.height
                        color: "#2a2e33"
                    }

                    Item {
                        width: vpx(20)
                        height: parent.height
                    }

                    Column {
                        id: detailsInfoRight
                        width: vpx(180)
                        spacing: vpx(20)

                        InfoRow {
                            width: parent.width
                            label: "Platforms"
                            value: currentGame ? Utils.getCollectionName(currentGame) : "Unknown"
                            showDivider: false
                        }

                        InfoRow {
                            width: parent.width
                            label: "Genres"
                            value: currentGame ? (currentGame.genre || "Unknown") : "Unknown"
                            visible: currentGame && currentGame.genre
                            showDivider: false
                        }

                        InfoRow {
                            width: parent.width
                            label: "Developers"
                            value: currentGame ? (currentGame.developer || "Unknown") : "Unknown"
                            visible: currentGame && currentGame.developer
                            showDivider: false
                        }

                        InfoRow {
                            width: parent.width
                            label: "Publishers"
                            value: currentGame ? (currentGame.publisher || "Unknown") : "Unknown"
                            visible: currentGame && currentGame.publisher
                            showDivider: false
                        }
                    }
                }
            }

        }
    }

    Row {
        id: floatingControls
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: vpx(20)
        anchors.bottomMargin: vpx(20)
        spacing: vpx(12)
        opacity: videoFullscreen ? 1 : 0
        visible: opacity > 0
        z: 1000

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        Rectangle {
            width: vpx(140)
            height: vpx(45)
            color: currentButtonIndex === 0 && videoFullscreen ? "#4a8ab5" : "#376f94"
            radius: vpx(2)

            border.width: currentButtonIndex === 0 && videoFullscreen ? vpx(3) : 0
            border.color: "#FFFFFF"

            property bool hovered: false

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.width {
                NumberAnimation { duration: 150 }
            }

            Row {
                anchors.centerIn: parent
                spacing: vpx(10)

                Image {
                    id: playGameIconFloat
                    source: "assets/icons/play-game.svg"
                    width: vpx(18)
                    height: vpx(18)
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                    asynchronous: true
                    visible: status === Image.Ready
                    mipmap: true
                }

                Text {
                    text: "▶"
                    font.pixelSize: vpx(16)
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                    visible: playGameIconFloat.status !== Image.Ready
                }

                Text {
                    text: "Play"
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    font.bold: true
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: {
                    if (currentGame) {
                        Utils.launchGame(currentGame, api)
                    }
                }
            }
        }

        Rectangle {
            width: vpx(45)
            height: vpx(45)
            color: currentButtonIndex === 5 && videoFullscreen ? "#4a505a" : "#31383a"
            radius: vpx(2)

            border.width: currentButtonIndex === 5 && videoFullscreen ? vpx(3) : 0
            border.color: "#FFFFFF"

            property bool isFavorite: detailsView.currentGameFavorite

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.width {
                NumberAnimation { duration: 150 }
            }

            Image {
                id: favoriteIconFloat
                source: parent.isFavorite ? "assets/icons/favorite-yes.svg" : "assets/icons/favorite-no.svg"
                width: vpx(22)
                height: vpx(22)
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
                asynchronous: true
                visible: status === Image.Ready
                mipmap: true
            }

            Text {
                text: parent.isFavorite ? "★" : "☆"
                font.pixelSize: vpx(20)
                color: "#FFFFFF"
                anchors.centerIn: parent
                visible: favoriteIconFloat.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (currentGame) {
                        var newState = Utils.toggleFavorite(currentGame, api, themeRoot)
                        detailsView.currentGameFavorite = newState
                        parent.isFavorite = newState
                    }
                }
            }
        }

        Rectangle {
            width: vpx(45)
            height: vpx(45)
            color: currentButtonIndex === 1 && videoFullscreen ? "#4a505a" : "#31383a"
            radius: vpx(2)

            border.width: currentButtonIndex === 1 && videoFullscreen ? vpx(3) : 0
            border.color: "#FFFFFF"

            property bool isPlaying: themeRoot ? themeRoot.videoOverlay.isPlaying : false

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.width {
                NumberAnimation { duration: 150 }
            }

            Image {
                id: pauseVideoIconFloat
                source: parent.isPlaying ? "assets/icons/pause-video.svg" : "assets/icons/play-video.svg"
                width: vpx(22)
                height: vpx(22)
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
                asynchronous: true
                visible: status === Image.Ready
                mipmap: true
            }

            Text {
                text: parent.isPlaying ? "⏸" : "▶"
                font.pixelSize: vpx(20)
                color: "#FFFFFF"
                anchors.centerIn: parent
                visible: pauseVideoIconFloat.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.togglePlayPause()
                    }
                }
            }
        }

        Rectangle {
            width: vpx(45)
            height: vpx(45)
            color: currentButtonIndex === 2 && videoFullscreen ? "#4a505a" : "#31383a"
            radius: vpx(2)

            border.width: currentButtonIndex === 2 && videoFullscreen ? vpx(3) : 0
            border.color: "#FFFFFF"

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.width {
                NumberAnimation { duration: 150 }
            }

            Image {
                id: stopVideoIconFloat
                source: "assets/icons/stop-video.svg"
                width: vpx(22)
                height: vpx(22)
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
                asynchronous: true
                visible: status === Image.Ready
                mipmap: true
            }

            Text {
                text: "⏹"
                font.pixelSize: vpx(20)
                color: "#FFFFFF"
                anchors.centerIn: parent
                visible: stopVideoIconFloat.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.stop()
                    }
                }
            }
        }

        Rectangle {
            width: vpx(45)
            height: vpx(45)
            color: currentButtonIndex === 3 && videoFullscreen ? "#4a505a" : "#31383a"
            radius: vpx(2)

            border.width: currentButtonIndex === 3 && videoFullscreen ? vpx(3) : 0
            border.color: "#FFFFFF"

            opacity: videoHasStarted ? 1.0 : 0.3

            property bool isFullscreen: videoFullscreen

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.width {
                NumberAnimation { duration: 150 }
            }

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Image {
                id: maximizeVideoIconFloat
                source: parent.isFullscreen ? "assets/icons/maximize-video.svg" : "assets/icons/full-video.svg"
                width: vpx(22)
                height: vpx(22)
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
                asynchronous: true
                visible: status === Image.Ready
                mipmap: true
            }

            Text {
                text: "⛶"
                font.pixelSize: vpx(20)
                color: "#FFFFFF"
                anchors.centerIn: parent
                visible: maximizeVideoIconFloat.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.toggleFullscreen()
                    }
                }
            }
        }

        Rectangle {
            width: vpx(45)
            height: vpx(45)
            color: currentButtonIndex === 4 && videoFullscreen ? "#4a505a" : "#31383a"
            radius: vpx(2)

            border.width: currentButtonIndex === 4 && videoFullscreen ? vpx(3) : 0
            border.color: "#FFFFFF"

            opacity: videoHasStarted ? 1.0 : 0.3

            property bool isMuted: themeRoot ? themeRoot.videoOverlay.isMuted : false

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.width {
                NumberAnimation { duration: 150 }
            }

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Image {
                id: muteVideoIconFloat
                source: parent.isMuted ? "assets/icons/mute.svg" : "assets/icons/volume.svg"
                width: vpx(22)
                height: vpx(22)
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
                asynchronous: true
                visible: status === Image.Ready
                mipmap: true
            }

            Text {
                text: parent.isMuted ? "🔇" : "🔊"
                font.pixelSize: vpx(18)
                color: "#FFFFFF"
                anchors.centerIn: parent
                visible: muteVideoIconFloat.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.toggleMute()
                        parent.isMuted = themeRoot.videoOverlay.isMuted
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
            if (allowEscape) {
                event.accepted = true
                soundManager.playNavigation()
                hide()
            } else {
                event.accepted = true
            }
        }
        else if (api.keys.isAccept(event)) {
            event.accepted = true
            soundManager.playNavigation()

            switch(currentButtonIndex) {
                case 0:
                    if (currentGame) {
                        Utils.launchGame(currentGame, api)
                    }
                    break
                case 1:
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.togglePlayPause()
                    }
                    break
                case 2:
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.stop()
                    }
                    break
                case 3:
                    if (videoHasStarted && themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.toggleFullscreen()
                    }
                    break
                case 4:
                    if (videoHasStarted && themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.toggleMute()
                        muteButton.isMuted = themeRoot.videoOverlay.isMuted
                    }
                    break
                case 5:
                    if (currentGame) {
                        var wasInFilteredView = (themeRoot.collectionFilter === "favorites" ||
                        themeRoot.collectionFilter === "mostplayed" ||
                        themeRoot.collectionFilter === "recent")
                        var currentIndex = -1

                        if (wasInFilteredView && themeRoot.currentCollection) {
                            for (var i = 0; i < themeRoot.currentCollection.count; i++) {
                                var game = themeRoot.currentCollection.get(i)
                                if (game.title === currentGame.title) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }

                        var newState = Utils.toggleFavorite(currentGame, api, themeRoot)
                        detailsView.currentGameFavorite = newState
                        favoriteButton.isFavorite = newState

                        if (themeRoot.collectionFilter === "favorites" && !newState) {
                            hide()

                            Qt.callLater(function() {
                                if (themeRoot.currentCollection && themeRoot.currentCollection.count > 0) {
                                    var newIndex = Math.min(currentIndex, themeRoot.currentCollection.count - 1)
                                    if (themeRoot.gameListView) {
                                        themeRoot.gameListView.currentIndex = newIndex
                                    }
                                    themeRoot.currentGame = themeRoot.currentCollection.get(newIndex)
                                } else {
                                    Utils.updateFilter(0, themeRoot)
                                }
                            })
                        }
                    }
                    break
            }
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            soundManager.playNavigation()

            if (!videoHasStarted) {
                if (currentButtonIndex === 0) {
                    currentButtonIndex = 2
                } else if (currentButtonIndex === 5) {
                    currentButtonIndex = 0
                } else if (currentButtonIndex === 1) {
                    currentButtonIndex = 5
                } else if (currentButtonIndex === 2) {
                    currentButtonIndex = 1
                } else {
                    currentButtonIndex = 2
                }
            } else {

                if (currentButtonIndex === 0) {
                    currentButtonIndex = 4
                } else if (currentButtonIndex === 5) {
                    currentButtonIndex = 0
                } else if (currentButtonIndex === 1) {
                    currentButtonIndex = 5
                } else if (currentButtonIndex === 2) {
                    currentButtonIndex = 1
                } else if (currentButtonIndex === 3) {
                    currentButtonIndex = 2
                } else if (currentButtonIndex === 4) {
                    currentButtonIndex = 3
                }
            }
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            soundManager.playNavigation()

            if (!videoHasStarted) {
                if (currentButtonIndex === 0) {
                    currentButtonIndex = 5
                } else if (currentButtonIndex === 5) {
                    currentButtonIndex = 1
                } else if (currentButtonIndex === 1) {
                    currentButtonIndex = 2
                } else if (currentButtonIndex === 2) {
                    currentButtonIndex = 0
                } else {
                    currentButtonIndex = 0
                }
            } else {
                if (currentButtonIndex === 0) {
                    currentButtonIndex = 5
                } else if (currentButtonIndex === 5) {
                    currentButtonIndex = 1
                } else if (currentButtonIndex === 1) {
                    currentButtonIndex = 2
                } else if (currentButtonIndex === 2) {
                    currentButtonIndex = 3
                } else if (currentButtonIndex === 3) {
                    currentButtonIndex = 4
                } else if (currentButtonIndex === 4) {
                    currentButtonIndex = 0
                }
            }
        }
    }
}
