import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smartsnut/AppPage/courseTable/coursetable_page.dart';
import 'package:smartsnut/AppPage/electricMeter/electricmeter_page.dart';
import 'package:smartsnut/AppPage/schoolNetwork/schoolnetwork_page.dart';
import 'package:smartsnut/AppPage/stdExam/stdexam_page.dart';
import 'package:smartsnut/AppPage/stdGrades/stdgrades_page.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html_parser;

//最新版本下载链接
bool updateChecked = false;
String latestDownloadLink = '';

//判断是否需要联网下载课表
bool needRefresh = false;

//学期信息
String termStart = '';
String termEnd = '';
int termWeeks = 0;
bool termEnded = false;

//周信息
int currentDOW = 0;

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

//今日课表数据
List<List> courseToday = [[],[],[],[],[],[],[],[],[],[]];//今日课程（第一节到第十节）

//课表读取状态
bool isReadingCT = true;

//学期数据
Map semestersData = {};
int semesterTotal = 0;//学年的数量
List semestersName = [];

//当前课表学年
int currentYearInt = 0;
String currentYearName = '';

//当前课表学期
int currentTermInt = 1;
String currentTermName = '';

//当前课表信息
int currentWeekInt = 1;
late DateTime termStartDateTime;
late DateTime termEndDateTime;

//解析新闻相关变量
int newsState = 0;//用于防止反复获取新闻，0 - 未获取； 1 - 已获取
bool isLoading = true;
bool loadSuccess = false;//用于判断是否成功获取新闻
int newsType = 0;//用于判断获取 理工要闻 或 通知公告 0 - 理工要闻； 1 - 通知公告
List<Map<String, String>> newsOutput = [];
List<dynamic> jsonData = [];
String jsonOutput='';

//用于存储新闻的完整URL
Uri url = Uri.parse("uri");

//用于存储最新六条 理工要闻
Map<String,dynamic> lgyw1 ={};
Map<String,dynamic> lgyw2 ={};
Map<String,dynamic> lgyw3 ={};
Map<String,dynamic> lgyw4 ={};
Map<String,dynamic> lgyw5 ={};
Map<String,dynamic> lgyw6 ={};

//用于存储最新六条 通知公告
Map<String,dynamic> tzgg1 ={};
Map<String,dynamic> tzgg2 ={};
Map<String,dynamic> tzgg3 ={};
Map<String,dynamic> tzgg4 ={};
Map<String,dynamic> tzgg5 ={};
Map<String,dynamic> tzgg6 ={};

//用于存储智慧陕理工的公告
int announcementState = 0;//用于防止反复获取公告，0 - 未获取； 1 - 已获取
List smartSNUTAnnouncements = [];

