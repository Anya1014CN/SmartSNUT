import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
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
        TextField(
          controller: textUsernameController,
          decoration: InputDecoration(
            labelText: '用户名',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: textPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '密码',
            prefixIcon: Icon(Icons.lock),
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
            padding:EdgeInsets.fromLTRB(15, 0, 15, 10),
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
          Container(
            padding: EdgeInsets.fromLTRB(0, 60, 0, 0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
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
                        loginjwgl();
                      }
                    },
                    child: FittedBox(
                      child: Row(
                        children: [
                          Icon(Icons.login),
                          SizedBox(width: 10,),
                          Text('登录智慧陕理工',style: TextStyle(fontSize: GlobalVars.genericTextMedium),)
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  FilledButton(
                    onPressed: () {
                      url = Uri.parse('https://authserver.snut.edu.cn/retrieve-password/retrievePassword/index.html');
                      launchURL();
                    },
                    child: FittedBox(
                      child: Row(
                        children: [
                          Icon(Icons.question_mark),
                          SizedBox(width: 10,),
                          Text('忘记密码？',style: TextStyle(fontSize: GlobalVars.genericTextMedium),)
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
    );
  }

  //登录教务系统
  loginjwgl() async {
    if(mounted){
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('正在登录...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Column(
            children: [
              SizedBox(height: 10,),
              CircularProgressIndicator(),
              SizedBox(height: 10,)
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                clearTempLogindata();
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        ),
      );
    }

    //数据目录
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == false){
      await smartSNUTdirectory.create();
    }

    //存储用户名、密码
    String userName = textUsernameController.text;
    String password = textPasswordController.text;

    String realName = '';

    String? passwordhash = '';//存储 Hash
    String encryptedpassword = '';//加密后的密码

    //初始化 Dio
    CookieJar jwglcookie = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(jwglcookie));

    //第一次请求，获取 hash
    late Response response1;
    try{
      response1 = await dio.get('http://jwgl.snut.edu.cn/eams/loginExt.action');
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
        clearTempLogindata();
      }
      return;
    }

    String jwglcode = response1.data.toString();
    RegExp regExp = RegExp(r"SHA1\('([0-9a-fA-F\-]+)-");
    Match? match = regExp.firstMatch(jwglcode);
      
    if (match != null) {
      passwordhash = match.group(1);
    } else {
      return;
    }

    // **对密码进行加密**
    var combinedpassword = utf8.encode('$passwordhash-$password');
    var digest = sha1.convert(combinedpassword);
    encryptedpassword = digest.toString();

    //等待一秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(seconds: 1));

    //第二次请求，尝试登录
    final formData = FormData.fromMap({
      "username": userName,
      "password": encryptedpassword,
      "session_locale": "zh_CN"
    });


  late Response response2;
  try{
        response2 = await dio.post(
        'http://jwgl.snut.edu.cn/eams/loginExt.action',
        options: Options(
          followRedirects: true,
          validateStatus: (status){
            return status != null && status <= 302;
          },
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
        data: formData,
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
        clearTempLogindata();
      }
      return;
    }

    String response2string = response2.data.toString();
    if(response2string.contains('账户不存在')){
    if(mounted){
      Navigator.pop(context);
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Text('登录失败，账户不存在',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      clearTempLogindata();
    }
    return;
    }if(response2string.contains('密码错误')){
    if(mounted){
      Navigator.pop(context);
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Text('登录失败，密码错误',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      clearTempLogindata();
    }
    return;
    }

    //登录成功，获取个人信息
    List<Map<String, String>> stdAccount = [];
    
    Directory datadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver');
    if(await datadirectory.exists() == false){
      await datadirectory.create();
    }

    //真实姓名
    late Response myactionresponse;
    try{
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
        clearTempLogindata();
      }
      return;
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
      'PassWord': password
    });
    String stdAccountJson = jsonEncode(stdAccount);
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    stdAccountfile.writeAsString(stdAccountJson);

  //学籍信息保存
  late Response stdDetailresponse;
  try{
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
      clearTempLogindata();
    }
    return;
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
    late Response courseresponse1;
    try{
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
        clearTempLogindata();
      }
      return;
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
        clearTempLogindata();
      }
      return;
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
}