import QtQuick 2.0

Item {


  // type of message client send to server
  readonly property int wantLogin: 1
  readonly property int wantGetAvailableRoomInfo: 2
  readonly property int wantGetCurrentRoomInfo: 3
  readonly property int wantEnterRoom: 4
  readonly property int wantExitRoom: 5
  readonly property int wantDoSomethingInRoom: 6
  readonly property int wantRegister: 7

  // instruct in game, will be sent to server
  readonly property int wantReady: 1
  readonly property int wantCancelReady: 2
  readonly property int wantCall: 3
  readonly property int wantNotCall: 4
  readonly property int wantPut: 5
  readonly property int wantPass: 6
  readonly property int wantTalk: 7


//  // the templet of message client send to server:
//  // (when type != wantDoSomethingInRoom)
//  readonly property var json_send_to_server: {
//    "type": wantLogin,
//    "content": {

//    }
//  }

//  // if it's instruct in game, it will be as below:
//  // (when type == wantDoSomethingInRoom)
//  readonly property var json_send_to_server: {
//    "type": wantDoSomethingInRoom,
//    "content": {
//      "room_id": room_id,
//      "player_index": index,
//      "socket": socket,

//      "type": wantReady,

//      "card_array": []
//    }
//  }


  // type of message from server
  readonly property int returnGameInfo: 9
  readonly property int returnPlayerInfo: 10
  readonly property int returnAvailableRoomInfo: 11
  readonly property int returnRoomInfo: 12
  readonly property int returnPlayerIndex: 13



  // state of message from server, which type is returnGameInfo
  readonly property int someoneEnterRoom: 1
  readonly property int waitReady: 2
  readonly property int waitCall: 3
  readonly property int waitPut: 4
  readonly property int finish: 5
  readonly property int someoneReady: 6
  readonly property int someoneCancelReady: 7
  readonly property int someoneCall: 8
  readonly property int someoneNotCall: 9
  readonly property int someonePut: 10
  readonly property int someonePass: 11
  readonly property int someoneExitRoom: 12
  readonly property int someoneTalk: 13


//    // the templet of message from server:
//    // (when type != returnGameInfo)
//    readonly property var json_receive_from_server: {
//      "type": returnPlayerInfo,
//      "content": {

//      }
//    }

//    // if it's instruct in game, it will be as below:
//    // (when type == returnGameInfo)
//    readonly property var json_receive_from_server: {
//      "type": returnGameInfo,
//      "room_id": index,
//      "player_count": 0,
//      "player_online": [false, false, false],
//      "gaming": false,
//      "player_ready": [false, false, false],
//      "asked_call": [false, false, false],
//      "card_counter": [4, 4, 4, 4, 4,
//                       4, 4, 4, 4, 4,
//                       4, 4, 4, 1, 1],
//      "extra_card": [],
//      "state": waitReady,
//      "remain_time": 20,
//      "last_index": -1,
//      "target_index": -1,
//      "base_score": single_room.baseScore,
//      "times": 1,
//      "card_array": [],

//      "player_info_array": [
//            {
//              "socket": -1,
//              "index": 0,
//              "name": "",
//              "score": -1,
//              "ready": false,
//              "is_landlord": false,
//              "win": false,
//              "card_count": -1,

//              "current_card": []

//            },
//            {
//              "socket": -1,
//              "index": 1,
//              "name": "",
//              "score": -1,
//              "ready": false,
//              "is_landlord": false,
//              "win": false,
//              "card_count": -1,

//              "current_card": []

//            },
//            {
//              "socket": -1,
//              "index": 2,
//              "name": "",
//              "score": -1,
//              "ready": false,
//              "is_landlord": false,
//              "win": false,
//              "card_count": -1,

//              "current_card": []

//            }
//      ]
//    }



}
