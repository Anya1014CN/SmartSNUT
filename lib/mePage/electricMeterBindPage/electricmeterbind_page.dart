import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/AppPage/schoolNetwork/schoolnetwork_page.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/mePage/guidePage/emBindGuidePage/embindguide_page.dart';

//用于存储用户头像路径
String emavatarpath = '';

//判断绑定状态
bool isBinding = false;
bool binded = false;

//用户信息
String wechatUserNickname = '';
String wechatId = '';

//电表数量
String electricmeternum = '0';

//TextController
final textOpenidController = TextEditingController();

String openid = '';

//用于存储用户的信息
List emUserData = [];

class electricmeterbindPage extends StatefulWidget{
  const electricmeterbindPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _electricmeterbindPageState();
  }
}

class _electricmeterbindPageState extends State<electricmeterbindPage>{

  checkbindstate() async {

    //每次读取之前进行电费账号目录检查，防止后续版本升级，目录未被创建导致崩溃
    Directory datadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata');
    if(await datadirectory.exists() == false){
      await datadirectory.create();
    }

    String openidtxtpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidtxtfile = File(openidtxtpath);

    if(await openidtxtfile.exists() == true){
    String openidstring = await openidtxtfile.readAsString();


    //wechatId
    String wechatIdpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatId.txt';
    File wechatIdfile = File(wechatIdpath);
    final wechatIdstring = await wechatIdfile.readAsString();

    //wechatUserNickname
    String wechatUserNicknamepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserNickname.txt';
    File wechatUserNicknamefile = File(wechatUserNicknamepath);
    final wechatUserNicknamestring = await wechatUserNicknamefile.readAsString();

    //电表数量
    String emnumpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emnum.txt';
    File emnumfile = File(emnumpath);
    electricmeternum = await emnumfile.readAsString();

    //读取用户数据
    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    emUserData =jsonDecode(await emUserDatafile.readAsString());

    final docpath = (await getApplicationDocumentsDirectory()).path;
    if(mounted){
        setState(() {
          openid = emUserData[0]['openId'];
          wechatId = emUserData[0]['wechatId'];
          wechatUserNickname = emUserData[0]['wechatUserNickname'];
          emavatarpath = '$docpath/SmartSNUT/embinddata/emavatar.jpg';
          electricmeternum = emUserData[0]['emNum'].toString();
          binded = true;
        });
      }
    }else{
      if(mounted){
        setState(() {
          binded = false;
        });
      }
    }
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
        leading:isBinding? null:IconButton(
          onPressed: (){Navigator.pop(context);},
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: 
      ListView(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
            child: Row(
              children: [
                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/electricitybind.png'):AssetImage('assets/icons/darktheme/electricitybind.png'),height: 40,),
                SizedBox(width: 10,),
                Text('解/绑电费账号',style: TextStyle(fontSize: GlobalVars.embind_page_title),)
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Card(
              shadowColor: Theme.of(context).colorScheme.onPrimary,
              color: Theme.of(context).colorScheme.surfaceDim,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              ),
              child: binded? Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(backgroundImage: binded? FileImage(File(emavatarpath)):AssetImage('assets/images/default_avatar.png')),
                        SizedBox(width: 10,),
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(wechatUserNickname,style: TextStyle(fontSize: GlobalVars.embind_wechatname_title,fontWeight: FontWeight.bold),),
                              Text('电表数量：$electricmeternum',style: TextStyle(fontSize: GlobalVars.embind_emnum_title),)
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
              :Container(
                padding: EdgeInsets.all(20),
                child: TextField(
                  controller: textOpenidController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '请输入您从微信获取到的 openId',
                    hintText: 'openId',
                    filled: false
                  ),
                ),
              ),
            ),
          ),
          binded? 
          Container(
            padding: EdgeInsets.fromLTRB(60, 0, 60, 10),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    shadowColor: Theme.of(context).colorScheme.onPrimary,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    child: SizedBox(
                      height: 75,
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isQuerying? null:(){
                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text('询问：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
                              content: Text('您确定要刷新数据吗',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'Cancel'),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: (){
                                    Navigator.pop(context);
                                    bindelectricmeter();
                                  },
                                  child: const Text('确认'),
                                ),
                              ],
                            ),
                          );
                        }, 
                        child: isBinding? Center(child: CircularProgressIndicator(),):Text('刷新数据',style: TextStyle(fontSize: GlobalVars.embindrefresh_button_title),),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10,),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    shadowColor: Theme.of(context).colorScheme.onPrimary,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    child: SizedBox(
                      height: 75,
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isQuerying? null:(){
                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text('询问：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
                              content: Text('您确定要解绑账号吗',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'Cancel'),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: (){
                                    Navigator.pop(context);
                                    unbind();
                                  },
                                  child: const Text('确认'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text('解绑账号',style: TextStyle(fontSize: GlobalVars.embindunbind_button_title),),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
          :Container(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    shadowColor: Theme.of(context).colorScheme.onPrimary,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    child: SizedBox(
                      height: 75,
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isBinding? null:(){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => EMBindGuidePage()));},
                        child: Text('如何绑定？',style: TextStyle(fontSize: GlobalVars.embind_binding_title),),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    shadowColor: Theme.of(context).colorScheme.onPrimary,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    child: SizedBox(
                      height: 75,
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: (){
                          if(textOpenidController.text == ''){
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                scrollable: true,
                                title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
                                content: Text('请先输入您的 openId',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, 'OK'),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }else{
                            openid = textOpenidController.text;
                            bindelectricmeter();
                          }
                        },
                        child: isBinding? Center(child: CircularProgressIndicator(),):Text('绑定账号',style: TextStyle(fontSize: GlobalVars.embind_binding_title),),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Card(
              shadowColor: Theme.of(context).colorScheme.onPrimary,
              color: Theme.of(context).colorScheme.surfaceDim,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('服务说明',style: TextStyle(fontSize: GlobalVars.embind_hint_title,fontWeight: FontWeight.bold),),
                    Text('1.电费账号与陕西理工大学统一身份认证账号相互独立\n登录/退出陕西理工大学统一身份认证账号不会影响电费账号\n绑定电费账号不会关联到陕西理工大学统一身份认证账号',style: TextStyle(fontSize: GlobalVars.embind_hint_subtitle),),
                    Text('2.如果您在绑定电费账号之后在陕西理工大学后勤保障部公众号进行了绑定/解绑用户（电表）操作，请务必点击下方的“刷新数据”按钮，否则可能会导致“电表查询”功能出现电表列表不准确的情况',style: TextStyle(fontSize: GlobalVars.embind_hint_subtitle),),
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
    if(mounted){
      setState(() {
        isBinding = true;
      });
    }
    CookieJar emcookiejar = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(emcookiejar));

    //获取用户相关信息
    var emresponse1;
    try{
      emresponse1 = await dio.post('https://hqkddk.snut.edu.cn/kddz/electricmeterpost/index?openId=$openid',);
    }catch (e){
      showDialog(
        context: context, 
        builder: (BuildContext context)=>AlertDialog(
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
          content: Text('无法连接网络，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
          actions: [TextButton(onPressed:  () => Navigator.pop(context, 'OK'), child: Text('确认'))],
        ));
        if(mounted){
          setState(() {
            isBinding = false;
            if(binded == true){
              return;
            }else{
              binded = false;
            }
          });
        }
        return;
    }
    
    if(emresponse1.data.toString().contains('获取用户失败请重新打开')){
      showDialog(
        context: context, 
        builder: (BuildContext context)=>AlertDialog(
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
          content: Text('无法获取用户信息，请检查您的 openId 是否正确',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
          actions: [TextButton(onPressed:  () => Navigator.pop(context, 'OK'), child: Text('确认'))],
        ));
        if(mounted){
          setState(() {
            isBinding = false;
            binded = false;
          });
        }
        return;
    }

    //检查并电表信息
    wechatId = emresponse1.data['data']['wechatId'].toString();
    Response emresponse2 = await dio.post('https://hqkddk.snut.edu.cn/kddz/electricmeterpost/getBindListWx?wechatUserId=$wechatId');

    if(emresponse2.data['data'].toString() == '[]'){
    showDialog(
      context: context, 
      builder: (BuildContext context)=>AlertDialog(
        title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
        content: Text('您的微信账号还未绑定电表，请先前往陕西理工大学后勤保障部公众号绑定电表',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
        actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
      ));
      if(mounted){
        setState(() {
          binded = false;
          isBinding = false;
        });
      }
      return;
    }if(emresponse2.data['data'].toString() == 'null'){
    showDialog(
      context: context, 
      builder: (BuildContext context)=>AlertDialog(
        title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
        content: Text('无法获取数据，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
        actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
      ));
      if(mounted){
        setState(() {
          binded = false;
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
    await dio.download(emresponse1.data['data']['wechatUserHeadimgurl'],'${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emavatar.jpg');

    //保存 id 相关信息
    String openidpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidfile = File(openidpath);
    openidfile.writeAsString(openid);

    //wechatId
    String wechatIdpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatId.txt';
    File wechatIdfile = File(wechatIdpath);
    wechatIdfile.writeAsString(emresponse1.data['data']['wechatId'].toString());

    //wechatUserNickname
    String wechatUserNicknamepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserNickname.txt';
    File wechatUserNicknamefile = File(wechatUserNicknamepath);
    wechatUserNicknamefile.writeAsString(emresponse1.data['data']['wechatUserNickname'].toString());

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('电表数据获取成功'),
      ),
    );

    if(mounted){
      setState(() {
        emavatarpath = '$docpath/SmartSNUT/embinddata/emavatar.jpg';
        wechatId = emresponse1.data['data']['wechatId'].toString();
        wechatUserNickname = emresponse1.data['data']['wechatUserNickname'].toString();
        electricmeternum =  emresponse2.data['data'].length.toString();
        isBinding = false;
        binded = true;
        GlobalVars.emBinded = true;
      });
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('电表账号解绑成功'),
      ),
    );

    if(mounted){
      setState(() {
        binded = false;
        isBinding = false;
        GlobalVars.emBinded = false;
      });
    }
  }
}