import QtQuick 2.15

Item {
    id: infoRow

    property string label: ""
    property string value: ""
    property int valueFontSize: vpx(16)
    property bool showDivider: false
    property bool valueBold: true
    property alias labelColor: labelText.color
    property alias valueColor: valueText.color

    width: parent.width
    height: value === "" || value === "0" || value === "Never" ? 0 : labelText.height + vpx(8) + valueText.height
    visible: height > 0

    Column {
        width: parent.width
        spacing: vpx(5)

        Text {
            id: labelText
            text: label
            font.pixelSize: vpx(14)
            font.family: global.fonts.sans
            color: "#9099a1"
            width: parent.width
            elide: Text.ElideRight
        }

        Text {
            id: valueText
            text: value
            font.pixelSize: valueFontSize
            font.family: global.fonts.sans
            font.bold: valueBold
            color: "#FFFFFF"
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: vpx(1)
        color: "#2a2e33"
        visible: showDivider
    }
}

