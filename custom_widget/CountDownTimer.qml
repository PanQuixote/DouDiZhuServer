import QtQuick 2.0


Rectangle {
  id: root

  width: 70
  height: width

  visible: timer.running

  radius: width / 2

  clip: true

  property int totalTime: 3

  property alias runing: timer.running

  signal timerout()

  function start() {
    timer.start()
  }

  function restart(time) {
    time_text.text = time
    timer.remainTime = time
    timer.restart()
  }

  function stop() {
    timer.stop()
  }

  Text {
    id: time_text

    anchors.fill: parent

    text: root.totalTime

    font.bold: true
    font.pointSize: 20

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
  }

  Timer {
    id: timer

    property int remainTime: root.totalTime

    triggeredOnStart: false

    repeat: true

    onTriggered: {

      remainTime =  remainTime - 1

      if(remainTime === 0) {
        time_text.text = 0
        stop()
        root.timerout()

        return
      }

      time_text.text = remainTime
    }
  }

  color: "green"

}

