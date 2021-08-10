import QtQuick 2.0



Rectangle {

  width: 500
  height: 300

  property var server

  property var rooms: []

  property int max_room_count: 3

  Component.onCompleted: {

    for (var i = 0; i < max_room_count; i++) {
      room_list_view.model.append({})
    }

  }

  function doSomethingInRoom(room_index, messageFromPlayer) {

    if (room_index > room_list_view.count || room_index < 0) {
      return false
    }

    room_list_view.getItem(room_index).messageFromPlayer = messageFromPlayer

    return true
  }

  function getAvailableRoomIndex() {
    var res = []
    for (var i = 0; i < room_list_view.count; i++) {
      if (room_list_view.getItem(i).onlinePlayerCount < 3) {
        res.push(i)
      }
    }

    return res
  }

  function enterRoom(room_index, player_socket, player_name, player_score) {
    if (room_index > room_list_view.count || room_index < 0) {
      return -1
    }

    var res = room_list_view.getItem(room_index).playerEnterRoom(player_socket,
                                                            player_name,
                                                            player_score)

    return res
  }

  function exitRoom(room_index, player_socket) {
    if (room_index > room_list_view.count || room_index < 0) {
      return -1
    }

    return room_list_view.getItem(room_index).playerExitRoom(player_socket)
  }

  function getRoomInfo(room_index) {

    if (room_index > room_list_view.count || room_index < 0) {
      return false
    }

    return room_list_view.getItem(room_index).currentInfo
  }


  CustomListView {
    id: room_list_view

    anchors.fill: parent

    spacing: 20

    delegate: single_room_delegate
  }

  Component {
    id: single_room_delegate

    Rectangle {
      id: single_room

      width: parent.width
      height: 150

      color: "lightgrey"

      property int room_id: index
      property int onlinePlayerCount: 0

      property int baseScore: 1

      property var playerOnline: [false, false, false]
      property var playerSocket: [-1, -1, -1]

      property int maxThinkTime: 20


      property var currentInfo  // will be sent to client

      readonly property int someoneEnterRoom: 0

      readonly property int waitReady: 1
      readonly property int waitCall: 2

      readonly property int waitPut: 3
      readonly property int finish: 4

      readonly property int someoneReady: 5

      readonly property int someoneCall: 6
      readonly property int someoneNotCall: 7

      readonly property int someonePut: 8
      readonly property int someonePass: 9

      readonly property int someoneExitRoom: 10



      property var messageFromPlayer  // send from client

      readonly property int wantReady: 0

      readonly property int wantCall: 1
      readonly property int wantNotCall: 2

      readonly property int wantPut: 3
      readonly property int wantPass: 4


//      property var templete_of_json_from_player: {

//        "room_id": 0,
//        "player_index": 0,
//        "socket": 0,

//        "type": wantReady,

//        "card_array": []

//      }


      CountDownTimer {
        id: timer

        width: 0
        height: 0
        visible: false

        onTimerout: {

          var auto_not_call_message

          if (single_room.currentInfo.sate === waitCall) {

            auto_not_call_message = {
              "room_id": single_room.room_id,
              "player_index": single_room.currentInfo.target_index,
              "socket": single_room.playerSocket[single_room.currentInfo.target_index],

              "type": single_room.wantNotCall,

              "card_array": []
            }

            single_room.messageFromPlayer = auto_not_call_message

          } else if (single_room.currentInfo.sate === waitPut) {

            // the index of card witch will be put
            var auto_put_card_index = single_room.currentInfo.player_info_array[single_room.currentInfo.target_index]
                                        .current_card[single_room.currentInfo.player_info_array[single_room.currentInfo.target_index].card_count - 1]

            auto_not_call_message = {
              "room_id": single_room.room_id,
              "player_index": single_room.currentInfo.target_index,
              "socket": single_room.playerSocket[single_room.currentInfo.target_index],

              "type": single_room.currentInfo.target_index === single_room.currentInfo.last_index
                      ? single_room.wantPut
                      : single_room.wantPass,

              "card_array": [auto_put_card_index]
            }

            single_room.messageFromPlayer = auto_not_call_message

          }

        }
      }

      Component.onCompleted: {
        init()
      }

      onMessageFromPlayerChanged: {

        var player_index = messageFromPlayer.player_index

        var i

        if (messageFromPlayer.type === wantReady) {

          currentInfo.state = someoneReady
          currentInfo.target_index = player_index

          currentInfo.player_ready[player_index] = true
          currentInfo.player_info_array[player_index].ready = true

          sendToAllPlayer()




          let all_ready = true
          for (i = 0; i < 3; i++) {
            if (currentInfo.player_ready[i] !== true) {
              all_ready = false
              break
            }
          }

          if (all_ready) {  // everyone ready

            restart()

            currentInfo.state = waitCall
            currentInfo.remain_time = maxThinkTime
            currentInfo.target_index = getRandomInt(0, 2)

            var card_array = generateRandomCardArray()

            for (i = 0; i < 3; i++) {
              currentInfo.player_info_array[i].card_count = 17
              currentInfo.player_info_array[i].current_card = sortByBigToSmall(card_array.slice(i * 17, (i + 1)) * 17)
            }

            currentInfo.extra_card = sortByBigToSmall(card_array.slice(51, 54))

            sendToAllPlayer()

            // start count down
            timer.restart(maxThinkTime)

          } else {

            currentInfo.state = waitReady

            sendToAllPlayer()
          }



        } else if (messageFromPlayer.type === wantCall) {

          timer.stop()

          currentInfo.state = someoneCall
          currentInfo.target_index = player_index

          currentInfo.player_info_array[player_index].is_landlord = true

          let t = currentInfo.player_info_array[player_index].current_card.concat(currentInfo.extra_card)
          currentInfo.player_info_array[player_index].current_card = t

          currentInfo.player_info_array[player_index].card_count = 20

          sendToAllPlayer()


          currentInfo.state = waitPut
          currentInfo.remain_time = maxThinkTime
          currentInfo.target_index = player_index

          sendToAllPlayer()

          // start count down
          timer.restart(maxThinkTime)

        } else if (messageFromPlayer.type === wantNotCall) {

          timer.stop()

          currentInfo.state = someoneNotCall
          currentInfo.target_index = player_index
          sendToAllPlayer()


          currentInfo.asked_call[player_index] = true

          let all_asked_call = true
          for (i = 0; i < 3; i++) {
            if (currentInfo.asked_call[i] === false) {
              all_asked_call = false
              break
            }
          }

          if (all_asked_call) { // none one call, finish

            currentInfo.state = finish
            for (i = 0; i < 3; i++) {
              currentInfo.player_info_array[i].win = false
            }
            sendToAllPlayer()

          } else {  // someone have not be ask, ask him

            currentInfo.state = waitCall
            currentInfo.remain_time = maxThinkTime
            currentInfo.target_index = nextPlayerIndex(player_index)
            sendToAllPlayer()

            // start count down
            timer.restart(maxThinkTime)

          }


        } else if (messageFromPlayer.type === wantPut) {

          timer.stop()

          currentInfo.state = someonePut
          currentInfo.target_index = player_index
          currentInfo.last_index = player_index
          currentInfo.card_array = messageFromPlayer.card_array


          var put_card_length = messageFromPlayer.card_array.length
          var booom_flag = put_card_length === 4
                           ? true
                           : false
          for (i = 0; i < put_card_length; i++) {

            if (i !== 0 && messageFromPlayer.card_array[i] !== messageFromPlayer.card_array[i - 1]) {
              booom_flag = false
            }

            let t = currentInfo.player_info_array[player_index].indexOf(messageFromPlayer.card_array[i])
            if (t > 0) {
              currentInfo.player_info_array[player_index].splice(t, 1)
            }
          }

          // king boom
          if (put_card_length === 2
              && messageFromPlayer.card_array[0]
                  + messageFromPlayer.card_array[1] === 52 + 53)
          {
            booom_flag = true
          }

          if (booom_flag) {
            currentInfo.times *= 2
          }

          sendToAllPlayer()




          if (currentInfo.player_info_array[player_index].card_count === 0) { // finish

            var landlord_win = currentInfo.player_info_array[player_index].is_landlord

            currentInfo.state = finish
            for ( i = 0; i < 3; i++) {
              var player_i_is_landlord = currentInfo.player_info_array[i].is_landlord
              currentInfo.player_info_array[player_index].win = (player_i_is_landlord === landlord_win)
            }
            sendToAllPlayer()

          } else {  // wait next player put

            currentInfo.state = waitPut
            currentInfo.remain_time = maxThinkTime
            currentInfo.target_index = nextPlayerIndex(player_index)
            sendToAllPlayer()

            // start count down
            timer.restart(maxThinkTime)

          }




        } else if (messageFromPlayer.type === wantPass) {

          timer.stop()

          currentInfo.state = someonePass
          currentInfo.target_index = player_index
          sendToAllPlayer()


          currentInfo.state = waitPut
          currentInfo.remain_time = 20
          currentInfo.target_index = nextPlayerIndex(player_index)
          sendToAllPlayer()

          // start count down
          timer.restart(maxThinkTime)

        }
      }



      // if success return index of player, else return -1
      function playerEnterRoom(player_socket, player_name, player_score) {

        if (onlinePlayerCount < 3) {

          for (var i = 0; i < 3; i++) {
            if (playerOnline[i] !== true) {

              playerOnline[i] = true
              playerSocket[i] = player_socket
              onlinePlayerCount += 1


              currentInfo.state = someoneEnterRoom
              currentInfo.player_count = onlinePlayerCount
              currentInfo.player_online = playerOnline
              currentInfo.player_ready[i] = false
              currentInfo.target_index = i
              currentInfo.player_info_array[i].name = player_name
              currentInfo.player_info_array[i].score = player_score
              sendToAllPlayer()


              currentInfo.state = waitReady
              sendToAllPlayer()

              return i
            }
          }

        }

        return -1
      }

      function playerExitRoom(player_socket) {

        var i = playerSocket.indexOf(player_socket)
        if (i > 0) {

          playerOnline[i] = false
          playerSocket[i] = -1
          onlinePlayerCount -= 1


          currentInfo.state = someoneExitRoom
          currentInfo.player_count = onlinePlayerCount
          currentInfo.player_online = playerOnline
          currentInfo.player_ready[i] = false
          currentInfo.target_index = i
          currentInfo.player_info_array[i].name = ""
          currentInfo.player_info_array[i].score = -1
          sendToAllPlayer()

          if (currentInfo.state !== waitReady) {  // if game is running
            currentInfo.state = finish
            for (var j = 0; j < 3; j++) {

              if (j === i) {
                currentInfo.player_info_array[i].win = false
              } else {
                currentInfo.player_info_array[i].win = true
              }

            }
            sendToAllPlayer()


            currentInfo.state = waitReady
            sendToAllPlayer()

          } else {

            currentInfo.state = someoneExitRoom
            sendToAllPlayer()

          }


        }

        return i

      }

      function sendToAllPlayer() {
        var flag = true
        for (var i = 0; i < 3; i++) {
          if (playerOnline[i] !== true) {
            continue
          }

          if (server.sendJsonMessage(currentInfo, playerSocket[i]) !== true) {
            flag = false
          }
        }
        return flag
      }

      function nextPlayerIndex(player_index) {
        return player_index + 1 > 2 ? 0 : player_index + 1
      }

      function getRandomInt(min, max) {
        min = Math.ceil(min);
        max = Math.floor(max);
        return Math.floor(Math.random() * (max - min + 1)) + min;
      }

      function generateRandomCardArray() {

        var i, j, temp

        var arr = []
        for (i = 0; i < 54; i++) {
          arr[i] = i
        }

        for (i = 53; i > 0; i--) {
          j = Math.floor(Math.random() * (i + 1))
          temp = arr[i]
          arr[i] = arr[j]
          arr[j] = temp
        }
        return arr
      }

      function init() {
        currentInfo = {
          "room_id": index,
          "player_count": 0,
          "player_online": [false, false, false],
          "player_ready": [false, false, false],
          "asked_call": [false, false, false],
          "card_counter": [4, 4, 4, 4, 4,
                           4, 4, 4, 4, 4,
                           4, 4, 4, 4, 4,
                           1, 1],
          "extra_card": [],
          "state": waitReady,
          "remain_time": 20,
          "last_index": -1,
          "target_index": -1,
          "base_score": single_room.baseScore,
          "times": 1,
          "card_array": [],

          "player_info_array": [
                {
                  "socket": -1,
                  "index": 0,
                  "name": "",
                  "score": -1,
                  "ready": false,
                  "is_landlord": false,
                  "win": false,
                  "card_count": -1,

                  "current_card": []

                },
                {
                  "socket": -1,
                  "index": 1,
                  "name": "",
                  "score": -1,
                  "ready": false,
                  "is_landlord": false,
                  "win": false,
                  "card_count": -1,

                  "current_card": []

                },
                {
                  "socket": -1,
                  "index": 2,
                  "name": "",
                  "score": -1,
                  "ready": false,
                  "is_landlord": false,
                  "win": false,
                  "card_count": -1,

                  "current_card": []

                }
          ]
        }
      }

      function restart() {

        currentInfo.state = waitReady

        currentInfo.asked_call = [false, false, false]
        currentInfo.card_counter = [4, 4, 4, 4, 4,
                                    4, 4, 4, 4, 4,
                                    4, 4, 4, 4, 4,
                                    1, 1]
        currentInfo.extra_card = []
        currentInfo.remain_time = 20
        currentInfo.last_index = -1
        currentInfo.target_index = -1
        currentInfo.times = 1
        currentInfo.card_array = []
        for (var i = 0; i < 3; i++) {

          currentInfo.player_info_array[i].ready = false
          currentInfo.player_info_array[i].is_landlord = false
          currentInfo.player_info_array[i].win = false
          currentInfo.player_info_array[i].card_count = 0
          currentInfo.player_info_array[i].current_card = []

        }
      }

      function setInfo(names, values) {

        if (names.length !== values.length) {
          return
        }

        for (var i = 0; i < names.length; i++) {
          currentInfo[names[i]] = values[i]
        }

      }

      function sortByBigToSmall(card_index) {
        for (var i = 0; i < card_index.length; i++) {
          for (var j = i + 1; j < card_index.length; j++) {
            if (card_index[i] < card_index[j]) {
              var t = card_index[i]
              card_index[i] = card_index[j]
              card_index[j] = t
            }
          }

        }

        return card_index
      }

      Column {
        anchors.fill: parent

        spacing: 5

        CustomText {

          width: parent.width
          height: 30

          text: qsTr("room id:") + single_room.room_id
          font.bold: true
          font.pointSize: 14

          horizontalAlignment: Text.AlignLeft
        }

        CustomText {

          width: parent.width
          height: 30

          text: qsTr("player count:") + single_room.onlinePlayerCount
          font.bold: true
          font.pointSize: 14

          horizontalAlignment: Text.AlignLeft
        }

        CustomText {

          width: parent.width
          height: 30

          text: qsTr("base score:") + single_room.baseScore
          font.bold: true
          font.pointSize: 14

          horizontalAlignment: Text.AlignLeft
        }

      }

    }
  }
}