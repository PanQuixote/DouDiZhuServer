import QtQuick 2.12

ListView {
  id: list_view

  clip: true

  model: ListModel{
    id: list_model
  }

  cacheBuffer: 10000

  boundsBehavior: Flickable.StopAtBounds //  ListView.DragOverBounds

//  orientation: ListView.Horizontal

  function getItem(index) {
    if (!(index >= 0 && index < list_view.count)) {
      return
    }

    var tem = list_view.currentIndex
    list_view.currentIndex = index
    list_view.currentIndex = tem

    return list_view.itemAtIndex(index)
  }


}
