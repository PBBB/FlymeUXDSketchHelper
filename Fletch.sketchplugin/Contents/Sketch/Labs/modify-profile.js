// documentation: https://developer.sketchapp.com/reference/api/

function onRun() {
  let sketch = require('sketch')
  const Document = sketch.Document
  const document = Document.getSelectedDocument()
  const UI = sketch.UI
  const Settings = sketch.Settings
  let regPhone = /[0-9]{3}.[0-9]{3}/
  let regEmail = /[@]/
  let regDate = /^[最后更新]/
  let nameTextField
  let phoneTextField
  let emailTextField
  
  function createWindow(){
    let alert = COSAlertWindow.new()
    // 自定义 icon（暂时还不需要）
    // alert.setIcon(NSImage.alloc().initByReferencingFile(context.plugin.urlForResourceNamed("icon.png").path()))

    //配置标题
    alert.setMessageText("修改设计师信息")

    // 创建按钮
    alert.addButtonWithTitle("确认修改")
    alert.addButtonWithTitle("取消")

    // 创建 VIEW
    let viewWidth = 400
    let viewHeight = 160
    let view = NSView.alloc().initWithFrame(NSMakeRect(0, 0, viewWidth, viewHeight))
    alert.addAccessoryView(view)

    // 创建文本标签
    let infoLabel = NSTextField.alloc().initWithFrame(NSMakeRect(0, viewHeight - 33, (viewWidth - 100), 35))
    let nameLabel = NSTextField.alloc().initWithFrame(NSMakeRect(-1, viewHeight - 65, (viewWidth / 2) - 10, 20))
    let phoneLabel = NSTextField.alloc().initWithFrame(NSMakeRect(140, viewHeight - 65, (viewWidth / 2) - 10, 20))
    let emailLabel = NSTextField.alloc().initWithFrame(NSMakeRect(-1, viewHeight - 115, (viewWidth / 2) - 10, 20))
    
    // 配置文本标签
    infoLabel.setStringValue("以下信息将会自动填写到封面。我们尽量不卖你的隐私。看到这句话表明你已同意我们的服务协议。")
    infoLabel.setSelectable(false)
    infoLabel.setEditable(false)
    infoLabel.setBezeled(false)
    infoLabel.setDrawsBackground(false)
    nameLabel.setStringValue("你的名字：")
    nameLabel.setSelectable(false)
    nameLabel.setEditable(false)
    nameLabel.setBezeled(false)
    nameLabel.setDrawsBackground(false)

    phoneLabel.setStringValue("你的手机号：")
    phoneLabel.setSelectable(false)
    phoneLabel.setEditable(false)
    phoneLabel.setBezeled(false)
    phoneLabel.setDrawsBackground(false)

    emailLabel.setStringValue("你的邮箱：")
    emailLabel.setSelectable(false)
    emailLabel.setEditable(false)
    emailLabel.setBezeled(false)
    emailLabel.setDrawsBackground(false)

  // 绘制文本标签
    view.addSubview(infoLabel)
    view.addSubview(nameLabel)
    view.addSubview(phoneLabel)
    view.addSubview(emailLabel)

    // 创建文本框
    nameTextField = NSTextField.alloc().initWithFrame(NSMakeRect(0, viewHeight - 85, 130, 22))
    phoneTextField = NSTextField.alloc().initWithFrame(NSMakeRect(140, viewHeight - 85, 130, 22))
    emailTextField = NSTextField.alloc().initWithFrame(NSMakeRect(0, viewHeight - 135, 270, 22))

    // 绘制文本框
    view.addSubview(nameTextField)
    view.addSubview(phoneTextField)
    view.addSubview(emailTextField)

    // 允许 TAB 键切换输入框
    nameTextField.setNextKeyView(phoneTextField)
    phoneTextField.setNextKeyView(emailTextField)

    // 文本框默认值
    nameTextField.setStringValue(Settings.settingForKey('name')?Settings.settingForKey('name'):'')
    phoneTextField.setStringValue(Settings.settingForKey('phone')?Settings.settingForKey('phone'):'')
    emailTextField.setStringValue(Settings.settingForKey('email')?Settings.settingForKey('email'):'')

    // 展示弹窗
    return alert
  }

  function getInputFromUser(){
    // 展示弹窗
    let alert = createWindow()
    let response = alert.runModal()
    // 将输入内容存入数组
    let textFieldArr = []
    if(response == '1000'){
      textFieldArr.push(nameTextField.stringValue())
      textFieldArr.push(phoneTextField.stringValue())
      textFieldArr.push(emailTextField.stringValue())
      return textFieldArr
    }else{
      return false
    }
  }

  let inputArr = getInputFromUser()
  
  if(inputArr){
    Settings.setSettingForKey('name', inputArr[0])
    Settings.setSettingForKey('email', inputArr[2])
    Settings.setSettingForKey('phone', inputArr[1])
  }else{
    UI.message('设计师信息未修改')
    return
  }
  if(inputArr[0] == ''){
    UI.alert('稍等，我看看你填的什么东西','为什么不写名字呢？如果考试的时候忘记写名字可能会零分的我跟你港。')
    onRun()
    return
  }
  if(!regEmail.test(inputArr[2])){
    UI.alert('稍等，我看看你填的什么东西','邮箱地址好像不太对，你再检查检查。')
    onRun()
    return
  }
  if(!regPhone.test(inputArr[1])){
    UI.alert('稍等，我看看你填的什么东西','手机号好像不太对，你再检查检查。')
    onRun()
    return
  }
  // 使用数组保存设计师的信息
  let designerProfileArr = [(inputArr[0]!=''|'null' ? inputArr[0] : 'Designer'), (inputArr[2]!=''|'null' ? inputArr[2] : 'designer@meizu.com'), (inputArr[1]!=''|'null' ? inputArr[1] : '138 0013 8000')]
  // 找到设计师相关信息的图层组
  let currentPage = document.selectedPage
  let layersInCurrentPage = currentPage.layers
  let profileGroup
  let coverArtboard
  for(let i = 0; i < layersInCurrentPage.length; i++){
    if(layersInCurrentPage[i].name == '封面' && layersInCurrentPage[i].type == 'Artboard'){
      coverArtboard = layersInCurrentPage[i]
      break
    }
  }
  if(coverArtboard){
    for(let i = 0; i < coverArtboard.layers.length; i++){
      if(coverArtboard.layers[i].name == '设计师相关信息' && coverArtboard.layers[i].type == 'Group'){
        profileGroup = coverArtboard.layers[i]
        break
      }
    }
  }
  // 新建数组，用以放置文本图层
  let textArr = []
  // 新建数组，用以放置非文本图层
  let lineArr = []

  let textLayerOrder = 0;
  for (let infoLayer of profileGroup.layers) {
    // 排除非文本图层，只处理文本图层
    if(infoLayer.type == 'Text'){
      // 左对齐&&非固定宽度
      infoLayer.alignment = 'left'
      infoLayer.fixedWidth = false
      if (regDate.test(infoLayer.text)){
        // 找到日期图层，并加到 textArr 数组中以便后续排版
        textArr[3] = infoLayer
      }else{
        // 按顺序填入 designerProfileArr 数组中的信息，可避免查找特定图层
        infoLayer.text = designerProfileArr[textLayerOrder]
        textArr[textLayerOrder] = infoLayer
        textLayerOrder = textLayerOrder + 1
      }
    }else{
      // 非文本图层加到 lineArr 数组中
      lineArr.push(infoLayer)
    }
  }

  let startPointX = 0
  let margin = 90
  // 文本图层等间距排版
  for (let i = 0; i < textArr.length; i++) {
    textArr[i].frame.x = startPointX
    startPointX = textArr[i].frame.width + startPointX + margin
  }
  // 非文本图层等间距排版
  for (let i = 0; i < lineArr.length; i++) {
    lineArr[i].frame.x = textArr[i].frame.x + textArr[i].frame.width + margin/2
  }

  let logoLayer = document.getLayersNamed('logo')
  // 自动调整一下图层组的尺寸
  profileGroup.adjustToFit()
  // logo 图层的位置
  logoLayer[0].frame.x = (3024 - (logoLayer[0].frame.width + 70 + profileGroup.frame.width))/2
  // 整个图层组的位置
  profileGroup.frame.x = logoLayer[0].frame.x + logoLayer[0].frame.width + 70
  UI.message('设计师信息已填入封面（天呐这个功能太好用了吧）')
}