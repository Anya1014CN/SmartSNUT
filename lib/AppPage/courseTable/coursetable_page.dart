import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import 'package:smartsnut/globalvars.dart';

//保存查询状态
bool isQuerying = false;

//判断是否需要联网下载课表
bool needRefresh = false;

//学期信息
String termStart = '';
String termEnd = '';
int termWeeks = 0;
bool termEnded = false;

//周信息
int currentDOW = 0;

//课表滚动控制器
final ScrollController tableVerticalController = ScrollController();
final ScrollController tableHorizontalController = ScrollController();
double horizontalDragStart = 0.0;//支持鼠标直接拖拽课表

//定义课表的行高和列宽
double tableWidth = 0;
double tableHeadWidth = 0;
double tableHeight = 0;

//全年课表数据
List courseTableFull = [];//一学期的完整课表
List<List> courseMonTotal = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
List<List> courseTueTotal = [[],[],[],[],[],[],[],[],[],[]];//周二课程
List<List> courseWedTotal = [[],[],[],[],[],[],[],[],[],[]];//周三课程
List<List> courseThuTotal = [[],[],[],[],[],[],[],[],[],[]];//周四课程
List<List> courseFriTotal = [[],[],[],[],[],[],[],[],[],[]];//周五课程
List<List> courseSatTotal = [[],[],[],[],[],[],[],[],[],[]];//周六课程
List<List> courseSunTotal = [[],[],[],[],[],[],[],[],[],[]];//周日课程

//单周课表数据
List<List> courseMonWeek = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
List<List> courseTueWeek = [[],[],[],[],[],[],[],[],[],[]];//周二课程
List<List> courseWedWeek = [[],[],[],[],[],[],[],[],[],[]];//周三课程
List<List> courseThuWeek = [[],[],[],[],[],[],[],[],[],[]];//周四课程
List<List> courseFriWeek = [[],[],[],[],[],[],[],[],[],[]];//周五课程
List<List> courseSatWeek = [[],[],[],[],[],[],[],[],[],[]];//周六课程
List<List> courseSunWeek = [[],[],[],[],[],[],[],[],[],[]];//周日课程

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
final menuWeekController = MenuController();

//当前课表学年
int currentYearInt = 1;
String currentYearName = '';

//当前课表学期
int currentTermInt = 1;
String currentTermName = '';
bool noCourseTable = false;//用于判断该学期是否有课表

//当前课表信息
int currentWeekInt = 1;
late DateTime termStartDateTime;
late DateTime termEndDateTime;

//判断课表加载状态
bool isReading = true;

class CourseTablePage extends StatefulWidget{
  const CourseTablePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CourseTablePage();
  }
}

class _CourseTablePage extends State<CourseTablePage>{

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

  //读取课表的选中状态
  readSelectState() async {
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/selectedTY.json';
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
          needRefresh = true;
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
    if(needRefresh){
      getCourseTable();
    }else{
      readSchoolCalendarInfo();
    }
  }

