import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:smartsnut/globalvars.dart';

//验证码输入框
TextEditingController textCaptchaController = TextEditingController();

//学期信息
String termStart = '';
String termEnd = '';
int termWeeks = 0;
bool termEnded = false;

//菜单 Controller
final menuYearController = MenuController();
final menuTermController = MenuController();
final menuExamBatchController = MenuController();

//用户数据
List stdAccount = [];
String userName = '';
String passWord = '';

//学期数据
Map semestersData = {};
int semesterTotal = 0;//学年的数量
List semestersName = [];

//当前考试学年
int currentYearInt = 1;
String currentYearName = '';

//当前考试学期
int currentTermInt = 1;
String currentTermName = '';

//当前考试批次
int currentExamBatch = 1;
int currentExamBatchid = 000;
String currentExamBatchName = '';

//当前学期考试信息
List stdExamTotal = [];
bool noExam = false;//用于判断该学期是否有考试

class StdExamPage extends StatefulWidget{
  const StdExamPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _StdExamPageState();
  }
}

class _StdExamPageState extends State<StdExamPage>{
  bool _showAppBarTitle = false;

  //读取用户信息并保存在变量中
  readStdAccount() async {
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    stdAccount = jsonDecode(await stdAccountfile.readAsString());
    if(mounted){
      setState(() {
        userName = stdAccount[0]['UserName'];
        passWord = stdAccount[0]['PassWord'];
      });
    }
  }

  //读取学期相关信息
  readSemesterInfo() async {
    //清空学期列表
    semestersData = {};
    semestersName = [];
    String semesterspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/semesters.json';
    File semestersfile = File(semesterspath);
    semestersData = jsonDecode(await semestersfile.readAsString());
    semesterTotal = semestersData.length;
    for(int i = 0; i < semesterTotal; i++){
      semestersName.add({
        'name': semestersData['y$i'][0]['schoolYear']
      });
    }
    readSelectState();
  }

  //读取学期的选中状态
  readSelectState() async {

    //每次读取之前进行考试数据目录检查，防止后续版本升级，目录未被创建导致崩溃
    Directory stdExamdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam');
    if(await stdExamdirectory.exists() == false){
      await stdExamdirectory.create();
    }
    
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    if(await selectedTYfile.exists()){
      var selectedTYjson = jsonDecode(await selectedTYfile.readAsString());
      if(mounted){
        setState(() {
          currentYearInt = selectedTYjson[0]['selectedYear'];
          currentYearName = semestersName[currentYearInt]['name'];
          currentTermInt = selectedTYjson[1]['selectedTerm'];
          if(currentTermInt == 1){
            currentTermName = '第一学期';
          }if(currentTermInt == 2){
            currentTermName = '第二学期';
          }
          currentExamBatch = selectedTYjson[2]['examBatch'];
          if(currentExamBatch == 0){
            currentExamBatchName = '期末考试';
          }if(currentExamBatch == 1){
            currentExamBatchName = '重修考试';
          }
        });
      }
    }else{
      if(mounted){
        setState(() {
          currentYearInt = semestersData.length - 1;
          currentYearName = semestersName[semestersName.length - 1]['name'];
          currentExamBatch = 0;
          currentExamBatchName = '期末考试';
          //获取当前月份
          int month = DateTime.now().month;
          if(month < 9){
            //如果月份小于9，则选择第二学期
            currentTermInt = 2;
            currentTermName = '第二学期';
          }else{
            //如果月份大于等于9，则选择第一学期
            currentTermInt = 1;
            currentTermName = '第一学期';
          }
        });
      }
      saveSelectedTY();
    }
    readSchoolCalendarInfo();
  }

