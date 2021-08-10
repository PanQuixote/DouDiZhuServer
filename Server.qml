import QtQuick 2.0
import qt.SocketServer 1.0

SocketServer {
  id: server

  signal getJsonMessage(var json_obj, var sender_socket)


  readonly property int wantGetRoomList: 0
  readonly property int wantGetRoomInfo: 1
  readonly property int wantEnterRoom: 2
  readonly property int wantDoSomethingInRoom: 3

  property var templet_of_json_from_client: {
    "request_type": wantGetRoomList,
    "request_content": {}
  }

  onGetMessageFromClient: {
    var json_obj = JSON.parse(msg)

    getJsonMessage(json_obj, sender_socket)
  }

  Component.onCompleted: {
    start(false)
  }

  function sendJsonMessage(json_obj, receiver_socket) {
    var str = JSON.stringify(json_obj)

    return sendMessage(str, receiver_socket)
  }
}
