import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';

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
    semestersName.clear();
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
          currentYearInt = 0;
          currentYearName = semestersName[0]['name'];
          currentExamBatch = 0;
          currentExamBatchName = '期末考试';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '切换考试时间',
                      style: TextStyle(
                        fontSize: GlobalVars.alertdialogTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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
                              if(semestersData['y$currentYearInt'].length < 2) {
                                currentTermInt = 1;
                              }
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
                      if(semestersData['y$currentYearInt'].length == 2)
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '确定',
                    style: TextStyle(
                      fontSize: GlobalVars.genericTextMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
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
                          ? AssetImage('assets/icons/lighttheme/exam.png')
                          : AssetImage('assets/icons/darktheme/exam.png'),
                        height: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '我的考试',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              
              // 考试类型选择卡片
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
                                      '类型：$currentExamBatchName', 
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
              // 无考试信息显示
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
              // 有考试信息显示
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
                              Flexible(
                                child: Text(
                                  '$currentYearName $currentTermName $currentExamBatchName',
                                  style: TextStyle(
                                    fontSize: GlobalVars.listTileTitle,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
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
      GlobalVars.operationCanceled = false;
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
                SizedBox(width: 8),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(loginAuthResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }

    if(GlobalVars.operationCanceled) {
      GlobalVars.operationCanceled = false;
      return;
    }
    List getStdExamResponse = await Modules.getStdExam(currentYearInt, currentTermInt, currentExamBatch);
    if(getStdExamResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(getStdExamResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }
     
    readSemesterInfo();
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('考试数据刷新成功'),
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