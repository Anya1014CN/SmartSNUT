import 'package:flutter/material.dart';
import 'package:smartsnut/AppPage/electricMeter/electricmeter_page.dart';
import 'package:smartsnut/AppPage/stdGrades/stdgrades_page.dart';
import 'package:smartsnut/AppPage/schoolNetwork/schoolnetwork_page.dart';
import 'package:smartsnut/AppPage/stdDetail/stddetail_page.dart';
import 'package:smartsnut/AppPage/stdExam/stdexam_page.dart';
import 'package:smartsnut/globalvars.dart';
import 'courseTable/coursetable_page.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

//用于存储外部链接的完整URL
Uri url = Uri.parse("uri");

bool loginstate = false;

//获取当前日期
int month = DateTime.now().month;
int day = DateTime.now().day;
int hour = DateTime.now().hour;

//用于存储不同时间段的问候语
String greeting = '';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AppPageState();
  }
}

class _AppPageState extends State<AppPage> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (hour >= 0 && hour <= 5) {
      greeting = '晚上好';
    }
    if (hour >= 6 && hour <= 11) {
      greeting = '早上好';
    }
    if (hour >= 12 && hour <= 13) {
      greeting = '中午好';
    }
    if (hour >= 14 && hour <= 18) {
      greeting = '下午好';
    }
    if (hour >= 19 && hour <= 23) {
      greeting = '晚上好';
    }
    return ListView(
      children: [
        // 问候语区域
        Container(
          padding: EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(179),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Text(
            '$greeting，${GlobalVars.realName}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: GlobalVars.genericGreetingTitle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: 10),
        // 教务功能标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '教务功能',
                style: TextStyle(
                    fontSize: GlobalVars.dividerTitle,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        // 教务功能卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '我的课表',
                          'schedule',
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext ctx) =>
                                        CourseTablePage()));
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '学籍信息',
                          'account',
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext ctx) =>
                                        StdDetailPage()));
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '我的考试',
                          'exam',
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext ctx) =>
                                        StdExamPage()));
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '我的成绩',
                          'grade',
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext ctx) =>
                                        StdGradesPage()));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // 后勤功能标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '后勤功能',
                style: TextStyle(
                    fontSize: GlobalVars.dividerTitle,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        // 后勤功能卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
            color: Theme.of(context).colorScheme.surfaceDim,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: buildFunctionButton(
                      context,
                      '网费查询',
                      'web',
                      () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext ctx) =>
                                    SchoolNetworkPage()));
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: buildFunctionButton(
                      context,
                      '电费查询',
                      'electricity',
                      () {
                        if (GlobalVars.emBinded == false) {
                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text('提示：',
                                  style: TextStyle(
                                      fontSize: GlobalVars.alertdialogTitle)),
                              content: Text(
                                  '您还没有绑定电费账号，\n请先前往 "我的 -> 解/绑电费账号" 绑定后再试',
                                  style: TextStyle(
                                      fontSize: GlobalVars.alertdialogContent)),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, 'OK'),
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                          return;
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext ctx) =>
                                      Electricmeterpage()));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 校内链接标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '校内链接',
                style: TextStyle(
                    fontSize: GlobalVars.dividerTitle,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        // 校内链接卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '图书检索',
                          'library',
                          () {
                            url = Uri.parse('https://findsnut.libsp.com/');
                            launchURL();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '人脸信息采集系统',
                          'face',
                          () {
                            url = Uri.parse(
                                'https://faceid.snut.edu.cn/cflms-opencas/cas/v1/collection/');
                            launchURL();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          'WebVPN',
                          'vpn',
                          () {
                            url = Uri.parse('https://sec.snut.edu.cn/');
                            launchURL();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '一网通办',
                          'museum',
                          () {
                            url = Uri.parse('https://newehall.snut.edu.cn/');
                            launchURL();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '南区全景',
                          'city',
                          () {
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                scrollable: true,
                                title: Text('提示',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle)),
                                content: Text(
                                    '此页面可能包含背景音乐\n如果您正在公共场所，请注意控制设备声音',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle)),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Cancel'),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      url = Uri.parse(
                                          'http://720yun.com/t/728jOreO5n0?scene_id=2641644');
                                      launchURL();
                                    },
                                    child: const Text('确认'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '北区全景',
                          'mountain-city',
                          () {
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                scrollable: true,
                                title: Text('提示',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle)),
                                content: Text(
                                    '此页面可能包含背景音乐\n如果您正在公共场所，请注意控制设备声音',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle)),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Cancel'),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      url = Uri.parse(
                                          'http://720yun.com/t/271jO0uyOv2?scene_id=2712476');
                                      launchURL();
                                    },
                                    child: const Text('确认'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // 底部间隔
        SizedBox(height: 20),
      ],
    );
  }

  // 功能按钮构建辅助方法
  Widget buildFunctionButton(
      BuildContext context, String title, String iconName, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: Theme.of(context).brightness == Brightness.light
                  ? AssetImage('assets/icons/lighttheme/$iconName.png')
                  : AssetImage('assets/icons/darktheme/$iconName.png'),
              height: 40,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: GlobalVars.genericFunctionsButtonTitle,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  loginstatecheck() async {
    String loginstatepath =
        '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/loginstate.txt';
    File loginstatefile = File(loginstatepath);
    if (await loginstatefile.exists() == true) {
      if (mounted) {
        setState(() {
          loginstate = true;
        });
      }
    }
    if (await loginstatefile.exists() == false) {
      if (mounted) {
        setState(() {
          loginstate = false;
        });
      }
    }
  }

  //打开链接
  void launchURL() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text('提示', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',
            style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if (context.mounted) {
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