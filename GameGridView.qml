import QtQuick 2.15
import QtGraphicalEffects 1.15
import "utils.js" as Utils

GridView {
    id: gameGridView

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

    anchors.fill: parent
    anchors.topMargin: vpx(10
    anchors.bottomMargin: vpx(20
    anchors.leftMargin: vpx(40)
    anchors.rightMargin: vpx(40)

    clip: true
    activeFocusOnTab: true
    keyNavigationWraps: true

    model: currentCollection

    highlightMoveDuration: 200
    highlightFollowsCurrentItem: true
    cacheBuffer: vpx(1500)

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
        console.log("GameGridView focus changed to:", focus)

        if (currentItem) {
            currentItem.hasFocus = focus
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
            width: vpx(16)
            height: vpx(16)
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            asynchronous: true
            mipmap: true
        }
    }

    Component {
        id: playerIconComponent
        Image {
            width: vpx(20)
            height: vpx(20)
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            asynchronous: true
            mipmap: true
        }
    }

    delegate: Item {
        width: gameGridView.cellWidth
        height: gameGridView.cellHeight

        property bool isSelected: GridView.isCurrentItem
        property bool hasFocus: gameGridView.activeFocus && gameGridView.focus
        property bool shouldShowReflection: false

        scale: isSelected ? 1.05 : 0.95
        z: isSelected ? 10 : 1

        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        onIsSelectedChanged: {
            if (isSelected && hasFocus) {
                shouldShowReflection = true
                reflectionEffect.reflectionProgress = 0.0
                reflectionEffect.timerRunning = true

                if (gradientBorder) {
                    gradientBorder.progress = 0.0
                    gradientBorder.running = true
                    gradientBorder.requestPaint()
                }
            } else {
                shouldShowReflection = false
                reflectionEffect.timerRunning = false
            }
        }

        onHasFocusChanged: {
            console.log("Delegate hasFocus changed:", index, "to:", hasFocus, "isSelected:", isSelected)

            if (isSelected && hasFocus) {
                shouldShowReflection = true
                reflectionEffect.reflectionProgress = 0.0
                reflectionEffect.timerRunning = true

                if (gradientBorder) {
                    gradientBorder.progress = 0.0
                    gradientBorder.running = true
                    gradientBorder.requestPaint()
                }
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
            id: contentContainer
            anchors.fill: parent
            anchors.margins: vpx(8

            Rectangle {
                id: cardBackground
                anchors.fill: parent
                color: "#1A1A1A"
                radius: vpx(8)

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
                        radius: vpx(8)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 0.7; color: "#00000000" }
                        GradientStop { position: 1.0; color: "#CC000000" }
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: vpx(10)
                    spacing: vpx(5)

                    Item {
                        width: parent.width
                        height: parent.height * 0.7

                        Image {
                            id: logoOverlay
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.width * 0.9)
                            height: Math.min(implicitHeight, parent.height * 0.9)
                            source: modelData.assets.logo || ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            mipmap: true
                            visible: status === Image.Ready

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
                            anchors.centerIn: parent
                            text: modelData.title || ""
                            font.pixelSize: vpx(14)
                            font.family: global.fonts.sans
                            font.bold: true
                            color: "#FFFFFF"
                            style: Text.Outline
                            styleColor: "#000000"
                            visible: logoOverlay.status !== Image.Ready || logoOverlay.source === ""
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
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
                            radius: vpx(8)
                        }
                    }
                }
            }

            Canvas {
                id: gradientBorder
                anchors.fill: parent
                anchors.margins: -vpx(1)
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
                    running: gradientBorder.running && gradientBorder.opacity > 0
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
                    console.log("GradientBorder opacity changed:", opacity, "isSelected:", isSelected, "hasFocus:", hasFocus)

                    if (opacity === 1 && isSelected && hasFocus) {
                        progress = 0.0
                        running = true
                        requestPaint()
                    } else {
                        running = false
                    }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    var w = width
                    var h = height
                    var r = vpx(8)
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

                Component.onCompleted: {
                    if (isSelected && hasFocus) {
                        progress = 0.0
                        running = true
                        requestPaint()
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        console.log("GameGridView Key pressed:", event.key, "Focus:", focus)

        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
            event.accepted = true
            Utils.launchGame(currentGameRef, api)
        }
        else if (api.keys.isDetails(event)) {
            event.accepted = true
            if (detailsViewRef) {
                detailsViewRef.show()
            }
            if (focusManagerRef) {
                focusManagerRef.switchView("details")
            }
        }
        else if (api.keys.isNextPage(event)) {
            event.accepted = true
            if (themeRoot && themeRoot.jumpToNextLetter) {
                themeRoot.jumpToNextLetter()
            }
        }
        else if (api.keys.isPrevPage(event)) {
            event.accepted = true
            if (themeRoot && themeRoot.jumpToPrevLetter) {
                themeRoot.jumpToPrevLetter()
            }
        }
        else if (api.keys.isFilters(event)) {
            event.accepted = true
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
            console.log("GameGridView: Up key pressed")
            var cols = Math.floor(width / cellWidth)
            if (currentIndex < cols) {
                if (focusManagerRef) {
                    focusManagerRef.setFocus("filterSelector")
                }
            } else {
                var cols = Math.floor(width / cellWidth)
                if (currentIndex >= cols) {
                    currentIndex -= cols
                }
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            console.log("GameGridView: Down key pressed")
            var cols = Math.floor(width / cellWidth)
            if (currentIndex + cols < count) {
                currentIndex += cols
            }
        }
        else if (api.keys.isCancel(event)) {
            if (themeRoot && themeRoot.showingCollections) {
                event.accepted = true
                if (focusManagerRef) {
                    focusManagerRef.setFocus("filterSelector")
                }
            } else {
                if (focusManagerRef && focusManagerRef.handleBack()) {
                    event.accepted = true
                }
            }
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            moveCurrentIndexLeft()
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            moveCurrentIndexRight()
        }
        else if (event.key === Qt.Key_PageUp) {
            event.accepted = true
            var cols = Math.floor(width / cellWidth)
            if (currentIndex >= cols) {
                currentIndex -= cols
            }
        }
        else if (event.key === Qt.Key_PageDown) {
            event.accepted = true
            var cols = Math.floor(width / cellWidth)
            if (currentIndex + cols < count) {
                currentIndex += cols
            }
        }
    }

    function moveCurrentIndexLeft() {
        if (currentIndex > 0) {
            currentIndex--
        } else if (keyNavigationWraps) {
            currentIndex = count - 1
        }
    }

    function moveCurrentIndexRight() {
        if (currentIndex < count - 1) {
            currentIndex++
        } else if (keyNavigationWraps) {
            currentIndex = 0
        }
    }

    Component.onCompleted: {
        if (focusManagerRef) {
            focusManagerRef.gameGridView = this
        }
        this.forceActiveFocus()
    }
}