  //读取校历相关信息
  readSchoolCalendarInfo() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的成绩
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String schoolCalendarpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar/schoolCalendar$semesterId.json';
    File schoolCalendarfile = File(schoolCalendarpath);
    if(await schoolCalendarfile.exists()){
      var termTimejson = jsonDecode(await schoolCalendarfile.readAsString());
      termStart = termTimejson[0]['termStart'];
      termEnd = termTimejson[0]['termEnd'];
    }
    readstdExam();
  }

  //读取考试信息
  readstdExam() async  {
    //使用本地选中的 semetserid 来读取对应的课表
    late List stdExamBatchInfo;
    String semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String stdExamBatchpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-Batch.json';
    File stdExamBatchfile = File(stdExamBatchpath);
    if(await stdExamBatchfile.exists()){
      stdExamBatchInfo = jsonDecode(await stdExamBatchfile.readAsString());
      if(currentExamBatch == 0){
        if(stdExamBatchInfo[0]['normalExam'] == ''){
          if(mounted){
            setState(() {
              noExam = true;
            });
          }
        }else{
          currentExamBatchid = int.parse(stdExamBatchInfo[0]['normalExam']);
          if(mounted){
            setState(() {
              noExam = false;
            });
          }
        }
      }if(currentExamBatch == 1){
        if(stdExamBatchInfo[0]['retakeExam'] == ''){
          if(mounted){
            setState(() {
              noExam = true;
            });
          }
        }else{
          currentExamBatchid = int.parse(stdExamBatchInfo[0]['retakeExam']);
          if(mounted){
            setState(() {
              noExam = false;
            });
          }
        }
      }
    }else{
      if(mounted){
        setState(() {
          noExam = true;
        });
      }
    }

    String stdExampath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-$currentExamBatchid.json';
    File stdExamfile = File(stdExampath);
    if(await stdExamfile.exists()){
      var readexamTotal = jsonDecode(await stdExamfile.readAsString());
      if(readexamTotal.isEmpty){
        if(mounted){
          setState(() {
            noExam = true;
          });
        }
      }else{
        if(mounted){
          setState(() {
            stdExamTotal = readexamTotal;
            noExam = false;
          });
        }
      }
    }else{
      if(mounted){
        setState(() {
          noExam = true;
        });
      }
    }
  }
  
  ///保存选中的考试学期状态
  saveSelectedTY() async {
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    List selectedTY = [];
    selectedTY.remove('selectedYear');
    selectedTY.remove('selectedTerm');
    selectedTY.remove('examBatch');
    selectedTY.add({
      'selectedYear': currentYearInt,
    });
    selectedTY.add({
      'selectedTerm': currentTermInt,
    });
    selectedTY.add({
      'examBatch': currentExamBatch,
    });
    //保存完成后刷新状态，防止出现参数更新不及时的情况
    setState(() {});
    selectedTYfile.writeAsString(jsonEncode(selectedTY));
  }
  
  //切换考试学期
  switchTerm() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('切换考试时间',style: TextStyle(fontSize: GlobalVars.alertdialogTitle),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 学年选择
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MenuAnchor(
                    controller: menuYearController,
                    menuChildren: semestersName.map((item) {
                      return MenuItemButton(
                        onPressed: () async {
                          int yearSelectedIndex = semestersName.indexOf(item);
                          if(mounted){
                            setState(() {
                              currentYearInt = yearSelectedIndex;
                              currentYearName = item['name'];
                            });
                          }
                          saveSelectedTY();
                          readSemesterInfo();
                          menuYearController.close();
                        },
                        child: Text('${item['name']} 学年',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
                      );
                    }).toList(),
                    child: SizedBox(
                      height: 50,
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (menuYearController.isOpen) {
                            menuYearController.close();
                          } else {
                            menuYearController.open();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '学年：$currentYearName',
                              style: TextStyle(
                                fontSize: GlobalVars.genericSwitchMenuTitle,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis
                            ),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 学期选择
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MenuAnchor(
                    controller: menuTermController,
                    menuChildren: [
                      MenuItemButton(
                        child: Text('第一学期',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
                        onPressed: () async {
                          if(mounted){
                            setState(() {
                              currentTermInt = 1;
                              currentTermName = '第一学期';
                            });
                          }
                          saveSelectedTY();
                          readSemesterInfo();
                          menuTermController.close();
                        },
                      ),
                      MenuItemButton(
                        child: Text('第二学期',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
                        onPressed: () async {
                          if(mounted){
                            setState(() {
                              currentTermInt = 2;
                              currentTermName = '第二学期';
                            });
                          }
                          saveSelectedTY();
                          readSemesterInfo();
                          menuTermController.close();
                        },
                      ),
                    ],
                    child: SizedBox(
                      height: 50,
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (menuTermController.isOpen) {
                            menuTermController.close();
                          } else {
                            menuTermController.open();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '学期：$currentTermName', 
                              style: TextStyle(
                                fontSize: GlobalVars.genericSwitchMenuTitle,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis
                            ),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    readStdAccount();
    readSemesterInfo();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){getStdExam();},
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        label: Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 10,),
            Text('刷新数据',style: TextStyle(fontSize: GlobalVars.genericFloationActionButtonTitle),)
          ],
        ),
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
                actions: [
                  IconButton(
                    onPressed: () => switchTerm(),
                    icon: Icon(Icons.date_range),
                    tooltip: '切换考试时间',
                  )
                ],
                pinned: true,
                expandedHeight: 0,
                title: _showAppBarTitle ? Text("我的考试") : null,
              ),
            ];
          },
          body: ListView(
            children: [
              // 页面标题区域 - 改进样式和间距
              Container(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 20),
                child: Row(
                  children: [
                    Image(
                      image: Theme.of(context).brightness == Brightness.light ? 
                        AssetImage('assets/icons/lighttheme/exam.png') : 
                        AssetImage('assets/icons/darktheme/exam.png'),
                      height: 40,
                    ),
                    SizedBox(width: 16,),
                    Text(
                      '我的考试',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  ],
                ),
              ),
              
              // 考试类型选择卡片 - 改进视觉呈现
              Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.type_specimen,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: MenuAnchor(
                            controller: menuExamBatchController,
                            menuChildren: [
                              MenuItemButton(
                                child: Text('期末考试',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
                                onPressed: () async {
                                  if(mounted){
                                    setState(() {
                                      currentExamBatch = 0;
                                      currentExamBatchName = '期末考试';
                                    });
                                  }
                                  saveSelectedTY();
                                  readSemesterInfo();
                                  menuExamBatchController.close();
                                },
                              ),
                              MenuItemButton(
                                child: Text('重修考试',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
                                onPressed: () async {
                                  if(mounted){
                                    setState(() {
                                      currentExamBatch = 1;
                                      currentExamBatchName = '重修考试';
                                    });
                                  }
                                  saveSelectedTY();
                                  readSemesterInfo();
                                  menuExamBatchController.close();
                                },
                              ),
                            ],
                            child: SizedBox(
                              height: 50,
                              child: TextButton(
                                style: ElevatedButton.styleFrom(
                                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  if (menuExamBatchController.isOpen) {
                                    menuExamBatchController.close();
                                  } else {
                                    menuExamBatchController.open();
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '考试类型：$currentExamBatchName', 
                                      style: TextStyle(
                                        fontSize: GlobalVars.genericSwitchContainerTitle,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    Icon(Icons.arrow_drop_down)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 考试信息内容区域
              noExam ? 
              // 无考试信息显示 - 改进样式
              Center(
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: Card(
                    shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                    color: Theme.of(context).colorScheme.surfaceDim,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image(
                            image: Theme.of(context).brightness == Brightness.light? 
                              AssetImage('assets/icons/lighttheme/empty.png'):
                              AssetImage('assets/icons/darktheme/empty.png'),
                            height: MediaQuery.of(context).size.height / 4,
                          ),
                          Divider(height: 24, indent: 20, endIndent: 20,),
                          Text(
                            '暂无 $currentYearName $currentTermName 的 $currentExamBatchName 信息',
                            style: TextStyle(
                              fontSize: GlobalVars.listTileTitle,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '请尝试在右上角切换学期或在右下角刷新',
                            style: TextStyle(
                              fontSize: GlobalVars.listTileSubtitle,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ) : 
              // 有考试信息显示 - 改进样式
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '$currentYearName $currentTermName $currentExamBatchName',
                                style: TextStyle(
                                  fontSize: GlobalVars.listTileTitle,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 24, indent: 16, endIndent: 16),
                        Column(
                          children: stdExamTotal.map((exam) {
                            return buildExamItem(context, exam);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 底部间隔
              Container(padding: EdgeInsets.fromLTRB(0, 80, 0, 0),)
            ],
          ),
        ),
      ),
    );
  }

  // 考试项构建辅助方法
  Widget buildExamItem(BuildContext context, Map exam) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${exam['CourseName']}', 
              style: TextStyle(
                fontSize: GlobalVars.listTileTitle, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '考试日期：${exam['CourseExamDate']}', 
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '考试时间：${exam['CourseExamTime']}', 
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '考试地点：${exam['CourseExamLocation']}', 
                    style: TextStyle(
                      fontSize: GlobalVars.genericTextMedium,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_seat, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '座位号：${exam['CourseExamSeatNo']}', 
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.category, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '考试类型：${exam['CourseExamType']}', 
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  getStdExam() async {
    String loadStateString = '请稍后...';
    bool getStdExamCanceled = false;
    if(mounted){
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('正在刷新...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    loadStateString,
                    style: TextStyle(
                      fontSize: GlobalVars.alertdialogContent,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    getStdExamCanceled = true;
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          );
        },
      );
    }
    
    //考试数据目录
    Directory stdExamdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam');
    if(await stdExamdirectory.exists() == false){
      await stdExamdirectory.create();
    }

    String encryptedpassword = '';//加密后的密码
    String authexecution = '';//存储获取到的 execution
    String pwdEncryptSalt = '';//存储获取到的 pwdEncryptSalt

    //初始化 Dio
    CookieJar authservercookie = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(authservercookie));

    //第一次请求，提取 execution
    if(mounted){
      setState(() {
        loadStateString = '正在获取登录信息...';
      });
    }
    if(getStdExamCanceled) return;
    late Response authresponse1;
    try{
      authresponse1 = await dio.get('https://authserver.snut.edu.cn/authserver/login?service=http%3A%2F%2Fjwgl.snut.edu.cn%2Feams%2FssoLogin.action');
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
        loadStateString = '请稍后...';
        return;
      }
    }   
    // 提取 execution 值// 定义正则表达式查找带有 "execution" 名称的隐藏输入字段
    final RegExp executionRegExp = RegExp(
      r'<input\s+type="hidden"\s+id="execution"\s+name="execution"\s+value="([^"]+)"',
      caseSensitive: false,
    );
    // 在响应中查找匹配
    final Match? match = executionRegExp.firstMatch(authresponse1.data.toString());
    // 如果找到匹配项，则返回提取的值
    if (match != null && match.groupCount >= 1) {
      authexecution = match.group(1)!;
    }

    // 提取 pwdEncryptSalt 值
    final RegExp pwdEncryptSaltRegExp = RegExp(
      r'<input\s+type="hidden"\s+id="pwdEncryptSalt"\s+value="([^"]+)"',
      caseSensitive: false,
    );
    // 在响应中查找匹配
    final Match? saltMatch = pwdEncryptSaltRegExp.firstMatch(authresponse1.data.toString());
    // 如果找到匹配项，则提取值
    if (saltMatch != null && saltMatch.groupCount >= 1) {
      pwdEncryptSalt = saltMatch.group(1)!;
    }

    //AES 加密密码// 使用提取到的 pwdEncryptSalt 作为密钥
    encryptedpassword = encryptAES(passWord,pwdEncryptSalt);

    //请求验证码
    if(mounted){
      setState(() {
        loadStateString = '正在获取验证码...';
      });
    }
    String captchaCode = '';
    textCaptchaController.clear();
    // 请求验证码图片
    if(getStdExamCanceled) return;
    Response captchaResponse = await dio.get(
      'https://authserver.snut.edu.cn/authserver/getCaptcha.htl',
      options: Options(
        responseType: ResponseType.bytes, // 指定响应类型为字节数组
      ),
    );
  
    // 确保响应数据是 Uint8List 类型
    Uint8List captchaBytes;
    if (captchaResponse.data is Uint8List) {
      captchaBytes = captchaResponse.data;
    } else {
      // 如果不是，尝试转换
      captchaBytes = Uint8List.fromList(captchaResponse.data as List<int>);
    }
    
    if(mounted){
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('请输入验证码',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Column(
            children: [
              FittedBox(
                child: Image.memory(captchaBytes),
              ),
              SizedBox(height: 10,),
              TextField(
                controller: textCaptchaController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '验证码',
                  hintText: '请输入验证码',
                  filled: false
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if(textCaptchaController.text.isEmpty){
                  showDialog<String>(
                    context: context, 
                    builder: (BuildContext context)=>AlertDialog(
                      title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                      content: Text('验证码不能为空，请输入验证码',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                      actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
                    ));
                  return;
                }
                captchaCode = textCaptchaController.text;
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }

    //开始登录
    if(mounted){
      setState(() {
        loadStateString = '正在登录...';
      });
    }
    late Response authresponse2;
    final loginParams = {
      "username": userName,
      "password": encryptedpassword,
      "captcha": captchaCode,
      "_eventId": "submit",
      "cllt": "userNameLogin",
      "dllt": "generalLogin",
      "lt": "",
      "execution": authexecution,
    };
    try{
      //这里手动处理重定向,解决 Cookie 问题
      if(getStdExamCanceled) return;
      authresponse2 = await  dio.post(
        'https://authserver.snut.edu.cn/authserver/login?service=http%3A%2F%2Fjwgl.snut.edu.cn%2Feams%2FssoLogin.action',
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 302;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
      //跟随第一步重定向 (ssologin 的 ticket)
      if(getStdExamCanceled) return;
      var authresponse21 = await dio.get(
        authresponse2.headers['location']![0],
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 302;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
      //跟随第二步重定向 (ssologin 的 ticket)
      if(getStdExamCanceled) return;
      var authresponse22 = await dio.get(
        authresponse21.headers['location']![0],
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 307;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
      //跟随第三步重定向 (ssologin 的 jsessionid)
      if(getStdExamCanceled) return;
      await dio.get(
        'http://jwgl.snut.edu.cn${authresponse22.headers['location']![0]}',
        data: loginParams,
        options: Options(
          followRedirects: false,
          contentType: Headers.formUrlEncodedContentType,
        )
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
        loadStateString = '请稍后...';
        return;
      }
    }
    if(authresponse2.data.toString().contains('您提供的用户名或者密码有误')){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('用户名或密码错误',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loadStateString = '请稍后...';
        return;
      }
    }
    if(authresponse2.data.toString().contains('图形动态码错误')){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('验证码错误',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loadStateString = '请稍后...';
        return;
      }
    }

    //请求考试页面
    if(mounted){
      setState(() {
        loadStateString = '正在获取考试信息...';
      });
    }
    //等待半秒，防止教务系统判定为过快点击
    if(getStdExamCanceled) return;
    await Future.delayed(Duration(milliseconds: 500));

    if(getStdExamCanceled) return;
    late Response stdExamresponse1;
    try{
      stdExamresponse1 = await dio.get(
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
            'Referer': 'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
          }
        ),
        'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
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
        loadStateString = '请稍后...';
        return;
      }
    }

    //提取相关数据
    String semesterId = '';

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(stdExamresponse1.headers['Set-Cookie']!.first);
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    //获取 examBatchId

    //使用本地选中的 semetserid 来覆盖教务系统返回的 semetserid ，用于请求对应的考试
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1]['id'].toString();

    //等待半秒，防止教务系统判定为过快点击
    if(getStdExamCanceled) return;
    await Future.delayed(Duration(milliseconds: 500));

    if(getStdExamCanceled) return;
    late Response stdExamresponse5;
    try{
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      var data = {
        'project.id': '1',
        'semester.id': semesterId
      };
      stdExamresponse5 = await dio.request(
        'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
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
        loadStateString = '请稍后...';
        return;
      }
    }

    dom.Document stdExamdocument1 = parser.parse(stdExamresponse5.data);
    // 找到 <select> 标签
    dom.Element? select = stdExamdocument1.querySelector('select#examBatchId');
    if (select == null) return {};

    // 存储 examBatchId
    String normalExam = "";
    String retakeExam = "";

    // 遍历所有 <option> 选项
    select.querySelectorAll('option').forEach((option) {
      String value = option.attributes['value'] ?? "";
      String text = option.text.trim();

      if (text == "期末考试") {
        normalExam = value;
      } else if (text == "重修考试") {
        retakeExam = value;
      }
    });
    
    //保存考试批次id信息到本地
    List stdExamBatchID = [];
    //使用本地选中的 semetserid
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    stdExamBatchID.add({
      'normalExam': normalExam,
      'retakeExam': retakeExam
    });
    String stdExamBatchpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-Batch.json';
    File stdExamBatchfile = File(stdExamBatchpath);
    stdExamBatchfile.writeAsString(jsonEncode(stdExamBatchID));
    

    //请求考试的详细信息
    if(await stdExamBatchfile.exists() && normalExam != '' && retakeExam != ''){
      if(currentExamBatch == 0){
        currentExamBatchid = int.parse(normalExam);
      }if(currentExamBatch == 1){
        currentExamBatchid = int.parse(retakeExam);
      }
    }else{
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('当前学期暂未设置考试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loadStateString = '请稍后...';
        return;
      }
    }

    if(getStdExamCanceled) return;
    late Response stdExamresponse6;
    try{
      stdExamresponse6 = await dio.get(
        'http://jwgl.snut.edu.cn/eams/stdExamTable!examTable.action?examBatch.id=$currentExamBatchid',
        options: Options(
          headers: {
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
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
        loadStateString = '请稍后...';
        return;
      }
    }

    List<Map<String, String>> foundedExams = [];
    dom.Document stdExmaDocument2 = parser.parse(stdExamresponse6.data);
    
    //提取 tableid
    dom.Element? table = stdExmaDocument2.querySelector('table.gridtable');
    if (table == null) return jsonEncode([]);
    String? tableId = table.attributes['id']; // 使用attributes获取id
    if (tableId == null || tableId.isEmpty) return jsonEncode([]);

    // 查找 tbody 对应的 id
    String tbodyId = "${tableId}_data";
    stdExmaDocument2.querySelectorAll('#$tbodyId tr').forEach((tr) {
      List<dom.Element> tds = tr.querySelectorAll('td');
      if (tds.length >= 8) {
        Map<String, String> exam = {
          "CourseID": tds[0].text.trim(),
          "CourseName": tds[1].text.trim(),
          "CourseExamType": tds[2].text.trim(),
          "CourseExamDate": tds[3].text.trim(),
          "CourseExamTime": tds[4].text.trim(),
          "CourseExamLocation": tds[5].text.trim(),
          "CourseExamSeatNo": tds[6].text.trim(),
          "CourseExamState": tds[7].text.trim(),
          "CourseExamDescription": tds.length > 8 ? tds[8].text.trim() : ""
        };
        foundedExams.add(exam);
      }
    });

    if(mounted){
      setState(() {
        stdExamTotal = foundedExams;
      });
    }

    //保存考试信息到本地
    //使用本地选中的 semetserid
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String stdExampath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-$currentExamBatchid.json';
    File stdExamfile = File(stdExampath);
    stdExamfile.writeAsString(jsonEncode(foundedExams));

    readSchoolCalendarInfo();
    if(mounted){
      Navigator.pop(context);
    }
  }
  
  //加密密码
  String encryptAES(String data, String keyString) {
    // 字符集
    String chars = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678";
    var random = Random();

    // 生成随机字符串
    String randomString(int length) {
      var result = StringBuffer();
      for (var i = 0; i < length; i++) {
        result.write(chars[random.nextInt(chars.length)]);
      }
      return result.toString();
    }

    // 生成64位随机前缀和16位IV
    String randomPrefix = randomString(64);
    String iv = randomString(16);

    // 准备加密所需的key和iv
    final key = encrypt.Key.fromUtf8(keyString.trim());
    final ivObj = encrypt.IV.fromUtf8(iv);

    // 创建AES加密器
    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        key,
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );

    // 加密数据(随机前缀+原始数据)
    final encrypted = encrypter.encrypt(randomPrefix + data, iv: ivObj);

    // 返回Base64编码的加密结果
    return encrypted.base64;
  }
}