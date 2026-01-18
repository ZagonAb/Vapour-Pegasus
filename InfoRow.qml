import QtQuick 2.15

Item {
    property string label: ""
    property string value: ""

    width: parent.width
    height: vpx(30)
    visible: value !== "" && value !== "0" && value !== "Never"

    Row {
        anchors.fill: parent
        spacing: vpx(10)

        Text {
            text: label
            font.pixelSize: vpx(14)
            font.family: global.fonts.sans
            color: "#888888"
            width: vpx(140)
        }

        Text {
            text: value
            font.pixelSize: vpx(14)
            font.family: global.fonts.sans
            color: "#FFFFFF"
            elide: Text.ElideRight
            width: vpx(150)
        }
    }
}
