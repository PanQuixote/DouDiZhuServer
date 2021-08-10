import QtQuick 2.0

Rectangle {
  id: background

  width: 100
  height: 30

  color: "transparent"

  property int margins: 2
  property int topMargin: margins
  property int bottomMargin: margins
  property int leftMargin: margins
  property int rightMargin: margins

  property var key_: text

  property alias textObj: t
  property alias text: t.text
  property alias textColor: t.color
  property alias backgroundColor: background.color

  property alias contentWidth: t.contentWidth
  property alias contentHeight: t.contentHeight

  property alias font: t.font
  property alias pointSize: t.font.pointSize
  property alias pixelSize: t.font.pixelSize

  property alias verticalAlignment: t.verticalAlignment
  property alias horizontalAlignment: t.horizontalAlignment

  property alias wrapMode: t.wrapMode

  property alias lineCount: t.lineCount

  property alias textFormat: t.textFormat

  property alias enableClick: area.enabled

  signal clicked(var key)


  MouseArea {
    id: area

    enabled: false

    anchors.fill: parent

    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onClicked: {
      background.clicked(background.key_)
    }

  }

  Text {
    id: t

    anchors {
      fill: parent

      topMargin: background.topMargin
      bottomMargin: background.bottomMargin
      leftMargin: background.leftMargin
      rightMargin: background.rightMargin
    }

    text: ""

    color: "black"

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
  }
}
