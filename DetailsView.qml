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

    function show() {
        visible = true
        if (themeRoot) {
            themeRoot.currentView = "details"
        }
        if (focusManager) {
            focusManager.switchView("details")
        }
        // Conectar las seÃ±ales del video overlay
        if (themeRoot && themeRoot.videoOverlay) {
            themeRoot.videoOverlay.fullscreenChanged.connect(handleFullscreenChanged)
            themeRoot.videoOverlay.muteStateChanged.connect(handleMuteChanged)
        }
    }

    function hide() {
        visible = false
        if (themeRoot) {
            themeRoot.currentView = "home"
        }
        if (focusManager) {
            focusManager.switchView("home")
        }
        // Desconectar las seÃ±ales
        if (themeRoot && themeRoot.videoOverlay) {
            themeRoot.videoOverlay.fullscreenChanged.disconnect(handleFullscreenChanged)
            themeRoot.videoOverlay.muteStateChanged.disconnect(handleMuteChanged)
        }
    }

    function handleFullscreenChanged(fullscreen) {
        videoFullscreen = fullscreen
    }

    function handleMuteChanged(muted) {
        console.log("Mute state changed in DetailsView:", muted)
        // Forzar actualizaciÃ³n del botÃ³n de mute
        muteButton.isMuted = muted
    }

    // Contenedor principal
    Item {
        anchors.fill: parent
        anchors.topMargin: vpx(60) // Compensar por el top bar

        // Columna izquierda - InformaciÃ³n principal
        Column {
            id: leftColumn
            anchors.left: parent.left
            anchors.leftMargin: vpx(80)
            anchors.top: parent.top
            anchors.topMargin: vpx(100)
            spacing: vpx(15)
            width: parent.width * 0.5

            // TÃ­tulo del juego
            Text {
                text: currentGame ? currentGame.title : ""
                font.pixelSize: vpx(48)
                font.family: global.fonts.sans
                font.bold: true
                color: "#FFFFFF"
                wrapMode: Text.Wrap
                width: parent.width
                opacity: videoFullscreen ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            // Fila de metadatos (Rating â€¢ Platform â€¢ Players)
            Row {
                spacing: vpx(20)
                height: vpx(24)
                opacity: videoFullscreen ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                // Rating Stars
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
                    color: "#666666"
                    visible: currentGame && (ratingRow.visible || playersRow.visible)
                    anchors.verticalCenter: parent.verticalCenter
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
                    color: "#666666"
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
                    color: "#376f94"
                    radius: vpx(2)

                    property bool hovered: false

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
                    id: pauseButton
                    width: vpx(50)
                    height: vpx(50)
                    color: "#31383a"
                    radius: vpx(2)

                    property bool isPlaying: themeRoot ? themeRoot.videoOverlay.isPlaying : false

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
                    color: "#31383a"
                    radius: vpx(2)

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
                    color: "#31383a"
                    radius: vpx(2)

                    property bool isFullscreen: videoFullscreen

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
                    color: "#31383a"
                    radius: vpx(2)

                    property bool isMuted: themeRoot ? themeRoot.videoOverlay.isMuted : false

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
                            console.log("Mute button clicked")
                            if (themeRoot && themeRoot.videoOverlay) {
                                themeRoot.videoOverlay.toggleMute()
                                // Forzar actualizaciÃ³n inmediata
                                muteButton.isMuted = themeRoot.videoOverlay.isMuted
                            }
                        }
                    }
                }
            }

            Item {
                id: scrollContainer
                width: parent.width
                height: vpx(250)
                clip: true
                opacity: videoFullscreen ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

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
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: vpx(80)
            anchors.top: parent.top
            anchors.topMargin: vpx(380)
            spacing: vpx(18)
            width: vpx(350)
            opacity: videoFullscreen ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            InfoRow {
                label: "Time Played"
                value: Utils.formatPlayTime(currentGame ? currentGame.playTime : 0)
            }

            InfoRow {
                label: "Last Played"
                value: currentGame && currentGame.lastPlayed.getTime() > 0 ?
                Qt.formatDate(currentGame.lastPlayed, "dd/MM/yyyy") : "Never"
            }

            InfoRow {
                label: "Platforms"
                value: currentGame && Utils.getCollectionName(currentGame) ?
                Utils.getCollectionName(currentGame) : ""
            }

            InfoRow {
                label: "Completion Status"
                value: "Not Played"
            }

            InfoRow {
                label: "Library"
                value: "Playnite"
            }

            InfoRow {
                label: "Release Date"
                value: currentGame && currentGame.release.getTime() > 0 ?
                Qt.formatDate(currentGame.release, "dd/MM/yyyy") : ""
            }

            InfoRow {
                label: "Critic Score"
                value: currentGame && currentGame.rating > 0 ?
                Math.round(currentGame.rating * 100).toString() : ""
            }

            InfoRow {
                label: "Genres"
                value: currentGame ? currentGame.genre : ""
            }

            InfoRow {
                label: "Developers"
                value: currentGame ? currentGame.developer : ""
            }

            InfoRow {
                label: "Publishers"
                value: currentGame ? currentGame.publisher : ""
            }

            InfoRow {
                label: "Categories"
                value: "Windows Games"
            }

            InfoRow {
                label: "Features"
                value: "Single Player"
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
            color: "#376f94"
            radius: vpx(2)

            property bool hovered: false

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
            color: "#31383a"
            radius: vpx(2)

            property bool isPlaying: themeRoot ? themeRoot.videoOverlay.isPlaying : false

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
            color: "#31383a"
            radius: vpx(2)

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
            color: "#31383a"
            radius: vpx(2)

            property bool isFullscreen: videoFullscreen

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
            color: "#31383a"
            radius: vpx(2)

            property bool isMuted: themeRoot ? themeRoot.videoOverlay.isMuted : false

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
                    console.log("Floating mute button clicked")
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
            event.accepted = true
            hide()
        }
        else if (api.keys.isAccept(event)) {
            event.accepted = true
            if (currentGame) {
                Utils.launchGame(currentGame, api)
            }
        }
    }
}
