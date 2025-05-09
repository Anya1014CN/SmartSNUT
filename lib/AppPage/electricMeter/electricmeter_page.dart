import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/mePage/electricMeterBindPage/electricmeterbind_page.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

class Electricmeterpage extends StatefulWidget {
  const Electricmeterpage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ElectricmeterPageState();
  }
}

class _ElectricmeterPageState extends State<Electricmeterpage>{
  bool _showAppBarTitle = false;

  //查询状态相关变量
  bool isQuerying =false;
  bool querySuccess = false;
  int currentQuery = 0;
  List<dynamic> emstatetotal = [];

  @override
  void dispose() {
    super.dispose();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled && !Platform.isWindows) {
        UmengCommonSdk.onPageEnd("校内应用 - 电费查询");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      queryem();
      if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled && !Platform.isWindows) {
          UmengCommonSdk.onPageStart("校内应用 - 电费查询");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){
          Navigator.push(context, CustomPageRoute(page: ElectricmeterbindPage()));
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        label: Row(
          children: [
            Icon(Icons.link),
            SizedBox(width: 10,),
            Text('账号管理',style: TextStyle(fontSize: GlobalVars.genericFloationActionButtonTitle),)
          ],
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification.metrics.pixels > 80 && !_showAppBarTitle) {
            if(mounted){
              setState(() {
                _showAppBarTitle = true;
              });
            }
          } else if (scrollNotification.metrics.pixels <= 80 &&
              _showAppBarTitle) {
            if(mounted){
              setState(() {
                _showAppBarTitle = false;
              });
            }
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
                padding: EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image(
                        image: Theme.of(context).brightness == Brightness.light
                          ? AssetImage('assets/icons/lighttheme/electricity.png')
                          : AssetImage('assets/icons/darktheme/electricity.png'),
                        height: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '电费查询',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              
              // 查询状态显示与电表信息展示
              isQuerying ?
              SizedBox() :
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  child: emstatetotal.isEmpty ? 
                    // 无电表数据时显示加载提示
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              "正在加载电表数据...", 
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: GlobalVars.genericTextMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ) :
                    // 有电表数据时显示列表
                    Column(
                      children: emstatetotal.map((em) {
                        return Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 电表编号
                              Row(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '电表编号：${em['userCode']}',
                                      style: TextStyle(
                                        fontSize: GlobalVars.genericTextLarge,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              
                              // 电表数据卡片
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 电表剩余
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.electric_bolt,
                                          size: 18,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '电表剩余：${em['emDetail']['shengyu']}',
                                          style: TextStyle(
                                            fontSize: GlobalVars.genericTextLarge,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // 电表累计
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 18,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '电表累计：${em['emDetail']['leiji']}',
                                          style: TextStyle(
                                            fontSize: GlobalVars.genericTextLarge,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // 电表状态
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '电表状态：${em['emDetail']['zhuangtai']}',
                                          style: TextStyle(
                                            fontSize: GlobalVars.genericTextLarge,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 16),
                              
                              // 地址信息
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${em['userAddress']}',
                                      style: TextStyle(
                                        fontSize: GlobalVars.genericTextMedium,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              Divider(height: 1),
                              SizedBox(height: 8),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

 queryem() async {
  bool queryemCanceled = false;
  if(mounted){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('请稍后...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                SizedBox(height: 10,),
                CircularProgressIndicator(),
                SizedBox(height: 10,),
                Text('正在查询第 $currentQuery 个，共 ${GlobalVars.emNum} 个',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
              ],
            ),
            actions: [
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                  queryemCanceled = true;
                },
                child: Text('取消'),
              ),
            ],
          ),
        );
      },
    );
  }

    for(int i = 0;i <= GlobalVars.emNum - 1;i++){
      if(mounted){
        setState(() {
          currentQuery = i + 1;
        });
      }
      //获取电表 id
      String emdetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emdetail.json';
      File emdetailfile = File(emdetailpath);
      GlobalVars.emDetail = jsonDecode(await emdetailfile.readAsString());
      String electricUserUid = GlobalVars.emDetail[i]['bindMeterId'];

      Dio dio = Dio(
        BaseOptions(
          headers: {
            'User-Agent':
                (Platform.isWindows)? 'SmartSNUT-Windows/${GlobalVars.versionCodeString}':(Platform.isAndroid)? 'SmartSNUT-Android/${GlobalVars.versionCodeString}':'SmartSNUT/${GlobalVars.versionCodeString}',
          }
        )
      );
      try{
        Response emqresponse1 = await dio.post('https://hqkddk.snut.edu.cn/kddz/electricmeterpost/electricMeterQuery?wechatUserId=${GlobalVars.wechatUserId}&electricUserUid=$electricUserUid&isAfterMoney=0',);
        emstatetotal.add({
          'userCode': GlobalVars.emDetail[i]['userCode'],
          'userAddress': GlobalVars.emDetail[i]['userAddress'],
          'emDetail': emqresponse1.data['data']
        });
        if(queryemCanceled) return;
      }catch (e){
        if(mounted){
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error),
                  SizedBox(width: 8),
                  Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                ],
              ),
              content: Text('查询失败，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('确定'),
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
    if(queryemCanceled) return;
    if(mounted){
      setState(() {
        isQuerying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('电表数据查询成功'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      Navigator.pop(context);
    }
  }
}