import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:url_launcher/url_launcher.dart';

//用于存储外部链接的完整URL
Uri url = Uri.parse("uri");

bool isQuerying = false;
//用于存储用户头像路径
String emavatarpath = '';

//判断绑定状态
bool isBinding = false;

//用户信息
String wechatUserNickname = '';
String wechatId = '';

//电表数量
int electricmeternum = 0;

//TextController
final textOpenidController = TextEditingController();

String openid = '';

//用于存储用户的信息
List emUserData = [];

class ElectricmeterbindPage extends StatefulWidget{
  const ElectricmeterbindPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ElectricmeterbindPageState();
  }
}

class _ElectricmeterbindPageState extends State<ElectricmeterbindPage>{

  checkbindstate() async {

    //每次读取之前进行电费账号目录检查，防止后续版本升级，目录未被创建导致崩溃
    Directory datadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata');
    if(await datadirectory.exists() == false){
      await datadirectory.create();
    }

    //读取用户数据
    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    if(await emUserDatafile.exists() == true){
    emUserData =jsonDecode(await emUserDatafile.readAsString());

    final docpath = (await getApplicationDocumentsDirectory()).path;
    if(mounted){
      List emUserData = jsonDecode(await emUserDatafile.readAsString());
        if(emUserData[0]['openId'] != ''){
          setState(() {
            openid = emUserData[0]['openId'];
            wechatId = emUserData[0]['wechatId'];
            wechatUserNickname = emUserData[0]['wechatUserNickname'];
            emavatarpath = '$docpath/SmartSNUT/embinddata/emavatar.jpg';
            electricmeternum = emUserData[0]['emNum'];
            GlobalVars.emBinded = true;
          });
        }else{
          if(mounted){
            setState(() {
              GlobalVars.emBinded = false;
            });
          }
        }
      }
    }else{
      if(mounted){
        setState(() {
          GlobalVars.emBinded = false;
        });
      }
    }
    
    //若用户使用旧版数据，则进行迁移
    String emnumpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emnum.txt';
    File emnumfile = File(emnumpath);
    if(await emnumfile.exists()){
      electricmeternum = int.parse(await emnumfile.readAsString());
      await emnumfile.delete();
    }

    String openidpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidfile = File(openidpath);
    if(await openidfile.exists()){
      openid = await openidfile.readAsString();
      await openidfile.delete();
    }

    String wechatIdpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatId.txt';
    File wechatIdfile = File(wechatIdpath);
    if(await wechatIdfile.exists()){
      wechatId = await wechatIdfile.readAsString();
      await wechatIdfile.delete();
    }

    String wechatUserNicknamepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserNickname.txt';
    File wechatUserNicknamefile = File(wechatUserNicknamepath);
    if(await wechatUserNicknamefile.exists()){
      wechatUserNickname = await wechatUserNicknamefile.readAsString();
      await wechatUserNicknamefile.delete();
      setState(() {GlobalVars.emBinded = true;});
    }
    
    emUserData.clear();
    emUserData.add({
      'emNum': electricmeternum,
      'openId': openid,
      'wechatId': wechatId,
      'wechatUserNickname': wechatUserNickname,
    });
    emUserDatafile.writeAsString(jsonEncode(emUserData));
  }
  

