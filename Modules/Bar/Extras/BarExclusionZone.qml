import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons


/**
 * BarExclusionZone - Invisible PanelWindow that reserves exclusive space for the bar
 *
 * This is a minimal window that works with the compositor to reserve space,
 * while the actual bar UI is rendered in NFullScreenWindow.
 */
PanelWindow {
  id: root

  // Get monitor-specific configuration
  readonly property var monitorConfig: screen ? Settings.getMonitorBarConfig(screen.name) : Settings.getDefaultBarConfig()

  property bool exclusive: monitorConfig.exclusive !== undefined ? monitorConfig.exclusive : false

  readonly property string barPosition: monitorConfig.position || "top"
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
  readonly property bool barFloating: monitorConfig.floating || false
  readonly property real barMarginH: barFloating ? monitorConfig.marginHorizontal * Style.marginXL : 0
  readonly property real barMarginV: barFloating ? monitorConfig.marginVertical * Style.marginXL : 0

  // Invisible - just reserves space
  color: "transparent"

  mask: Region {}

  // Wayland layer shell configuration
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "noctalia-bar-exclusion-" + (screen?.name || "unknown")
  WlrLayershell.exclusionMode: exclusive ? ExclusionMode.Auto : ExclusionMode.Ignore

  // Anchor based on bar position
  anchors {
    top: barPosition === "top"
    bottom: barPosition === "bottom"
    left: barPosition === "left" || barPosition === "top" || barPosition === "bottom"
    right: barPosition === "right" || barPosition === "top" || barPosition === "bottom"
  }

  // Size based on bar orientation
  // When floating, only reserve space for the bar + margin on the anchored edge
  implicitWidth: {
    if (barIsVertical) {
      // Vertical bar: reserve bar height + margin on the anchored edge only
      if (barFloating) {
        // For left bar, reserve left margin; for right bar, reserve right margin
        return Style.barHeight + barMarginH
      }
      return Style.barHeight
    }
    return 0 // Auto-width when left/right anchors are true
  }

  implicitHeight: {
    if (!barIsVertical) {
      // Horizontal bar: reserve bar height + margin on the anchored edge only
      if (barFloating) {
        // For top bar, reserve top margin; for bottom bar, reserve bottom margin
        return Style.barHeight + barMarginV
      }
      return Style.barHeight
    }
    return 0 // Auto-height when top/bottom anchors are true
  }

  Component.onCompleted: {
    Logger.d("BarExclusionZone", "Created for screen:", screen?.name)
    Logger.d("BarExclusionZone", "  Position:", barPosition, "Exclusive:", exclusive, "Floating:", barFloating)
    Logger.d("BarExclusionZone", "  Anchors - top:", anchors.top, "bottom:", anchors.bottom, "left:", anchors.left, "right:", anchors.right)
    Logger.d("BarExclusionZone", "  Size:", width, "x", height, "implicitWidth:", implicitWidth, "implicitHeight:", implicitHeight)
  }
}
