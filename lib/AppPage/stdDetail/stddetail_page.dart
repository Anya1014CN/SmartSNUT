import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:smartsnut/globalvars.dart';

Map<String, String> studentData = {};

class stdDetailPage extends StatefulWidget{
  const stdDetailPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _stddetailPageState();
  }
}

class _stddetailPageState extends State<stdDetailPage>{
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    readstdinfo();
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
                padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
                child: Row(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/account.png'):AssetImage('assets/icons/darktheme/account.png'),height: 40,),
                    SizedBox(width: 10,),
                    Text('学籍信息',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21),
                  ),
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  child: Column(
                    children: studentData.entries.map((entry) {
                      return Container(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.genericTextSmall)),
                            SizedBox(height: 5,),
                            Text(entry.value,style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.genericTextSmall)),
                            SizedBox(height: 20,),
                            Divider(height: 5,indent: 20,endIndent: 20,),
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
  readstdinfo() async {
    int i = 1;
    String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailfile = File(stdDetailpath);
    String jsonstring = await stdDetailfile.readAsString();
    Map<String, dynamic> jsonData = json.decode(jsonstring);
        if(mounted){
          setState(() {
            studentData = jsonData.map((key, value) => MapEntry(key, value.toString()));
          });
        }
        for(i = 1; i <= studentData.length;){
          return Text(studentData[i].toString());
        }
  }
}