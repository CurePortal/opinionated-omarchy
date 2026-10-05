import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  property int hoveredId: -1

  // Apple-style workspace strip: a plain white numeral per workspace, no
  // chip or pill backgrounds. Focus is full white and bold; occupied sits
  // brighter than empty; hover lifts whichever numeral the pointer is on.
  readonly property color labelColor: Color.bar.text
  readonly property real stripPadX: vertical ? Style.spaceReal(2) : Style.spaceReal(4)
  readonly property real stripPadY: vertical ? Style.spaceReal(2) : Style.spaceReal(3)
  readonly property real cellWidth: Math.max(16, Style.font.body * 1.6)

  implicitWidth: strip.width + stripPadX * 2
  implicitHeight: strip.height + stripPadY * 2

  GridLayout {
    id: strip
    x: root.stripPadX
    y: root.stripPadY
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(2)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property bool hot: root.hoveredId === modelData

        implicitWidth: root.cellWidth
        implicitHeight: Style.font.body * 1.4
        Layout.preferredWidth: root.cellWidth
        Layout.preferredHeight: Style.font.body * 1.4

        Text {
          anchors.centerIn: parent
          text: modelData === 10 ? "0" : String(modelData)
          color: root.labelColor
          opacity: parent.focused || parent.hot ? 1 : (parent.occupied ? 0.72 : 0.4)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: parent.focused
          renderType: Text.NativeRendering

          Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.hoveredId = modelData
          onExited: if (root.hoveredId === modelData) root.hoveredId = -1
          onClicked: root.focusWorkspace(modelData)
        }
      }
    }
  }
}
