import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/mePage/electricMeterBindPage/electricmeterbind_page.dart';

//用于存储用户的信息
List emUserData = [];

class electricmeterpage extends StatefulWidget {
  const electricmeterpage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _electricmeterPageState();
  }
}

class _electricmeterPageState extends State<electricmeterpage>{
  bool _showAppBarTitle = false;

  //查询状态相关变量
  bool isQuerying =false;
  bool QuerySuccess = false;
  int currentQuery = 0;

  String wechatUserId = '';
  String electricUserUid = '';
  int electricmeternum = 0;
  var emdetail;
  int emnum = 0;
  List<dynamic> emstatetotal = [];

  @override
  void initState() {
    queryem();
    initData();
    super.initState();
  }

  initData() async {
    String emnumpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emnum.txt';
    File emnumfile = File(emnumpath);
    if(await emnumfile.exists()){
      electricmeternum = int.parse(await emnumfile.readAsString());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      floatingActionButton: FloatingActionButton(
        onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => electricmeterbindPage()));},
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.link),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification.metrics.pixels > 80 && !_showAppBarTitle) {
            setState(() {
              _showAppBarTitle = true;
            });
          } else if (scrollNotification.metrics.pixels <= 80 &&
              _showAppBarTitle) {
            setState(() {
              _showAppBarTitle = false;
            });
          }
          return true;
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                ),
                pinned: true,
                expandedHeight: 0,
                title: _showAppBarTitle ? Text("电费查询") : null,
              ),
            ];
          },
          body: ListView(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
                child: Row(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/electricity.png'):AssetImage('assets/icons/darktheme/electricity.png'),height: 40,),
                    SizedBox(width: 10,),
                    Text('电费查询',style: TextStyle(fontSize: GlobalVars.emquery_page_title),)
                  ],
                ),
              ),
              isQuerying?
              SizedBox(width: 0,height: 0,):
              QuerySuccess?
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 80),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: emstatetotal.map((em) {
                    return Container(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('电表编号：${em['userCode']}',style: TextStyle(fontSize: GlobalVars.emdetail_emid_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          SizedBox(height: 10,),
                          Text('电表剩余：${em['emDetail']['shengyu']}',style: TextStyle(fontSize: GlobalVars.emdetail_emleft_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          Text('电表累计：${em['emDetail']['leiji']}',style: TextStyle(fontSize: GlobalVars.emdetail_emtotal_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          Text('电表状态：${em['emDetail']['zhuangtai']}',style: TextStyle(fontSize: GlobalVars.emdetail_emstate_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          SizedBox(height: 10,),
                          Text('${em['userAddress']}',style: TextStyle(fontSize: GlobalVars.emdetail_emaddress_title),textAlign: TextAlign.center,softWrap: true,maxLines: 1,overflow: TextOverflow.ellipsis),
                          SizedBox(height: 20,),
                          Divider(height: 5,indent: 20,endIndent: 20,),
                        ],
                      ),
                    );
                  }).toList(),
                  )
                ),
              ):
              Container(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('无法连接网络，请点击这里重试',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.emquery_nonetwork_title),),
                      onTap: (){
                        queryem();
                      },
                    ),
                  ),
                ),
              ),
              isQuerying? Container(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: ListTile(
                      title: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 10,),
                          Text('正在查询（$currentQuery/$electricmeternum）......',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.emquery_querying_title),)
                        ],
                      ),
                    ),
                  ),
                ),
              ):SizedBox(width: 0,height: 0,)
            ],
          ),
        ),
      ),
    );
  }

 queryem() async {
  if(mounted){
    setState(() {
      isQuerying = true;
    });
  }
    //读取用户 id

    //读取用户数据
    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    if(await emUserDatafile.exists() == true){
    emUserData =jsonDecode(await emUserDatafile.readAsString());

    final docpath = (await getApplicationDocumentsDirectory()).path;
    if(mounted){
        setState(() {
          openid = emUserData[0]['openId'];
          wechatId = emUserData[0]['wechatId'];
          wechatUserNickname = emUserData[0]['wechatUserNickname'];
          emavatarpath = '$docpath/SmartSNUT/embinddata/emavatar.jpg';
          electricmeternum = int.parse(emUserData[0]['emNum']);
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
      setState(() {binded = true;});
    }
    
    emUserData.clear();
    emUserData.add({
      'emNum': electricmeternum,
      'openId': openid,
      'wechatId': wechatId,
      'wechatUserNickname': wechatUserNickname,
    });
    emUserDatafile.writeAsString(jsonEncode(emUserData));

    for(int i = 0;i <= electricmeternum - 1;i++){
      if(mounted){
        setState(() {
        currentQuery = i + 1;
      });
      }
      //获取电表 id
      String emdetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emdetail.json';
      File emdetailfile = File(emdetailpath);
      emdetail = jsonDecode(await emdetailfile.readAsString());
      String electricUserUid = emdetail[i]['bindMeterId'];

      Dio dio = Dio();
      try{
        Response emqresponse1 = await dio.post('https://hqkddk.snut.edu.cn/kddz/electricmeterpost/electricMeterQuery?wechatUserId=$wechatUserId&electricUserUid=$electricUserUid&isAfterMoney=0',);
        emstatetotal.add({
          'userCode': emdetail[i]['userCode'],
          'userAddress': emdetail[i]['userAddress'],
          'emDetail': emqresponse1.data['data']
        });
      }catch (e){
        if(mounted){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
              content: Text('查询失败，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
          setState(() {
            isQuerying = false;
          });
        }
        return;
      }
    }
    if(mounted){
      setState(() {
        QuerySuccess = true;
        isQuerying = false;
      });
    }
  }
}