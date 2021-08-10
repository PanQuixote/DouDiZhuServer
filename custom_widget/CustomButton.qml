import QtQuick 2.0

Rectangle {
  id: root

  width: 50
  height: 50

  color: "red"

  property alias text: t.text
  property alias font: t.font
  property alias horizontalAlignment: t.horizontalAlignment
  property alias verticalAlignment: t.verticalAlignment

  signal clicked()

  MouseArea {
    anchors.fill: parent
    enabled: parent.enabled

    cursorShape: enabled
                 ? Qt.PointingHandCursor
                 : Qt.ArrowCursor

    onClicked: {
      root.clicked()
    }
  }

  Text {
    id: t
    anchors.fill: parent

    font.pointSize: 14

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}
