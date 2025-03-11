import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/mePage/electricMeterBindPage/electricmeterbind_page.dart';

class electricmeterpage extends StatefulWidget {
  const electricmeterpage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _electricmeterPageState();
  }
}

class _electricmeterPageState extends State<electricmeterpage>{
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
    emnum = int.parse(await emnumfile.readAsString());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: IconButton(
          onPressed: (){Navigator.pop(context);},
          icon: Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => electricmeterbindPage()));},
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.link),
      ),
      body: Column(
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
          Expanded(
            child: ListView.builder(
            itemCount: emnum,
            itemBuilder: (context,int i){
              return Container(
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
                      title: Text('电表编号：${emdetail[i]['userCode']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.emdetail_emid_title),),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10,),
                          Text('电表剩余：${emstatetotal[i]['shengyu']} 度',style: TextStyle(fontSize: GlobalVars.emdetail_emleft_title),),
                          SizedBox(height: 5,),
                          Text('电表累计：${emstatetotal[i]['leiji']} 度',style: TextStyle(fontSize: GlobalVars.emdetail_emtotal_title),),
                          SizedBox(height: 5,),
                          Text('电表状态：${emstatetotal[i]['zhuangtai']}',style: TextStyle(fontSize: GlobalVars.emdetail_emstate_title),),
                          SizedBox(height: 5,),
                          Text('${emdetail[i]['userAddress']}',style: TextStyle(fontSize: GlobalVars.emdetail_emaddress_title,fontWeight: FontWeight.bold),),
                        ],
                      )
                    ),
                  ),
                ),
              );
            }
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
                      Text('正在查询（$currentQuery/$emnum）......',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.emquery_querying_title),)
                    ],
                  ),
                ),
              ),
            ),
          ):SizedBox(width: 0,height: 0,)
        ],
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
    String wechatidpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatId.txt';
    File wechtaidfile = File(wechatidpath);
    wechatUserId = await wechtaidfile.readAsStringSync();

    //获取电表数量
    String emnumpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emnum.txt';
    File emnumfile = File(emnumpath);
    electricmeternum = int.parse(await emnumfile.readAsString());

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
        emstatetotal.add(emqresponse1.data['data']);
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
      isQuerying = false;
      QuerySuccess = true;
    });
    }
  }
}