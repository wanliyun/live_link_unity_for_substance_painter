import QtQuick 2.5
import QtQml 2.2
import QtQml.Models 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import AlgWidgets 2.0
import AlgWidgets.Style 2.0

AlgDialog
{
  id: root;
  visible: false;
  title: "DH-Tone Live Link Unity configuration";
  width: 400;
  height: 280;
  minimumWidth: width;
  minimumHeight: height;
  maximumWidth: width;
  maximumHeight: height;

  signal configurationChanged(
    int exportTextureInterval,
    int syncShaderParamFromUnityInterval,
    string unityAssetsRootDirectory)

  onVisibleChanged: {
    if (visible) internal.initModel()
  }

  Component.onCompleted: {
    internal.initModel()
    internal.emit()
  }

  onAccepted: internal.emit()

  QtObject {
    id: internal

    readonly property string exportTextureIntervalKey:           "autoExportTextureInterval"
    readonly property int exportTextureIntervalDefault:          0
    readonly property int exportTextureIntervalMax:              120

    readonly property string syncShaderParamFromUnityIntervalKey:           "syncShaderParamFromUnityInterval"
    readonly property int syncShaderParamFromUnityIntervalDefault:          0
    readonly property int syncShaderParamFromUnityIntervalMax:              120

    readonly property string unityAssetsRootDirectoryKey:      "unityAssetsRootDirectory"
    readonly property string unityAssetsRootDirectoryDefault:  alg.documents_directory + "autosave/"

    property var settings: ({})

    function newModelComponent(label, min_value, max_value, default_value, settings_name) {
      return {
        "label": label,
        "min_value": min_value,
        "max_value": max_value,
        "default_value": default_value,
        "settings_name": settings_name
      }
    }

    function initModel() {
      reinitSettings()
      model.clear()
      model.append(
        newModelComponent(
          "Auto Export Texture interval in seconds:",
          0,
          syncShaderParamFromUnityIntervalMax,
          syncShaderParamFromUnityIntervalDefault,
          syncShaderParamFromUnityIntervalKey)
        )

      model.append(
        newModelComponent(
          "Autoupdate Sync Shader Params From Unity in seconds:",
          0,
          exportTextureIntervalMax,
          exportTextureIntervalDefault,
          exportTextureIntervalKey)
        )
    }
    function reinitSettings() {
      updateSettings(exportTextureIntervalKey, alg.settings.value(exportTextureIntervalKey, exportTextureIntervalDefault))
      updateSettings(syncShaderParamFromUnityIntervalKey, alg.settings.value(syncShaderParamFromUnityIntervalKey, syncShaderParamFromUnityIntervalDefault))
      updateSettings(unityAssetsRootDirectoryKey, alg.settings.value(unityAssetsRootDirectoryKey, unityAssetsRootDirectoryDefault))
    }

    function updateSettings(settings_name, value) {
      settings[settings_name] = value
      alg.settings.value(settings_name, value)
    }

    function emit() {
      alg.log.info("emit")
      alg.settings.setValue(exportTextureIntervalKey, settings[exportTextureIntervalKey])
      alg.settings.setValue(syncShaderParamFromUnityIntervalKey, settings[syncShaderParamFromUnityIntervalKey])
      alg.settings.setValue(unityAssetsRootDirectoryKey, settings[unityAssetsRootDirectoryKey])
      configurationChanged(
        settings[exportTextureIntervalKey],
        settings[syncShaderParamFromUnityIntervalKey],
        settings[unityAssetsRootDirectoryKey],
        )
    }
  }


 AlgScrollView {
    id: scrollView;
    parent: root.contentItem
    anchors.fill: parent
    anchors.margins: 16

    ColumnLayout {
      Layout.preferredWidth: scrollView.viewportWidth
      spacing: AlgStyle.defaultSpacing

      Layout.fillWidth: true
      AlgLabel {
        text: "Specify Unity Asset Root Directory"
      }
      RowLayout {
        Layout.fillWidth: true
        AlgTextEdit {
          id: saveDirectoryLabel
          text: elideDelegate.elidedText
          selectByKeyboard: false
          selectByMouse: false
          property string fullPath: alg.settings.value(internal.unityAssetsRootDirectory, internal.unityAssetsRootDirectoryDefault)
          readOnly: true
          enabled: true
          Layout.fillWidth: true
          onFullPathChanged: {
            internal.updateSettings(internal.unityAssetsRootDirectory, fullPath)
            fileDialog.folder = fullPath
          }
          TextMetrics {
            id: elideDelegate
            elide: Qt.ElideMiddle
            text: saveDirectoryLabel.fullPath
            elideWidth: saveDirectoryLabel.width - saveDirectoryLabel.anchors.leftMargin - saveDirectoryLabel.anchors.rightMargin
            font: saveDirectoryLabel.font
          }
        }
        AlgButton {
          text: "Select directory"
          enabled: true
          onClicked: {
            fileDialog.open()
          }
        }
      }
      Repeater {
        id: layoutInstantiator
        model: ListModel {
          id: model
        }
        delegate: AlgSlider {
          id: slider
          text: label
          minValue: min_value
          maxValue: max_value
          value: alg.settings.value(settings_name, default_value)
          // integers only
          stepSize: 1
          precision: 0
          Layout.fillWidth: true
          onRoundValueChanged: internal.updateSettings(settings_name, roundValue)
        }
      }
    }
  }

  FileDialog {
    id: fileDialog
    title: "Please choose Unity Assets Root directory"
    folder: internal.unityAssetsRootDirectoryDefault
    selectFolder: true
    selectMultiple: false
    selectExisting: true
    onAccepted: {
      saveDirectoryLabel.fullPath = alg.fileIO.urlToLocalFile(fileUrl) + "/"
    }
  }
}
