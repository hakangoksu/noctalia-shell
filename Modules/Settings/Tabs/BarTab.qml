import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  // Track current monitor being configured
  property int currentMonitorIndex: 0
  property string currentMonitorName: {
    if (Settings.data.bar.syncAcrossMonitors) {
      return "default"
    }
    if (currentMonitorIndex >= 0 && currentMonitorIndex < Quickshell.screens.length) {
      return Quickshell.screens[currentMonitorIndex].name
    }
    return "default"
  }

  // Get current monitor config
  property var currentConfig: Settings.getMonitorBarConfig(currentMonitorName)

  // Helper functions to update arrays immutably
  function addMonitor(list, name) {
    const arr = (list || []).slice()
    if (!arr.includes(name))
      arr.push(name)
    return arr
  }
  function removeMonitor(list, name) {
    return (list || []).filter(function (n) {
      return n !== name
    })
  }

  // Helper to update current monitor's config
  function updateCurrentConfig(property, value) {
    var config = JSON.parse(JSON.stringify(currentConfig))
    config[property] = value
    Settings.setMonitorBarConfig(currentMonitorName, config)
  }

  // Handler for drag start - disables panel background clicks
  function handleDragStart() {
    var panel = PanelService.getPanel("settingsPanel", screen)
    if (panel && panel.disableBackgroundClick) {
      panel.disableBackgroundClick()
    }
  }

  // Handler for drag end - re-enables panel background clicks
  function handleDragEnd() {
    var panel = PanelService.getPanel("settingsPanel", screen)
    if (panel && panel.enableBackgroundClick) {
      panel.enableBackgroundClick()
    }
  }

  // Sync toggle at the top
  NToggle {
    Layout.fillWidth: true
    label: "Sync all monitors"
    description: "Use the same bar configuration on all monitors"
    checked: Settings.data.bar.syncAcrossMonitors
    onToggled: checked => {
                 Settings.data.bar.syncAcrossMonitors = checked
                 currentMonitorIndex = 0
               }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
    visible: Settings.data.bar.syncAcrossMonitors
  }

  // Monitor Visibility Configuration (only shown in sync mode)
  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true
    visible: Settings.data.bar.syncAcrossMonitors

    NHeader {
      label: I18n.tr("settings.bar.monitors.section.label")
      description: I18n.tr("settings.bar.monitors.section.description")
    }

    Repeater {
      model: Quickshell.screens || []
      delegate: NCheckbox {
        Layout.fillWidth: true
        label: modelData.name || "Unknown"
        description: {
          const compositorScale = CompositorService.getDisplayScale(modelData.name)
          I18n.tr("system.monitor-description", {
                    "model": modelData.model,
                    "width": modelData.width * compositorScale,
                    "height": modelData.height * compositorScale,
                    "scale": compositorScale
                  })
        }
        checked: (Settings.data.bar.monitors || []).length === 0 || (Settings.data.bar.monitors || []).indexOf(modelData.name) !== -1
        onToggled: checked => {
                     if (checked) {
                       Settings.data.bar.monitors = addMonitor(Settings.data.bar.monitors, modelData.name)
                     } else {
                       Settings.data.bar.monitors = removeMonitor(Settings.data.bar.monitors, modelData.name)
                     }
                   }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // Monitor tabs - only visible when not syncing
  TabBar {
    id: monitorTabBar
    Layout.fillWidth: true
    visible: !Settings.data.bar.syncAcrossMonitors

    Repeater {
      model: Quickshell.screens
      TabButton {
        required property var modelData
        required property int index
        text: modelData.name
        onClicked: currentMonitorIndex = index
      }
    }
  }

  // Section header
  NHeader {
    label: Settings.data.bar.syncAcrossMonitors ? I18n.tr("settings.bar.appearance.section.label") : `Bar Configuration - ${currentMonitorName}`
    description: Settings.data.bar.syncAcrossMonitors ? I18n.tr("settings.bar.appearance.section.description") : `Configure bar settings for monitor ${currentMonitorName}`
  }

  // Monitor visibility toggle (only shown in per-monitor mode)
  NToggle {
    Layout.fillWidth: true
    visible: !Settings.data.bar.syncAcrossMonitors
    label: `Show bar on ${currentMonitorName}`
    description: `Enable or disable the bar on this monitor`
    checked: (Settings.data.bar.monitors || []).length === 0 || (Settings.data.bar.monitors || []).indexOf(currentMonitorName) !== -1
    onToggled: checked => {
                 if (checked) {
                   Settings.data.bar.monitors = addMonitor(Settings.data.bar.monitors, currentMonitorName)
                 } else {
                   Settings.data.bar.monitors = removeMonitor(Settings.data.bar.monitors, currentMonitorName)
                 }
               }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
    visible: !Settings.data.bar.syncAcrossMonitors
  }

  // Position
  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("settings.bar.appearance.position.label")
    description: I18n.tr("settings.bar.appearance.position.description")
    model: [{
        "key": "top",
        "name": I18n.tr("options.bar.position.top")
      }, {
        "key": "bottom",
        "name": I18n.tr("options.bar.position.bottom")
      }, {
        "key": "left",
        "name": I18n.tr("options.bar.position.left")
      }, {
        "key": "right",
        "name": I18n.tr("options.bar.position.right")
      }]
    currentKey: currentConfig.position || "top"
    onSelected: key => updateCurrentConfig("position", key)
  }

  // Density
  NComboBox {
    Layout.fillWidth: true
    label: I18n.tr("settings.bar.appearance.density.label")
    description: I18n.tr("settings.bar.appearance.density.description")
    model: [{
        "key": "mini",
        "name": I18n.tr("options.bar.density.mini")
      }, {
        "key": "compact",
        "name": I18n.tr("options.bar.density.compact")
      }, {
        "key": "default",
        "name": I18n.tr("options.bar.density.default")
      }, {
        "key": "comfortable",
        "name": I18n.tr("options.bar.density.comfortable")
      }]
    currentKey: currentConfig.density || "default"
    onSelected: key => updateCurrentConfig("density", key)
  }

  // Show Capsule
  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("settings.bar.appearance.show-capsule.label")
    description: I18n.tr("settings.bar.appearance.show-capsule.description")
    checked: currentConfig.showCapsule !== undefined ? currentConfig.showCapsule : true
    onToggled: checked => updateCurrentConfig("showCapsule", checked)
  }

  // Floating
  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("settings.bar.appearance.floating.label")
    description: I18n.tr("settings.bar.appearance.floating.description")
    checked: currentConfig.floating || false
    onToggled: checked => {
                 updateCurrentConfig("floating", checked)
                 if (checked) {
                   updateCurrentConfig("outerCorners", false)
                 } else {
                   updateCurrentConfig("outerCorners", true)
                 }
               }
  }

  // Outer Corners
  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("settings.bar.appearance.outer-corners.label")
    description: I18n.tr("settings.bar.appearance.outer-corners.description")
    checked: currentConfig.outerCorners !== undefined ? currentConfig.outerCorners : true
    visible: !currentConfig.floating
    onToggled: checked => updateCurrentConfig("outerCorners", checked)
  }

  // Floating bar margins
  ColumnLayout {
    visible: currentConfig.floating || false
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.bar.appearance.margins.label")
      description: I18n.tr("settings.bar.appearance.margins.description")
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginL

      ColumnLayout {
        spacing: Style.marginXXS

        NText {
          text: I18n.tr("settings.bar.appearance.margins.vertical")
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
        }

        NValueSlider {
          Layout.fillWidth: true
          from: 0
          to: 1
          stepSize: 0.01
          value: currentConfig.marginVertical !== undefined ? currentConfig.marginVertical : 0.25
          onMoved: value => updateCurrentConfig("marginVertical", value)
          text: Math.round((currentConfig.marginVertical !== undefined ? currentConfig.marginVertical : 0.25) * 100) + "%"
        }
      }

      ColumnLayout {
        spacing: Style.marginXXS

        NText {
          text: I18n.tr("settings.bar.appearance.margins.horizontal")
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
        }

        NValueSlider {
          Layout.fillWidth: true
          from: 0
          to: 1
          stepSize: 0.01
          value: currentConfig.marginHorizontal !== undefined ? currentConfig.marginHorizontal : 0.25
          onMoved: value => updateCurrentConfig("marginHorizontal", value)
          text: Math.round((currentConfig.marginHorizontal !== undefined ? currentConfig.marginHorizontal : 0.25) * 100) + "%"
        }
      }
    }
  }

  // Background Opacity
  ColumnLayout {
    spacing: Style.marginXXS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.bar.appearance.background-opacity.label")
      description: I18n.tr("settings.bar.appearance.background-opacity.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 1
      stepSize: 0.01
      value: currentConfig.backgroundOpacity !== undefined ? currentConfig.backgroundOpacity : 1.0
      onMoved: value => updateCurrentConfig("backgroundOpacity", value)
      text: Math.floor((currentConfig.backgroundOpacity !== undefined ? currentConfig.backgroundOpacity : 1.0) * 100) + "%"
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL
    Layout.bottomMargin: Style.marginXL
  }

  // Widgets Management Section
  ColumnLayout {
    spacing: Style.marginXXS
    Layout.fillWidth: true

    NHeader {
      label: I18n.tr("settings.bar.widgets.section.label")
      description: I18n.tr("settings.bar.widgets.section.description")
    }

    // Bar Sections
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.topMargin: Style.marginM
      spacing: Style.marginM

      // Left Section
      NSectionEditor {
        sectionName: "Left"
        sectionId: "left"
        settingsDialogComponent: Qt.resolvedUrl(Quickshell.shellDir + "/Modules/Settings/Bar/BarWidgetSettingsDialog.qml")
        widgetRegistry: BarWidgetRegistry
        widgetModel: currentConfig.widgets ? currentConfig.widgets.left || [] : []
        availableWidgets: availableWidgets
        onAddWidget: (widgetId, section) => _addWidgetToSection(widgetId, section)
        onRemoveWidget: (section, index) => _removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => _reorderWidgetInSection(section, fromIndex, toIndex)
        onUpdateWidgetSettings: (section, index, settings) => _updateWidgetSettingsInSection(section, index, settings)
        onMoveWidget: (fromSection, index, toSection) => _moveWidgetBetweenSections(fromSection, index, toSection)
        onDragPotentialStarted: root.handleDragStart()
        onDragPotentialEnded: root.handleDragEnd()
      }

      // Center Section
      NSectionEditor {
        sectionName: "Center"
        sectionId: "center"
        settingsDialogComponent: Qt.resolvedUrl(Quickshell.shellDir + "/Modules/Settings/Bar/BarWidgetSettingsDialog.qml")
        widgetRegistry: BarWidgetRegistry
        widgetModel: currentConfig.widgets ? currentConfig.widgets.center || [] : []
        availableWidgets: availableWidgets
        onAddWidget: (widgetId, section) => _addWidgetToSection(widgetId, section)
        onRemoveWidget: (section, index) => _removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => _reorderWidgetInSection(section, fromIndex, toIndex)
        onUpdateWidgetSettings: (section, index, settings) => _updateWidgetSettingsInSection(section, index, settings)
        onMoveWidget: (fromSection, index, toSection) => _moveWidgetBetweenSections(fromSection, index, toSection)
        onDragPotentialStarted: root.handleDragStart()
        onDragPotentialEnded: root.handleDragEnd()
      }

      // Right Section
      NSectionEditor {
        sectionName: "Right"
        sectionId: "right"
        settingsDialogComponent: Qt.resolvedUrl(Quickshell.shellDir + "/Modules/Settings/Bar/BarWidgetSettingsDialog.qml")
        widgetRegistry: BarWidgetRegistry
        widgetModel: currentConfig.widgets ? currentConfig.widgets.right || [] : []
        availableWidgets: availableWidgets
        onAddWidget: (widgetId, section) => _addWidgetToSection(widgetId, section)
        onRemoveWidget: (section, index) => _removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => _reorderWidgetInSection(section, fromIndex, toIndex)
        onUpdateWidgetSettings: (section, index, settings) => _updateWidgetSettingsInSection(section, index, settings)
        onMoveWidget: (fromSection, index, toSection) => _moveWidgetBetweenSections(fromSection, index, toSection)
        onDragPotentialStarted: root.handleDragStart()
        onDragPotentialEnded: root.handleDragEnd()
      }
    }
  }

  // Widget management functions - now monitor-aware
  function _addWidgetToSection(widgetId, section) {
    var config = JSON.parse(JSON.stringify(currentConfig))
    if (!config.widgets) {
      config.widgets = {
        "left": [],
        "center": [],
        "right": []
      }
    }
    if (!config.widgets[section]) {
      config.widgets[section] = []
    }

    var newWidget = {
      "id": widgetId
    }
    if (BarWidgetRegistry.widgetHasUserSettings(widgetId)) {
      var metadata = BarWidgetRegistry.widgetMetadata[widgetId]
      if (metadata) {
        Object.keys(metadata).forEach(function (key) {
          if (key !== "allowUserSettings") {
            newWidget[key] = metadata[key]
          }
        })
      }
    }
    config.widgets[section].push(newWidget)
    Settings.setMonitorBarConfig(currentMonitorName, config)
  }

  function _removeWidgetFromSection(section, index) {
    var config = JSON.parse(JSON.stringify(currentConfig))
    if (config.widgets && config.widgets[section] && index >= 0 && index < config.widgets[section].length) {
      var removedWidgets = config.widgets[section].splice(index, 1)
      Settings.setMonitorBarConfig(currentMonitorName, config)

      // Check that we still have a control center
      if (removedWidgets[0].id === "ControlCenter" && BarService.lookupWidget("ControlCenter") === undefined) {
        ToastService.showWarning(I18n.tr("toast.missing-control-center.label"), I18n.tr("toast.missing-control-center.description"), 12000)
      }
    }
  }

  function _reorderWidgetInSection(section, fromIndex, toIndex) {
    var config = JSON.parse(JSON.stringify(currentConfig))
    if (config.widgets && config.widgets[section] && fromIndex >= 0 && fromIndex < config.widgets[section].length && toIndex >= 0 && toIndex < config.widgets[section].length) {
      var item = config.widgets[section][fromIndex]
      config.widgets[section].splice(fromIndex, 1)
      config.widgets[section].splice(toIndex, 0, item)
      Settings.setMonitorBarConfig(currentMonitorName, config)
    }
  }

  function _updateWidgetSettingsInSection(section, index, settings) {
    var config = JSON.parse(JSON.stringify(currentConfig))
    if (config.widgets && config.widgets[section] && index >= 0 && index < config.widgets[section].length) {
      config.widgets[section][index] = settings
      Settings.setMonitorBarConfig(currentMonitorName, config)
    }
  }

  function _moveWidgetBetweenSections(fromSection, index, toSection) {
    var config = JSON.parse(JSON.stringify(currentConfig))
    if (config.widgets && config.widgets[fromSection] && index >= 0 && index < config.widgets[fromSection].length) {
      var widget = config.widgets[fromSection][index]
      config.widgets[fromSection].splice(index, 1)
      if (!config.widgets[toSection]) {
        config.widgets[toSection] = []
      }
      config.widgets[toSection].push(widget)
      Settings.setMonitorBarConfig(currentMonitorName, config)
    }
  }

  // Data model functions
  function getWidgetLocations(widgetId) {
    if (!BarService)
      return []
    const instances = BarService.getAllRegisteredWidgets()
    const locations = {}
    for (var i = 0; i < instances.length; i++) {
      if (instances[i].widgetId === widgetId) {
        const section = instances[i].section
        if (section === "left")
          locations["L"] = true
        else if (section === "center")
          locations["C"] = true
        else if (section === "right")
          locations["R"] = true
      }
    }
    return Object.keys(locations).join('')
  }

  function updateAvailableWidgetsModel() {
    availableWidgets.clear()
    const widgets = BarWidgetRegistry.getAvailableWidgets()
    widgets.forEach(entry => {
                      availableWidgets.append({
                                                "key": entry,
                                                "name": entry,
                                                "badgeLocations": getWidgetLocations(entry)
                                              })
                    })
  }

  // Base list model for all combo boxes
  ListModel {
    id: availableWidgets
  }

  Component.onCompleted: {
    updateAvailableWidgetsModel()
  }

  Connections {
    target: BarService
    function onActiveWidgetsChanged() {
      updateAvailableWidgetsModel()
    }
  }
}
