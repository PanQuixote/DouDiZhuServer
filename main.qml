import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Window {
  id: main_window
  visible: true
  width: 960
  height: 540
  title: qsTr("Hello World")

  function receiveMessageFromClient(msg, sender_socket) {

    var i, return_json

    if (msg.type === dpf.wantLogin) {

      let name = msg.content.name
      let password = msg.content.password

      let success = checkPassword(name, password)
      let score = getUserScore(name)


      return_json = {
        "type": dpf.returnPlayerInfo,
        "content": {
          "success": success,
          "name": name,
          "password": password,
          "score": score,
          "socket": sender_socket
        }
      }

      server_main.sendJsonMessage(return_json, sender_socket)

    } else if (msg.type === dpf.wantRegister) {

      let name = msg.content.name
      let password = msg.content.password

      let success = checkName(name, password)
      let score = 0

      return_json = {
        "type": dpf.returnPlayerInfo,
        "content": {
          "success": success,
          "name": name,
          "password": password,
          "score": score,
          "socket": sender_socket
        }
      }

      server_main.sendJsonMessage(return_json, sender_socket)

    } else if (msg.type === dpf.wantGetAvailableRoomInfo) {

      let room_info_array = room_list.getAvailableRoomInfo()

      return_json = {
        "type": dpf.returnAvailableRoomInfo,
        "content": room_info_array
      }

      server_main.sendJsonMessage(return_json, sender_socket)

    } else if (msg.type === dpf.wantGetCurrentRoomInfo) {

      return_json = room_list.getRoomInfo(msg.content.room_id)
      return_json.type = dpf.returnGameInfo
      server_main.sendJsonMessage(return_json, sender_socket)

    } else if (msg.type === dpf.wantEnterRoom) {

      var player_index = room_list.enterRoom(msg.content.room_id,
                                             msg.content.socket,
                                             msg.content.name,
                                             msg.content.score)

      // enter room success
      if (player_index >= 0)
      {
        return_json = {
          "type": dpf.returnPlayerIndex,

          "content": {
            "room_id": msg.content.room_id,
            "player_index": player_index
          }
        }

        server_main.sendJsonMessage(return_json, sender_socket)

        function_rec.addNewLog("client enter room " + msg.content.room_id +
                               ", index = " + player_index +
                               ", socket = " + msg.content.socket)



        // update AvailableRoomInfo
        let room_info_array = room_list.getAvailableRoomInfo()

        return_json = {
          "type": dpf.returnAvailableRoomInfo,
          "content": room_info_array
        }

        for (i = 0; i < server_main.clientCount(); i++) {
          server_main.sendJsonMessage(return_json, server_main.getSocket(i))
        }
      }

    } else if (msg.type === dpf.wantExitRoom) {

      var room_index = room_list.exitRoom(msg.content.socket)

      // exit room success
      if (room_index >= 0)
      {
        let room_info_array = room_list.getAvailableRoomInfo()

        return_json = {
          "type": dpf.returnAvailableRoomInfo,
          "content": room_info_array
        }

        for (let i = 0; i < server_main.clientCount(); i++) {
          server_main.sendJsonMessage(return_json, server_main.getSocket(i))
        }

      }

    } else if (msg.type === dpf.wantDoSomethingInRoom) {

      room_list.doSomethingInRoom(msg.content.room_id, msg.content)

    }
  }

  function slotClientConnected(client_socket) {
    function_rec.addNewLog("new client connected: socket = " + client_socket)
  }

  function slotClientDisconnected(client_socket) {

    var room_id = room_list.exitRoom(client_socket)
    if (room_id > 0) {
      function_rec.addNewLog("client exit room " + room_id + ", socket = " + client_socket)

      let room_info_array = room_list.getAvailableRoomInfo()

      var j = {
        "type": dpf.returnAvailableRoomInfo,
        "content": room_info_array
      }

      for (let i = 0; i < server_main.clientCount(); i++) {
        sendJsonMessage(j, server_main.getSocket(i))
      }
    }

    function_rec.addNewLog("client disconnected: socket = " + client_socket)
  }

  // if password is right, return score, else return false
  function checkPassword(name, password) {

    var user_info_array = config.obj.user_info
    for (var i = 0; i < user_info_array.length; i++) {
      if (name === user_info_array[i].name) {
        return password === user_info_array[i].password
      }
    }

    return false
  }

  // if name already exist, return false
  function checkName(name, password) {

    var user_info_array = config.obj.user_info
    for (var i = 0; i < user_info_array.length; i++) {
      if (name === user_info_array[i].name) {
        return false
      }
    }

    config.obj.user_info.push({"name": name,
                                "password": password,
                                "score": 0})

    return config.updateConfiguration()
  }

  function getUserScore(name) {
    var user_info_array = config.obj.user_info
    for (var i = 0; i < user_info_array.length; i++) {
      if (name === user_info_array[i].name) {
        return user_info_array[i].score
      }
    }

    return false
  }

  function updateUserScore(name, score) {

    var user_info_array = config.obj.user_info
    for (var i = 0; i < user_info_array.length; i++) {
      if (name === user_info_array[i].name) {
        config.obj.user_info[i].score = score
        return config.updateConfiguration()
      }
    }

    return false

  }

  // server
  Server {
    id: server_main

    onGetJsonMessage: {
      main_window.receiveMessageFromClient(json_obj, sender_socket)
    }

    onClientConnected: {
      main_window.slotClientConnected(client_socket)
    }

    onClientDisconnected: {
      main_window.slotClientDisconnected(client_socket)
      var room_id = room_list.exitRoom(client_socket)
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

    onWantToUpdateUserScore: {
      server_main.updateUserScore(name, score)
    }
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

  Configuration {
    id: config

    onOpenConfigurationFileFail: {
      function_rec.addNewLog("open configuration file fail!")
    }
  }

  DataPackageFormat {
    id: dpf
  }
}
