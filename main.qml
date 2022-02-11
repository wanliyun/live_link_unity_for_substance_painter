
import QtQuick 2.7
import Painter 1.0

PainterPlugin
{
  QtObject {
    id: internal
    property string unityPorjectDirectory : ""
    property string spexpFilePath : ""
    property int intervalTime_exportTexture : 0
    property int remainingTime_exportTexture : -1

    property int intervalTime_syncShaderParamFromUnity : 0
    property int remainingTime_syncShaderParamFromUnity : -1

    property bool projectOpen: alg.project.isOpen()

    onProjectOpenChanged: {
      resetTimerState()
    }

    function reinitRemainingTime_exportTexture(){
      remainingTime_exportTexture = intervalTime_exportTexture > 0 ? intervalTime_exportTexture : -1
    }

    function reinitRemainingTime_syncShaderParamFromUnity(){
      remainingTime_syncShaderParamFromUnity = intervalTime_syncShaderParamFromUnity > 0 ? intervalTime_syncShaderParamFromUnity : -1
    }

    function resetTimerState()
    {
      if (!projectOpen || (intervalTime_exportTexture <= 0 && intervalTime_syncShaderParamFromUnity <= 0))
        timer.stop()
      else
      {
        reinitRemainingTime_exportTexture()
        reinitRemainingTime_syncShaderParamFromUnity()
        timer.restart()
      }        
    }
 
    function exportTexture() {
      var projectName = alg.project.name()
      var exportPath = internal.unityPorjectDirectory + "Assets/Res/character/"  + projectName + "/materials/" 
      alg.log.info("exportTexture:"+ exportPath)
      var info = alg.mapexport.exportDocumentMaps(
       internal.spexpFilePath,
       exportPath,
       "tga"
      )
      alg.log.info(info)
    }

    function syncShaderParamFromUnity(){
      alg.log.info("syncShaderParamFromUnity");
    }
  }

  Timer{
    id: timer
    repeat: true
    interval: 100
    onTriggered: {
      if(internal.projectOpen){
        if (internal.remainingTime_exportTexture > 0) {
          --internal.remainingTime_exportTexture;
          if (internal.remainingTime_exportTexture == 0) {
            internal.exportTexture()
            internal.reinitRemainingTime_exportTexture()
          }
        }
        if (internal.remainingTime_syncShaderParamFromUnity > 0) {
          --internal.remainingTime_syncShaderParamFromUnity;
          if (internal.remainingTime_syncShaderParamFromUnity == 0) {
            internal.syncShaderParamFromUnity()
            internal.reinitRemainingTime_syncShaderParamFromUnity()
          }
        }
      }
    }
  }

  onConfigure:
  {
    configDialog.open();
  }
  ConfigurePanel
  {
    id: configDialog
    onConfigurationChanged: {
      internal.intervalTime_exportTexture = exportTextureInterval
      internal.intervalTime_syncShaderParamFromUnity = syncShaderParamFromUnityInterval
      internal.unityPorjectDirectory = unityPorjectDirectory
      if(!alg.fileIO.isDir(internal.unityPorjectDirectory))
      {
        internal.intervalTime_exportTexture = 0
        internal.intervalTime_syncShaderParamFromUnity = 0
      }
      internal.spexpFilePath = unityPorjectDirectory + "tools/substance_painter/DH-Toon.spexp"
      alg.log.info("intervalTime_exportTexture=" + internal.intervalTime_exportTexture)
      alg.log.info("intervalTime_syncShaderParamFromUnity=" + internal.intervalTime_syncShaderParamFromUnity)
      alg.log.info("unityPorjectDirectory=" + internal.unityPorjectDirectory)
      internal.resetTimerState()
    }
  }
}
