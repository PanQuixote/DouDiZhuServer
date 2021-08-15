import QtQuick 2.0
import qt.SocketServer 1.0

SocketServer {
  id: server

  signal getJsonMessage(var json_obj, var sender_socket)


  // request get from client
  readonly property int wantLogin: 0
  readonly property int wantGetAvailableRoomInfo: 1
  readonly property int wantGetCurrentRoomInfo: 2
  readonly property int wantEnterRoom: 3
  readonly property int wantExitRoom: 4
  readonly property int wantDoSomethingInRoom: 5
  readonly property int wantRegister: 6


  // return to client
  readonly property int returnGameInfo: 9
  readonly property int returnPlayerInfo: 10
  readonly property int returnAvailableRoomInfo: 11
  readonly property int returnRoomInfo: 12
  readonly property int returnPlayerIndex: 13



//  property var templet_of_json_from_client: {
//    "type": wantLogin,
//    "content": {}
//  }

  function isJsonStr(str) {
    if (typeof str == 'string') {
        try {
            var obj=JSON.parse(str);
            if(typeof obj == 'object' && obj ){
                return true;
            }else{
                return false;
            }

        } catch(e) {
//            console.log('error：'+str+'!!!'+e);
            return false;
        }
    }
    return false
  }

  onGetMessageFromClient: {

    if (isJsonStr(msg)) {
      var json_obj = JSON.parse(msg)

      getJsonMessage(json_obj, sender_socket)
    }


  }

  Component.onCompleted: {
    start(false)
  }

  function sendJsonMessage(json_obj, receiver_socket) {
    var str = JSON.stringify(json_obj)

    var res = sendMessage(str, receiver_socket)
    if (res !== true) {
      console.log("fail to send message to client ", receiver_socket)
    }

    return res
  }
}
