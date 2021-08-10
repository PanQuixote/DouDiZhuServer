import QtQuick 2.12
import QtQuick.Window 2.12

Window {
  visible: true
  width: 960
  height: 540
  title: qsTr("Hello World")

  Server {
    id: server_main

    onGetJsonMessage: {

      if (json_obj.type === wantGetRoomList) {

        return room_list.getAvailableRoomIndex()

      } else if (json_obj.type === wantGetRoomInfo){

        return room_list.getRoomInfo(json_obj.request_content.room_id)

      } else if (json_obj.type === wantEnterRoom){

        return room_list.getRoomInfo(json_obj.request_content.room_id)

      } else if (json_obj.type === wantDoSomethingInRoom){

        return room_list.doSomethingInRoom(json_obj.request_content.room_id)

      }

    }
  }

  RoomList {
    id: room_list

    color: "lightblue"

    server: server_main

    width: parent.width / 2
    height: parent.height



  }
}
