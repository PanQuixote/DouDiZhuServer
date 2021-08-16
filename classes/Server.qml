import QtQuick 2.0
import qt.SocketServer 1.0

SocketServer {
  id: server

  signal getJsonMessage(var json_obj, var sender_socket)

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
