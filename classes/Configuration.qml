import QtQuick 2.0

import qt.LocalFileOperator 1.0

Item {
  id: root

  property var obj

  property alias operator: l

  property bool isValid: false

  signal openConfigurationFileFail()

  function writeJsonFile(json_obj) {
    if (l.writeJsonFile(json_obj)) {
      l.readJsonFile()
      return true
    }

    return false
  }

  function updateConfiguration() {
    return writeJsonFile(obj)
  }

  LocalFileOperator {
    id: l

    Component.onCompleted: {
//      console.log(source)

      source = getCurrentPath() + "/../../DoDiZhuServer/configuration.json"
      obj = l.readJsonFile()
      if (Object.keys(obj).length > 0) {
        isValid = true
        return
      } else {
        isValid = false
      }

      source = getCurrentPath() + "./configuration.json"
      obj = l.readJsonFile()
      if (Object.keys(obj).length > 0) {
        isValid = true
        return
      } else {
        isValid = false
      }

//      console.log(isValid)
    }
  }
}
