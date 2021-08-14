import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Window {
  visible: true
  width: 960
  height: 540
  title: qsTr("Hello World")

  // server
  Server {
    id: server_main

    property var name_list: ["wolf", "son", "grandson"]
    property var password_list: ["1234", "123", "123"]
    property var score_list: [0, 0, 0]

    function checkPassword(name, password) {


      var index = name_list.indexOf(name)
      if (index < 0) {
        return false
      }

      if (password_list[index] !== password) {
        return false
      }

      return true
    }

    function checkName(name, password) {
      return false
    }

    function getScore(name) {
      var index = name_list.indexOf(name)
      if (index < 0) {
        return -9999
      }

      return score_list[index]
    }

    onGetJsonMessage: {

      var j

      if (json_obj.type === wantLogin) {

        let name = json_obj.content.name
        let password = json_obj.content.password
        let success = checkPassword(name, password)
        let score = 0

        j = {
          "type": returnPlayerInfo,
          "content": {
            "success": success,
            "name": name,
            "score": score,
            "socket": sender_socket
          }
        }

        sendJsonMessage(j, sender_socket)

      } else if (json_obj.type === wantRegister) {

        let name = json_obj.content.name
        let password = json_obj.content.password
        let success = checkName(name, password)
        let score = 0

        j = {
          "type": returnPlayerInfo,
          "content": {
            "success": success,
            "name": name,
            "score": score,
            "socket": sender_socket
          }
        }

        sendJsonMessage(j, sender_socket)

      } else if (json_obj.type === wantGetAvailableRoomInfo) {

        let room_info_array = room_list.getAvailableRoomInfo()

        j = {
          "type": returnAvailableRoomInfo,
          "content": room_info_array
        }

        sendJsonMessage(j, sender_socket)

      } else if (json_obj.type === wantGetCurrentRoomInfo) {

        j = room_list.getRoomInfo(json_obj.content.room_id)
        j["type"] = returnGameInfo
        sendJsonMessage(j, sender_socket)
        
      } else if (json_obj.type === wantEnterRoom) {

        var player_index = room_list.enterRoom(json_obj.content.room_id,
                                               json_obj.content.socket,
                                               json_obj.content.name,
                                               json_obj.content.score)

        // enter room success
        if (player_index >= 0)
        {
          j = {
            "type": returnPlayerIndex,

            "content": {
              "room_id": json_obj.content.room_id,
              "player_index": player_index
            }
          }

          sendJsonMessage(j, sender_socket)

          function_rec.addNewLog("client enter room " + json_obj.content.room_id +
                                 ", index = " + player_index +
                                 ", socket = " + json_obj.content.socket)
        }

      } else if (json_obj.type === wantExitRoom) {

        var room_index = room_list.exitRoom(json_obj.content.socket)

        // exit room success
        if (room_index >= 0)
        {
          let room_info_array = room_list.getAvailableRoomInfo()

          j = {
            "type": returnAvailableRoomInfo,
            "content": room_info_array
          }

          for (let i = 0; i < server_main.clientCount(); i++) {
            sendJsonMessage(j, server_main.getSocket(i))
          }

        }

      } else if (json_obj.type === wantDoSomethingInRoom) {

        room_list.doSomethingInRoom(json_obj.content.room_id, json_obj.content)

      }
    }

    onClientConnected: {
      function_rec.addNewLog("new client connected: socket = " + client_socket)
    }

    onClientDisconnected: {
      var room_id = room_list.exitRoom(client_socket)
      if (room_id > 0) {
        function_rec.addNewLog("client exit room " + room_id + ", socket = " + client_socket)

        let room_info_array = room_list.getAvailableRoomInfo()

        var j = {
          "type": returnAvailableRoomInfo,
          "content": room_info_array
        }

        for (let i = 0; i < server_main.clientCount(); i++) {
          sendJsonMessage(j, server_main.getSocket(i))
        }
      }
      function_rec.addNewLog("client disconnected: socket = " + client_socket)
    }
  }

  // room list
  RoomList {
    id: room_list

    color: "lightblue"

    server: server_main

    width: parent.width / 2
    height: parent.height

    anchors.left: parent.left
  }

  // function rec
  Column {
    id: function_rec

    width: parent.width / 2
    height: parent.height

    anchors.right: parent.right

    spacing: 20

    function addNewLog(str) {
      log_text.text += str + "\n"
    }

    function clearLog() {
      log_text.text = ""
    }

    Rectangle {
      id: log_text_wrapper

      width: parent.width - 20
      height: 400

      border.width: 3

      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        id: log_text_frame
        clip: true
        anchors.fill: parent
        anchors.margins: 3
        border.color: "black"
        anchors.centerIn: parent
        anchors.top: parent.bottom
        anchors.left: parent.left
        focus: true

        Keys.onUpPressed: vbar.decrease()
        Keys.onDownPressed: vbar.increase()

        TextEdit {
          id: log_text

          font.bold: true
          font.pointSize: 16

          height: contentHeight
          width: log_text_frame.width - vbar.width
          y: -vbar.position * log_text.height
          wrapMode: TextEdit.Wrap
          selectByKeyboard: true
          selectByMouse: true

          onTextChanged: {
            //            moveCursorSelection(log_text.length)
            if (log_text.height > log_text_frame.height) {
              vbar.increase()
            }
          }

          MouseArea {
            anchors.fill: parent
            onWheel: {
              if (wheel.angleDelta.y > 0) {
                vbar.decrease()
              } else {
                vbar.increase()
              }
            }
            onClicked: {
              log_text.forceActiveFocus()
            }
          }
        }

        ScrollBar {
          id: vbar
          hoverEnabled: true
          active: hovered || pressed
          orientation: Qt.Vertical
          size: log_text_frame.height / log_text.height
          width: 10
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.bottom: parent.bottom
        }
      }
    }

    Rectangle {
      id: enter_instruct_rec

      width: parent.width - 20
      height: 50

      anchors.horizontalCenter: parent.horizontalCenter

      Row {
        anchors.fill: parent

        spacing: 20

        TextField {
          id: instruct_text

          width: parent.width - instruct_btn.width - parent.spacing
          height: parent.height

          horizontalAlignment: TextInput.AlignLeft

          //          verticalAlignment: TextInput.AlignTop
          font.bold: true
          font.pointSize: 16
        }

        CustomButton {
          id: instruct_btn

          color: "grey"

          text: "Run"

          width: 100
          height: parent.height

          onClicked: {
            var instruct_str = instruct_text.getText(0, instruct_text.length)

            if (instruct_str === "clear") {
              log_text.text = ""
              instruct_text.text = ""
              return
            }

            if (server_main.executeInstruct(instruct_str)) {
              instruct_text.text = ""
            } else {
              function_rec.addNewLog(
                    "fail to execute instruct '" + instruct_str + "'")
            }
          }
        }
      }
    }
  }
}
