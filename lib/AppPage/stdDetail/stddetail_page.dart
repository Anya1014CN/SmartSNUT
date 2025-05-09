import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:smartsnut/globalvars.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

Map<String, String> studentData = {};

class StdDetailPage extends StatefulWidget{
  const StdDetailPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _StddetailPageState();
  }
}

class _StddetailPageState extends State<StdDetailPage>{
  bool _showAppBarTitle = false;
  bool _isLoading = true;

  @override
  void dispose() {
    super.dispose();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled && !Platform.isWindows) {
        UmengCommonSdk.onPageStart("校内应用 - 学籍信息");
    }
  }

  @override
  void initState() {
    super.initState();
    readstdinfo();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled && !Platform.isWindows) {
        UmengCommonSdk.onPageStart("校内应用 - 学籍信息");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                title: _showAppBarTitle ? Text("学籍信息") : null,
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
                          ? AssetImage('assets/icons/lighttheme/account.png')
                          : AssetImage('assets/icons/darktheme/account.png'),
                        height: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '学籍信息',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              
              // 学籍信息内容
              _isLoading 
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          "正在加载学籍信息...",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: GlobalVars.genericTextMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                    color: Theme.of(context).colorScheme.surfaceDim,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: studentData.entries.map((entry) {
                          return buildInfoItem(context, entry.key, entry.value);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              
              // 底部间隔
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  // 信息项构建辅助方法
  Widget buildInfoItem(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: GlobalVars.genericTextMedium,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: GlobalVars.genericTextMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Divider(height: 1),
        ],
      ),
    );
  }
  
  readstdinfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
      File stdDetailfile = File(stdDetailpath);
      String jsonstring = await stdDetailfile.readAsString();
      Map<String, dynamic> jsonData = json.decode(jsonstring);
      
      if(mounted){
        setState(() {
          studentData = jsonData.map((key, value) => MapEntry(key, value.toString()));
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
            content: Text('加载学籍信息失败，请稍后再试'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}