  @override
  void initState() {
    checkbindstate();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: isBinding ? null : IconButton(
          onPressed: () {Navigator.pop(context);},
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: 
      ListView(
        children: [
          // 标题部分
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 30),
            child: Row(
              children: [
                Image(
                  image: Theme.of(context).brightness == Brightness.light 
                    ? AssetImage('assets/icons/lighttheme/electricitybind.png')
                    : AssetImage('assets/icons/darktheme/electricitybind.png'),
                  height: 40,
                ),
                SizedBox(width: 10,),
                Text(
                  '解/绑电费账号',
                  style: TextStyle(
                    fontSize: GlobalVars.genericPageTitle,
                    fontWeight: FontWeight.bold
                  ),
                )
              ],
            ),
          ),
          
          // 用户信息卡片
          Container(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Card(
              elevation: 2,
              shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
              color: Theme.of(context).colorScheme.surfaceDim,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: GlobalVars.emBinded
                ? Container(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: GlobalVars.emBinded 
                                ? FileImage(File(emavatarpath))
                                : AssetImage('assets/images/default_avatar.png') as ImageProvider
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wechatUserNickname,
                                    style: TextStyle(
                                      fontSize: GlobalVars.genericTextLarge,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '电表数量：$electricmeternum',
                                    style: TextStyle(
                                      fontSize: GlobalVars.genericTextLarge,
                                      color: Theme.of(context).colorScheme.secondary
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(20),
                    child: TextField(
                      controller: textOpenidController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelText: 'openId',
                        prefixIcon: Icon(Icons.commit),
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                    ),
                  ),
            ),
          ),
          
          // 操作按钮区域
          GlobalVars.emBinded
            ? Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isQuerying 
                            ? null
                            : () {
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: Text('询问：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                                    content: Text('您确定要刷新数据吗', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, 'Cancel'),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          bindelectricmeter();
                                        },
                                        child: const Text('确认'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            child: Text(
                              '刷新数据',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                        color: Theme.of(context).colorScheme.primary,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isQuerying
                            ? null
                            : () {
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: Text('询问：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                                    content: Text('您确定要解绑账号吗', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, 'Cancel'),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          unbind();
                                        },
                                        child: const Text('确认'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            child: Text(
                              '解绑账号',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            : Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/EMBindGuide.html');
                            launchURL();
                          },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            child: Text(
                              '如何绑定',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                        color: Theme.of(context).colorScheme.primary,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if(textOpenidController.text == '') {
                              showDialog<String>(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  scrollable: true,
                                  title: Text('提示', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                                  content: Text('请先输入您的 openId', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, 'OK'),
                                      child: const Text('确定'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              openid = textOpenidController.text;
                              bindelectricmeter();
                            }
                          },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            child: Text(
                              '绑定账号',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          
          // 服务说明
          Container(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              elevation: 2,
              shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
              color: Theme.of(context).colorScheme.surfaceDim,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Text(
                        '服务说明',
                        style: TextStyle(
                          fontSize: GlobalVars.genericTextLarge,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '1. 电费账号与陕西理工大学统一身份认证账号相互独立\n登录/退出陕西理工大学统一身份认证账号不会影响电费账号\n绑定电费账号不会关联到陕西理工大学统一身份认证账号',
                        style: TextStyle(
                          fontSize: GlobalVars.genericTextMedium,
                          height: 1.5
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '2. 如果您在绑定电费账号之后在陕西理工大学后勤保障部公众号进行了绑定/解绑用户（电表）操作，请务必点击上方的"刷新数据"按钮，否则可能会导致"电表查询"功能出现电表列表不准确的情况',
                        style: TextStyle(
                          fontSize: GlobalVars.genericTextMedium,
                          height: 1.5
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bindelectricmeter() async {
    bool bindelectricmeterCanceled = false;
    if(mounted){
      setState(() {
        isBinding = true;
      });
      
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('正在绑定...', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Column(
            children: [
              SizedBox(height: 16),
              CircularProgressIndicator(),
              SizedBox(height: 16)
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                bindelectricmeterCanceled = true;
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        ),
      );
    }

    CookieJar emcookiejar = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(emcookiejar));

    //获取用户相关信息
    if(bindelectricmeterCanceled) return;
    late Response emresponse1;
    try{
      emresponse1 = await dio.post('https://hqkddk.snut.edu.cn/kddz/electricmeterpost/index?openId=$openid',);
    }catch (e){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接网络，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'OK'), child: Text('确认'))],
          ));
          setState(() {
            isBinding = false;
            if(GlobalVars.emBinded == true){
              return;
            }else{
              GlobalVars.emBinded = false;
            }
          });
        }
        return;
    }
    
    if(emresponse1.data.toString().contains('获取用户失败请重新打开')){
        if(mounted){
          Navigator.pop(context);
          showDialog(
            context: context, 
            builder: (BuildContext context)=>AlertDialog(
              title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('无法获取用户信息，请检查您的 openId 是否正确',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [TextButton(onPressed:  () => Navigator.pop(context, 'OK'), child: Text('确认'))],
          ));
          setState(() {
            isBinding = false;
            GlobalVars.emBinded = false;
          });
        }
        return;
    }

    //检查并电表信息
    wechatId = emresponse1.data['data']['wechatId'].toString();

    if(bindelectricmeterCanceled) return;
    Response emresponse2 = await dio.post('https://hqkddk.snut.edu.cn/kddz/electricmeterpost/getBindListWx?wechatUserId=$wechatId');

    if(emresponse2.data['data'].toString() == '[]'){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('您的微信账号还未绑定电表，请先前往陕西理工大学后勤保障部公众号绑定电表',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
        ));
        setState(() {
          GlobalVars.emBinded = false;
          isBinding = false;
        });
      }
      return;
    }if(emresponse2.data['data'].toString() == 'null'){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法获取数据，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
        ));
        setState(() {
          GlobalVars.emBinded = false;
          isBinding = false;
        });
      }
      return;
    }

    //保存电表信息
    String emdetailstring = jsonEncode(emresponse2.data['data']);
    String emdetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emdetail.json';
    File emdetailfile = File(emdetailpath);
    emdetailfile.writeAsString(emdetailstring);

    String emnumpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emnum.txt';
    File emnumfile = File(emnumpath);
    emnumfile.writeAsString('${emresponse2.data['data'].length}');


    //下载用户头像
    if(bindelectricmeterCanceled) return;
    await dio.download(emresponse1.data['data']['wechatUserHeadimgurl'],'${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emavatar.jpg');

    //保存用户信息
    emUserData.clear();
    emUserData.add({
      'emNum': emresponse2.data['data'].length,
      'openId': openid,
      'wechatId': emresponse1.data['data']['wechatId'].toString(),
      'wechatUserNickname': emresponse1.data['data']['wechatUserNickname'].toString(),
    });

    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    emUserDatafile.writeAsString(jsonEncode(emUserData));

    final docpath = (await getApplicationDocumentsDirectory()).path;

    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('电表数据获取成功'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      setState(() {
        emavatarpath = '$docpath/SmartSNUT/embinddata/emavatar.jpg';
        wechatId = emresponse1.data['data']['wechatId'].toString();
        wechatUserNickname = emresponse1.data['data']['wechatUserNickname'].toString();
        electricmeternum =  emresponse2.data['data'].length;
        isBinding = false;
        GlobalVars.emBinded = true;
      });
      Navigator.pop(context);
    }
  }

  unbind() async {
    if(mounted){
      setState(() {
        isBinding = true;
      });
    }

    Directory emdatadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata');
    if(await emdatadirectory.exists() == true){
      await emdatadirectory.delete(recursive: true);
      await emdatadirectory.create();
    }

    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('电表账号解绑成功'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      setState(() {
        isBinding = false;
        GlobalVars.emBinded = false;
      });
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
}