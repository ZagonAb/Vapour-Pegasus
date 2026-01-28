import QtQuick 2.15
import QtGraphicalEffects 1.15
import "utils.js" as Utils

ListView {
    id: gameListView

    property var currentCollection: null
    property var currentGameRef: null
    property bool showingCollections: false
    property var focusManagerRef: null
    property var detailsViewRef: null
    property string currentView: "home"
    property var themeRoot: null

    signal gameChanged(var game)
    signal letterIndexRequested()
    signal filterValidationRequested()

    anchors.left: parent.left
    anchors.leftMargin: vpx(40)
    anchors.right: parent.right
    anchors.rightMargin: vpx(40)
    anchors.verticalCenter: parent.verticalCenter
    height: vpx(300)
    orientation: ListView.Horizontal
    spacing: vpx(2)
    clip: false

    activeFocusOnTab: true
    keyNavigationEnabled: true

    focus: currentView === "home" && focusManagerRef && focusManagerRef.currentFocus === "gameList"

    preferredHighlightBegin: vpx(0)
    preferredHighlightEnd: width - vpx(120)
    highlightRangeMode: ListView.ApplyRange
    highlightMoveDuration: 250
    highlightFollowsCurrentItem: true
    cacheBuffer: vpx(1000)
    displayMarginBeginning: vpx(500)
    displayMarginEnd: vpx(500)

    model: currentCollection

    onCurrentIndexChanged: {
        if (!showingCollections && currentItem && model) {
            var game = model.get(currentIndex)
            gameChanged(game)
        } else if (showingCollections && currentItem && model) {
            if (model.count > 0 && currentIndex >= 0 && currentIndex < model.count) {
                var game = model.get(currentIndex)
                gameChanged(game)
            }
        }
        letterIndexRequested()
        filterValidationTimer.restart()
    }

    onFocusChanged: {
        if (focus) {
            console.log("GameListView received focus")
        }
    }

    Timer {
        id: filterValidationTimer
        interval: 100
        onTriggered: filterValidationRequested()
    }

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
                        text: modelData.title || ""
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
            soundManager.playNavigation()
            if (detailsViewRef) {
                detailsViewRef.show()
            }
            if (focusManagerRef) {
                focusManagerRef.switchView("details")
            }
        }
        else if (api.keys.isDetails(event)) {
            event.accepted = true
            soundManager.playNavigation()

            if (themeRoot) {
                var currentViewMode = api.memory.has('viewMode') ? api.memory.get('viewMode') : 'list'
                var newViewMode = currentViewMode === 'grid' ? 'list' : 'grid'

                api.memory.set('viewMode', newViewMode)

                if (themeRoot.viewToggleButton) {
                    themeRoot.viewToggleButton.isGridView = (newViewMode === 'grid')
                }

                if (themeRoot.gameViewLoader) {
                    themeRoot.gameViewLoader.active = false

                    Qt.callLater(function() {
                        themeRoot.gameViewLoader.sourceComponent = undefined
                        themeRoot.gameViewLoader.sourceComponent =
                        (newViewMode === 'grid') ? themeRoot.gridViewComponent : themeRoot.listViewComponent
                        themeRoot.gameViewLoader.active = true

                        Qt.callLater(function() {
                            if (focusManagerRef) {
                                if (newViewMode === 'grid') {
                                    focusManagerRef.gameGridView = themeRoot.gameViewLoader.item
                                    focusManagerRef.gameListView = null
                                } else {
                                    focusManagerRef.gameListView = themeRoot.gameViewLoader.item
                                    focusManagerRef.gameGridView = null
                                }
                                focusManagerRef.setFocus("gameList")
                            }
                        })
                    })
                }
            }
        }
        else if (api.keys.isNextPage(event)) {
            event.accepted = true
            soundManager.playNavigation()
            if (themeRoot && themeRoot.jumpToNextLetter) {
                themeRoot.jumpToNextLetter()
            }
        }
        else if (api.keys.isPrevPage(event)) {
            event.accepted = true
            soundManager.playNavigation()
            if (themeRoot && themeRoot.jumpToPrevLetter) {
                themeRoot.jumpToPrevLetter()
            }
        }
        else if (api.keys.isFilters(event)) {
            event.accepted = true
            soundManager.playNavigation()
            if (themeRoot) {
                if (!themeRoot.showingCollections) {
                    themeRoot.showingCollections = true
                    var filterListView = themeRoot.children[0]
                    for (var i = 0; i < themeRoot.children.length; i++) {
                        var child = themeRoot.children[i]
                        if (child.objectName === "unifiedFilterListView") {
                            child.currentIndex = 0
                            break
                        }
                    }
                    if (api.collections.count > 0) {
                        themeRoot.currentCollection = api.collections.get(0).games
                        if (themeRoot.currentCollection.count > 0) {
                            themeRoot.currentGame = themeRoot.currentCollection.get(0)
                        }
                    }
                    currentIndex = 0
                    if (focusManagerRef) {
                        focusManagerRef.enterCollectionsView()
                    }
                } else {
                    themeRoot.showingCollections = false
                    var filterListView = themeRoot.children[0]
                    for (var i = 0; i < themeRoot.children.length; i++) {
                        var child = themeRoot.children[i]
                        if (child.objectName === "unifiedFilterListView") {
                            child.currentIndex = 0
                            break
                        }
                    }
                    themeRoot.currentCollection = api.allGames
                    currentIndex = 0
                    if (themeRoot.currentCollection.count > 0) {
                        themeRoot.currentGame = themeRoot.currentCollection.get(0)
                    }
                    if (focusManagerRef) {
                        focusManagerRef.exitCollectionsView()
                    }
                }
            }
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            soundManager.playNavigation()
            if (focusManagerRef) {
                focusManagerRef.handleUp()
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            soundManager.playNavigation()
            if (focusManagerRef) {
                focusManagerRef.handleDown()
            }
        }
        else if (api.keys.isCancel(event)) {
            if (themeRoot && themeRoot.showingCollections) {
                event.accepted = true
                soundManager.playNavigation()
                if (focusManagerRef) {
                    focusManagerRef.setFocus("filterSelector")
                }
            } else {
                if (focusManagerRef && focusManagerRef.handleBack()) {
                    event.accepted = true
                }
            }
        }
    }
}
