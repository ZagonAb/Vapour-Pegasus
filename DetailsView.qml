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
    property bool allowEscape: true  // Nueva propiedad para controlar si Escape está permitido
    property int currentButtonIndex: 0  // Índice del botón actualmente seleccionado (0-4)
    property int totalButtons: 5  // Total de botones (Play, Pause, Stop, Maximize, Mute)
    property bool videoHasStarted: false  // Para saber si el video ha iniciado alguna vez

    function show() {
        visible = true
        allowEscape = true  // Resetear al mostrar la vista
        currentButtonIndex = 0  // Resetear al botón Play (index 0)
        videoHasStarted = false  // Resetear el estado del video
        if (themeRoot) {
            themeRoot.currentView = "details"
        }
        if (focusManager) {
            focusManager.switchView("details")
        }
        // Conectar las señales del video overlay
        if (themeRoot && themeRoot.videoOverlay) {
            themeRoot.videoOverlay.fullscreenChanged.connect(handleFullscreenChanged)
            themeRoot.videoOverlay.muteStateChanged.connect(handleMuteChanged)
            themeRoot.videoOverlay.videoFinished.connect(handleVideoFinished)
        }
    }

    function hide() {
        visible = false

        // SIEMPRE detener el video al salir, sin importar su estado
        if (themeRoot && themeRoot.videoOverlay) {
            console.log("Hiding DetailsView - Stopping video completely")
            themeRoot.videoOverlay.stop()
            // Forzar salida de fullscreen si estaba activo
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
        // Desconectar las señales
        if (themeRoot && themeRoot.videoOverlay) {
            themeRoot.videoOverlay.fullscreenChanged.disconnect(handleFullscreenChanged)
            themeRoot.videoOverlay.muteStateChanged.disconnect(handleMuteChanged)
            themeRoot.videoOverlay.videoFinished.disconnect(handleVideoFinished)
        }
    }

    function handleFullscreenChanged(fullscreen) {
        videoFullscreen = fullscreen
        // Al entrar/salir de fullscreen, resetear al botón Play (index 0)
        currentButtonIndex = 0
        console.log("Fullscreen changed to:", fullscreen, "- Reset to Play button (index 0)")
    }

    function handleMuteChanged(muted) {
        console.log("Mute state changed in DetailsView:", muted)
        // Forzar actualización del botón de mute
        muteButton.isMuted = muted
    }

    function handleVideoFinished() {
        console.log("Video finished - Re-enabling Escape and resetting to Play button")
        allowEscape = true
        videoHasStarted = false  // Bloquear nuevamente Maximize y Mute
        currentButtonIndex = 0  // Volver al botón Play
    }

    // Conexiones para monitorear el estado del video
    Connections {
        target: themeRoot ? themeRoot.videoOverlay : null

        function onIsPlayingChanged() {
            if (themeRoot && themeRoot.videoOverlay) {
                // Bloquear Escape cuando el video está reproduciéndose
                allowEscape = !themeRoot.videoOverlay.isPlaying

                // Marcar que el video ha iniciado cuando empieza a reproducirse
                if (themeRoot.videoOverlay.isPlaying && !videoHasStarted) {
                    videoHasStarted = true
                    console.log("Video has started for the first time - Unlocking Maximize and Mute buttons")
                }

                console.log("Video playing state changed. allowEscape:", allowEscape, "videoHasStarted:", videoHasStarted)
            }
        }
    }

    // Contenedor principal
    Item {
        anchors.fill: parent
        anchors.topMargin: vpx(60) // Compensar por el top bar

        // Columna izquierda - Información principal
        Column {
            id: leftColumn
            anchors.left: parent.left
            anchors.leftMargin: vpx(80)
            anchors.top: parent.top
            anchors.topMargin: vpx(100)
            spacing: vpx(15)
            width: parent.width * 0.5

            // Título del juego
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

            // Fila de metadatos (Rating • Platform • Players)
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
                                // La señal videoFinished manejará el resto (allowEscape, videoHasStarted, currentButtonIndex)
                                console.log("Stop button clicked")
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

                    opacity: videoHasStarted ? 1.0 : 0.3  // Opacidad reducida si no ha iniciado

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

                    opacity: videoHasStarted ? 1.0 : 0.3  // Opacidad reducida si no ha iniciado

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
                            console.log("Mute button clicked")
                            if (themeRoot && themeRoot.videoOverlay) {
                                themeRoot.videoOverlay.toggleMute()
                                // Forzar actualización inmediata
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

            // Contenedor de descripción (scroll)
            Item {
                id: scrollContainer
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter  // Centrar verticalmente
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

            // Contenedor de información dividida en dos columnas
            Row {
                id: detailsInfoContainer
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter  // Centrar verticalmente
                spacing: vpx(50)
                width: parent.width * 0.45

                // Columna izquierda de información
                Column {
                    id: detailsInfoLeft
                    spacing: vpx(18)
                    width: parent.width * 0.5 - vpx(20)

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
                        label: "Release Date"
                        value: currentGame && currentGame.release.getTime() > 0 ?
                        Qt.formatDate(currentGame.release, "dd/MM/yyyy") : ""
                    }
                }

                // Columna derecha de información
                Column {
                    id: detailsInfoRight
                    spacing: vpx(18)
                    width: parent.width * 0.5 - vpx(20)

                    InfoRow {
                        label: "Rating"
                        value: currentGame && currentGame.rating > 0 ?
                        Math.round(currentGame.rating * 100).toString() + "%" : ""
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
                        // La señal videoFinished manejará el resto (allowEscape, videoHasStarted, currentButtonIndex)
                        console.log("Floating stop button clicked")
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

            opacity: videoHasStarted ? 1.0 : 0.3  // Opacidad reducida si no ha iniciado

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

            opacity: videoHasStarted ? 1.0 : 0.3  // Opacidad reducida si no ha iniciado

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
            // Solo permitir Escape si está habilitado
            if (allowEscape) {
                event.accepted = true
                hide()
            } else {
                event.accepted = true
                console.log("Escape blocked - Video is playing")
            }
        }
        else if (api.keys.isAccept(event)) {
            event.accepted = true

            // Ejecutar la acción del botón actualmente seleccionado
            switch(currentButtonIndex) {
                case 0: // Play button
                    if (currentGame) {
                        Utils.launchGame(currentGame, api)
                    }
                    break
                case 1: // Pause button
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.togglePlayPause()
                    }
                    break
                case 2: // Stop button
                    if (themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.stop()
                        // La señal videoFinished manejará el resto (allowEscape, videoHasStarted, currentButtonIndex)
                        console.log("Stop button activated via keyboard")
                    }
                    break
                case 3: // Maximize button
                    if (videoHasStarted && themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.toggleFullscreen()
                    } else {
                        console.log("Maximize blocked - Video hasn't started yet")
                    }
                    break
                case 4: // Mute button
                    if (videoHasStarted && themeRoot && themeRoot.videoOverlay) {
                        themeRoot.videoOverlay.toggleMute()
                        muteButton.isMuted = themeRoot.videoOverlay.isMuted
                    } else {
                        console.log("Mute blocked - Video hasn't started yet")
                    }
                    break
            }
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            var nextIndex = currentButtonIndex - 1

            // Si el video no ha iniciado, saltar botones bloqueados (3 y 4)
            if (!videoHasStarted) {
                if (nextIndex < 0) {
                    nextIndex = 2 // Ir al Stop (último botón accesible)
                } else if (nextIndex === 4 || nextIndex === 3) {
                    nextIndex = 2 // Saltar a Stop
                }
            } else {
                // Navegación normal circular
                if (nextIndex < 0) {
                    nextIndex = totalButtons - 1
                }
            }

            currentButtonIndex = nextIndex
            console.log("Navigated to button index:", currentButtonIndex)
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            var nextIndex = currentButtonIndex + 1

            // Si el video no ha iniciado, saltar botones bloqueados (3 y 4)
            if (!videoHasStarted) {
                if (nextIndex > 2) {
                    nextIndex = 0 // Volver al Play
                }
            } else {
                // Navegación normal circular
                if (nextIndex >= totalButtons) {
                    nextIndex = 0
                }
            }

            currentButtonIndex = nextIndex
            console.log("Navigated to button index:", currentButtonIndex)
        }
    }
}
