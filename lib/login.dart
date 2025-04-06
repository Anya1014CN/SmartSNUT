import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smartsnut/main.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:url_launcher/url_launcher.dart';

//用于存储要打开的URL
Uri url = Uri.parse("uri");

class LoginPage extends StatefulWidget{
  const LoginPage ({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage>{
  
  //创建 TextEditingController
  final textUsernameController = TextEditingController();
  final textPasswordController = TextEditingController();
  final textCaptchaController = TextEditingController();

  //读取设置并保存在变量中
  readSettings() async {
    String settingstpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/settings.json';
    File settingstfile = File(settingstpath);
    if(await settingstfile.exists()){
      GlobalVars.settingsTotal = jsonDecode(await settingstfile.readAsString());
      setState(() {
        GlobalVars.fontsizeint = GlobalVars.settingsTotal[0]['fontSize']?? 3;
        GlobalVars.darkModeint = GlobalVars.settingsTotal[0]['DarkMode']?? 0;
        GlobalVars.themeColor = GlobalVars.settingsTotal[0]['ThemeColor']?? 1;
        GlobalVars.showSatCourse = GlobalVars.settingsTotal[0]['showSatCourse']?? true;
        GlobalVars.showSunCourse = GlobalVars.settingsTotal[0]['showSunCourse']?? true;
        GlobalVars.courseBlockColorsInt = GlobalVars.settingsTotal[0]['courseBlockColorsint']?? 0;
      });
    }else{
      setState(() {
        GlobalVars.fontsizeint = 3;
        GlobalVars.darkModeint = 0;
        GlobalVars.themeColor = 1;
        GlobalVars.showSatCourse = true;
        GlobalVars.showSunCourse = true;
        GlobalVars.courseBlockColorsInt = 0;
      });
    }
    setfontsize();
  }

  //设置字体大小
  setfontsize() {
    double changevalue = 0;
    if(GlobalVars.fontsizeint == 0)changevalue = -6;
    if(GlobalVars.fontsizeint == 1)changevalue = -4;
    if(GlobalVars.fontsizeint == 2)changevalue = -2;
    if(GlobalVars.fontsizeint == 3)changevalue = 0;
    if(GlobalVars.fontsizeint == 4)changevalue = 2;
    if(GlobalVars.fontsizeint == 5)changevalue = 4;
    if(GlobalVars.fontsizeint == 6)changevalue = 6;

    //弹出对话框字体
    GlobalVars.alertdialogTitle = DefaultfontSize.alertdialogTitle + changevalue;
    GlobalVars.alertdialogContent = DefaultfontSize.alertdialogContent + changevalue;

    //通用页面字体
    GlobalVars.splashPageTitle = DefaultfontSize.splashPageTitle + changevalue;
    GlobalVars.bottonbarAppnameTitle = DefaultfontSize.bottonbarAppnameTitle + changevalue;
    GlobalVars.bottonbarSelectedTitle = DefaultfontSize.bottonbarSelectedTitle + changevalue;
    GlobalVars.bottonbarUnselectedTitle = DefaultfontSize.bottonbarUnselectedTitle + changevalue;
    GlobalVars.genericPageTitle = DefaultfontSize.genericPageTitle + changevalue;
    GlobalVars.genericPageTitleSmall = DefaultfontSize.genericPageTitleSmall + changevalue;
    GlobalVars.genericGreetingTitle = DefaultfontSize.genericGreetingTitle + changevalue;
    GlobalVars.genericFloationActionButtonTitle = DefaultfontSize.genericFloationActionButtonTitle + changevalue;
    GlobalVars.dividerTitle = DefaultfontSize.dividerTitle + changevalue;
    GlobalVars.listTileTitle = DefaultfontSize.listTileTitle + changevalue;
    GlobalVars.listTileSubtitle = DefaultfontSize.listTileSubtitle + changevalue;
    GlobalVars.genericFunctionsButtonTitle = DefaultfontSize.genericFunctionsButtonTitle + changevalue;
    GlobalVars.genericSwitchContainerTitle = DefaultfontSize.genericSwitchContainerTitle + changevalue;
    GlobalVars.genericSwitchMenuTitle = DefaultfontSize.genericSwitchMenuTitle + changevalue;
    GlobalVars.genericTextSmall = DefaultfontSize.genericTextSmall + changevalue;
    GlobalVars.genericTextMedium = DefaultfontSize.genericTextMedium + changevalue;
    GlobalVars.genericTextLarge = DefaultfontSize.genericTextLarge + changevalue;

    if(mounted){
      setState(() {});
    }
  }

  @override
  void initState() {
    readSettings();
    super.initState();
  }

  Widget _buildCardContent() {
    return Column(
      children: [
        Text('请使用陕西理工大学统一身份认证平台的账号登录',style: TextStyle(fontSize: GlobalVars.genericTextSmall),),
        SizedBox(height: 10),
        Divider(height: 15,indent: 20,endIndent: 20,),
        SizedBox(height: 10),
        TextField(
          controller: textUsernameController,
          decoration: InputDecoration(
            labelText: '用户名',
            hintText: '请在此输入您的学号/工号',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: textPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '密码',
            hintText: '请在此输入您的统一身份认证平台的密码',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
          child: Column(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50), // 确保按钮宽度填满父容器
                ),
                onPressed: () {
                  if (textUsernameController.text == '' ) {
                    showDialog(
                      context: context, 
                      builder: (BuildContext context)=>AlertDialog(
                        title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                        content: Text('用户名不能为空，请输入您的学号/工号',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                        actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
                      ));
                    return;
                  }if (textPasswordController.text == '') {
                    showDialog(
                      context: context, 
                      builder: (BuildContext context)=>AlertDialog(
                        title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                        content: Text('密码不能为空，请输入您的密码',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                        actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
                      ));
                    return;
                  }else{
                    loginAuth();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '登录智慧陕理工',
                      style: TextStyle(
                        fontSize: GlobalVars.genericTextMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Divider(height: 15,indent: 20,endIndent: 20,),
        SizedBox(height: 10),
        Text('如忘记密码，请点击下方按钮进行找回',style: TextStyle(fontSize: GlobalVars.genericTextSmall),),
        Container(
          padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
          child: Column(
            children: [
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50), // 确保按钮宽度填满父容器
                ),
                onPressed: () {
                  url = Uri.parse('https://authserver.snut.edu.cn/retrieve-password/retrievePassword/index.html');
                  launchURL();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '忘记密码？',
                      style: TextStyle(
                        fontSize: GlobalVars.genericTextMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
            child: Row(
              children: [
                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/hand.png'):AssetImage('assets/icons/darktheme/hand.png'),height: 40,),
                SizedBox(width: 10,),
                Text('欢迎',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('登录智慧陕理工',style: TextStyle(fontSize: GlobalVars.genericTextMedium,color: Theme.of(context).colorScheme.primary),),
                Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
              ],
            ),
          ),
          Container(
            padding:EdgeInsets.fromLTRB(15, 20, 15, 10),
            child: ScreenTypeLayout.builder(
              mobile: (BuildContext context) => Card(
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                color: Theme.of(context).colorScheme.surfaceDim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width / 30, 0, MediaQuery.of(context).size.width / 30, 10), // 手机端边距
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: _buildCardContent(),
                ),
              ),
              desktop: (BuildContext context) => Card(
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                color: Theme.of(context).colorScheme.surfaceDim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width / 5, 10, MediaQuery.of(context).size.width / 5, 10), // 手机端边距
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: _buildCardContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //读取用户信息并保存在变量中
  readStdAccount() async {
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    GlobalVars.stdAccount = jsonDecode(await stdAccountfile.readAsString());
    if(mounted){
      setState(() {
        GlobalVars.realName = GlobalVars.stdAccount[0]['UserRealName'];
        GlobalVars.userName = GlobalVars.stdAccount[0]['UserName'];
        GlobalVars.passWord = GlobalVars.stdAccount[0]['PassWord'];
      });
    }
    String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailfile = File(stdDetailpath);
    String stdDetailString = await stdDetailfile.readAsString();
    Map<String, dynamic> jsonData = json.decode(stdDetailString);
    GlobalVars.stdDetail = jsonData.map((key, value) => MapEntry(key, value.toString()));
    if(mounted){
      setState(() {
        GlobalVars.enrollTime = GlobalVars.stdDetail['入校时间：']!;
        GlobalVars.graduationTime = GlobalVars.stdDetail['毕业时间：']!;
      });
    }
    emBindCheck();
  }

  //判断用户是否绑定电表账号
  emBindCheck() async {
    String openidtxtpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidtxtfile = File(openidtxtpath);
    if(await openidtxtfile.exists() == true){
      if(mounted){
        setState(() {
          GlobalVars.emBinded = true;
        });
      }else{
        setState(() {
          GlobalVars.emBinded = false;
        });
      }
    }
    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    if(await emUserDatafile.exists() == true){
      List emUserData = jsonDecode(await emUserDatafile.readAsString());
      if(emUserData[0]['openId'] != ''){
        if(mounted){
          setState(() {
            GlobalVars.emBinded = true;
          });
        }
      }else{
        setState(() {
          GlobalVars.emBinded = false;
        });
      }
    }
  }

  //打开链接
  void launchURL() async{
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if(context.mounted){
                Navigator.pop(context, 'OK');
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  //清空数据文件夹（登录未完全成功时调用，防止残缺数据影响下次登录）
  void clearTempLogindata() async {
    //清空并重新创建数据目录
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == true){
      await smartSNUTdirectory.delete(recursive: true);
      await smartSNUTdirectory.create();
    }
  }

  //从 authserver 登录
  loginAuth() async {
    bool loginAuthCanceled = false;
    String loginStateString = '请稍后...';
    if(mounted){
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('正在登录...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10,),
                  CircularProgressIndicator(),
                  SizedBox(height: 10,),
                  Text(loginStateString,style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    loginAuthCanceled = true;
                    clearTempLogindata();
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          );
        },
      );
    }

    //数据目录
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == false){
      await smartSNUTdirectory.create();
    }

    //存储用户名、密码
    String userName = textUsernameController.text;
    String passWord = textPasswordController.text;
    String realName = '';

    String encryptedpassword = '';//加密后的密码
    String authexecution = '';//存储获取到的 execution
    String pwdEncryptSalt = '';//存储获取到的 pwdEncryptSalt

    //初始化 Dio
    CookieJar authservercookie = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(authservercookie));

    //第一次请求，提取 execution
    if(loginAuthCanceled) return;
    if(mounted){
      setState(() {
        loginStateString = '正在获取登录信息...';
      });
    }
    late Response authresponse1;
    try{
      authresponse1 = await dio.get('https://authserver.snut.edu.cn/authserver/login?service=http%3A%2F%2Fjwgl.snut.edu.cn%2Feams%2FssoLogin.action');
    }catch (e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
      }
      return;
    }   
    // 提取 execution 值// 定义正则表达式查找带有 "execution" 名称的隐藏输入字段
    final RegExp executionRegExp = RegExp(
      r'<input\s+type="hidden"\s+id="execution"\s+name="execution"\s+value="([^"]+)"',
      caseSensitive: false,
    );
    // 在响应中查找匹配
    final Match? match = executionRegExp.firstMatch(authresponse1.data.toString());
    // 如果找到匹配项，则返回提取的值
    if (match != null && match.groupCount >= 1) {
      authexecution = match.group(1)!;
    }

    // 提取 pwdEncryptSalt 值
    final RegExp pwdEncryptSaltRegExp = RegExp(
      r'<input\s+type="hidden"\s+id="pwdEncryptSalt"\s+value="([^"]+)"',
      caseSensitive: false,
    );
    // 在响应中查找匹配
    final Match? saltMatch = pwdEncryptSaltRegExp.firstMatch(authresponse1.data.toString());
    // 如果找到匹配项，则提取值
    if (saltMatch != null && saltMatch.groupCount >= 1) {
      pwdEncryptSalt = saltMatch.group(1)!;
    }

    //AES 加密密码// 使用提取到的 pwdEncryptSalt 作为密钥
    encryptedpassword = encryptAES(passWord,pwdEncryptSalt);

    //请求验证码
    if(mounted){
      setState(() {
        loginStateString = '正在获取验证码...';
      });
    }
    
    String captchaCode = '';
    Uint8List? captchaBytes;
    bool isLoadingCaptcha = false;

    getAuthCaptcha() async {
      if(mounted){
        setState(() {
          isLoadingCaptcha = true;
        });
      }
      textCaptchaController.clear();
      // 请求验证码图片
      if(loginAuthCanceled) return;
      Response captchaResponse = await dio.get(
        'https://authserver.snut.edu.cn/authserver/getCaptcha.htl',
        options: Options(
          responseType: ResponseType.bytes, // 指定响应类型为字节数组
        ),
      );
      
      // 确保响应数据是 Uint8List 类型
      if (captchaResponse.data is Uint8List) {
        captchaBytes = captchaResponse.data;
      } else {
        // 如果不是，尝试转换
        captchaBytes = Uint8List.fromList(captchaResponse.data as List<int>);
      }
      if(mounted){
        setState(() {
          isLoadingCaptcha = false;
        });
      }
    }

    await getAuthCaptcha();
    if(mounted) {
      Navigator.pop(context);
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('请输入验证码',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCaptchaController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '验证码',
                          hintText: '请输入验证码',
                          filled: false
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    isLoadingCaptcha? 
                    FittedBox(
                      child: CircularProgressIndicator(),
                    )
                    :Expanded(
                      child: FittedBox(
                        child: Image.memory(captchaBytes!),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10,),
                Divider(height: 15,indent: 20,endIndent: 20,),
                Text('验证码不区分大小写',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                Divider(height: 15,indent: 20,endIndent: 20,),
                SizedBox(height: 10,),
                Column(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 50), // 确保按钮宽度填满父容器
                    ),
                    onPressed: isLoadingCaptcha? null:() {
                      getAuthCaptcha();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '刷新验证码',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  loginAuthCanceled = true;
                  Navigator.pop(context);
                  return;
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if(textCaptchaController.text.isEmpty){
                    showDialog<String>(
                      context: context, 
                      builder: (BuildContext context)=>AlertDialog(
                        title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                        content: Text('验证码不能为空，请输入验证码',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                        actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
                      ));
                    return;
                  }
                  captchaCode = textCaptchaController.text;
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          ),
          );
        },
      );
    }

    if(loginAuthCanceled) return;
    if(mounted){
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('正在登录...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10,),
                  CircularProgressIndicator(),
                  SizedBox(height: 10,),
                  Text(loginStateString,style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    loginAuthCanceled = true;
                    clearTempLogindata();
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          );
        },
      );
    }

    //开始登录
    if(mounted){
      setState(() {
        loginStateString = '正在登录...';
      });
    }
    late Response authresponse2;
    final loginParams = {
      "username": userName,
      "password": encryptedpassword,
      "captcha": captchaCode,
      "_eventId": "submit",
      "cllt": "userNameLogin",
      "dllt": "generalLogin",
      "lt": "",
      "execution": authexecution,
    };
    try{
      if(loginAuthCanceled) return;
      authresponse2 = await  dio.post(
        'https://authserver.snut.edu.cn/authserver/login?service=http%3A%2F%2Fjwgl.snut.edu.cn%2Feams%2FssoLogin.action',
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 401;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
    }catch(e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
      }
      return;
    }
    if(authresponse2.data.toString().contains('您提供的用户名或者密码有误')){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('用户名或密码错误',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
        return;
      }
    }
    if(authresponse2.data.toString().contains('图形动态码错误')){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('验证码错误',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
        return;
      }
    }

    //手动跟随重定向
    try{
      //跟随第一步重定向 (ssologin 的 ticket)
      if(loginAuthCanceled) return;
      var authresponse21 = await dio.get(
        authresponse2.headers['location']![0],
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 302;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
      //跟随第二步重定向 (ssologin 的 ticket)
      if(loginAuthCanceled) return;
      var authresponse22 = await dio.get(
        authresponse21.headers['location']![0],
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 307;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
      //跟随第三步重定向 (ssologin 的 jsessionid)
      if(loginAuthCanceled) return;
      await dio.get(
        'http://jwgl.snut.edu.cn${authresponse22.headers['location']![0]}',
        data: loginParams,
        options: Options(
          followRedirects: false,
          contentType: Headers.formUrlEncodedContentType,
        )
      );
    }catch(e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
      }
      return;
    }

    //延迟 350 毫秒
    await Future.delayed(Duration(milliseconds: 350));

    //获取个人信息
    if(mounted){
      setState(() {
        loginStateString = '正在获取个人信息...';
      });
    }
    List<Map<String, String>> stdAccount = [];
    
    Directory datadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver');
    if(await datadirectory.exists() == false){
      await datadirectory.create();
    }

    //真实姓名
    late Response myactionresponse;
    try{
      if(loginAuthCanceled) return;
      myactionresponse = await dio.get('http://jwgl.snut.edu.cn/eams/security/my.action');
    }catch(e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
        return;
      }
    }

    RegExp regExpRealname = RegExp(r'title="(.*?)"', caseSensitive: false);
    Match? matchRealname = regExpRealname.firstMatch(myactionresponse.data);
    if(matchRealname != null){
      realName = matchRealname.group(1).toString();
    }

    //保存上述信息
    stdAccount.add({
      'UserRealName': realName,
      'UserName': userName,
      'PassWord': passWord
    });
    String stdAccountJson = jsonEncode(stdAccount);
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    stdAccountfile.writeAsString(stdAccountJson);

    //学籍信息保存
    if(mounted){
      setState(() {
        loginStateString = '正在获取学籍信息...';
      });
    }
    late Response stdDetailresponse;
    try{
      if(loginAuthCanceled) return;
      stdDetailresponse = await dio.get('http://jwgl.snut.edu.cn/eams/stdDetail.action');
    }catch(e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
        return;
      }
    }
    // 解析 HTML
    var document = html_parser.parse(stdDetailresponse.data);
    List<html_dom.Element> tableRows = document.querySelectorAll("table#studentInfoTb tr");

    // 存储解析后的数据
    Map<String, String> studentInfo = {};

    for (var row in tableRows) {
      List<html_dom.Element> columns = row.querySelectorAll("td"); 

      for (int i = 0; i < columns.length - 1; i += 2) {
        String key = columns[i].text.trim();
        String value = columns[i + 1].text.trim();

        if (key.isNotEmpty) {
          studentInfo[key] = value;
        }
      }
    }

    // 转换为 JSON 并保存到本地
    String jsonOutput = jsonEncode(studentInfo);
    String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailfile = File(stdDetailpath);
    stdDetailfile.writeAsString(jsonOutput);

    //课表数据目录
    Directory courseTableStddirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd');
    if(await courseTableStddirectory.exists() == false){
      await courseTableStddirectory.create();
    }

    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    //请求课表初始信息
    if(mounted){
      setState(() {
        loginStateString = '正在获取课表信息...';
      });
    }
    late Response courseresponse1;
    try{
      if(loginAuthCanceled) return;
      courseresponse1 = await dio.get('http://jwgl.snut.edu.cn/eams/courseTableForStd.action');
    }catch (e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
        return;
      }
    }
    //提取相关数据
    String semesterId = '';
    String tagId = '';

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(courseresponse1.headers['Set-Cookie']!.first);
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    RegExp tagIdExp = RegExp(r'semesterBar(\d+)Semester');
    Match? tagIdmatch = tagIdExp.firstMatch(courseresponse1.data.toString());
    if(tagIdmatch != null){
      tagId = tagIdmatch.group(1)!;
    }

    //获取所有学期的 semester.id，学年名称，学期名称
    final courseTableformData = FormData.fromMap({
      "tagId": 'semesterBar${tagId}Semester',
      "dataType": 'semesterCalendar',
      "value": semesterId.toString(),
      "empty": 'false'
    });
    late Response courseresponse2;
    try{
      if(loginAuthCanceled) return;
      courseresponse2 = await dio.post(
      'http://jwgl.snut.edu.cn/eams/dataQuery.action',
      options: Options(
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "PostmanRuntime/7.43.0",
        }
      ),
      data: courseTableformData,
      );
    }catch (e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loginStateString = '请稍后...';
        clearTempLogindata();
        return;
      }
    }
    
    String rawdata = courseresponse2.data.toString();
    late String semesters;

    //处理教务系统的非标准 json
    rawdata = rawdata.replaceAllMapped(
      RegExp(r'(\w+):'), (match) => '"${match[1]}":');
    rawdata = rawdata.replaceAll("'", "\""); // 替换单引号为双引号

    // 去除 HTML 代码
    rawdata = rawdata.replaceAll(RegExp(r'\"<tr>.*?</tr>\"', dotAll: true), '""');

    // 解析 JSON
    Map<String, dynamic> proceeddata = json.decode(rawdata);

      if (proceeddata.containsKey("semesters")) {
        Map<String, dynamic> semestersMap = proceeddata["semesters"];

        // 转换为标准 JSON 格式的字符串
        String jsonSemesters = json.encode(semestersMap);

        semesters = jsonSemesters;
      }
    
    String semesterspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/semesters.json';
    File semestersfile = File(semesterspath);
    semestersfile.writeAsString(semesters);

    //成绩数据目录
    Directory stdGradesdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades');
    if(await stdGradesdirectory.exists() == false){
      await stdGradesdirectory.create();
    }
    
    //考试数据目录
    Directory stdExamdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam');
    if(await stdExamdirectory.exists() == false){
      await stdExamdirectory.create();
    }

    //电费数据目录
    Directory emdatadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata');
    if(await emdatadirectory.exists() == false){
      await emdatadirectory.create();
    }

    //绩点计算器数据目录
    Directory gpaCalculatordirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/GPACalculator');
    if(await gpaCalculatordirectory.exists() == false){
      await gpaCalculatordirectory.create();
    }

    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('登录成功'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
    }

    //登录流程完成，刷新用户信息，创建一个占位文件
    readStdAccount();
    String loginsuccesspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/LoginSuccess';
    File loginsuccessfile = File(loginsuccesspath);
    loginsuccessfile.writeAsString('');
  

    if(mounted){
      Navigator.pop(context);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => HomePage()));
    }
  }

  //加密密码
  String encryptAES(String data, String keyString) {
    // 字符集
    String chars = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678";
    var random = Random();

    // 生成随机字符串
    String randomString(int length) {
      var result = StringBuffer();
      for (var i = 0; i < length; i++) {
        result.write(chars[random.nextInt(chars.length)]);
      }
      return result.toString();
    }

    // 生成64位随机前缀和16位IV
    String randomPrefix = randomString(64);
    String iv = randomString(16);

    // 准备加密所需的key和iv
    final key = encrypt.Key.fromUtf8(keyString.trim());
    final ivObj = encrypt.IV.fromUtf8(iv);

    // 创建AES加密器
    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        key,
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );

    // 加密数据(随机前缀+原始数据)
    final encrypted = encrypter.encrypt(randomPrefix + data, iv: ivObj);

    // 返回Base64编码的加密结果
    return encrypted.base64;
  }
}