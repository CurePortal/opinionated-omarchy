import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

// Compact transport notch for the center of the bar. With no MPRIS player
// around the buttons fall through to launching/focusing the Tidal web app.
BarWidget {
  id: root
  moduleName: "cure.media"

  readonly property var players: Mpris.players.values
  readonly property var activePlayer: {
    for (var i = 0; i < players.length; i++)
      if (players[i].isPlaying) return players[i]
    return players.length > 0 ? players[0] : null
  }

  readonly property bool playing: activePlayer ? activePlayer.isPlaying : false
  readonly property color contentColor: root.bar ? root.bar.barForeground : Color.foreground

  implicitWidth: controls.implicitWidth + Style.space(18)
  implicitHeight: barSize

  function launchTidal() {
    if (root.bar && typeof root.bar.run === "function")
      root.bar.run("omarchy-launch-or-focus-webapp tidal https://tidal.com")
  }

  function action(name) {
    if (!activePlayer) {
      launchTidal()
      return
    }
    if (name === "playPause") activePlayer.togglePlaying()
    else if (name === "next") activePlayer.next()
    else if (name === "previous") activePlayer.previous()
  }

  Row {
    id: controls
    anchors.centerIn: parent
    spacing: Style.space(8)

    TransportButton {
      glyph: "󰒮"
      onClicked: root.action("previous")
    }

    TransportButton {
      glyph: root.playing ? "󰏤" : "󰐊"
      glyphSize: Style.font.iconLarge
      onClicked: root.action("playPause")
    }

    TransportButton {
      glyph: "󰒭"
      onClicked: root.action("next")
    }
  }

  component TransportButton: Item {
    id: button

    property string glyph: ""
    property int glyphSize: Style.font.icon

    signal clicked()

    implicitWidth: label.implicitWidth + Style.space(8)
    implicitHeight: root.barSize

    Text {
      id: label
      anchors.centerIn: parent
      text: button.glyph
      color: root.contentColor
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: button.glyphSize
      opacity: interaction.hovered ? 1 : 0.75

      Behavior on opacity {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
      }
    }

    HoverHandler { id: interaction }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
      onWheel: function(wheel) {
        if (!root.activePlayer) return
        root.action(wheel.angleDelta.y > 0 ? "previous" : "next")
      }
    }
  }
}