//首页为 陕西理工大学 - 理工要闻
class Home extends StatefulWidget{
  const Home({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home>{

  //读取学期相关信息
  readSemesterInfo() async {
    if(mounted){
      setState(() {
        isReadingCT = true;
      });
    }
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
    readSchoolCalendarInfo();
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
      if(mounted){setState(() {});}
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

    //加载本周周四课程
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

    //加载本周周五课程
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

    //加载本周周六课程
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

    //加载本周周日课程
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
    readTodayCourseTable();
  }

  //读取今日课表信息
  readTodayCourseTable() async {
    //读取之前清空课表，防止与前一天的课表叠加
    courseToday = [[],[],[],[],[],[],[],[],[],[]];
    
    if(currentDOW == 1){
      for(int courseTODInt = 0;courseTODInt < 10;courseTODInt++){
        if(courseMonWeek[courseTODInt].isEmpty == false){
          courseToday[courseTODInt].add({
            'CourseName': courseMonWeek[courseTODInt][0]['CourseName'],
            'CourseLocation': courseMonWeek[courseTODInt][0]['CourseLocation'],
            'CourseTeacher': courseMonWeek[courseTODInt][0]['CourseTeacher'],
          });
        }
      }
    }
    if(currentDOW == 2){
      for(int courseTODInt = 0;courseTODInt < 10;courseTODInt++){
        if(courseTueWeek[courseTODInt].isEmpty != true){
          courseToday[courseTODInt].add({
            'CourseName': courseTueWeek[courseTODInt][0]['CourseName'],
            'CourseLocation': courseTueWeek[courseTODInt][0]['CourseLocation'],
            'CourseTeacher': courseTueWeek[courseTODInt][0]['CourseTeacher'],
          });
        }
      }
    }
    if(currentDOW == 3){
      for(int courseTODInt = 0;courseTODInt < 10;courseTODInt++){
        if(courseWedWeek[courseTODInt].isEmpty != true){
          courseToday[courseTODInt].add({
            'CourseName': courseWedWeek[courseTODInt][0]['CourseName'],
            'CourseLocation': courseWedWeek[courseTODInt][0]['CourseLocation'],
            'CourseTeacher': courseWedWeek[courseTODInt][0]['CourseTeacher'],
          });
        }
      }
    }
    if(currentDOW == 4){
      for(int courseTODInt = 0;courseTODInt < 10;courseTODInt++){
        if(courseThuWeek[courseTODInt].isEmpty != true){
          courseToday[courseTODInt].add({
            'CourseName': courseThuWeek[courseTODInt][0]['CourseName'],
            'CourseLocation': courseThuWeek[courseTODInt][0]['CourseLocation'],
            'CourseTeacher': courseThuWeek[courseTODInt][0]['CourseTeacher'],
          });
        }
      }
    }
    if(currentDOW == 5){
      for(int courseTODInt = 0;courseTODInt < 10;courseTODInt++){
        if(courseFriWeek[courseTODInt].isEmpty != true){
          courseToday[courseTODInt].add({
            'CourseName': courseFriWeek[courseTODInt][0]['CourseName'],
            'CourseLocation': courseFriWeek[courseTODInt][0]['CourseLocation'],
            'CourseTeacher': courseFriWeek[courseTODInt][0]['CourseTeacher'],
          });
        }
      }
    }
    if(currentDOW == 6){
      for(int courseTODInt = 0;courseTODInt < 10;courseTODInt++){
        if(courseSatWeek[courseTODInt].isEmpty != true){
          courseToday[courseTODInt].add({
            'CourseName': courseSatWeek[courseTODInt][0]['CourseName'],
            'CourseLocation': courseSatWeek[courseTODInt][0]['CourseLocation'],
            'CourseTeacher': courseSatWeek[courseTODInt][0]['CourseTeacher'],
          });
        }
      }
    }
    if(currentDOW == 7){
      for(int courseTODInt = 0;courseTODInt < 10;courseTODInt++){
        if(courseSunWeek[courseTODInt].isEmpty != true){
          courseToday[courseTODInt].add({
            'CourseName': courseSunWeek[courseTODInt][0]['CourseName'],
            'CourseLocation': courseSunWeek[courseTODInt][0]['CourseLocation'],
            'CourseTeacher': courseSunWeek[courseTODInt][0]['CourseTeacher'],
          });
        }
      }
    }
    if(mounted){
      setState(() {
        isReadingCT = false;
      });//全部解析完成之后刷新
    }
  }

  //控件被创建的时候，执行 initState
  @override
  void initState() {
    if(updateChecked == false){
      checkUpdate();
    }
    readSemesterInfo();
    super.initState();
    if(newsState == 0){
      getNewsList();
    }
    if(announcementState == 0){
      getSmartSNUTAnnouncement();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context)  {
    //加载首页之前立即刷新一次周几，解决进入首页后，“星期几” 延迟出现的问题
    initializeDateFormatting("zh_CN");
    GlobalVars.weekDay = DateFormat('EEEE',"zh_CN").format(DateTime.now());
    
    //获取长宽并保存
    tableWidth = (MediaQuery.of(context).size.width );
    tableHeight = tableWidth / 12;
    //渲染首页
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10, 50, 0, 30),
          child: Text('${GlobalVars.greeting}，${GlobalVars.realName}',style: TextStyle(fontWeight: FontWeight.w300,fontSize: GlobalVars.genericGreetingTitle),),
        ),
        (smartSNUTAnnouncements.isEmpty)? 
        SizedBox():
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
              child: ListTile(
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
                ),
                trailing: Icon(Icons.chevron_right),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${smartSNUTAnnouncements[0]['Content']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                    Text('${smartSNUTAnnouncements[1]['Content']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                  ],
                ),
                subtitle: Text('阅读更多',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                onTap: () {
                  url = Uri.parse('https://smartsnut.cn/Announcements');
                  launchURL();
                },
              )
            )
          ),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('今日课表',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
              Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(15, 5, 15, 10),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21),
            ),
            shadowColor: Theme.of(context).colorScheme.onPrimary,
            color: Theme.of(context).colorScheme.surfaceDim,
            child: isReadingCT? Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Center(child: CircularProgressIndicator(),),
            )
            :Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('今天是：',style: TextStyle(fontSize: GlobalVars.genericTextLarge,fontWeight: FontWeight.normal),),
                            Text('${GlobalVars.month} 月 ${GlobalVars.day} 日 ${GlobalVars.weekDay}',style: TextStyle(fontSize: GlobalVars.genericTextLarge,fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary),),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 15,indent: 20,endIndent: 20,),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        //第一节
                        (courseToday[0].isEmpty)?
                        SizedBox()
                        :ListTile(
                          title: ((courseToday[3].isEmpty)? false:(courseToday[0][0]['CourseName'] == courseToday[3][0]['CourseName'] && courseToday[0][0]['CourseLocation'] == courseToday[3][0]['CourseLocation'])? true:false)? Text('[1 - 4 节] ${courseToday[0][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                            ((courseToday[2].isEmpty)? false:(courseToday[0][0]['CourseName'] == courseToday[2][0]['CourseName'] && courseToday[0][0]['CourseLocation'] == courseToday[2][0]['CourseLocation'])? true:false)? Text('[1 - 3 节] ${courseToday[0][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                            ((courseToday[1].isEmpty)? false:(courseToday[0][0]['CourseName'] == courseToday[1][0]['CourseName'] && courseToday[0][0]['CourseLocation'] == courseToday[1][0]['CourseLocation'])? true:false)? Text('[1 - 2 节] ${courseToday[0][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                            Text('[第 1 节] ${courseToday[0][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[0][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[0][0]['CourseLocation'] == '')? '无':'${courseToday[0][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                            ],
                          ),
                        ),
                        //第二节
                        (courseToday[1].isEmpty)? (courseToday[0].isEmpty == courseToday[1].isEmpty)? SizedBox(width: 0,height: 0,) :
                        SizedBox()
                        :(((courseToday[0].isEmpty)? false:(courseToday[0][0]['CourseName'] == courseToday[1][0]['CourseName'] && courseToday[0][0]['CourseLocation'] == courseToday[1][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :ListTile(
                          title: Text('[第 2 节] ${courseToday[1][0]['CourseName']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[1][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[1][0]['CourseLocation'] == '')? '无':'${courseToday[1][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第三节
                        (courseToday[2].isEmpty)? 
                        SizedBox()
                        :(((courseToday[0].isEmpty)? false:(courseToday[0][0]['CourseName'] == courseToday[2][0]['CourseName'] && courseToday[0][0]['CourseLocation'] == courseToday[2][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :ListTile(
                          title: (courseToday[3].isEmpty == false)? (courseToday[2][0]['CourseName'] == courseToday[3][0]['CourseName'] && courseToday[3].isEmpty == false)? Text('[3 - 4 节] ${courseToday[2][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):Text('[第 3 节] ${courseToday[2][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                              Text('[第 3 节] ${courseToday[2][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[2][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[2][0]['CourseLocation'] == '')? '无':'${courseToday[2][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第四节
                        (courseToday[3].isEmpty)? (courseToday[2].isEmpty == courseToday[3].isEmpty)? SizedBox(width: 0,height: 0,) :
                        SizedBox()
                        :(((courseToday[0].isEmpty)? false:(courseToday[0][0]['CourseName'] == courseToday[3][0]['CourseName'] && courseToday[0][0]['CourseLocation'] == courseToday[3][0]['CourseLocation'])) || ((courseToday[2].isEmpty)? false:(courseToday[2][0]['CourseName'] == courseToday[3][0]['CourseName'] && courseToday[2][0]['CourseLocation'] == courseToday[3][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :ListTile(
                          title: Text('[第 4 节] ${courseToday[3][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[3][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[3][0]['CourseLocation'] == '')? '无':'${courseToday[3][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第五节
                        (courseToday[4].isEmpty)? 
                        SizedBox()
                        :ListTile(
                          title: ((courseToday[7].isEmpty)? false:(courseToday[4][0]['CourseName'] == courseToday[7][0]['CourseName'] && courseToday[4][0]['CourseLocation'] == courseToday[7][0]['CourseLocation'])? true:false)? Text('[5 - 8 节] ${courseToday[4][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                            ((courseToday[6].isEmpty)? false:(courseToday[4][0]['CourseName'] == courseToday[6][0]['CourseName'] && courseToday[4][0]['CourseLocation'] == courseToday[6][0]['CourseLocation'])? true:false)? Text('[5 - 7 节] ${courseToday[4][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                            ((courseToday[5].isEmpty)? false:(courseToday[4][0]['CourseName'] == courseToday[5][0]['CourseName'] && courseToday[4][0]['CourseLocation'] == courseToday[5][0]['CourseLocation'])? true:false)? Text('[5 - 6 节] ${courseToday[4][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                            Text('[第 5 节] ${courseToday[4][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[4][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[4][0]['CourseLocation'] == '')? '无':'${courseToday[4][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第六节
                        (courseToday[5].isEmpty)?  (courseToday[4].isEmpty == courseToday[5].isEmpty)? SizedBox(width: 0,height: 0,):
                        SizedBox()
                        :(((courseToday[4].isEmpty)? false:(courseToday[4][0]['CourseName'] == courseToday[5][0]['CourseName'] && courseToday[4][0]['CourseLocation'] == courseToday[5][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :ListTile(
                          title: Text('[第 6 节] ${courseToday[5][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[5][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[5][0]['CourseLocation'] == '')? '无':'${courseToday[5][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第七节
                        (courseToday[6].isEmpty)? 
                        SizedBox()
                        :(((courseToday[4].isEmpty)? false:(courseToday[4][0]['CourseName'] == courseToday[6][0]['CourseName'] && courseToday[4][0]['CourseLocation'] == courseToday[6][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :ListTile(
                          title: (courseToday[7].isEmpty == false)? (courseToday[6][0]['CourseName'] == courseToday[7][0]['CourseName'] && courseToday[6][0]['CourseLocation'] == courseToday[7][0]['CourseLocation'])? Text('[7 - 8 节] ${courseToday[6][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):Text('[第 7 节] ${courseToday[6][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                              Text('[第 7 节] ${courseToday[6][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[6][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[6][0]['CourseLocation'] == '')? '无':'${courseToday[6][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第八节
                        (courseToday[7].isEmpty)? (courseToday[6].isEmpty == courseToday[7].isEmpty)? SizedBox(width: 0,height: 0,):
                        SizedBox()
                        :(((courseToday[4].isEmpty)? false:(courseToday[4][0]['CourseName'] == courseToday[7][0]['CourseName'] && courseToday[4][0]['CourseLocation'] == courseToday[7][0]['CourseLocation'])) || ((courseToday[6].isEmpty)? false:(courseToday[6][0]['CourseName'] == courseToday[7][0]['CourseName'] || courseToday[6][0]['CourseLocation'] == courseToday[7][0]['CourseLocation'])))? SizedBox(width: 0,height: 0,)
                        :ListTile(
                          title: Text('[第 8 节] ${courseToday[7][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[7][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[7][0]['CourseLocation'] == '')? '无':'${courseToday[7][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第九节
                        (courseToday[8].isEmpty)? 
                        SizedBox()
                        :ListTile(
                          title: (courseToday[9].isEmpty == false)? (courseToday[8][0]['CourseName'] == courseToday[9][0]['CourseName'] && courseToday[8][0]['CourseLocation'] == courseToday[9][0]['CourseLocation'])? Text('[9 - 10 节] ${courseToday[8][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):Text('[第 9 节] ${courseToday[8][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,):
                            Text('[第 9 节] ${courseToday[8][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[8][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[8][0]['CourseLocation'] == '')? '无':'${courseToday[8][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //第十节
                        (courseToday[9].isEmpty)? (courseToday[8].isEmpty == courseToday[9].isEmpty)? SizedBox(width: 0,height: 0,):
                        SizedBox()
                        :((courseToday[8].isEmpty)? false:(courseToday[8][0]['CourseName'] == courseToday[9][0]['CourseName'] || courseToday[8][0]['CourseLocation'] == courseToday[9][0]['CourseLocation']))? SizedBox(width: 0,height: 0,)
                        :ListTile(
                          title: Text('[第 10 节] ${courseToday[9][0]['CourseName']}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle,color: Theme.of(context).colorScheme.primary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(' 教师：${courseToday[9][0]['CourseTeacher']}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,),
                              Text(' 地点：${(courseToday[9][0]['CourseLocation'] == '')? '无':'${courseToday[9][0]['CourseLocation']}'}',textAlign: TextAlign.end,style: TextStyle(fontSize: GlobalVars.listTileSubtitle,color: Theme.of(context).colorScheme.secondary),maxLines: 1,overflow: TextOverflow.ellipsis,)
                            ],
                          ),
                        ),
                        //今日无课
                        ((courseToday[0].isEmpty == true) && (courseToday[1].isEmpty == true) && (courseToday[2].isEmpty == true) && (courseToday[3].isEmpty == true) && (courseToday[4].isEmpty == true) && (courseToday[5].isEmpty == true) && (courseToday[6].isEmpty == true) && (courseToday[7].isEmpty == true) && (courseToday[8].isEmpty == true) && (courseToday[9].isEmpty == true))?
                        Column(
                          children: [
                            SizedBox(height: 30,),
                            Text('今日无课哦',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.genericTextLarge),),
                            SizedBox(height: 30,)
                          ],
                        ):SizedBox()
                      ],
                    ),
                    Divider(height: 15,indent: 20,endIndent: 20,),
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('查看本周课表、切换学年、刷新数据，请点击这里',style: TextStyle(fontWeight: FontWeight.bold,fontSize: GlobalVars.listTileTitle),),
                      onTap: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => CourseTablePage())).then((value) => readSemesterInfo());},
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('便捷生活',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
                Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.cover,
            child: Container(
              padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                    child: Row(
                      children: [
                        Container(
                          width: (MediaQuery.of(context).size.width)/2 - 25,
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          height: 100,
                          child: ElevatedButton(
                            onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => SchoolNetworkPage()));},
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/web.png'):AssetImage('assets/icons/darktheme/web.png'),height: 36,),
                                SizedBox(width: 10,),
                                Expanded(child: Text('网费查询',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 5), // 按钮之间的间距
                        Container(
                          width: (MediaQuery.of(context).size.width)/2 - 25,
                          padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                          height: 100,
                          child: ElevatedButton(
                            onPressed: (){
                              if(GlobalVars.emBinded == false){
                                  showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle),),
                                    content: Text('您还没有绑定电费账号，\n请先前往 “我的 -> 解/绑电费账号” 绑定后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent),),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, 'OK'),
                                        child: const Text('确定'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }else{
                                Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => Electricmeterpage()));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/electricity.png'):AssetImage('assets/icons/darktheme/electricity.png'),height: 36,),
                                SizedBox(width: 10,),
                                Expanded(child: Text('电费查询',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
                    child: Row(
                        children: [
                          Container(
                            width: (MediaQuery.of(context).size.width)/2 - 25,
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            height: 100,
                            child: ElevatedButton(
                              onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => StdExamPage()));},
                              style: ElevatedButton.styleFrom(
                                shadowColor: Theme.of(context).colorScheme.onPrimary,
                                backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(21),
                                ),
                              ),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/exam.png'):AssetImage('assets/icons/darktheme/exam.png'),height: 36,),
                                    SizedBox(width: 10,),
                                    Expanded(child: Text('我的考试',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                                  ],
                                ),
                            ),
                          ),
                          SizedBox(width: 5), // 按钮之间的间距
                          Container(
                            width: (MediaQuery.of(context).size.width)/2 - 25,
                            padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                            height: 100,
                            child: ElevatedButton(
                              onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => StdGradesPage()));},
                              style: ElevatedButton.styleFrom(
                                shadowColor: Theme.of(context).colorScheme.onPrimary,
                                backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(21),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/grade.png'):AssetImage('assets/icons/darktheme/grade.png'),height: 36,),
                                  SizedBox(width: 10,),
                                  Expanded(child: Text('我的成绩',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('通知公告',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
                Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
              color: Theme.of(context).colorScheme.surfaceDim,
              shadowColor: Theme.of(context).colorScheme.onPrimary,
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: isLoading? 
                Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      title: Center(child: CircularProgressIndicator(),),
                      onTap: (){
                        getNewsList();
                      },
                    ),
                  ],
                ):
                loadSuccess? Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('${tzgg1['title']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                      subtitle: Text('${tzgg1['date']}',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      onTap: (){
                        url = Uri.parse('https://www.snut.edu.cn${tzgg1['location']}');
                        launchURL();
                      },
                    ),
                    Divider(height: 5,indent: 20,endIndent: 20,),
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('${tzgg2['title']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                      subtitle: Text('${tzgg2['date']}',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      onTap: (){
                        url = Uri.parse('https://www.snut.edu.cn${tzgg2['location']}');
                        launchURL();
                      },
                    ),
                    Divider(height: 5,indent: 20,endIndent: 20,),
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('${tzgg3['title']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                      subtitle: Text('${tzgg3['date']}',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      onTap: (){
                        url = Uri.parse('https://www.snut.edu.cn${tzgg3['location']}');
                        launchURL();
                      },
                    ),
                    Divider(height: 5,indent: 20,endIndent: 20,),
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('${tzgg4['title']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                      subtitle: Text('${tzgg4['date']}',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      onTap: (){
                        url = Uri.parse('https://www.snut.edu.cn${tzgg4['location']}');
                        launchURL();
                      },
                    ),
                    Divider(height: 5,indent: 20,endIndent: 20,),
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('${tzgg5['title']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                      subtitle: Text('${tzgg5['date']}',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      onTap: (){
                        url = Uri.parse('https://www.snut.edu.cn${tzgg5['location']}');
                        launchURL();
                      },
                    ),
                    Divider(height: 5,indent: 20,endIndent: 20,),
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('${tzgg6['title']}',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                      subtitle: Text('${tzgg6['date']}',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      onTap: (){
                        url = Uri.parse('https://www.snut.edu.cn${tzgg6['location']}');
                        launchURL();
                      },
                    ),
                  ],
                ):
                Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      title: Text('无法连接网络，请点击这里重试',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                      onTap: (){
                        getNewsList();
                      },
                    ),
                  ],
                )
              ),
            ),
          ),
        ],
      );
  }
  //获取公告
  getSmartSNUTAnnouncement() async {
    smartSNUTAnnouncements = [];
    Dio dio = Dio();
    late Response smartSNUTNotifyResponse;
    try{
      smartSNUTNotifyResponse = await dio.get('https://apis.smartsnut.cn/Generic/Announcement/Announcement.json');
    }catch(e){
      return;
    }
    if(mounted){
      smartSNUTAnnouncements = jsonDecode(jsonEncode(smartSNUTNotifyResponse.data));
      announcementState = 1;
    }
  }

  //获取新闻并解析，便于首页渲染
  getNewsList() async {
    if(mounted){
      setState(() {
        isLoading = true;
      });
    }
      String newsurl="";
      for(int newsType = 0;newsType < 2;newsType++){
        newsOutput = [];//清空旧的新闻列表
        if(newsType == 0){
          newsurl = 'https://www.snut.edu.cn/index/lgyw.htm';
        }if(newsType == 1){
          newsurl = 'https://www.snut.edu.cn/index/tzgg.htm';
        }
        Dio dio = Dio();
        CookieJar snutcookie = CookieJar();
        dio.interceptors.add(CookieManager(snutcookie));
        try{
          await dio.get(
            options: Options(
              followRedirects: false,
              validateStatus: (status) {
                return status == 302;
              },
            ),newsurl);
        }catch (e){
          if(mounted){
            setState(() {
            isLoading = false;
            loadSuccess = false;
            newsState = 1;
            });
          }
        }
          
          //这里需要进行两次 get，第一次 get 拿到 cookie，第二次 get 需要带 cookie 才能正常获取到页面
          late html_dom.Document document;
          try{
            Response response = await dio.get(newsurl);
            document = html_parser.parse(response.data);
          }catch (e){
            if(mounted){
              setState(() {
                isLoading = false;
                loadSuccess = false;
                newsState = 1;
              });
            }
            return;
          }

          var newsItems = document.querySelectorAll('.lby-list li');
          for (var item in newsItems) {
            var titleElement = item.querySelector('a');
            var dateElement = item.querySelector('span');
            var linkElement = titleElement?.attributes['href'];
            
            if (titleElement != null && dateElement != null && linkElement != null) {
              // 网站中新闻的地址为 "../info/1037/75038.htm" ，这里处理 URL，去掉最前面的 ".."
              String cleanedUrl = linkElement.startsWith("../") ? linkElement.substring(2) : linkElement;
              
              //保存新闻的标题、发布日期以及最终的 URL 到变量中
              if(mounted){
                setState(() {
                  newsOutput.add(
                    {
                      'title': titleElement.text.trim(),
                      'date': dateElement.text.trim(),
                      'location': cleanedUrl.trim(),
                    }
                  );
                });
              }
          }
          jsonOutput = jsonEncode(newsOutput);
          jsonData = jsonDecode(jsonOutput);
          }
          if(mounted){
            tzgg1 = jsonData[1];
            tzgg2 = jsonData[2];
            tzgg3 = jsonData[3];
            tzgg4 = jsonData[4];
            tzgg5 = jsonData[5];
            tzgg6 = jsonData[6];
          }
      }
      if(mounted){
        setState(() {
          newsState = 1;
          isLoading = false;
          loadSuccess = true;
        });
      }
  }

  //打开链接
  void launchURL() async{
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if(context.mounted){
                Navigator.pop(context, 'OK');
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  
  //检查更新
  checkUpdate() async {
    Dio dio = Dio();
    late Response updateServerResponse;
    try{
      updateServerResponse = await dio.get('https://apis.smartsnut.cn/Generic/UpdateCheck/LatestVersion.json');
    }catch(e){
      return;
    }
    List serverResponseData = updateServerResponse.data;
    if(Platform.isWindows){
      if(serverResponseData[0]['Windows'][0]['LatestVersionInt'] - GlobalVars.versionCodeInt > 0){
        if(mounted){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('发现新的 Windows 版智慧陕理工  ${GlobalVars.versionCodeString} -> ${serverResponseData[0]['Windows'][0]['LatestVersionString']}',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('是否立即更新？\n\n发布日期：${serverResponseData[0]['Windows'][0]['ReleaseDate']}\n\n更新日志：\n${serverResponseData[0]['Windows'][0]['Changelog']}',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    latestDownloadLink = serverResponseData[0]['Windows'][0]['DownloadLink'];
                    Navigator.pop(context, 'OK');
                    getUpdate();
                  },
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        }
      }else{
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('暂未发现新的 Windows 版智慧陕理工\n您正在使用最新版本的 Windows 版智慧陕理工：${GlobalVars.versionCodeString}'),
            ),
          );
        }
      }
    }if(Platform.isAndroid){
      if(serverResponseData[0]['Android'][0]['LatestVersionInt'] - GlobalVars.versionCodeInt > 0){
        if(mounted){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('发现新的 Android 版智慧陕理工  ${GlobalVars.versionCodeString} -> ${serverResponseData[0]['Android'][0]['LatestVersionString']}',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('是否立即更新？\n\n发布日期：${serverResponseData[0]['Android'][0]['ReleaseDate']}\n\n更新日志：\n${serverResponseData[0]['Android'][0]['Changelog']}',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    latestDownloadLink = serverResponseData[0]['Android'][0]['DownloadLink'];
                    Navigator.pop(context, 'OK');
                    getUpdate();
                  },
                  child: const Text('确认'),
                ),
              ],
            ),
          );
          
        }
      }else{
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('暂未发现新的 Android 版智慧陕理工\n您正在使用最新版本的 Android 版智慧陕理工：${GlobalVars.versionCodeString}'),
            ),
          );
        }
      }
    }
    if(mounted){
      setState(() {
        updateChecked = true;
      });
    }
  }

  //下载更新
  getUpdate() async {
    int downloadedSize = 0;
    int totalDownloadSize = 0;
    double downloadProgress = 0;
    Dio dio = Dio();
    showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('正在更新...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Text((Platform.isWindows)? '请勿关闭智慧陕理工，下载完成后智慧陕理工将会自动重启，完成更新操作':(Platform.isAndroid)? '正在下载安装包，下载完成后智慧陕理工将会启动软件更新流程，请您手动进行更新':'正在下载更新...',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                SizedBox(height: 10,),
                LinearProgressIndicator(
                  value: downloadProgress,
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(downloadProgress * 100).toStringAsFixed(2)}%',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    Text('${(downloadedSize / 1024 /1024).toStringAsFixed(2)}MB / ${(totalDownloadSize / 1024 / 1024).toStringAsFixed(2)}MB',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
    if(Platform.isWindows){
    //Windows 版更新代码
      String exePath = Platform.resolvedExecutable;
      String exeDir = File(exePath).parent.path;
      try{
        await dio.download(
          latestDownloadLink,
          '$exeDir/Windows_latest.exe',
          onReceiveProgress: (count, total) {
            if(mounted){
              setState(() {
                downloadProgress = count / total;
              });
            }
          },
        );
      }catch(e){
        if(mounted){
          Navigator.pop(context);
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('Windows 版更新下载失败，请您稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: <Widget>[
                TextButton(
                  onPressed: () {Navigator.pop(context, 'OK');},
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        }
        return;
      }
      Process.start('$exeDir/Windows_latest.exe', [], workingDirectory: exeDir);
    }if(Platform.isAndroid){
      //Android 版更新代码
      try{
        await dio.download(
          latestDownloadLink,
          '${(await getApplicationDocumentsDirectory()).path}/Android_latest.apk',
          onReceiveProgress: (count, total) {
            if(mounted){
              setState(() {
                downloadProgress = count / total;
                downloadedSize = count;
                totalDownloadSize = total;
              });
            }
          },
        );
      }catch(e){
        if(mounted){
          Navigator.pop(context);
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('Android 版更新下载失败，请您稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: <Widget>[
                TextButton(
                  onPressed: () {Navigator.pop(context, 'OK');},
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        }
        return;
      }
      OpenFilex.open('${(await getApplicationDocumentsDirectory()).path}/Android_latest.apk');
    }
  }

}
