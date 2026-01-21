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

    FocusManager {
        id: focusManager
        homeView: homeView
        detailsView: detailsViewComponent
        gameListView: gameListView
        filterListView: unifiedFilterListView
    }

    Component.onCompleted: {
        if (api.allGames.count > 0) {
            currentGame = api.allGames.get(0)
        }

        /*var savedIndex = api.memory.get('lastGameIndex')
        if (savedIndex !== undefined && savedIndex < api.allGames.count) {
            gameListView.currentIndex = savedIndex
        }*/
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"

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
                GradientStop { position: 0.6; color: "#FF000000" }
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

        Row {
            id: contentRow
            anchors.right: parent.right
            anchors.rightMargin: vpx(30)
            anchors.verticalCenter: parent.verticalCenter
            spacing: vpx(15)

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

            Item {
                width: vpx(400)
                height: vpx(150)

                readonly property var game: {
                    if (!currentGame) return null
                        if (showingCollections && currentCollection &&
                            gameListView.currentIndex >= 0 &&
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
                    anchors.centerIn: parent
                    text: parent.game ? (parent.game.title || parent.game.name || "") : ""
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
                            gameListView.currentIndex >= 0 &&
                            gameListView.currentIndex < currentCollection.count) {
                            var game = currentCollection.get(gameListView.currentIndex)
                            return game ? (game.title || game.name || "Unknown") : "No games"
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
                    visible: currentGame && currentGame.releaseYear > 0 && !showingCollections
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height
                }

                Row {
                    id: ratingRow
                    spacing: vpx(2)
                    visible: currentGame && !showingCollections && currentGame.rating > 0
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
                    visible: currentGame && currentGame.players > 1 && !showingCollections
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

        ListView {
            id: gameListView
            anchors.left: parent.left
            anchors.leftMargin: vpx(40)
            anchors.right: parent.right
            anchors.rightMargin: vpx(40)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: vpx(125)
            height: vpx(300)
            orientation: ListView.Horizontal
            spacing: vpx(2)
            clip: false
            focus: currentView === "home" && focusManager.currentFocus === "gameList"

            preferredHighlightBegin: vpx(0)
            preferredHighlightEnd: width - vpx(120)
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 250
            highlightFollowsCurrentItem: true
            cacheBuffer: vpx(1000)
            displayMarginBeginning: vpx(500)
            displayMarginEnd: vpx(500)

            property bool isShowingCollections: showingCollections

            model: currentCollection

            onCurrentIndexChanged: {
                if (!showingCollections && currentItem && model) {
                    currentGame = model.get(currentIndex)
                } else if (showingCollections && currentItem && model) {
                    if (model.count > 0 && currentIndex >= 0 && currentIndex < model.count) {
                        currentGame = model.get(currentIndex)
                    }
                }
            }

            delegate: Item {
                width: vpx(180)
                height: vpx(245)

                property bool isSelected: ListView.isCurrentItem
                property bool hasFocus: gameListView.focus
                property bool shouldShowReflection: false

                scale: isSelected ? 1.1 : 0.9
                z: isSelected ? 10 : 1

                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                onIsSelectedChanged: {
                    if (isSelected && hasFocus) {
                        shouldShowReflection = true
                        reflectionEffect.reflectionProgress = 0.0
                        reflectionEffect.timerRunning = true
                    } else {
                        shouldShowReflection = false
                        reflectionEffect.timerRunning = false
                    }
                }

                onHasFocusChanged: {
                    if (isSelected && hasFocus) {
                        shouldShowReflection = true
                        reflectionEffect.reflectionProgress = 0.0
                        reflectionEffect.timerRunning = true
                    } else {
                        shouldShowReflection = false
                        reflectionEffect.timerRunning = false
                    }
                }

                property string imageSource: {
                    if (modelData.assets.background && modelData.assets.background !== "") {
                        return modelData.assets.background
                    } else if (modelData.assets.screenshot && modelData.assets.screenshot !== "") {
                        return modelData.assets.screenshot
                    }
                    return ""
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: vpx(-7)

                    Rectangle {
                        id: cardBackground
                        anchors.fill: parent
                        color: "#1A1A1A"
                        radius: vpx(12)

                        Image {
                            id: cardImage
                            anchors.fill: parent
                            source: imageSource
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false

                            onStatusChanged: {
                                if (status === Image.Error) {
                                } else if (status === Image.Ready) {
                                } else if (status === Image.Loading) {
                                } else if (status === Image.Null) {
                                }
                            }
                        }

                        OpacityMask {
                            anchors.fill: cardImage
                            source: cardImage
                            maskSource: Rectangle {
                                width: cardImage.width
                                height: cardImage.height
                                radius: vpx(12)
                            }
                        }

                        Item {
                            anchors.centerIn: parent
                            width: parent.width * 0.8
                            height: parent.height * 0.5

                            Image {
                                id: logoOverlay
                                anchors.centerIn: parent
                                width: parent.width * 0.9
                                height: parent.height * 0.8
                                source: modelData.assets.logo || ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                mipmap: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.title || modelData.name || ""
                                font.pixelSize: vpx(20)
                                font.family: global.fonts.sans
                                font.bold: true
                                color: "#FFFFFF"
                                style: Text.Outline
                                styleColor: "#000000"
                                visible: logoOverlay.status !== Image.Ready
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }

                        Item {
                            id: reflectionContainer
                            anchors.fill: parent
                            visible: shouldShowReflection

                            ShaderEffect {
                                id: reflectionEffect
                                anchors.fill: parent
                                visible: false
                                opacity: shouldShowReflection ? 0.8 : 0

                                property real reflectionProgress: 0.0
                                property color reflectionColor: "#FFFFFF"
                                property real reflectionWidth: 0.35
                                property real intensity: 0.5
                                property bool timerRunning: false

                                Timer {
                                    id: reflectionTimer
                                    interval: 25
                                    running: reflectionEffect.timerRunning
                                    repeat: true
                                    onTriggered: {
                                        reflectionEffect.reflectionProgress += 0.04
                                        if (reflectionEffect.reflectionProgress > 1.5) {
                                            reflectionEffect.reflectionProgress = 1.5
                                            reflectionEffect.timerRunning = false
                                        }
                                    }
                                }

                                vertexShader: "
                                uniform highp mat4 qt_Matrix;
                                attribute highp vec4 qt_Vertex;
                                attribute highp vec2 qt_MultiTexCoord0;
                                varying highp vec2 coord;
                                void main() {
                                coord = qt_MultiTexCoord0;
                                gl_Position = qt_Matrix * qt_Vertex;
                            }"

                            fragmentShader: "
                            varying highp vec2 coord;
                            uniform lowp float qt_Opacity;
                            uniform lowp float reflectionProgress;
                            uniform lowp float reflectionWidth;
                            uniform lowp float intensity;
                            uniform lowp vec4 reflectionColor;

                            void main() {
                            if (reflectionProgress >= 1.5) {
                                gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
                                return;
                            }

                            highp vec2 normalizedCoord = coord;
                            highp float diagonalLine = normalizedCoord.x + normalizedCoord.y;
                            highp float reflectionPos = diagonalLine * 0.5;
                            highp float movingReflection = reflectionProgress - reflectionPos;
                            highp float distanceFromReflection = abs(movingReflection);

                            highp float gradientFactor;
                            if (distanceFromReflection < reflectionWidth) {
                                gradientFactor = 1.0 - (distanceFromReflection / reflectionWidth);
                                gradientFactor = smoothstep(0.0, 1.0, gradientFactor);
                            } else {
                                gradientFactor = 0.0;
                            }

                            highp float alpha = gradientFactor * intensity * reflectionColor.a * qt_Opacity;
                            highp vec3 color = reflectionColor.rgb * alpha;

                            gl_FragColor = vec4(color, alpha);
                            }"

                            Behavior on opacity {
                                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                            }

                            onTimerRunningChanged: {
                                if (!timerRunning && reflectionProgress >= 1.5) {
                                    fadeOutTimer.start()
                                }
                            }

                            Timer {
                                id: fadeOutTimer
                                interval: 200
                                onTriggered: {
                                    shouldShowReflection = false
                                }
                            }
                            }

                            OpacityMask {
                                anchors.fill: reflectionEffect
                                source: reflectionEffect
                                maskSource: Rectangle {
                                    width: reflectionEffect.width
                                    height: reflectionEffect.height
                                    radius: vpx(12)
                                }
                            }
                        }
                    }
                }

                Canvas {
                    id: gradientBorder
                    anchors.fill: parent
                    anchors.margins: -vpx(8)
                    opacity: (isSelected && hasFocus) ? 1 : 0

                    property real progress: 0.0
                    property real speed: 0.0040
                    property bool running: false

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    Timer {
                        id: sweepTimer
                        interval: 16
                        repeat: true
                        running: gradientBorder.running
                        onTriggered: {
                            gradientBorder.progress += gradientBorder.speed
                            if (gradientBorder.progress >= 1.0) {
                                gradientBorder.progress = 1.0
                                gradientBorder.running = false
                            }
                            gradientBorder.requestPaint()
                        }
                    }

                    onOpacityChanged: {
                        if (opacity === 1) {
                            progress = 0.0
                            running = true
                            requestPaint()
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        var w = width
                        var h = height
                        var r = vpx(12)
                        var borderWidth = vpx(3)
                        var offset = borderWidth / 2

                        ctx.clearRect(0, 0, w, h)

                        var straightW = w - 2 * r - borderWidth
                        var straightH = h - 2 * r - borderWidth
                        var corner = Math.PI * r / 2

                        var perimeter =
                        2 * straightW +
                        2 * straightH +
                        4 * corner

                        var startOffset =
                        straightW +
                        corner +
                        straightH +
                        corner +
                        straightW


                        var dist = (progress * perimeter + startOffset) % perimeter

                        function pointOnBorder(d) {
                            if (d < straightW)
                                return { x: r + offset + d, y: offset }

                                d -= straightW
                                if (d < corner) {
                                    var a = d / corner * Math.PI / 2
                                    return {
                                        x: w - r - offset + Math.sin(a) * r,
                                        y: r + offset - Math.cos(a) * r
                                    }
                                }

                                d -= corner
                                if (d < straightH)
                                    return { x: w - offset, y: r + offset + d }

                                    d -= straightH
                                    if (d < corner) {
                                        var a = d / corner * Math.PI / 2
                                        return {
                                            x: w - r - offset + Math.cos(a) * r,
                                            y: h - r - offset + Math.sin(a) * r
                                        }
                                    }

                                    d -= corner
                                    if (d < straightW)
                                        return { x: w - r - offset - d, y: h - offset }

                                        d -= straightW
                                        if (d < corner) {
                                            var a = d / corner * Math.PI / 2
                                            return {
                                                x: r + offset - Math.sin(a) * r,
                                                y: h - r - offset + Math.cos(a) * r
                                            }
                                        }

                                        d -= corner
                                        if (d < straightH)
                                            return { x: offset, y: h - r - offset - d }

                                            d -= straightH
                                            var a = d / corner * Math.PI / 2
                                            return {
                                                x: r + offset - Math.cos(a) * r,
                                                y: r + offset - Math.sin(a) * r
                                            }
                        }

                        var p = pointOnBorder(dist)
                        var glow = ctx.createRadialGradient(
                            p.x, p.y, 0,
                            p.x, p.y, vpx(60)
                        )
                        glow.addColorStop(0.0, "#bae5f5")
                        glow.addColorStop(0.25, "#bae5f5")
                        glow.addColorStop(1.0, "#397499")

                        ctx.strokeStyle = glow
                        ctx.lineWidth = borderWidth
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        ctx.beginPath()
                        ctx.moveTo(r + offset, offset)
                        ctx.lineTo(w - r - offset, offset)
                        ctx.quadraticCurveTo(w - offset, offset, w - offset, r + offset)
                        ctx.lineTo(w - offset, h - r - offset)
                        ctx.quadraticCurveTo(w - offset, h - offset, w - r - offset, h - offset)
                        ctx.lineTo(r + offset, h - offset)
                        ctx.quadraticCurveTo(offset, h - offset, offset, h - r - offset)
                        ctx.lineTo(offset, r + offset)
                        ctx.quadraticCurveTo(offset, offset, r + offset, offset)
                        ctx.closePath()
                        ctx.stroke()
                    }
                }
            }

            Keys.onPressed: {
                if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                    event.accepted = true
                    Utils.launchGame(currentGame, api)
                }
                else if (api.keys.isDetails(event)) {
                    event.accepted = true
                    detailsViewComponent.show()
                    focusManager.switchView("details")
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
                        gameListView.currentIndex = 0
                        focusManager.enterCollectionsView()
                    } else {
                        showingCollections = false
                        unifiedFilterListView.currentIndex = 0
                        currentCollection = api.allGames
                        gameListView.currentIndex = 0
                        if (currentCollection.count > 0) {
                            currentGame = currentCollection.get(0)
                        }
                        focusManager.exitCollectionsView()
                    }
                }
                else if (event.key === Qt.Key_Up) {
                    event.accepted = true
                    focusManager.handleUp()
                }
                else if (event.key === Qt.Key_Down) {
                    event.accepted = true
                    focusManager.handleDown()
                }

                else if (api.keys.isCancel(event)) {
                    if (showingCollections) {
                        event.accepted = true
                        focusManager.setFocus("filterSelector")
                    } else {
                        if (focusManager.handleBack()) {
                            event.accepted = true
                        }
                    }
                }
            }
        }

        Item {
            id: filterContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: keyHints.top
            anchors.bottomMargin: vpx(5)
            width: showingCollections ? root.width * 0.8 : Math.min(parent.width - vpx(120), vpx(800))
            height: vpx(50)

            ListView {
                id: unifiedFilterListView
                anchors.centerIn: parent
                width: showingCollections ? parent.width : contentWidth
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
                    property string itemName: showingCollections ? modelData.name : modelData
                    property bool hasFocus: unifiedFilterListView.focus

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
                        gameListView.currentIndex = 0
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
                            gameListView.currentIndex = 0
                            focusManager.enterCollectionsView()
                        } else {
                            Utils.updateFilter(currentIndex, root)
                        }
                    }
                }

                Keys.onPressed: {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true
                        if (unifiedFilterListView.currentIndex > 0) {
                            unifiedFilterListView.currentIndex--
                        } else {
                            unifiedFilterListView.currentIndex = unifiedFilterListView.count - 1
                        }
                    }
                    else if (event.key === Qt.Key_Right) {
                        event.accepted = true
                        if (unifiedFilterListView.currentIndex < unifiedFilterListView.count - 1) {
                            unifiedFilterListView.currentIndex++
                        } else {
                            unifiedFilterListView.currentIndex = 0
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
                        focusManager.handleUp()
                    }
                    else if (event.key === Qt.Key_Down) {
                        event.accepted = true
                        focusManager.handleDown()
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
                            gameListView.currentIndex = 0
                            focusManager.enterCollectionsView()
                        } else {
                            showingCollections = false
                            unifiedFilterListView.currentIndex = 0
                            currentCollection = api.allGames
                            gameListView.currentIndex = 0
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
                            gameListView.currentIndex = 0
                            if (currentCollection.count > 0) {
                                currentGame = currentCollection.get(0)
                            }
                            focusManager.exitCollectionsView()
                        } else {
                            if (!focusManager.handleBack()) {
                            }
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
            anchors.bottomMargin: vpx(10)
            spacing: vpx(50)

            Row {
                spacing: vpx(10)
                Image {
                    source: "assets/icons/a.svg"
                    width: vpx(24)
                    height: vpx(24)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Play"
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
                    text: showingCollections ? "Details" : "Details"
                    font.pixelSize: vpx(16)
                    font.family: global.fonts.sans
                    color: "#CCCCCC"
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
}
