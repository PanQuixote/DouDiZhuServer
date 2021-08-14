import QtQuick 2.0

import qt.LocalFileOperator 1.0

Item {
  id: root

  property var obj

  property alias operator: l

  property bool isValid: false

  LocalFileOperator {
    id: l
    source: "./configuration.json"

    Component.onCompleted: {
      obj = l.readJsonFile()
      if (Object.keys(obj).length > 0) {
        isValid = true
      } else {
        isValid = false
      }
//      console.log(isValid)
    }
  }
}
