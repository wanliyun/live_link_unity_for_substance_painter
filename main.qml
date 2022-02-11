
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
      //resetTimerState()
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
      //alg.log.info(info)
    }
    
    function parseUnityMatFile(unityMatFile){
      function getColorVal(str){return Number(str.split(":")[1])}
      var out = {m_ShaderKeywords :{}, m_Floats: {}, m_Colors: {}}
      alg.log.info("parseUnityMatFile:"+ unityMatFile)
      try{
        var file = alg.fileIO.open(unityMatFile, "r")
        var step = 0
        while(true)
        {
          var line = file.readLine()
          if(line == "") break
          line = line.replace("\n", "").replace("\r", "")
          switch(step)
          {
            case 0:{
                if(line.indexOf("m_ShaderKeywords") > 0)
                {
                  line.split(":")[1].trim().split(" ").forEach(function(keyword){ out.m_ShaderKeywords[keyword] = 1 })
                  step = 1 
                }
              }break;
            case 1:{
                if(line == "    m_Floats:")
                  step = 2
              }
              break;
            case 2:{
                if(line.indexOf("-") == 4)
                {
                  var kv = line.substring(6).split(":")
                  var k = kv[0].trim()
                  var v = Number(kv[1])
                  out.m_Floats[k] = v
                  break
                }
                step = 3
              }
            case 3:{
                if(line == "    m_Colors:")
                  step = 4
              }
              break;
            case 4:{
                if(line.indexOf("-") == 4)
                {
                  var kv = line.substring(6).trim().split(": {")
                  var k = kv[0].trim()
                  var colors = kv[1].replace("}", "").split(",")
                  out.m_Colors[k] = [getColorVal(colors[0]),getColorVal(colors[1]),getColorVal(colors[2]),getColorVal(colors[3]) ]
                  break
                }
                step = 5
              }
              break;
            default:
              break;
          }
        }
        file.close()
      }catch(e)
      {
        alg.log.error("error:" + e)
        return null
      }
      return out
    }

    function syncOneShader(shader, unityMatPathPrefix){
      var unityMatPath = unityMatPathPrefix + "_" + shader.label + ".mat"
      var unityParams = parseUnityMatFile(unityMatPath)
      if(unityParams == null){
        alg.log.error("Failed to parse Unity mat file")
        return;
      }
      //alg.log.info(unityParams)
      var shaderId = shader.id
      var params = alg.shaders.parameters(shaderId)
      //alg.log.info(params)

      var countKeyword = 0
      var countBool = 0
      var countFloat = 0
      var countFloat4 = 0
      for(var paramName in params){
        var shaderParamObj = params[paramName]
        var desc = shaderParamObj.description
        var dataType = desc.dataType
        var unityName = desc.label
        if(desc.group == "ShaderKeywords"){
          var st = unityParams.m_ShaderKeywords
          shaderParamObj.value = st.hasOwnProperty(unityName)
          ++countKeyword
          //alg.log.info("set KeyWords: " + unityName + "=" +  shaderParamObj.value)
        }
        else{
          if(dataType == "Bool"){
            var st = unityParams.m_Floats
            if(st.hasOwnProperty(unityName)){
              shaderParamObj.value = st[unityName] != 0
              ++countBool
              //alg.log.info("set Bool:" + unityName + "=" +  shaderParamObj.value)
            }
          }else if(dataType == "Float"){
            var st = unityParams.m_Floats
            if(st.hasOwnProperty(unityName)){
              shaderParamObj.value = st[unityName]
              ++countFloat
              //alg.log.info("set Float:" + unityName + "=" +  shaderParamObj.value)
            }
          }else if(dataType == "Float4"){
            var st = unityParams.m_Colors
            if(st.hasOwnProperty(unityName)){
              shaderParamObj.value = st[unityName]
              ++countFloat4
              //alg.log.info("set Float:" + unityName + "=" +  shaderParamObj.value)
            }
          }
        }
      }
      alg.log.info("Sync Param of " + shader.label + " from:" + unityMatPath)
      alg.log.info("countKeyword=" + countKeyword + " countBool=" + countBool + " countFloat" + countFloat + " countFloat4" + countFloat4)
    }
    function syncShaderParamFromUnity(){
      alg.log.info("syncShaderParamFromUnity")
      var projectName = alg.project.name()
      var exportPath = internal.unityPorjectDirectory + "Assets/Res/character/"  + projectName + "/materials/"

      alg.shaders.instances().forEach(function(shader) {
        if(shader.shader == "DH-Toon"){
        //if(shader.label == "face"){
           //alg.log.info(shader.label + ": " + shader.id + ":" + shader.shader + ":" + shader.url);
           syncOneShader(shader, exportPath + projectName)
        }
      });
    }
  }

  Timer{
    id: timer
    repeat: true
    interval: 100
    onTriggered: {
      return
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
      internal.resetTimerState()

      internal.syncShaderParamFromUnity()
    }
  }
}
