import QtQuick 2.0



Rectangle {

  width: 500
  height: 300

  property var server

  property var rooms: []

  property int max_room_count: 3

  signal wantToUpdateUserScore(var name, var score)

  Component.onCompleted: {

    for (var i = 0; i < max_room_count; i++) {
      room_list_view.model.append({})
    }

    room_list_view.getItem(0).setBaseScore(1)
    room_list_view.getItem(1).setBaseScore(5)
    room_list_view.getItem(2).setBaseScore(10)

  }

  function doSomethingInRoom(room_id, messageFromPlayer) {

    if (!(room_id >= 0
        && room_id < room_list_view.count)) {
      return false
    }

    room_list_view.getItem(room_id).receiveMessageFromClient(messageFromPlayer)

    return true
  }

  function getAvailableRoomIndex() {
    var res = []
    for (var i = 0; i < room_list_view.count; i++) {
      if (room_list_view.getItem(i).playerCount < 3) {
        res.push(i)
      }
    }

    return res
  }

  function getAvailableRoomInfo() {
    var res = []
    for (var i = 0; i < room_list_view.count; i++) {
      var room_i = room_list_view.getItem(i)
      if (room_i.playerCount < 3) {
        var info = {
          "room_id": i,
          "player_count": room_i.playerCount,
          "base_score": room_i.baseScore
        }

        res.push(info)
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

  function exitRoom(player_socket) {

    for (var i = 0; i < max_room_count; i++) {
      if (room_list_view.getItem(i).playerExitRoom(player_socket) >= 0) {
        return i
      }
    }

    return -1
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

      color: playerCount === 0
             ? "lightgrey"
             : playerCount === 1
               ? "lightyellow"
               : playerCount === 2
                 ? "orange"
                 : "orangered"

      property int room_id: index
      property int playerCount: 0

      property bool gaming: false

      property int baseScore: 1

      property var playerOnline: [false, false, false]
      property var playerSocket: [-1, -1, -1]

      property int maxThinkTime: 20

      property bool initFlag: false

      property var currentInfo  // will be sent to client

      signal timeout()

      onPlayerCountChanged: {
        initCurrentInfo()
        currentInfo.player_count = playerCount
      }

      onGamingChanged: {
        initCurrentInfo()
        currentInfo.gaming = gaming
      }

      onBaseScoreChanged: {
        initCurrentInfo()
        currentInfo.base_score = baseScore
      }

      onPlayerOnlineChanged: {
        initCurrentInfo()
        currentInfo.player_online = playerOnline
      }

      onPlayerSocketChanged: {
        initCurrentInfo()
        for (var i = 0; i < 3; i++) {
          currentInfo.player_info_array[i].socket = playerSocket[i]
        }
      }


      onTimeout: {

        var auto_message

        if (single_room.currentInfo.state === dpf.waitCall) {

          auto_message = {

            "room_id": single_room.room_id,
            "player_index": single_room.currentInfo.target_index,
            "socket": single_room.playerSocket[single_room.currentInfo.target_index],

            "type": dpf.wantNotCall,

            "card_array": []
          }

          single_room.receiveMessageFromClient(auto_message)

        } else if (single_room.currentInfo.state === dpf.waitPut) {

          // will put the last card
          let target_index = single_room.currentInfo.target_index
          let current_card = single_room.currentInfo.player_info_array[target_index].current_card
          let last_card = current_card[current_card.length - 1]

          auto_message = {

            "room_id": single_room.room_id,
            "player_index": single_room.currentInfo.target_index,
            "socket": single_room.playerSocket[single_room.currentInfo.target_index],

            "type": single_room.currentInfo.target_index === single_room.currentInfo.last_index
                    ? dpf.wantPut
                    : dpf.wantPass,

            "card_array": [last_card]
          }

          single_room.receiveMessageFromClient(auto_message)

        }
      }


      Component.onCompleted: {
        initCurrentInfo()
      }

      function receiveMessageFromClient(msg) {

        var player_index = msg.player_index

        var i

        if (msg.type === dpf.wantReady) {

          currentInfo.state = dpf.someoneReady
          currentInfo.target_index = player_index

          currentInfo.player_ready[player_index] = true
          currentInfo.player_info_array[player_index].ready = true

          sendToAllPlayer()




          let all_ready = currentInfo.player_ready[0]
                          && currentInfo.player_ready[1]
                          && currentInfo.player_ready[2]

          if (all_ready) {  // everyone ready

            restart()

            gaming = true

            currentInfo.state = dpf.waitCall
            currentInfo.remain_time = maxThinkTime
            currentInfo.target_index = getRandomInt(0, 2)

            var card_array = generateRandomCardArray()

            for (i = 0; i < 3; i++) {
              var current_card = card_array.slice(i * 17, (i + 1) * 17)
              currentInfo.player_info_array[i].card_count = 17
              currentInfo.player_info_array[i].current_card = sortByBigToSmall(current_card)
            }

            currentInfo.extra_card = sortByBigToSmall(card_array.slice(51, 54))

            sendToAllPlayer()

            // start count down
            timer.restart(maxThinkTime)

          } else {

            currentInfo.state = dpf.waitReady

            sendToAllPlayer()
          }



        } else if (msg.type === dpf.wantCancelReady) {

          currentInfo.player_ready[player_index] = false
          currentInfo.player_info_array[player_index].ready = false

          currentInfo.state = dpf.someoneCancelReady
          currentInfo.target_index = player_index

          sendToAllPlayer()


          currentInfo.state = dpf.waitReady

          sendToAllPlayer()

        } else if (msg.type === dpf.wantCall) {

          // not his turn
          if (currentInfo.target_index !== player_index) {
            return
          }

          timer.stop()

          currentInfo.state = dpf.someoneCall
          currentInfo.target_index = player_index

          currentInfo.player_info_array[player_index].is_landlord = true

          let t = currentInfo.player_info_array[player_index].current_card.concat(currentInfo.extra_card)
          currentInfo.player_info_array[player_index].current_card = sortByBigToSmall(t)
          currentInfo.player_info_array[player_index].card_count = 20

          sendToAllPlayer()


          currentInfo.state = dpf.waitPut
          currentInfo.remain_time = maxThinkTime
          currentInfo.target_index = player_index
          currentInfo.last_index = player_index

          sendToAllPlayer()

          // start count down
          timer.restart(maxThinkTime)

        } else if (msg.type === dpf.wantNotCall) {

          // not his turn
          if (currentInfo.target_index !== player_index) {
            return
          }

          timer.stop()

          currentInfo.state = dpf.someoneNotCall
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

            currentInfo.state = dpf.finish
            for (i = 0; i < 3; i++) {
              currentInfo.player_info_array[i].win = false
            }

            sendToAllPlayer()

          } else {  // someone have not be ask, ask him

            currentInfo.state = dpf.waitCall
            currentInfo.remain_time = maxThinkTime
            currentInfo.target_index = nextPlayerIndex(player_index)
            sendToAllPlayer()

            // start count down
            timer.restart(maxThinkTime)

          }


        } else if (msg.type === dpf.wantPut) {

          // not his turn
          if (currentInfo.target_index !== player_index) {
            return
          }


          let put_card = msg.card_array
          let put_card_length = msg.card_array.length
          let current_card = currentInfo.player_info_array[player_index].current_card
          var put_card_index_in_current_card = []


          // check if all card in put_card are also in current_card or not
          for (i = 0; i < put_card_length; i++) {
            let res = cardIndexInCardArray(put_card[i], current_card)
            if (res < 0) { // put_card[i] not in current_card
              return
            } else {
              put_card_index_in_current_card.push(res)
            }
          }

          // delete put_card from current_card
          for (i = put_card_length - 1; i >= 0; i--) {
            currentInfo.player_info_array[player_index].current_card.splice(put_card_index_in_current_card[i], 1)
          }


          timer.stop()

          currentInfo.state = dpf.someonePut
          currentInfo.target_index = player_index
          currentInfo.last_index = player_index
          currentInfo.card_array = msg.card_array

          // update card_count
          currentInfo.player_info_array[player_index].card_count
              = currentInfo.player_info_array[player_index].current_card.length


          // update card_counter
          for (i = 0; i < put_card_length; i++) {

            currentInfo.card_counter[put_card[i].grade - 3] -= 1

          }

          // check if times should double
          if (isBoomOrKingBoom(put_card)) {
            currentInfo.times *= 2
          }

          sendToAllPlayer()




          if (currentInfo.player_info_array[player_index].card_count === 0) { // finish

            gaming = false

            timer.stop()

            currentInfo.state = dpf.finish


            var landlord_win = currentInfo.player_info_array[player_index].is_landlord
            for (i = 0; i < 3; i++) {

              let is_landlord = currentInfo.player_info_array[i].is_landlord
              let win = (is_landlord === landlord_win)

              currentInfo.player_info_array[i].win = win

              let get_score = currentInfo.base_score * currentInfo.times

              get_score = is_landlord ? get_score * 2 : get_score
              get_score = win ? get_score : -get_score

              currentInfo.player_info_array[i].score += get_score

              let player_name = currentInfo.player_info_array[i].name
              let current_score = currentInfo.player_info_array[i].score

              wantToUpdateUserScore(player_name, current_score)

            }

            sendToAllPlayer()

          } else {  // wait next player put

            currentInfo.state = dpf.waitPut
            currentInfo.remain_time = maxThinkTime
            currentInfo.target_index = nextPlayerIndex(player_index)
            sendToAllPlayer()

            // start count down
            timer.restart(maxThinkTime)

          }




        } else if (msg.type === dpf.wantPass) {

          // not his turn
          if (currentInfo.target_index !== player_index) {
            return
          }

          timer.stop()

          currentInfo.state = dpf.someonePass
          currentInfo.target_index = player_index
          sendToAllPlayer()


          currentInfo.state = dpf.waitPut
          currentInfo.remain_time = 20
          currentInfo.target_index = nextPlayerIndex(player_index)
          sendToAllPlayer()

          // start count down
          timer.restart(maxThinkTime)

        } else if (msg.type === dpf.wantTalk) {

          let talk_msg = {
            "type": dpf.returnGameInfo,
            "state": dpf.someoneTalk,
            "text": msg.name + ": " + msg.text
          }

          sendToAllPlayer(talk_msg)

        }
      }



      // if success return index of player, else return -1
      function playerEnterRoom(player_socket, player_name, player_score) {

        if (playerCount < 3) {

          for (var i = 0; i < 3; i++) {

            if (playerOnline[i] !== true) {

              playerOnline[i] = true
              playerSocket[i] = player_socket
              playerCount += 1


              currentInfo.state = dpf.someoneEnterRoom
              currentInfo.player_ready[i] = false
              currentInfo.target_index = i
              currentInfo.player_info_array[i].name = player_name
              currentInfo.player_info_array[i].score = player_score

              for (var x = 0; x < 3; x++) {
                if (x !== i) {
                  sendToPlayer(x)
                }
              }


              currentInfo.state = dpf.waitReady
              for (var y = 0; y < 3; y++) {
                if (y !== i) {
                  sendToPlayer(y)
                }
              }

              return i
            }
          }

        }

        return -1
      }

      function playerExitRoom(player_socket) {

        var i = playerSocket.indexOf(player_socket)
        if (i >= 0) {


          playerCount -= 1
          playerOnline[i] = false
          playerSocket[i] = -1


          if (gaming) {  // if game is running

            gaming = false

            timer.stop()

            currentInfo.state = dpf.finish
            for (var j = 0; j < 3; j++) {

              let win = (j !== i)
              let is_landlord = currentInfo.player_info_array[j].is_landlord
              currentInfo.player_info_array[j].win = win

              let get_score = currentInfo.base_score * currentInfo.times

              get_score = is_landlord ? get_score * 2 : get_score
              get_score = win ? get_score : -get_score

              currentInfo.player_info_array[j].score += get_score

              let player_name = currentInfo.player_info_array[j].name
              let current_score = currentInfo.player_info_array[j].score
              wantToUpdateUserScore(player_name, current_score)

            }

            sendToAllPlayer()

          } else {

            currentInfo.state = dpf.someoneExitRoom
            sendToAllPlayer()

          }

          restart()
          sendToAllPlayer()


        }

        return i

      }

      function sendToAllPlayer(content = currentInfo) {
        var flag = true
        for (var i = 0; i < 3; i++) {
          if (playerOnline[i] !== true) {
            continue
          }

          if (server.sendJsonMessage(content, playerSocket[i]) !== true) {
            flag = false
          }
        }
        return flag
      }

      function sendToPlayer(player_index) {

        if (player_index >= 0 && player_index <= 2 && playerOnline[player_index]) {
          return server.sendJsonMessage(currentInfo, playerSocket[player_index])
        }
        return false

      }

      function nextPlayerIndex(player_index) {
        return player_index + 1 > 2 ? 0 : player_index + 1
      }

      function getRandomInt(min, max) { // get a random int in [min, max]
        min = Math.ceil(min);
        max = Math.floor(max);
        return Math.floor(Math.random() * (max - min + 1)) + min;
      }

      function generateRandomCardArray() {

        var i, j, temp

        var arr = []
        for(i = 3; i <= 17; i++) {

          if (i === 16) { // joker

            arr.push({"grade": 16, "face": 1, "card_index": 52})

          } else if (i === 17) {  // big joker

            arr.push({"grade": 17, "face": -2, "card_index": 53})

          } else {

            for (j = 1; j <= 4; j++) {
              arr.push({"grade": i, "face": j, "card_index": (i - 3) * 4 + j - 1})
            }

          }

        }

        for (i = 53; i > 0; i--) {
          j = Math.floor(Math.random() * (i + 1))
          temp = arr[i]
          arr[i] = arr[j]
          arr[j] = temp
        }

        return arr
      }

      function initCurrentInfo() {

        if (initFlag) {
          return
        }

        currentInfo = {
          "type": dpf.returnGameInfo,
          "room_id": index,
          "player_count": 0,
          "player_online": [false, false, false],
          "gaming": false,
          "player_ready": [false, false, false],
          "asked_call": [false, false, false],
          "card_counter": [4, 4, 4, 4, 4,
                           4, 4, 4, 4, 4,
                           4, 4, 4, 1, 1],
          "extra_card": [],
          "state": dpf.waitReady,
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

        initFlag = true
      }

      function setBaseScore(base_score) {
        baseScore = base_score
      }

      function restart() {

        currentInfo.state = dpf.waitReady
        currentInfo.player_ready = [false, false, false]
        currentInfo.asked_call = [false, false, false]
        currentInfo.card_counter = [4, 4, 4, 4, 4,
                                    4, 4, 4, 4, 4,
                                    4, 4, 4, 1, 1]
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

      function sortByBigToSmall(card_array) {
        var c = card_array

        c.sort(function (c1, c2) {
          return c2.card_index - c1.card_index
        })

        return c
      }

      function isFull() {
        return playerCount === 3
      }

      function isBoomOrKingBoom(card_array) {
        var len = card_array.length
        var booom_flag = len === 4
                         ? true
                         : false

        for (var i = 0; i < len; i++) {

          if (i !== 0 && card_array[i].grade !== card_array[i - 1].grade) {
            booom_flag = false  // not boom
          }

        }

        // king boom
        if (len === 2
            && card_array[0].card_index + card_array[1].card_index === 52 + 53)
        {
          booom_flag = true
        }

        return booom_flag
      }

      function cardIndexInCardArray(card, card_array) {

        let card_index = card.card_index
        for (var i = 0; i < card_array.length; i++) {
          if (card_index === card_array[i].card_index) {
            return i
          }
        }

        return -1
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

          text: qsTr("player count:") + single_room.playerCount
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

      CountDownTimer {
        id: timer

        width: 0
        height: 0
        visible: false

        onTimerout: {
          single_room.timeout()
        }
      }

      DataPackageFormat {
        id: dpf
      }
    }
  }
}
