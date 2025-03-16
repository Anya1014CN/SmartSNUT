import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/AppPage/stdGrades/stdgrades_page.dart';
import 'package:smartsnut/globalvars.dart';


//用户数据
List stdAccount = [];
String userName = '';
String passWord = '';

//学期数据
Map semestersData = {};
int semesterTotal = 0;//学年的数量
List semestersName = [];

//菜单 Controller
final menuYearController = MenuController();
final menuTermController = MenuController();

//当前成绩学年
int currentYearInt = 1;
String currentYearName = '';

//当前成绩学期
int currentTermInt = 1;
String currentTermName = '';

//当前学期成绩信息
List stdGradesTotal = [];
bool noGrades = false;//用于判断该学期是否有成绩

//存储每门课的绩点
double courseGPATotal = 0;

class GPACalculatorPage extends StatefulWidget{
  const GPACalculatorPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GPACalculatorPageState();
  }
}

class _GPACalculatorPageState extends State<GPACalculatorPage>{
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
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/GPACalculator/selectedTY.json';
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
        });
      }
    }else{
      if(mounted){
        setState(() {
          currentYearInt = semestersData.length - 1;
          currentYearName = semestersName[semestersName.length - 1]['name'];
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
    readstdGrades();
  }

  //读取成绩信息
  readstdGrades() async  {
    //使用本地选中的 semetserid 来读取对应的成绩
    String semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();

    String stdGradespath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades/stdGrades$semesterId.json';
    File stdGradesfile = File(stdGradespath);
    if(await stdGradesfile.exists()){
      var readGradesTotal = jsonDecode(await stdGradesfile.readAsString());
      if(readGradesTotal.isEmpty){
        if(mounted){
          setState(() {
            noGrades = true;
          });
        }
      }else{
        if(mounted){
          stdGradesTotal = readGradesTotal;
          for(int i = 0;i < stdGradesTotal.length;i ++){
            courseGPATotal = courseGPATotal+ num.parse(stdGradesTotal[i]['CourseGradeGPA']);
          }
          setState(() {
            noGrades = false;
          });
        }
      }
    }else{
      if(mounted){
        setState(() {
          noGrades = true;
        });
      }
    }
  }
  
  ///保存选中的考试学期状态
  saveSelectedTY() async {

    //每次读取之前进行绩点计算器目录检查，防止后续版本升级，目录未被创建导致崩溃
    Directory gpaCalculatordirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/GPACalculator');
    if(await gpaCalculatordirectory.exists() == false){
      await gpaCalculatordirectory.create();
    }

    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/GPACalculator/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    List selectedTY = [];
    selectedTY.remove('selectedYear');
    selectedTY.remove('selectedTerm');
    selectedTY.add({
      'selectedYear': currentYearInt,
    });
    selectedTY.add({
      'selectedTerm': currentTermInt,
    });
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
            title: Text('切换成绩时间',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_title_title),),
            content: Column(
              children: [
                MenuAnchor(
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
                      child: Text('${item['name']} 学年',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_year_title),),
                    );
                  }).toList(),
                  child: SizedBox(
                    height: 50,
                    child: TextButton(
                      style: ElevatedButton.styleFrom(
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        if (menuYearController.isOpen) {
                          menuYearController.close();
                        } else {
                          menuYearController.open();
                        }
                      },
                      child: Text('学年：$currentYearName', style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_year_title),softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                Divider(height: 5, indent: 20, endIndent: 20),
                MenuAnchor(
                  controller: menuTermController,
                  menuChildren: [
                    MenuItemButton(
                      child: Text('第一学期',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_term_title),),
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
                      child: Text('第二学期',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_term_title),),
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
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        if (menuTermController.isOpen) {
                          menuTermController.close();
                        } else {
                          menuTermController.open();
                        }
                      },
                      child: Text('学期：$currentTermName', style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_term_title),softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
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
        onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => StdGradesPage()));},
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: Row(
          children: [
            Icon(Icons.open_in_new),
            SizedBox(width: 10,),
            Text('我的成绩',style: TextStyle(fontSize: GlobalVars.refreshcoursetable_button_title),)
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
                  )
                ],
                pinned: true,
                expandedHeight: 0,
                title: _showAppBarTitle ? Text("绩点计算器") : null,
              ),
            ];
          },
          body: ListView(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
                child: Row(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/calculator.png'):AssetImage('assets/icons/darktheme/calculator.png'),height: 40,),
                    SizedBox(width: 10,),
                    Text('绩点计算器',style: TextStyle(fontSize: GlobalVars.gpacalculator_page_title),)
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
                  child: Container(
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('算数平均绩点：${(courseGPATotal / stdGradesTotal.length).toStringAsFixed(3)} （保留 3 位小数）',style: TextStyle(fontSize: GlobalVars.gpacalculator_GPAtitle_title),),
                        SizedBox(height: 5,),
                        Text('本学期共 ${stdGradesTotal.length} 门课程',style: TextStyle(fontSize: GlobalVars.gpacalculator_GPAcontent_title),),
                      ],
                    ),
                  )
                ),
              ),
              noGrades? 
              Center(
                child: Container(
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Card(
                    shadowColor: Theme.of(context).colorScheme.onPrimary,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.error),
                      title: Text('暂无 成绩 信息',style: TextStyle(fontSize: GlobalVars.nostdgrade_hint_title,fontWeight: FontWeight.bold),),
                      subtitle: Text('当前学期：$currentYearName $currentTermName\n请尝试在右上角切换学期或在右下角前往 “我的成绩” 页面刷新成绩',style: TextStyle(fontSize: GlobalVars.nostdgrade_hint_subtitle),),
                    ),
                  ),
                ),
              ):
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: stdGradesTotal.map((grades) {
                    return Container(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('课程名称：${grades['CourseName']}',style: TextStyle(fontSize: GlobalVars.gpacalculator_coursename_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          SizedBox(height: 10,),
                          Text('学分：${grades['CourseCredit']}  最终：${grades['CourseGradeFinal']}  绩点：${grades['CourseGradeGPA']}',style: TextStyle(fontSize: GlobalVars.gpacalculator_coursename_content),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          Divider(height: 5,indent: 20,endIndent: 20,),
                        ],
                      ),
                    );
                  }).toList(),
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}