  //读取校历相关信息
  readSchoolCalendarInfo() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String schoolCalendarpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar/schoolCalendar$semesterId.json';
    File schoolCalendarfile = File(schoolCalendarpath);
    if(await schoolCalendarfile.exists()){
      var termTimejson = jsonDecode(await schoolCalendarfile.readAsString());
      termStart = termTimejson[0]['termStart'];
      termEnd = termTimejson[0]['termEnd'];

      final dateFormat = DateFormat(r"yyyy'-'MM'-'dd");
      termStartDateTime = dateFormat.parse(termStart);
      termEndDateTime = dateFormat.parse(termEnd);
      termWeeks = termTimejson[0]['termWeeks'];
      int currentDay = DateTime.now().difference(termStartDateTime).inDays + 1;
      if(currentDay % 7 != 0){
        if(mounted){
          if((currentDay ~/ 7) + 1 > termWeeks){
            if(mounted){
              setState(() {
                termEnded = true;
                currentDOW = currentDay % 7;
              });
            }
          }else{
            if(mounted){
              setState(() {
                termEnded = false;
                currentWeekInt = (currentDay ~/ 7) + 1;
                currentDOW = currentDay % 7;
              });
            }
          }
        }
        saveSelectedTY();
      }if(currentDay % 7 == 0){
        if(mounted){
          if(currentDay ~/ 7 > termWeeks){
            if(mounted){
              setState(() {
                termEnded = true;
                currentDOW =  7;
              });
            }
          }else{
            if(mounted){
              setState(() {
                termEnded = false;
                currentWeekInt = currentDay ~/ 7;
                currentDOW =  7;
              });
            }
          }
        }
        saveSelectedTY();
      }
    }
    readCourseTabDetail();
  }

  ///保存选中的课表学期状态
  saveSelectedTY() async {
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    List selectedTY = [];
    selectedTY.remove('selectedYear');
    selectedTY.remove('selectedTerm');
    selectedTY.remove('selectedWeek');
    selectedTY.add({
      'selectedYear': currentYearInt,
    });
    selectedTY.add({
      'selectedTerm': currentTermInt,
    });
    selectedTYfile.writeAsString(jsonEncode(selectedTY));
  }

  //读取学期课表信息
  readCourseTabDetail() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String courseTablepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/courseTable$semesterId.json';
    File courseTablefile = File(courseTablepath);
    if(await courseTablefile.exists()){
      courseTableFull = jsonDecode(await courseTablefile.readAsString());
      if(mounted){
        setState(() {
          noCourseTable = false;
        });
      }
    }else{
      if(mounted){
        setState(() {
          noCourseTable = true;
        });
      }
    }
    //请求刷新课表之前先初始化课表
    courseMonTotal = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
    courseTueTotal = [[],[],[],[],[],[],[],[],[],[]];//周二课程
    courseWedTotal = [[],[],[],[],[],[],[],[],[],[]];//周三课程
    courseThuTotal = [[],[],[],[],[],[],[],[],[],[]];//周四课程
    courseFriTotal = [[],[],[],[],[],[],[],[],[],[]];//周五课程
    courseSatTotal = [[],[],[],[],[],[],[],[],[],[]];//周六课程
    courseSunTotal = [[],[],[],[],[],[],[],[],[],[]];//周日课程
    for(int courseint = 0; courseint < courseTableFull.length; courseint++){

      //处理课程的周数数据
        List<int> onePositions = [];

        // 记录所有 '1' 的索引
        for (int index = 0; index < courseTableFull[courseint]['CourseWeeks'].length; index++) {
          if (courseTableFull[courseint]['CourseWeeks'][index] == '1') {
            onePositions.add(index);
          }
        }

        // 处理相邻 '1' 的索引
        List<String> formattedResult = [];
        int rangeStart = onePositions[0];
        int rangeEnd = rangeStart;

        for (int position = 1; position < onePositions.length; position++) {
          if (onePositions[position] == onePositions[position - 1] + 1) {
            rangeEnd = onePositions[position];
          } else {
            formattedResult.add(rangeStart == rangeEnd ? "$rangeStart" : "$rangeStart-$rangeEnd");
            rangeStart = onePositions[position];
            rangeEnd = rangeStart;
          }
        }
        //最终的处理结果
        formattedResult.add(rangeStart == rangeEnd ? "$rangeStart" : "$rangeStart-$rangeEnd");

      //先判断课程在每一天的第几节
      for(int timesint = 1; timesint <= courseTableFull[courseint]['CourseTimes'].length; timesint++){
        //如果是每一天的第一节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 0){
          //如果是周一的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              //'CourseWeeks': formattedResult.join(",")
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第二节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 1){
          //如果是周一的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第三节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 2){
          //如果是周一的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第四节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 3){
          //如果是周一的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第五节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 4){
          //如果是周一的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第六节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 5){
          //如果是周一的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第七节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 6){
          //如果是周一的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第八节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 7){
          //如果是周一的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第九节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 8){
          //如果是周一的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
        //如果是每一天的第十节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 9){
          //如果是周一的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周二的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周三的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周四的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周五的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周六的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
          //如果是周日的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks']
            });
          }
        }
      }
    }
    readWeeklyCourseTableDetail();
  }

  //读取单周课表信息
  readWeeklyCourseTableDetail() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String courseTablepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/courseTable$semesterId.json';
    File courseTablefile = File(courseTablepath);
    if(await courseTablefile.exists()){
      courseTableFull = jsonDecode(await courseTablefile.readAsString());
      if(mounted){setState(() {});}
    }
    //请求刷新课表之前先初始化课表
    courseMonWeek = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
    courseTueWeek = [[],[],[],[],[],[],[],[],[],[]];//周二课程
    courseWedWeek = [[],[],[],[],[],[],[],[],[],[]];//周三课程
    courseThuWeek = [[],[],[],[],[],[],[],[],[],[]];//周四课程
    courseFriWeek = [[],[],[],[],[],[],[],[],[],[]];//周五课程
    courseSatWeek = [[],[],[],[],[],[],[],[],[],[]];//周六课程
    courseSunWeek = [[],[],[],[],[],[],[],[],[],[]];//周日课程

    //加载本周周一课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseMonTotal[courseTODInt].length;courseInt++){
        if(courseMonTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseMonWeek[courseTODInt].add({
              'CourseName': courseMonTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseMonTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseMonTotal[courseTODInt][courseInt]['CourseTeacher'],
          });
        }
      }
    }

    //加载本周周二课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseTueTotal[courseTODInt].length;courseInt++){
        if(courseTueTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseTueWeek[courseTODInt].add({
              'CourseName': courseTueTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseTueTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseTueTotal[courseTODInt][courseInt]['CourseTeacher'],
          });
        }
      }
    }

    //加载本周周三课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseWedTotal[courseTODInt].length;courseInt++){
        if(courseWedTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseWedWeek[courseTODInt].add({
              'CourseName': courseWedTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseWedTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseWedTotal[courseTODInt][courseInt]['CourseTeacher'],
          });
        }
      }
    }

    //加载本周周二课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseThuTotal[courseTODInt].length;courseInt++){
        if(courseThuTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseThuWeek[courseTODInt].add({
              'CourseName': courseThuTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseThuTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseThuTotal[courseTODInt][courseInt]['CourseTeacher'],
          });
        }
      }
    }

    //加载本周周三课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseFriTotal[courseTODInt].length;courseInt++){
        if(courseFriTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseFriWeek[courseTODInt].add({
              'CourseName': courseFriTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseFriTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseFriTotal[courseTODInt][courseInt]['CourseTeacher'],
          });
        }
      }
    }

    //加载本周周四课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseSatTotal[courseTODInt].length;courseInt++){
        if(courseSatTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseSatWeek[courseTODInt].add({
              'CourseName': courseSatTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseSatTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseSatTotal[courseTODInt][courseInt]['CourseTeacher'],
          });
        }
      }
    }

    //加载本周周五课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseSunTotal[courseTODInt].length;courseInt++){
        if(courseSunTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseSunWeek[courseTODInt].add({
              'CourseName': courseSunTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseSunTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseSunTotal[courseTODInt][courseInt]['CourseTeacher'],
          });
        }
      }
    }
    if(mounted){
      setState(() {
        isReading = false;
      });//全部解析完成之后刷新
    }
  }

  //切换课表学期
  switchTerm() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('切换课表时间',style: TextStyle(fontSize: GlobalVars.coursetableswitchterm_title_title),),
            content: Column(
              children: [
                MenuAnchor(
                  controller: menuYearController,
                  menuChildren: semestersName.map((item) {
                    return MenuItemButton(
                      onPressed: isQuerying ? null : () async {
                        int yearSelectedIndex = semestersName.indexOf(item);
                        if(mounted){
                          setState(() {
                            currentYearInt = yearSelectedIndex;
                            currentYearName = item['name'];
                          });
                        }
                        saveSelectedTY();
                        readSchoolCalendarInfo();
                        menuYearController.close();
                      },
                      child: Text('${item['name']} 学年',style: TextStyle(fontSize: GlobalVars.coursetableswitchterm_year_title),),
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
                      onPressed: isQuerying ? null : () {
                        if (menuYearController.isOpen) {
                          menuYearController.close();
                        } else {
                          menuYearController.open();
                        }
                      },
                      child: Text('当前学年：$currentYearName',style: TextStyle(fontSize: GlobalVars.coursetableswitchterm_year_title),),
                    ),
                  ),
                ),
                Divider(height: 5, indent: 20, endIndent: 20),
                MenuAnchor(
                  controller: menuTermController,
                  menuChildren: [
                    MenuItemButton(
                      child: Text('第一学期',style: TextStyle(fontSize: GlobalVars.coursetableswitchterm_term_title),),
                      onPressed: () async {
                        if(mounted){
                          setState(() {
                            currentTermInt = 1;
                            currentTermName = '第一学期';
                          });
                        }
                        saveSelectedTY();
                        readSchoolCalendarInfo();
                        menuTermController.close();
                      },
                    ),
                    MenuItemButton(
                      child: Text('第二学期',style: TextStyle(fontSize: GlobalVars.coursetableswitchterm_term_title),),
                      onPressed: () async {
                        if(mounted){
                          setState(() {
                            currentTermInt = 2;
                            currentTermName = '第二学期';
                          });
                        }
                        saveSelectedTY();
                        readSchoolCalendarInfo();
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
                      onPressed: isQuerying ? null : () {
                        if (menuTermController.isOpen) {
                          menuTermController.close();
                        } else {
                          menuTermController.open();
                        }
                      },
                      child: Text('当前学期：$currentTermName',style: TextStyle(fontSize: GlobalVars.coursetableswitchterm_term_title),),
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
    //清空学期列表
    semestersData = {};
    semestersName = [];
    super.initState();
    readStdAccount();
    readSemesterInfo();
  }

  @override
  Widget build(BuildContext context) {
    
    //获取长宽并保存
    tableWidth = (MediaQuery.of(context).size.width /7) - 3;
    tableHeight = ((MediaQuery.of(context).size.height) / 12) - 2;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => switchTerm(),
            icon: Icon(Icons.date_range),
          )
        ],
        title: Text('我的课表',style: TextStyle(fontSize: GlobalVars.coursetable_page_title),),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: IconButton(
          onPressed: (){Navigator.pop(context);},
          icon: Icon(Icons.close),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){getCourseTable();},
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: isQuerying? Row(
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary,),
            ),
            SizedBox(width: 10,),
            Text('正在刷新',style: TextStyle(fontSize: GlobalVars.refreshcoursetable_button_title),)
          ],
        ):
        Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 10,),
            Text('刷新课表',style: TextStyle(fontSize: GlobalVars.refreshcoursetable_button_title),)
          ],
        ),
      ),
      body: isReading? Center(child: CircularProgressIndicator(),):ListView(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
              shadowColor: Theme.of(context).colorScheme.onPrimary,
              color: Theme.of(context).colorScheme.surfaceDim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: (currentWeekInt == 1)? null:(){
                      if(mounted){
                        setState(() {
                          currentWeekInt --;
                        });
                      }
                      readWeeklyCourseTableDetail();
                      saveSelectedTY();
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                  termEnded? Text('第 $currentWeekInt 周\n（本学期已结束）',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetableweek_text_title),):Text('第 $currentWeekInt 周',style: TextStyle(fontSize: GlobalVars.coursetableweek_text_title),),
                  IconButton(
                    onPressed: (currentWeekInt == termWeeks)? null:(){
                      if(mounted){
                        setState(() {
                          currentWeekInt ++;
                        });
                      }
                      readWeeklyCourseTableDetail();
                      saveSelectedTY();
                    },
                    icon: Icon(Icons.arrow_forward),
                  ),
                ],
              )
            ),
          ),
          noCourseTable? 
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
                  title: Text('暂无 课表 信息',style: TextStyle(fontSize: GlobalVars.nocoursetable_hint_title,fontWeight: FontWeight.bold),),
                  subtitle: Text('当前学期：$currentYearName $currentTermName\n请尝试在右上角切换学期或在右下角刷新',style: TextStyle(fontSize: GlobalVars.nocoursetable_hint_subtitle),),
                ),
              ),
            ),
          ):
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                //表头 - 节次 + 星期几
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text('节\n次',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('一',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 1)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.coursetable_tablehead_title),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('二',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 2)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.coursetable_tablehead_title),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('三',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 3)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.coursetable_tablehead_title),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('四',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 4)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.coursetable_tablehead_title),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('五',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 5)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.coursetable_tablehead_title),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('六',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 6)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.coursetable_tablehead_title),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('日',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 7)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.coursetable_tablehead_title),),
                      )
                    ),
                  ],
                ),
                Divider(height: 5,indent: 20,endIndent: 20,),
                //表头 - 第几节课
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('1',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('2',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('3',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('4',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('5',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('6',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('7',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('8',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('9',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('10',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.coursetable_tablehead_title),),),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        //周一第一节
                        (courseMonWeek[0].isEmpty)?
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseMonWeek[0].isEmpty == courseMonWeek[1].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseMonWeek[3].isEmpty)? false:(courseMonWeek[0][0]['CourseName'] == courseMonWeek[3][0]['CourseName'] && courseMonWeek[0][0]['CourseLocation'] == courseMonWeek[3][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseMonWeek[2].isEmpty)? false:(courseMonWeek[0][0]['CourseName'] == courseMonWeek[2][0]['CourseName'] && courseMonWeek[0][0]['CourseLocation'] == courseMonWeek[2][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseMonWeek[1].isEmpty)? false:(courseMonWeek[0][0]['CourseName'] == courseMonWeek[1][0]['CourseName'] && courseMonWeek[0][0]['CourseLocation'] == courseMonWeek[1][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[0].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第二节
                        (courseMonWeek[1].isEmpty)? (courseMonWeek[0].isEmpty == courseMonWeek[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseMonWeek[0].isEmpty)? false:(courseMonWeek[0][0]['CourseName'] == courseMonWeek[1][0]['CourseName'] && courseMonWeek[0][0]['CourseLocation'] == courseMonWeek[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[1].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第三节
                        (courseMonWeek[2].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseMonWeek[2].isEmpty == courseMonWeek[3].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseMonWeek[0].isEmpty)? false:(courseMonWeek[0][0]['CourseName'] == courseMonWeek[2][0]['CourseName'] && courseMonWeek[0][0]['CourseLocation'] == courseMonWeek[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseMonWeek[3].isEmpty == false)? (courseMonWeek[2][0]['CourseName'] == courseMonWeek[3][0]['CourseName'] && courseMonWeek[3].isEmpty == false)? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[2].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第四节
                        (courseMonWeek[3].isEmpty)? (courseMonWeek[2].isEmpty == courseMonWeek[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseMonWeek[0].isEmpty)? false:(courseMonWeek[0][0]['CourseName'] == courseMonWeek[3][0]['CourseName'] && courseMonWeek[0][0]['CourseLocation'] == courseMonWeek[3][0]['CourseLocation'])) || ((courseMonWeek[2].isEmpty)? false:(courseMonWeek[2][0]['CourseName'] == courseMonWeek[3][0]['CourseName'] && courseMonWeek[2][0]['CourseLocation'] == courseMonWeek[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[3].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第五节
                        (courseMonWeek[4].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseMonWeek[4].isEmpty == courseMonWeek[5].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseMonWeek[7].isEmpty)? false:(courseMonWeek[4][0]['CourseName'] == courseMonWeek[7][0]['CourseName'] && courseMonWeek[4][0]['CourseLocation'] == courseMonWeek[7][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseMonWeek[6].isEmpty)? false:(courseMonWeek[4][0]['CourseName'] == courseMonWeek[6][0]['CourseName'] && courseMonWeek[4][0]['CourseLocation'] == courseMonWeek[6][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseMonWeek[5].isEmpty)? false:(courseMonWeek[4][0]['CourseName'] == courseMonWeek[5][0]['CourseName'] && courseMonWeek[4][0]['CourseLocation'] == courseMonWeek[5][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[4].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第六节
                        (courseMonWeek[5].isEmpty)?  (courseMonWeek[4].isEmpty == courseMonWeek[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseMonWeek[4].isEmpty)? false:(courseMonWeek[4][0]['CourseName'] == courseMonWeek[5][0]['CourseName'] && courseMonWeek[4][0]['CourseLocation'] == courseMonWeek[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[5].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList() 
                            ),
                          ),
                        ),
                        //周一第七节
                        (courseMonWeek[6].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseMonWeek[6].isEmpty == courseMonWeek[7].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseMonWeek[4].isEmpty)? false:(courseMonWeek[4][0]['CourseName'] == courseMonWeek[6][0]['CourseName'] && courseMonWeek[4][0]['CourseLocation'] == courseMonWeek[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseMonWeek[7].isEmpty == false)? (courseMonWeek[6][0]['CourseName'] == courseMonWeek[7][0]['CourseName'] && courseMonWeek[6][0]['CourseLocation'] == courseMonWeek[7][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[6].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第八节
                        (courseMonWeek[7].isEmpty)? (courseMonWeek[6].isEmpty == courseMonWeek[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseMonWeek[4].isEmpty)? false:(courseMonWeek[4][0]['CourseName'] == courseMonWeek[7][0]['CourseName'] && courseMonWeek[4][0]['CourseLocation'] == courseMonWeek[7][0]['CourseLocation'])) || ((courseMonWeek[6].isEmpty)? false:(courseMonWeek[6][0]['CourseName'] == courseMonWeek[7][0]['CourseName'] || courseMonWeek[6][0]['CourseLocation'] == courseMonWeek[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[7].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第九节
                        (courseMonWeek[8].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseMonWeek[8].isEmpty == courseMonWeek[9].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseMonWeek[9].isEmpty == false)? (courseMonWeek[8][0]['CourseName'] == courseMonWeek[9][0]['CourseName'] && courseMonWeek[8][0]['CourseLocation'] == courseMonWeek[9][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[8].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周一第十节
                        (courseMonWeek[9].isEmpty)? (courseMonWeek[8].isEmpty == courseMonWeek[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :((courseMonWeek[8].isEmpty)? false:(courseMonWeek[8][0]['CourseName'] == courseMonWeek[9][0]['CourseName'] || courseMonWeek[8][0]['CourseLocation'] == courseMonWeek[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseMonWeek[9].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 5,),
                                      Text('${item['CourseWeeks']}\n',style: TextStyle(fontSize: 12),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis)
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        //周二第一节
                        (courseTueWeek[0].isEmpty)?
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseTueWeek[0].isEmpty == courseTueWeek[1].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseTueWeek[3].isEmpty)? false:(courseTueWeek[0][0]['CourseName'] == courseTueWeek[3][0]['CourseName'] && courseTueWeek[0][0]['CourseLocation'] == courseTueWeek[3][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseTueWeek[2].isEmpty)? false:(courseTueWeek[0][0]['CourseName'] == courseTueWeek[2][0]['CourseName'] && courseTueWeek[0][0]['CourseLocation'] == courseTueWeek[2][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseTueWeek[1].isEmpty)? false:(courseTueWeek[0][0]['CourseName'] == courseTueWeek[1][0]['CourseName'] && courseTueWeek[0][0]['CourseLocation'] == courseTueWeek[1][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[0].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第二节
                        (courseTueWeek[1].isEmpty)? (courseTueWeek[0].isEmpty == courseTueWeek[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseTueWeek[0].isEmpty)? false:(courseTueWeek[0][0]['CourseName'] == courseTueWeek[1][0]['CourseName'] && courseTueWeek[0][0]['CourseLocation'] == courseTueWeek[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[1].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第三节
                        (courseTueWeek[2].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseTueWeek[2].isEmpty == courseTueWeek[3].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseTueWeek[0].isEmpty)? false:(courseTueWeek[0][0]['CourseName'] == courseTueWeek[2][0]['CourseName'] && courseTueWeek[0][0]['CourseLocation'] == courseTueWeek[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseTueWeek[3].isEmpty == false)? (courseTueWeek[2][0]['CourseName'] == courseTueWeek[3][0]['CourseName'] && courseTueWeek[3].isEmpty == false)? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[2].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第四节
                        (courseTueWeek[3].isEmpty)? (courseTueWeek[2].isEmpty == courseTueWeek[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseTueWeek[0].isEmpty)? false:(courseTueWeek[0][0]['CourseName'] == courseTueWeek[3][0]['CourseName'] && courseTueWeek[0][0]['CourseLocation'] == courseTueWeek[3][0]['CourseLocation'])) || ((courseTueWeek[2].isEmpty)? false:(courseTueWeek[2][0]['CourseName'] == courseTueWeek[3][0]['CourseName'] && courseTueWeek[2][0]['CourseLocation'] == courseTueWeek[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[3].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第五节
                        (courseTueWeek[4].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseTueWeek[4].isEmpty == courseTueWeek[5].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseTueWeek[7].isEmpty)? false:(courseTueWeek[4][0]['CourseName'] == courseTueWeek[7][0]['CourseName'] && courseTueWeek[4][0]['CourseLocation'] == courseTueWeek[7][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseTueWeek[6].isEmpty)? false:(courseTueWeek[4][0]['CourseName'] == courseTueWeek[6][0]['CourseName'] && courseTueWeek[4][0]['CourseLocation'] == courseTueWeek[6][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseTueWeek[5].isEmpty)? false:(courseTueWeek[4][0]['CourseName'] == courseTueWeek[5][0]['CourseName'] && courseTueWeek[4][0]['CourseLocation'] == courseTueWeek[5][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[4].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第六节
                        (courseTueWeek[5].isEmpty)?  (courseTueWeek[4].isEmpty == courseTueWeek[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseTueWeek[4].isEmpty)? false:(courseTueWeek[4][0]['CourseName'] == courseTueWeek[5][0]['CourseName'] && courseTueWeek[4][0]['CourseLocation'] == courseTueWeek[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[5].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList() 
                            ),
                          ),
                        ),
                        //周二第七节
                        (courseTueWeek[6].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseTueWeek[6].isEmpty == courseTueWeek[7].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseTueWeek[4].isEmpty)? false:(courseTueWeek[4][0]['CourseName'] == courseTueWeek[6][0]['CourseName'] && courseTueWeek[4][0]['CourseLocation'] == courseTueWeek[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseTueWeek[7].isEmpty == false)? (courseTueWeek[6][0]['CourseName'] == courseTueWeek[7][0]['CourseName'] && courseTueWeek[6][0]['CourseLocation'] == courseTueWeek[7][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[6].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第八节
                        (courseTueWeek[7].isEmpty)? (courseTueWeek[6].isEmpty == courseTueWeek[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseTueWeek[4].isEmpty)? false:(courseTueWeek[4][0]['CourseName'] == courseTueWeek[7][0]['CourseName'] && courseTueWeek[4][0]['CourseLocation'] == courseTueWeek[7][0]['CourseLocation'])) || ((courseTueWeek[6].isEmpty)? false:(courseTueWeek[6][0]['CourseName'] == courseTueWeek[7][0]['CourseName'] || courseTueWeek[6][0]['CourseLocation'] == courseTueWeek[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[7].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第九节
                        (courseTueWeek[8].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseTueWeek[8].isEmpty == courseTueWeek[9].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseTueWeek[9].isEmpty == false)? (courseTueWeek[8][0]['CourseName'] == courseTueWeek[9][0]['CourseName'] && courseTueWeek[8][0]['CourseLocation'] == courseTueWeek[9][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[8].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周二第十节
                        (courseTueWeek[9].isEmpty)? (courseTueWeek[8].isEmpty == courseTueWeek[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :((courseTueWeek[8].isEmpty)? false:(courseTueWeek[8][0]['CourseName'] == courseTueWeek[9][0]['CourseName'] || courseTueWeek[8][0]['CourseLocation'] == courseTueWeek[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseTueWeek[9].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 5,),
                                      Text('${item['CourseWeeks']}\n',style: TextStyle(fontSize: 12),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis)
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        //周三第一节
                        (courseWedWeek[0].isEmpty)?
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseWedWeek[0].isEmpty == courseWedWeek[1].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseWedWeek[3].isEmpty)? false:(courseWedWeek[0][0]['CourseName'] == courseWedWeek[3][0]['CourseName'] && courseWedWeek[0][0]['CourseLocation'] == courseWedWeek[3][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseWedWeek[2].isEmpty)? false:(courseWedWeek[0][0]['CourseName'] == courseWedWeek[2][0]['CourseName'] && courseWedWeek[0][0]['CourseLocation'] == courseWedWeek[2][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseWedWeek[1].isEmpty)? false:(courseWedWeek[0][0]['CourseName'] == courseWedWeek[1][0]['CourseName'] && courseWedWeek[0][0]['CourseLocation'] == courseWedWeek[1][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[0].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第二节
                        (courseWedWeek[1].isEmpty)? (courseWedWeek[0].isEmpty == courseWedWeek[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseWedWeek[0].isEmpty)? false:(courseWedWeek[0][0]['CourseName'] == courseWedWeek[1][0]['CourseName'] && courseWedWeek[0][0]['CourseLocation'] == courseWedWeek[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[1].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第三节
                        (courseWedWeek[2].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseWedWeek[2].isEmpty == courseWedWeek[3].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseWedWeek[0].isEmpty)? false:(courseWedWeek[0][0]['CourseName'] == courseWedWeek[2][0]['CourseName'] && courseWedWeek[0][0]['CourseLocation'] == courseWedWeek[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseWedWeek[3].isEmpty == false)? (courseWedWeek[2][0]['CourseName'] == courseWedWeek[3][0]['CourseName'] && courseWedWeek[3].isEmpty == false)? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[2].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第四节
                        (courseWedWeek[3].isEmpty)? (courseWedWeek[2].isEmpty == courseWedWeek[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseWedWeek[0].isEmpty)? false:(courseWedWeek[0][0]['CourseName'] == courseWedWeek[3][0]['CourseName'] && courseWedWeek[0][0]['CourseLocation'] == courseWedWeek[3][0]['CourseLocation'])) || ((courseWedWeek[2].isEmpty)? false:(courseWedWeek[2][0]['CourseName'] == courseWedWeek[3][0]['CourseName'] && courseWedWeek[2][0]['CourseLocation'] == courseWedWeek[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[3].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第五节
                        (courseWedWeek[4].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseWedWeek[4].isEmpty == courseWedWeek[5].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseWedWeek[7].isEmpty)? false:(courseWedWeek[4][0]['CourseName'] == courseWedWeek[7][0]['CourseName'] && courseWedWeek[4][0]['CourseLocation'] == courseWedWeek[7][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseWedWeek[6].isEmpty)? false:(courseWedWeek[4][0]['CourseName'] == courseWedWeek[6][0]['CourseName'] && courseWedWeek[4][0]['CourseLocation'] == courseWedWeek[6][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseWedWeek[5].isEmpty)? false:(courseWedWeek[4][0]['CourseName'] == courseWedWeek[5][0]['CourseName'] && courseWedWeek[4][0]['CourseLocation'] == courseWedWeek[5][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[4].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第六节
                        (courseWedWeek[5].isEmpty)?  (courseWedWeek[4].isEmpty == courseWedWeek[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseWedWeek[4].isEmpty)? false:(courseWedWeek[4][0]['CourseName'] == courseWedWeek[5][0]['CourseName'] && courseWedWeek[4][0]['CourseLocation'] == courseWedWeek[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[5].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList() 
                            ),
                          ),
                        ),
                        //周三第七节
                        (courseWedWeek[6].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseWedWeek[6].isEmpty == courseWedWeek[7].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseWedWeek[4].isEmpty)? false:(courseWedWeek[4][0]['CourseName'] == courseWedWeek[6][0]['CourseName'] && courseWedWeek[4][0]['CourseLocation'] == courseWedWeek[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseWedWeek[7].isEmpty == false)? (courseWedWeek[6][0]['CourseName'] == courseWedWeek[7][0]['CourseName'] && courseWedWeek[6][0]['CourseLocation'] == courseWedWeek[7][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[6].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第八节
                        (courseWedWeek[7].isEmpty)? (courseWedWeek[6].isEmpty == courseWedWeek[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseWedWeek[4].isEmpty)? false:(courseWedWeek[4][0]['CourseName'] == courseWedWeek[7][0]['CourseName'] && courseWedWeek[4][0]['CourseLocation'] == courseWedWeek[7][0]['CourseLocation'])) || ((courseWedWeek[6].isEmpty)? false:(courseWedWeek[6][0]['CourseName'] == courseWedWeek[7][0]['CourseName'] || courseWedWeek[6][0]['CourseLocation'] == courseWedWeek[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[7].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第九节
                        (courseWedWeek[8].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseWedWeek[8].isEmpty == courseWedWeek[9].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseWedWeek[9].isEmpty == false)? (courseWedWeek[8][0]['CourseName'] == courseWedWeek[9][0]['CourseName'] && courseWedWeek[8][0]['CourseLocation'] == courseWedWeek[9][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[8].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周三第十节
                        (courseWedWeek[9].isEmpty)? (courseWedWeek[8].isEmpty == courseWedWeek[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :((courseWedWeek[8].isEmpty)? false:(courseWedWeek[8][0]['CourseName'] == courseWedWeek[9][0]['CourseName'] || courseWedWeek[8][0]['CourseLocation'] == courseWedWeek[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseWedWeek[9].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 5,),
                                      Text('${item['CourseWeeks']}\n',style: TextStyle(fontSize: 12),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis)
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        //周四第一节
                        (courseThuWeek[0].isEmpty)?
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseThuWeek[0].isEmpty == courseThuWeek[1].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseThuWeek[3].isEmpty)? false:(courseThuWeek[0][0]['CourseName'] == courseThuWeek[3][0]['CourseName'] && courseThuWeek[0][0]['CourseLocation'] == courseThuWeek[3][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseThuWeek[2].isEmpty)? false:(courseThuWeek[0][0]['CourseName'] == courseThuWeek[2][0]['CourseName'] && courseThuWeek[0][0]['CourseLocation'] == courseThuWeek[2][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseThuWeek[1].isEmpty)? false:(courseThuWeek[0][0]['CourseName'] == courseThuWeek[1][0]['CourseName'] && courseThuWeek[0][0]['CourseLocation'] == courseThuWeek[1][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[0].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第二节
                        (courseThuWeek[1].isEmpty)? (courseThuWeek[0].isEmpty == courseThuWeek[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseThuWeek[0].isEmpty)? false:(courseThuWeek[0][0]['CourseName'] == courseThuWeek[1][0]['CourseName'] && courseThuWeek[0][0]['CourseLocation'] == courseThuWeek[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[1].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第三节
                        (courseThuWeek[2].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseThuWeek[2].isEmpty == courseThuWeek[3].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseThuWeek[0].isEmpty)? false:(courseThuWeek[0][0]['CourseName'] == courseThuWeek[2][0]['CourseName'] && courseThuWeek[0][0]['CourseLocation'] == courseThuWeek[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseThuWeek[3].isEmpty == false)? (courseThuWeek[2][0]['CourseName'] == courseThuWeek[3][0]['CourseName'] && courseThuWeek[3].isEmpty == false)? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[2].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第四节
                        (courseThuWeek[3].isEmpty)? (courseThuWeek[2].isEmpty == courseThuWeek[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseThuWeek[0].isEmpty)? false:(courseThuWeek[0][0]['CourseName'] == courseThuWeek[3][0]['CourseName'] && courseThuWeek[0][0]['CourseLocation'] == courseThuWeek[3][0]['CourseLocation'])) || ((courseThuWeek[2].isEmpty)? false:(courseThuWeek[2][0]['CourseName'] == courseThuWeek[3][0]['CourseName'] && courseThuWeek[2][0]['CourseLocation'] == courseThuWeek[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[3].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第五节
                        (courseThuWeek[4].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseThuWeek[4].isEmpty == courseThuWeek[5].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseThuWeek[7].isEmpty)? false:(courseThuWeek[4][0]['CourseName'] == courseThuWeek[7][0]['CourseName'] && courseThuWeek[4][0]['CourseLocation'] == courseThuWeek[7][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseThuWeek[6].isEmpty)? false:(courseThuWeek[4][0]['CourseName'] == courseThuWeek[6][0]['CourseName'] && courseThuWeek[4][0]['CourseLocation'] == courseThuWeek[6][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseThuWeek[5].isEmpty)? false:(courseThuWeek[4][0]['CourseName'] == courseThuWeek[5][0]['CourseName'] && courseThuWeek[4][0]['CourseLocation'] == courseThuWeek[5][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[4].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第六节
                        (courseThuWeek[5].isEmpty)?  (courseThuWeek[4].isEmpty == courseThuWeek[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseThuWeek[4].isEmpty)? false:(courseThuWeek[4][0]['CourseName'] == courseThuWeek[5][0]['CourseName'] && courseThuWeek[4][0]['CourseLocation'] == courseThuWeek[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[5].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList() 
                            ),
                          ),
                        ),
                        //周四第七节
                        (courseThuWeek[6].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseThuWeek[6].isEmpty == courseThuWeek[7].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseThuWeek[4].isEmpty)? false:(courseThuWeek[4][0]['CourseName'] == courseThuWeek[6][0]['CourseName'] && courseThuWeek[4][0]['CourseLocation'] == courseThuWeek[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseThuWeek[7].isEmpty == false)? (courseThuWeek[6][0]['CourseName'] == courseThuWeek[7][0]['CourseName'] && courseThuWeek[6][0]['CourseLocation'] == courseThuWeek[7][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[6].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第八节
                        (courseThuWeek[7].isEmpty)? (courseThuWeek[6].isEmpty == courseThuWeek[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseThuWeek[4].isEmpty)? false:(courseThuWeek[4][0]['CourseName'] == courseThuWeek[7][0]['CourseName'] && courseThuWeek[4][0]['CourseLocation'] == courseThuWeek[7][0]['CourseLocation'])) || ((courseThuWeek[6].isEmpty)? false:(courseThuWeek[6][0]['CourseName'] == courseThuWeek[7][0]['CourseName'] || courseThuWeek[6][0]['CourseLocation'] == courseThuWeek[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[7].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第九节
                        (courseThuWeek[8].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseThuWeek[8].isEmpty == courseThuWeek[9].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseThuWeek[9].isEmpty == false)? (courseThuWeek[8][0]['CourseName'] == courseThuWeek[9][0]['CourseName'] && courseThuWeek[8][0]['CourseLocation'] == courseThuWeek[9][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[8].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周四第十节
                        (courseThuWeek[9].isEmpty)? (courseThuWeek[8].isEmpty == courseThuWeek[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :((courseThuWeek[8].isEmpty)? false:(courseThuWeek[8][0]['CourseName'] == courseThuWeek[9][0]['CourseName'] || courseThuWeek[8][0]['CourseLocation'] == courseThuWeek[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseThuWeek[9].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 5,),
                                      Text('${item['CourseWeeks']}\n',style: TextStyle(fontSize: 12),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis)
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        //周五第一节
                        (courseFriWeek[0].isEmpty)?
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseFriWeek[0].isEmpty == courseFriWeek[1].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseFriWeek[3].isEmpty)? false:(courseFriWeek[0][0]['CourseName'] == courseFriWeek[3][0]['CourseName'] && courseFriWeek[0][0]['CourseLocation'] == courseFriWeek[3][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseFriWeek[2].isEmpty)? false:(courseFriWeek[0][0]['CourseName'] == courseFriWeek[2][0]['CourseName'] && courseFriWeek[0][0]['CourseLocation'] == courseFriWeek[2][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseFriWeek[1].isEmpty)? false:(courseFriWeek[0][0]['CourseName'] == courseFriWeek[1][0]['CourseName'] && courseFriWeek[0][0]['CourseLocation'] == courseFriWeek[1][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[0].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第二节
                        (courseFriWeek[1].isEmpty)? (courseFriWeek[0].isEmpty == courseFriWeek[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseFriWeek[0].isEmpty)? false:(courseFriWeek[0][0]['CourseName'] == courseFriWeek[1][0]['CourseName'] && courseFriWeek[0][0]['CourseLocation'] == courseFriWeek[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[1].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第三节
                        (courseFriWeek[2].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseFriWeek[2].isEmpty == courseFriWeek[3].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseFriWeek[0].isEmpty)? false:(courseFriWeek[0][0]['CourseName'] == courseFriWeek[2][0]['CourseName'] && courseFriWeek[0][0]['CourseLocation'] == courseFriWeek[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseFriWeek[3].isEmpty == false)? (courseFriWeek[2][0]['CourseName'] == courseFriWeek[3][0]['CourseName'] && courseFriWeek[3].isEmpty == false)? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[2].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第四节
                        (courseFriWeek[3].isEmpty)? (courseFriWeek[2].isEmpty == courseFriWeek[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseFriWeek[0].isEmpty)? false:(courseFriWeek[0][0]['CourseName'] == courseFriWeek[3][0]['CourseName'] && courseFriWeek[0][0]['CourseLocation'] == courseFriWeek[3][0]['CourseLocation'])) || ((courseFriWeek[2].isEmpty)? false:(courseFriWeek[2][0]['CourseName'] == courseFriWeek[3][0]['CourseName'] && courseFriWeek[2][0]['CourseLocation'] == courseFriWeek[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[3].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第五节
                        (courseFriWeek[4].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseFriWeek[4].isEmpty == courseFriWeek[5].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseFriWeek[7].isEmpty)? false:(courseFriWeek[4][0]['CourseName'] == courseFriWeek[7][0]['CourseName'] && courseFriWeek[4][0]['CourseLocation'] == courseFriWeek[7][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseFriWeek[6].isEmpty)? false:(courseFriWeek[4][0]['CourseName'] == courseFriWeek[6][0]['CourseName'] && courseFriWeek[4][0]['CourseLocation'] == courseFriWeek[6][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseFriWeek[5].isEmpty)? false:(courseFriWeek[4][0]['CourseName'] == courseFriWeek[5][0]['CourseName'] && courseFriWeek[4][0]['CourseLocation'] == courseFriWeek[5][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[4].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第六节
                        (courseFriWeek[5].isEmpty)?  (courseFriWeek[4].isEmpty == courseFriWeek[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseFriWeek[4].isEmpty)? false:(courseFriWeek[4][0]['CourseName'] == courseFriWeek[5][0]['CourseName'] && courseFriWeek[4][0]['CourseLocation'] == courseFriWeek[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[5].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList() 
                            ),
                          ),
                        ),
                        //周五第七节
                        (courseFriWeek[6].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseFriWeek[6].isEmpty == courseFriWeek[7].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseFriWeek[4].isEmpty)? false:(courseFriWeek[4][0]['CourseName'] == courseFriWeek[6][0]['CourseName'] && courseFriWeek[4][0]['CourseLocation'] == courseFriWeek[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseFriWeek[7].isEmpty == false)? (courseFriWeek[6][0]['CourseName'] == courseFriWeek[7][0]['CourseName'] && courseFriWeek[6][0]['CourseLocation'] == courseFriWeek[7][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[6].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第八节
                        (courseFriWeek[7].isEmpty)? (courseFriWeek[6].isEmpty == courseFriWeek[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseFriWeek[4].isEmpty)? false:(courseFriWeek[4][0]['CourseName'] == courseFriWeek[7][0]['CourseName'] && courseFriWeek[4][0]['CourseLocation'] == courseFriWeek[7][0]['CourseLocation'])) || ((courseFriWeek[6].isEmpty)? false:(courseFriWeek[6][0]['CourseName'] == courseFriWeek[7][0]['CourseName'] || courseFriWeek[6][0]['CourseLocation'] == courseFriWeek[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[7].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第九节
                        (courseFriWeek[8].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseFriWeek[8].isEmpty == courseFriWeek[9].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseFriWeek[9].isEmpty == false)? (courseFriWeek[8][0]['CourseName'] == courseFriWeek[9][0]['CourseName'] && courseFriWeek[8][0]['CourseLocation'] == courseFriWeek[9][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[8].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周五第十节
                        (courseFriWeek[9].isEmpty)? (courseFriWeek[8].isEmpty == courseFriWeek[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :((courseFriWeek[8].isEmpty)? false:(courseFriWeek[8][0]['CourseName'] == courseFriWeek[9][0]['CourseName'] || courseFriWeek[8][0]['CourseLocation'] == courseFriWeek[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseFriWeek[9].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 5,),
                                      Text('${item['CourseWeeks']}\n',style: TextStyle(fontSize: 12),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis)
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        //周六第一节
                        (courseSatWeek[0].isEmpty)?
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSatWeek[0].isEmpty == courseSatWeek[1].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseSatWeek[3].isEmpty)? false:(courseSatWeek[0][0]['CourseName'] == courseSatWeek[3][0]['CourseName'] && courseSatWeek[0][0]['CourseLocation'] == courseSatWeek[3][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseSatWeek[2].isEmpty)? false:(courseSatWeek[0][0]['CourseName'] == courseSatWeek[2][0]['CourseName'] && courseSatWeek[0][0]['CourseLocation'] == courseSatWeek[2][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseSatWeek[1].isEmpty)? false:(courseSatWeek[0][0]['CourseName'] == courseSatWeek[1][0]['CourseName'] && courseSatWeek[0][0]['CourseLocation'] == courseSatWeek[1][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[0].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第二节
                        (courseSatWeek[1].isEmpty)? (courseSatWeek[0].isEmpty == courseSatWeek[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSatWeek[0].isEmpty)? false:(courseSatWeek[0][0]['CourseName'] == courseSatWeek[1][0]['CourseName'] && courseSatWeek[0][0]['CourseLocation'] == courseSatWeek[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[1].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第三节
                        (courseSatWeek[2].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSatWeek[2].isEmpty == courseSatWeek[3].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseSatWeek[0].isEmpty)? false:(courseSatWeek[0][0]['CourseName'] == courseSatWeek[2][0]['CourseName'] && courseSatWeek[0][0]['CourseLocation'] == courseSatWeek[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseSatWeek[3].isEmpty == false)? (courseSatWeek[2][0]['CourseName'] == courseSatWeek[3][0]['CourseName'] && courseSatWeek[3].isEmpty == false)? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[2].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第四节
                        (courseSatWeek[3].isEmpty)? (courseSatWeek[2].isEmpty == courseSatWeek[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSatWeek[0].isEmpty)? false:(courseSatWeek[0][0]['CourseName'] == courseSatWeek[3][0]['CourseName'] && courseSatWeek[0][0]['CourseLocation'] == courseSatWeek[3][0]['CourseLocation'])) || ((courseSatWeek[2].isEmpty)? false:(courseSatWeek[2][0]['CourseName'] == courseSatWeek[3][0]['CourseName'] && courseSatWeek[2][0]['CourseLocation'] == courseSatWeek[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[3].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第五节
                        (courseSatWeek[4].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSatWeek[4].isEmpty == courseSatWeek[5].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseSatWeek[7].isEmpty)? false:(courseSatWeek[4][0]['CourseName'] == courseSatWeek[7][0]['CourseName'] && courseSatWeek[4][0]['CourseLocation'] == courseSatWeek[7][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseSatWeek[6].isEmpty)? false:(courseSatWeek[4][0]['CourseName'] == courseSatWeek[6][0]['CourseName'] && courseSatWeek[4][0]['CourseLocation'] == courseSatWeek[6][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseSatWeek[5].isEmpty)? false:(courseSatWeek[4][0]['CourseName'] == courseSatWeek[5][0]['CourseName'] && courseSatWeek[4][0]['CourseLocation'] == courseSatWeek[5][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[4].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第六节
                        (courseSatWeek[5].isEmpty)?  (courseSatWeek[4].isEmpty == courseSatWeek[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSatWeek[4].isEmpty)? false:(courseSatWeek[4][0]['CourseName'] == courseSatWeek[5][0]['CourseName'] && courseSatWeek[4][0]['CourseLocation'] == courseSatWeek[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[5].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList() 
                            ),
                          ),
                        ),
                        //周六第七节
                        (courseSatWeek[6].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSatWeek[6].isEmpty == courseSatWeek[7].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseSatWeek[4].isEmpty)? false:(courseSatWeek[4][0]['CourseName'] == courseSatWeek[6][0]['CourseName'] && courseSatWeek[4][0]['CourseLocation'] == courseSatWeek[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseSatWeek[7].isEmpty == false)? (courseSatWeek[6][0]['CourseName'] == courseSatWeek[7][0]['CourseName'] && courseSatWeek[6][0]['CourseLocation'] == courseSatWeek[7][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[6].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第八节
                        (courseSatWeek[7].isEmpty)? (courseSatWeek[6].isEmpty == courseSatWeek[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSatWeek[4].isEmpty)? false:(courseSatWeek[4][0]['CourseName'] == courseSatWeek[7][0]['CourseName'] && courseSatWeek[4][0]['CourseLocation'] == courseSatWeek[7][0]['CourseLocation'])) || ((courseSatWeek[6].isEmpty)? false:(courseSatWeek[6][0]['CourseName'] == courseSatWeek[7][0]['CourseName'] || courseSatWeek[6][0]['CourseLocation'] == courseSatWeek[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[7].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第九节
                        (courseSatWeek[8].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSatWeek[8].isEmpty == courseSatWeek[9].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseSatWeek[9].isEmpty == false)? (courseSatWeek[8][0]['CourseName'] == courseSatWeek[9][0]['CourseName'] && courseSatWeek[8][0]['CourseLocation'] == courseSatWeek[9][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[8].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周六第十节
                        (courseSatWeek[9].isEmpty)? (courseSatWeek[8].isEmpty == courseSatWeek[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :((courseSatWeek[8].isEmpty)? false:(courseSatWeek[8][0]['CourseName'] == courseSatWeek[9][0]['CourseName'] || courseSatWeek[8][0]['CourseLocation'] == courseSatWeek[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSatWeek[9].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 5,),
                                      Text('${item['CourseWeeks']}\n',style: TextStyle(fontSize: 12),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis)
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        //周日第一节
                        (courseSunWeek[0].isEmpty)?
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSunWeek[0].isEmpty == courseSunWeek[1].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseSunWeek[3].isEmpty)? false:(courseSunWeek[0][0]['CourseName'] == courseSunWeek[3][0]['CourseName'] && courseSunWeek[0][0]['CourseLocation'] == courseSunWeek[3][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseSunWeek[2].isEmpty)? false:(courseSunWeek[0][0]['CourseName'] == courseSunWeek[2][0]['CourseName'] && courseSunWeek[0][0]['CourseLocation'] == courseSunWeek[2][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseSunWeek[1].isEmpty)? false:(courseSunWeek[0][0]['CourseName'] == courseSunWeek[1][0]['CourseName'] && courseSunWeek[0][0]['CourseLocation'] == courseSunWeek[1][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[0].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第二节
                        (courseSunWeek[1].isEmpty)? (courseSunWeek[0].isEmpty == courseSunWeek[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSunWeek[0].isEmpty)? false:(courseSunWeek[0][0]['CourseName'] == courseSunWeek[1][0]['CourseName'] && courseSunWeek[0][0]['CourseLocation'] == courseSunWeek[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[1].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第三节
                        (courseSunWeek[2].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSunWeek[2].isEmpty == courseSunWeek[3].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseSunWeek[0].isEmpty)? false:(courseSunWeek[0][0]['CourseName'] == courseSunWeek[2][0]['CourseName'] && courseSunWeek[0][0]['CourseLocation'] == courseSunWeek[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseSunWeek[3].isEmpty == false)? (courseSunWeek[2][0]['CourseName'] == courseSunWeek[3][0]['CourseName'] && courseSunWeek[3].isEmpty == false)? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[2].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第四节
                        (courseSunWeek[3].isEmpty)? (courseSunWeek[2].isEmpty == courseSunWeek[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSunWeek[0].isEmpty)? false:(courseSunWeek[0][0]['CourseName'] == courseSunWeek[3][0]['CourseName'] && courseSunWeek[0][0]['CourseLocation'] == courseSunWeek[3][0]['CourseLocation'])) || ((courseSunWeek[2].isEmpty)? false:(courseSunWeek[2][0]['CourseName'] == courseSunWeek[3][0]['CourseName'] && courseSunWeek[2][0]['CourseLocation'] == courseSunWeek[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[3].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第五节
                        (courseSunWeek[4].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSunWeek[4].isEmpty == courseSunWeek[5].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: ((courseSunWeek[7].isEmpty)? false:(courseSunWeek[4][0]['CourseName'] == courseSunWeek[7][0]['CourseName'] && courseSunWeek[4][0]['CourseLocation'] == courseSunWeek[7][0]['CourseLocation'])? true:false)? tableHeight*4:
                              ((courseSunWeek[6].isEmpty)? false:(courseSunWeek[4][0]['CourseName'] == courseSunWeek[6][0]['CourseName'] && courseSunWeek[4][0]['CourseLocation'] == courseSunWeek[6][0]['CourseLocation'])? true:false)? tableHeight*3:
                              ((courseSunWeek[5].isEmpty)? false:(courseSunWeek[4][0]['CourseName'] == courseSunWeek[5][0]['CourseName'] && courseSunWeek[4][0]['CourseLocation'] == courseSunWeek[5][0]['CourseLocation'])? true:false)? tableHeight*2:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[4].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第六节
                        (courseSunWeek[5].isEmpty)?  (courseSunWeek[4].isEmpty == courseSunWeek[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSunWeek[4].isEmpty)? false:(courseSunWeek[4][0]['CourseName'] == courseSunWeek[5][0]['CourseName'] && courseSunWeek[4][0]['CourseLocation'] == courseSunWeek[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[5].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList() 
                            ),
                          ),
                        ),
                        //周日第七节
                        (courseSunWeek[6].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSunWeek[6].isEmpty == courseSunWeek[7].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :(((courseSunWeek[4].isEmpty)? false:(courseSunWeek[4][0]['CourseName'] == courseSunWeek[6][0]['CourseName'] && courseSunWeek[4][0]['CourseLocation'] == courseSunWeek[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseSunWeek[7].isEmpty == false)? (courseSunWeek[6][0]['CourseName'] == courseSunWeek[7][0]['CourseName'] && courseSunWeek[6][0]['CourseLocation'] == courseSunWeek[7][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[6].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第八节
                        (courseSunWeek[7].isEmpty)? (courseSunWeek[6].isEmpty == courseSunWeek[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :(((courseSunWeek[4].isEmpty)? false:(courseSunWeek[4][0]['CourseName'] == courseSunWeek[7][0]['CourseName'] && courseSunWeek[4][0]['CourseLocation'] == courseSunWeek[7][0]['CourseLocation'])) || ((courseSunWeek[6].isEmpty)? false:(courseSunWeek[6][0]['CourseName'] == courseSunWeek[7][0]['CourseName'] || courseSunWeek[6][0]['CourseLocation'] == courseSunWeek[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[7].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第九节
                        (courseSunWeek[8].isEmpty)? 
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: (courseSunWeek[8].isEmpty == courseSunWeek[9].isEmpty)? tableHeight*2 : tableHeight,
                          )
                        )
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height:(courseSunWeek[9].isEmpty == false)? (courseSunWeek[8][0]['CourseName'] == courseSunWeek[9][0]['CourseName'] && courseSunWeek[8][0]['CourseLocation'] == courseSunWeek[9][0]['CourseLocation'])? tableHeight*2:tableHeight:
                              tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[8].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                        //周日第十节
                        (courseSunWeek[9].isEmpty)? (courseSunWeek[8].isEmpty == courseSunWeek[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(width: tableWidth,height: tableHeight,)
                        )
                        :((courseSunWeek[8].isEmpty)? false:(courseSunWeek[8][0]['CourseName'] == courseSunWeek[9][0]['CourseName'] || courseSunWeek[8][0]['CourseLocation'] == courseSunWeek[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :Card(
                          child: SizedBox(
                            width: tableWidth,
                            height: tableHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: courseSunWeek[9].map((item) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${item['CourseName']}',style: TextStyle(fontSize: GlobalVars.coursetable_coursename_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 10,),
                                      Text('${item['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.coursetable_courselocation_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                      SizedBox(height: 5,),
                                      Text('${item['CourseWeeks']}\n',style: TextStyle(fontSize: 12),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,)
                                  ],
                                );
                              }).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(padding: EdgeInsets.fromLTRB(0, 80, 0, 0),)
         ],
      ),
    );
  }

  getCourseTable() async {
    if(mounted){
      setState(() {
        isQuerying = true;
      });
    }
    
    //课表数据目录
    Directory courseTableStddirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd');
    if(await courseTableStddirectory.exists() == false){
      await courseTableStddirectory.create();
    }

    String? passwordhash = '';//存储 Hash
    String encryptedpassword = '';//加密后的密码

    //初始化 Dio
    CookieJar jwglcookie = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(jwglcookie));

    //第一次请求，获取 hash
    var response1;
    try{
      response1 = await dio.get('http://jwgl.snut.edu.cn/eams/loginExt.action');
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
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

    String jwglcode = response1.data.toString();
    RegExp regExp = RegExp(r"SHA1\('([0-9a-fA-F\-]+)-");
    Match? match = regExp.firstMatch(jwglcode);
      
    if (match != null) {
      passwordhash = match.group(1);
    } else {
      return;
    }

    // **对密码进行加密**
    var combinedpassword = utf8.encode('$passwordhash-$passWord');
    var digest = sha1.convert(combinedpassword);
    encryptedpassword = digest.toString();

    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    //第二次请求，尝试登录
    final formData = FormData.fromMap({
      "username": userName,
      "password": encryptedpassword,
      "session_locale": "zh_CN"
    });

    Response response2 = await dio.post(
      'http://jwgl.snut.edu.cn/eams/loginExt.action',
      options: Options(
        followRedirects: true,
        validateStatus: (Status){
          return Status != null && Status <= 302;
        },
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "PostmanRuntime/7.43.0",
        }
      ),
      data: formData,
    );
    String response2string = response2.data.toString();
    if(response2string.contains('账户不存在')){
    if(mounted){
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
          content: Text('登录失败，账户不存在\n您的账户是否因毕业等原因被校方注销？',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setState(() {
        isQuerying = false;
      });
    }
    return;
    }if(response2string.contains('密码错误')){
    if(mounted){
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
          content: Text('登录失败，密码错误\n您是否在学校官网修改过密码？\n如果是，请退出智慧陕理并重新登录',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
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
    
    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    //请求课表初始信息
    var courseresponse1;
    try{
      courseresponse1 = await dio.get('http://jwgl.snut.edu.cn/eams/courseTableForStd.action');
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
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
    //提取相关数据
    String semesterId = '';
    String tagId = '';
    String idsMe = '';
    String idsClass = '';

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(courseresponse1.headers['Set-Cookie'][0].toString());
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    RegExp tagIdExp = RegExp(r'semesterBar(\d+)Semester');
    Match? tagIdmatch = tagIdExp.firstMatch(courseresponse1.data.toString());
    if(tagIdmatch != null){
      tagId = tagIdmatch.group(1)!;
    }

    RegExp idsExp = RegExp(r'bg\.form\.addInput\(form,"ids","(\d+)"\)');
    Iterable<Match> idsmatch = idsExp.allMatches(courseresponse1.data);
    if(idsmatch.length >=2 ){
      idsMe = idsmatch.elementAt(0).group(1)!;
      idsClass = idsmatch.elementAt(1).group(1)!;
    }

    //获取所有学期的 semester.id，学年名称，学期名称
    final courseTableformData = FormData.fromMap({
      "tagId": 'semesterBar${tagId}Semester',
      "dataType": 'semesterCalendar',
      "value": semesterId.toString(),
      "empty": 'false'
    });
    var courseresponse2;
    try{
      courseresponse2 = await dio.post(
      'http://jwgl.snut.edu.cn/eams/dataQuery.action',
      options: Options(
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "PostmanRuntime/7.43.0",
        }
      ),
      data: courseTableformData,
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
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

    String rawdata = courseresponse2.data.toString();
    var semesters;

    //处理教务系统的非标准 json
    rawdata = rawdata.replaceAllMapped(
      RegExp(r'(\w+):'), (match) => '"${match[1]}":');
    rawdata = rawdata.replaceAll("'", "\""); // 替换单引号为双引号

    // 去除 HTML 代码
    rawdata = rawdata.replaceAll(RegExp(r'\"<tr>.*?</tr>\"', dotAll: true), '""');

    // 解析 JSON
    Map<String, dynamic> proceeddata = json.decode(rawdata);

      if (proceeddata.containsKey("semesters")) {
        Map<String, dynamic> semestersMap = proceeddata["semesters"];

        // 转换为标准 JSON 格式的字符串
        String jsonSemesters = json.encode(semestersMap);

        semesters = jsonSemesters;
      }
    
    String semesterspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/semesters.json';
    File semestersfile = File(semesterspath);
    semestersfile.writeAsString(semesters);

    //获取课表
    //使用本地选中的 semetserid 来覆盖教务系统返回的 semetserid ，用于请求对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1]['id'].toString();
    
    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));
    final courseTablegetformData = FormData.fromMap({
      "ignoreHead": '1',
      "setting.kind": 'std',
      "startWeek": '',
      "semester.id": semesterId,
      'ids': idsMe,
    });
    var courseresponse3;
    try{
      courseresponse3 = await dio.post(
        'http://jwgl.snut.edu.cn/eams/courseTableForStd!courseTable.action',
        options: Options(
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
        data: courseTablegetformData,
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
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


  //解析并保存课表到本地
  List courseTableList = [];
  RegExp courseBlockPattern = RegExp(
    r'activity\s*=\s*new\s*TaskActivity\(.*?,.*?,"(.*?)","(.*?)"\+periodInfo\+.*?","(.*?)","(.*?)","(.*?)",',
    dotAll: true
  );

  RegExp teacherPattern = RegExp(
    r'var teachers = \[(.*?)\];',
    dotAll: true
  );

  RegExp timePattern = RegExp(
    r'index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+);'
  );

  List<Match> courseBlocks = courseBlockPattern.allMatches(courseresponse3.data).toList();
  List<Match> teacherBlocks = teacherPattern.allMatches(courseresponse3.data).toList();
  List<String> rawTimeBlocks = courseresponse3.data.split(RegExp(r'activity\s*=\s*new\s*TaskActivity\(.*?\);', dotAll: true));


  List<List<String>> extractedTeachers = teacherBlocks.map((teacherMatch) {
    return extractTeacherNames(teacherMatch.group(1)!);
  }).toList();

  List<String> finalTeachers = List.filled(courseBlocks.length, "未知");

  for (int i = 0; i < courseBlocks.length; i++) {
    if (i < extractedTeachers.length) {
      finalTeachers[i] = extractedTeachers[i].join(', ');
    }
  }

  List<List<Map<String, int>>> extractedTimes = [];
  for (int i = 0; i < courseBlocks.length; i++) {
    if (i < rawTimeBlocks.length - 1) {
      String timeSection = rawTimeBlocks[i + 1].split(RegExp(r'var teachers =')).first;
      extractedTimes.add(extractCourseTimes(timeSection));
    } else {
      extractedTimes.add([]);
    }
  }

  for (int i = 0; i < courseBlocks.length; i++) {
    String courseName = courseBlocks[i].group(2)!;
    String courseLocation = courseBlocks[i].group(4)!;
    String weeksBinary = courseBlocks[i].group(5)!;

    List<Map<String, int>> times = extractedTimes[i];

    courseTableList.add(
      {
        'CourseName': courseName,
        'CourseLocation': courseLocation,
        'CourseWeeks': weeksBinary,
        'CourseTimes': times,
        'CourseTeacher': finalTeachers[i],
      }
    );
  }

  String courseTablepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/courseTable$semesterId.json';
  File courseTablefile = File(courseTablepath);
  courseTablefile.writeAsString(jsonEncode(courseTableList));

  //获取学期的开始时间、结束时间以及周数
    //校历数据目录
    Directory schoolCalendardirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar');
    if(await schoolCalendardirectory.exists() == false){
      await schoolCalendardirectory.create();
    }

    //使用本地选中的 semetserid 来覆盖教务系统返回的 semetserid ，用于请求对应的校历
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1]['id'].toString();
    
    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));
    final schoolCalendarformData = FormData.fromMap({
      "semester.id": semesterId,
      '_': '1740564686472',
    });
    var schoolCalendarresponse;
    try{
      schoolCalendarresponse = await dio.post(
        'http://jwgl.snut.edu.cn/eams/schoolCalendar!search.action',
        options: Options(
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
        data: schoolCalendarformData,
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
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
    
    List schoolCalendarList = [];
    var schoolCalendardocument = parser.parse(schoolCalendarresponse.data);
    var contentCells = schoolCalendardocument.querySelectorAll("td.content");

      if (contentCells.length > 1) {
      String dateRange = contentCells[1].text.trim();
      RegExp regExp = RegExp(r"(\d{4}-\d{1,2}-\d{1,2})~(\d{4}-\d{1,2}-\d{1,2}) \((\d+)\)");
      var match = regExp.firstMatch(dateRange);
      
      if (match != null) {
        termStart = match.group(1)!;
        termEnd = match.group(2)!;
        termWeeks = int.parse(match.group(3)!);
        schoolCalendarList.add({
          'termStart': termStart,
          'termEnd': termEnd,
          'termWeeks': termWeeks,
        });
      }
    }
    String schoolCalendarpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar/schoolCalendar$semesterId.json';
    File schoolCalendarfile = File(schoolCalendarpath);
    schoolCalendarfile.writeAsString(jsonEncode(schoolCalendarList));

    readSchoolCalendarInfo();
    if(mounted){
      setState(() {
        isQuerying = false;
        needRefresh = false;
      });
    }
  }

  List<String> extractTeacherNames(String teacherData) {
    RegExp singleTeacherPattern = RegExp(r'name:"([^"]+)"');
    Iterable<Match> matches = singleTeacherPattern.allMatches(teacherData);
    return matches.map((match) => match.group(1)!).toList();
  }

  List<Map<String, int>> extractCourseTimes(String timeData) {
    RegExp timePattern = RegExp(r'index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+);');
    Iterable<Match> matches = timePattern.allMatches(timeData);

    return matches.map((match) {
      return {
        "DayOfWeek": int.parse(match.group(1)!),
        "TimeOfDay": int.parse(match.group(2)!)
      };
    }).toList();
  }
}