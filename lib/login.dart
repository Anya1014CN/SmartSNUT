import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smartsnut/main.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/function_modules.dart';
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
  late TextEditingController textUsernameController;
  late TextEditingController textPasswordController;

  @override
  void dispose() {
    textUsernameController.dispose();
    textPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    textUsernameController = TextEditingController();
    textPasswordController = TextEditingController();
    Modules.readSettings();
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
                        title: Row(
                          children: [
                            Icon(Icons.info),
                            SizedBox(width: 8,),
                            Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                          ],
                        ),
                        content: Text('用户名不能为空，请输入您的学号/工号',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
                      ));
                    return;
                  }if (textPasswordController.text == '') {
                    showDialog(
                      context: context, 
                      builder: (BuildContext context)=>AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.info),
                            SizedBox(width: 8,),
                            Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                          ],
                        ),
                        content: Text('密码不能为空，请输入您的密码',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
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
                      '登录智慧陕理',
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
                Text('登录智慧陕理',style: TextStyle(fontSize: GlobalVars.genericTextMedium,color: Theme.of(context).colorScheme.primary),),
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
        GlobalVars.realName = GlobalVars.stdDetail['姓名：']!;
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
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.help),
            SizedBox(width: 8,),
            Text('询问：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
          ],
        ),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if(context.mounted){
                Navigator.pop(context);
              }
            },
            child: Text('确定'),
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
    GlobalVars.operationCanceled = false;
    GlobalVars.loadingHint = '正在加载...';
    if(mounted){
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('请稍后...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10,),
                  CircularProgressIndicator(),
                  SizedBox(height: 10,),
                  Text(GlobalVars.loadingHint,style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    GlobalVars.operationCanceled = true;
                    Navigator.pop(context);
                  },
                  child: Text('取消'),
                ),
              ],
            ),
          );
        },
      );
    }

    if(GlobalVars.operationCanceled) {
      clearTempLogindata();
      return;
    }
    await Modules.checkDirectory();

    String userName = textUsernameController.text;
    String passWord = textPasswordController.text;

    if(GlobalVars.operationCanceled) {
      clearTempLogindata();
      return;
    }
    List loginAuthResponse = await Modules.loginAuth(userName, passWord,'jwgl');
    if(loginAuthResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8,),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(loginAuthResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }

    //保存上述信息
    List stdAccount = [];
    stdAccount.add({
      'UserName': userName,
      'PassWord': passWord
    });
    String stdAccountJson = jsonEncode(stdAccount);
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    stdAccountfile.writeAsString(stdAccountJson);

    //获取学籍信息
    if(GlobalVars.operationCanceled) {
      clearTempLogindata();
      return;
    }
    List getStdDetailResponse = await Modules.getStdDetail();
    if(getStdDetailResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8,),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(getStdDetailResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }

    //读取近两个学期的课表
    if(GlobalVars.operationCanceled) {
      clearTempLogindata();
      return;
    }
    List getCourseTableResponse = await Modules.getCourseTable(-1,-1);
    if(getCourseTableResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8,),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(getCourseTableResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }
    
    
    if(GlobalVars.operationCanceled) {
      clearTempLogindata();
      return;
    }
    List getSemestersDataResponse = await Modules.getSemestersData();
    
    
    if(GlobalVars.operationCanceled) {
      clearTempLogindata();
      return;
    }
    List getCourseTableResponse1 = await Modules.getCourseTable(getSemestersDataResponse[0]['semestersData'].length - 1,1);
    if(getCourseTableResponse1[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8,),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(getCourseTableResponse1[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }

    
    if(GlobalVars.operationCanceled) {
      clearTempLogindata();
      return;
    }
    List getCourseTableResponse2 = await Modules.getCourseTable(getSemestersDataResponse[0]['semestersData'].length - 1,2);
    if(getCourseTableResponse2[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8,),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(getCourseTableResponse2[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
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
}