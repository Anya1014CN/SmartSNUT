import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:smartsnut/globalvars.dart';

class Modules {
  //检查登录状态
  static checkLoginState() async {
    String loginsuccesspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/LoginSuccess';
    File loginsuccessfile = File(loginsuccesspath);
    if(await loginsuccessfile.exists() == false){
      GlobalVars.loginState = 1;
    }else{
      GlobalVars.loginState = 2;
    }
  }

  //读取用户信息并保存在变量中
  static readStdAccount() async {
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    GlobalVars.stdAccount = jsonDecode(await stdAccountfile.readAsString());
    
    String stdDetailPath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailFile = File(stdDetailPath);
    GlobalVars.stdDetail = jsonDecode(await stdDetailFile.readAsString());
    
    GlobalVars.realName = GlobalVars.stdDetail['姓名：'];
    GlobalVars.userName = GlobalVars.stdAccount[0]['UserName'];
    GlobalVars.passWord = GlobalVars.stdAccount[0]['PassWord'];
        
    String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailfile = File(stdDetailpath);
    String stdDetailString = await stdDetailfile.readAsString();
    Map<String, dynamic> jsonData = json.decode(stdDetailString);
    GlobalVars.stdDetail = jsonData.map((key, value) => MapEntry(key, value.toString()));

    GlobalVars.enrollTime = GlobalVars.stdDetail['入校时间：']!;
    GlobalVars.graduationTime = GlobalVars.stdDetail['毕业时间：']!;
  }

  //读取电表信息
  static readEMInfo() async {
    String openidtxtpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidtxtfile = File(openidtxtpath);
    if(await openidtxtfile.exists() == true){
      GlobalVars.emBinded = true;
    }else{
      GlobalVars.emBinded = false;
    }
    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    
    if(await emUserDatafile.exists() == true){
      GlobalVars.emUserData =jsonDecode(await emUserDatafile.readAsString());

      final docpath = (await getApplicationDocumentsDirectory()).path;
      GlobalVars.openId = GlobalVars.emUserData[0]['openId'];
      GlobalVars.wechatUserId = GlobalVars.emUserData[0]['wechatId'];
      GlobalVars.wechatUserNickname = GlobalVars.emUserData[0]['wechatUserNickname'];
      GlobalVars.emAvatarPath = '$docpath/SmartSNUT/embinddata/emavatar.jpg';
      GlobalVars.emNum = GlobalVars.emDetail.length;
      if(GlobalVars.openId == '' || GlobalVars.wechatUserId == '' || GlobalVars.wechatUserNickname == ''){
        GlobalVars.emBinded = false;
        return;
      }
      GlobalVars.emBinded = true;
    }else{
      GlobalVars.emBinded = false;
    }
    
    //读取电表详情
    String emDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emdetail.json';
    File emDetailfile = File(emDetailpath);
    if(await emDetailfile.exists() == true){
      GlobalVars.emDetail = jsonDecode(await emDetailfile.readAsString());
    }

    //若用户使用旧版数据且新版数据不存在，则进行迁移
    if(await emUserDatafile.exists() == false){
      String emnumpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emnum.txt';
      File emnumfile = File(emnumpath);
      if(await emnumfile.exists()){
        GlobalVars.emNum = int.parse(await emnumfile.readAsString());
        await emnumfile.delete();
      }else{
        return;
      }

      String openidpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
      File openidfile = File(openidpath);
      if(await openidfile.exists()){
        GlobalVars.openId = await openidfile.readAsString();
        await openidfile.delete();
      }else{
        return;
      }

      String wechatIdpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatId.txt';
      File wechatIdfile = File(wechatIdpath);
      if(await wechatIdfile.exists()){
        GlobalVars.wechatUserId = await wechatIdfile.readAsString();
        await wechatIdfile.delete();
      }else{
        return;
      }

      String wechatUserNicknamepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserNickname.txt';
      File wechatUserNicknamefile = File(wechatUserNicknamepath);
      if(await wechatUserNicknamefile.exists()){
        GlobalVars.wechatUserNickname = await wechatUserNicknamefile.readAsString();
          GlobalVars.emBinded = true;
      }else{
        return;
      }
      
      GlobalVars.emUserData.clear();
      GlobalVars.emUserData.add({
        'emNum': GlobalVars.emNum,
        'openId': GlobalVars.openId,
        'wechatId': GlobalVars.wechatUserId,
        'wechatUserNickname': GlobalVars.wechatUserNickname,
      });
      emUserDatafile.writeAsString(jsonEncode(GlobalVars.emUserData));
    }
  }

  //加密密码
  static String encryptPassword(String passWord, String pwdEncryptSalt) {
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
    final key = encrypt.Key.fromUtf8(pwdEncryptSalt.trim());
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
    final encrypted = encrypter.encrypt(randomPrefix + passWord, iv: ivObj);

    // 返回Base64编码的加密结果
    return encrypted.base64;
  }

  //检查并创建数据目录
  static checkDirectory() async {
    //数据根目录
    Directory rootDirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await rootDirectory.exists() == false){
      await rootDirectory.create();
    }

    //用户数据目录
    Directory authserverDirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver');
    if(await authserverDirectory.exists() == false){
      await authserverDirectory.create();
    }

    //课表数据目录
    Directory courseTableStdDirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd');
    if(await courseTableStdDirectory.exists() == false){
      await courseTableStdDirectory.create();
    }

    //成绩数据目录
    Directory stdGradesDirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades');
    if(await stdGradesDirectory.exists() == false){
      await stdGradesDirectory.create();
    }
    
    //考试数据目录
    Directory stdExamDirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam');
    if(await stdExamDirectory.exists() == false){
      await stdExamDirectory.create();
    }

    //电费数据目录
    Directory emdataDirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata');
    if(await emdataDirectory.exists() == false){
      await emdataDirectory.create();
    }

    //学工系统数据目录
    Directory wzxyDirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/wzxyData');
    if(await wzxyDirectory.exists() == false){
      await wzxyDirectory.create();
    }

    //绩点计算器数据目录 删除
    Directory gpaCalculatordirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/GPACalculator');
    if(await gpaCalculatordirectory.exists() == true){
      await gpaCalculatordirectory.delete(recursive: true);
    }
  }
  
  //设置字体大小
  static setFontSize() {
    double changevalue = 0;
    if(GlobalVars.fontsizeint == 0)changevalue = -6;
    if(GlobalVars.fontsizeint == 1)changevalue = -4;
    if(GlobalVars.fontsizeint == 2)changevalue = -2;
    if(GlobalVars.fontsizeint == 3)changevalue = 0;
    if(GlobalVars.fontsizeint == 4)changevalue = 2;
    if(GlobalVars.fontsizeint == 5)changevalue = 4;
    if(GlobalVars.fontsizeint == 6)changevalue = 6;

    //弹出对话框字体
    GlobalVars.alertdialogTitle = DefaultfontSize.alertdialogTitle + changevalue;
    GlobalVars.alertdialogContent = DefaultfontSize.alertdialogContent + changevalue;

    //通用页面字体
    GlobalVars.splashPageTitle = DefaultfontSize.splashPageTitle + changevalue;
    GlobalVars.bottonbarAppnameTitle = DefaultfontSize.bottonbarAppnameTitle + changevalue;
    GlobalVars.bottonbarSelectedTitle = DefaultfontSize.bottonbarSelectedTitle + changevalue;
    GlobalVars.bottonbarUnselectedTitle = DefaultfontSize.bottonbarUnselectedTitle + changevalue;
    GlobalVars.genericPageTitle = DefaultfontSize.genericPageTitle + changevalue;
    GlobalVars.genericPageTitleSmall = DefaultfontSize.genericPageTitleSmall + changevalue;
    GlobalVars.genericGreetingTitle = DefaultfontSize.genericGreetingTitle + changevalue;
    GlobalVars.genericFloationActionButtonTitle = DefaultfontSize.genericFloationActionButtonTitle + changevalue;
    GlobalVars.dividerTitle = DefaultfontSize.dividerTitle + changevalue;
    GlobalVars.listTileTitle = DefaultfontSize.listTileTitle + changevalue;
    GlobalVars.listTileSubtitle = DefaultfontSize.listTileSubtitle + changevalue;
    GlobalVars.genericFunctionsButtonTitle = DefaultfontSize.genericFunctionsButtonTitle + changevalue;
    GlobalVars.genericSwitchContainerTitle = DefaultfontSize.genericSwitchContainerTitle + changevalue;
    GlobalVars.genericSwitchMenuTitle = DefaultfontSize.genericSwitchMenuTitle + changevalue;
    GlobalVars.genericTextSmall = DefaultfontSize.genericTextSmall + changevalue;
    GlobalVars.genericTextMedium = DefaultfontSize.genericTextMedium + changevalue;
    GlobalVars.genericTextLarge = DefaultfontSize.genericTextLarge + changevalue;
  }

  //开始登录
  static Future<List> loginAuth(String userName,String passWord,String loginService) async {
    GlobalVars.loadingHint = '正在获取登录数据...';

    String loginServiceLocation = '';
    if(loginService == 'jwgl'){
      loginServiceLocation = 'http://jwgl.snut.edu.cn/eams/ssoLogin.action';
    }if(loginService == 'wzxy'){
      loginServiceLocation = 'https://wzxy.snut.edu.cn/basicinfo/mobile/login/cas?fid=50';
    }

    //清除残留 Cookie
    GlobalVars.globalCookieJar.deleteAll();

    //存储返回的信息
    List message = [];

    String authexecution = '';//存储获取到的 execution
    String pwdEncryptSalt = '';//存储获取到的 pwdEncryptSalt

    //初始化 Dio
    GlobalVars.globalDio.interceptors.add(CookieManager(GlobalVars.globalCookieJar));

    late Response authresponse1;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      authresponse1 = await GlobalVars.globalDio.get('https://authserver.snut.edu.cn/authserver/login?service=$loginServiceLocation');
    }catch (e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
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

    GlobalVars.loadingHint = '正在获取验证码...';
    Uint8List? captchaBytes;
    
    late Response captchaResponse;
    try{
      if(GlobalVars.operationCanceled){
        message.clear();
        message.add({
          'statue': false,
          'message': '操作已取消',
        });
        return message;
      }
      var response = await GlobalVars.globalDio.get(
        'https://authserver.snut.edu.cn/authserver/getCaptcha.htl',
        options: Options(
          responseType: ResponseType.bytes, // 指定响应类型为字节数组
        ),
      );
      captchaResponse = response;
    }catch (e) {
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
      
    // 确保响应数据是 Uint8List 类型
    if (captchaResponse.data is Uint8List) {
      captchaBytes = captchaResponse.data;
    }
    captchaBytes = Uint8List.fromList(captchaResponse.data as List<int>);

    GlobalVars.loadingHint = '正在自动识别验证码...';
    
    late Response ddddocrResponse;
    try{
      var response = await GlobalVars.globalDio.post(
        'https://apis.smartsnut.cn/ddddocr',
        data: captchaBytes, // 直接传递 Uint8List
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
          },
        ),
      );
      ddddocrResponse = response;
    }catch(e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    List ocrResult = ddddocrResponse.data;
    
    GlobalVars.loadingHint = '正在登录统一认证平台...';

    if(loginService == 'jwgl'){
      loginServiceLocation = 'http://jwgl.snut.edu.cn/eams/ssoLogin.action';
    }if(loginService == 'wzxy'){
      loginServiceLocation = 'https://wzxy.snut.edu.cn/basicinfo/mobile/login/cas?fid=50';
    }

    //加密密码
    String encryptedPassWord ='';
    encryptedPassWord = encryptPassword(passWord, pwdEncryptSalt);

    late Response authresponse2;
    final loginParams = {
      "username": userName,
      "password": encryptedPassWord,
      "captcha": ocrResult[0]['result'],
      "_eventId": "submit",
      "cllt": "userNameLogin",
      "dllt": "generalLogin",
      "lt": "",
      "execution": authexecution,
    };
    try{
      if(GlobalVars.operationCanceled){
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      authresponse2 = await GlobalVars.globalDio.post(
        'https://authserver.snut.edu.cn/authserver/login?service=$loginServiceLocation',
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 401;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
    }catch(e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    if(authresponse2.data.toString().contains('您提供的用户名或者密码有误')){
      message.clear();
      message.add({
        'statue': false,
        'message': '用户名或密码错误',
      });
      return message;
    }
    if(authresponse2.data.toString().contains('图形动态码错误')){
      message.clear();
      message.add({
        'statue': false,
        'message': '验证码错误',
      });
      return message;
    }

    //手动跟随重定向
    try{
      //跟随第一步重定向 (ssologin 的 ticket)
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      var authresponse21 = await GlobalVars.globalDio.get(
        authresponse2.headers['location']![0],
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 302;
          },
        )
      );
      //跟随第二步重定向 (ssologin 的 ticket)
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      var authresponse22 = await GlobalVars.globalDio.get(
        authresponse21.headers['location']![0],
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 307;
          },
        )
      );
      //跟随第三步重定向 (ssologin 的 jsessionid)
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      if(loginService == 'jwgl'){
        await GlobalVars.globalDio.get(
          'http://jwgl.snut.edu.cn${authresponse22.headers['location']![0]}',
          options: Options(
            followRedirects: false,
          )
        );
      }if(loginService == 'wzxy'){
        await GlobalVars.globalDio.get(
          authresponse22.headers['location']![0],
          options: Options(
            followRedirects: false,
            validateStatus: (status) {
              return status! <= 400;
            },
          )
        );
      }
    }catch(e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    message.clear();
    message.add({
      'statue': true,
      'message': '登录成功',
    });
    return message;
  }

  //获取学籍信息
  static Future<List> getStdDetail() async {
    //存储返回的信息
    List message = [];

    late Response stdDetailresponse;
    try{
      //if(loginAuthCanceled) return;
      stdDetailresponse = await GlobalVars.globalDio.get('http://jwgl.snut.edu.cn/eams/stdDetail.action');
    }catch(e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器1，请稍后再试',
      });
      return message;
    }
    // 解析 HTML
    var document = parser.parse(stdDetailresponse.data);
    List<dom.Element> tableRows = document.querySelectorAll("table#studentInfoTb tr");

    // 存储解析后的数据
    Map<String, String> studentInfo = {};

    for (var row in tableRows) {
      List<dom.Element> columns = row.querySelectorAll("td"); 
      for (int i = 0; i < columns.length - 1; i += 2) {
        String key = columns[i].text.trim();
        String value = columns[i + 1].text.trim();
        if (key.isNotEmpty) {
          studentInfo[key] = value;
        }
      }
    }

    // 转换为 JSON 并保存到本地
    String jsonOutput = jsonEncode(studentInfo);
    String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailfile = File(stdDetailpath);
    stdDetailfile.writeAsString(jsonOutput);
    GlobalVars.stdDetail = studentInfo;
    
    message.clear();
    message.add({
      'statue': true,
      'message': '',
    });
    return message;
  }

  //读取学期信息
  static Future<List> getSemestersData() async {
    //存储返回的信息
    List message = [];

    String semesterspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/semesters.json';
    File semestersfile = File(semesterspath);
    message.clear();
    message.add({
      'statue': true,
      'message': '',
      'semestersData': jsonDecode(await semestersfile.readAsString()),
    });
    return message;
  }

  //获取课表数据
  static Future<List> getCourseTable(int currentYearInt,int currentTermInt) async {
    GlobalVars.loadingHint = '正在获取课表数据...';

    //存储返回的信息
    List message =[];

    String termStart = '';
    String termEnd = '';
    int termWeeks = 0;
    
    //等待 350 毫秒，防止教务系统判定为过快点击
    if(GlobalVars.operationCanceled) {
      message.clear();
      message.add({
        'statue': true,
        'message': '操作已取消',
      });
      return message;
    }
    await Future.delayed(Duration(milliseconds: 350));

    //请求课表初始信息
    late Response courseresponse1;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      courseresponse1 = await GlobalVars.globalDio.get('http://jwgl.snut.edu.cn/eams/courseTableForStd.action');
    }catch (e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    //提取相关数据
    String semesterId = '';
    String tagId = '';
    String idsMe = '';
    //String idsClass = ''; 班级课表 id

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(courseresponse1.headers['Set-Cookie']!.first);
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
      //idsClass = idsmatch.elementAt(1).group(1)!; 班级课表
    }

    //获取所有学期的 semester.id，学年名称，学期名称
    final courseTableformData = FormData.fromMap({
      "tagId": 'semesterBar${tagId}Semester',
      "dataType": 'semesterCalendar',
      "value": semesterId.toString(),
      "empty": 'false'
    });
    late Response courseresponse2;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      courseresponse2 = await GlobalVars.globalDio.post(
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
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    
    String rawdata = courseresponse2.data.toString();
    late String semesters;

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
    semesterId = '0';
    if(currentYearInt != -1 || currentTermInt != -1){
      List semestersDataResponse = await getSemestersData();
      semesterId = semestersDataResponse[0]['semestersData']['y$currentYearInt'][currentTermInt -1]['id'].toString();
    }
    
    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    final courseTablegetformData = FormData.fromMap({
      "ignoreHead": '1',
      "setting.kind": 'std',
      "startWeek": '',
      "semester.id": semesterId,
      'ids': idsMe,
    });
    late Response courseresponse3;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      courseresponse3 = await GlobalVars.globalDio.post(
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
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
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

    List<Match> courseBlocks = courseBlockPattern.allMatches(courseresponse3.data).toList();
    List<Match> teacherBlocks = teacherPattern.allMatches(courseresponse3.data).toList();
    List<String> rawTimeBlocks = courseresponse3.data.split(RegExp(r'activity\s*=\s*new\s*TaskActivity\(.*?\);', dotAll: true));


    List<List<String>> extractedTeachers = teacherBlocks.map((teacherMatch) {
      RegExp singleTeacherPattern = RegExp(r'name:"([^"]+)"');
      Iterable<Match> matches = singleTeacherPattern.allMatches(teacherMatch.group(1)!);
      return matches.map((match) => match.group(1)!).toList();
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
        RegExp timePattern = RegExp(r'index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+);');
        Iterable<Match> matches = timePattern.allMatches(timeSection);
        extractedTimes.add(
          matches.map((match) {
            return {
              "DayOfWeek": int.parse(match.group(1)!),
              "TimeOfDay": int.parse(match.group(2)!)
            };
          }).toList()
        );
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
    if(currentYearInt != -1 || currentTermInt != -1){
      List semestersDataResponse = await getSemestersData();
      semesterId = semestersDataResponse[0]['semestersData']['y$currentYearInt'][currentTermInt -1]['id'].toString();
    }
    
    //等待 350 毫秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));
    final schoolCalendarformData = FormData.fromMap({
      "semester.id": semesterId,
      '_': '1740564686472',
    });
    late Response schoolCalendarresponse;
    try{
      schoolCalendarresponse = await GlobalVars.globalDio.post(
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
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
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
    message.clear();
    message.add({
      'statue': true,
      'message': '',
    });
    return message;
  }
  
  //获取考试信息
  static Future<List> getStdExam(int currentYearInt,int currentTermInt,int currentExamBatch) async {
    GlobalVars.loadingHint = '正在获取考试数据...';

    //存储返回的信息
    List message = [];

    //存储考试批次
    String currentExamBatchid = '';

    late Response stdExamresponse1;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      stdExamresponse1 = await GlobalVars.globalDio.get(
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
            'Referer': 'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
          }
        ),
        'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
      );
    }catch (e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
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
    List semestersDataResponse = await getSemestersData();
    semesterId = semestersDataResponse[0]['semestersData']['y$currentYearInt'][currentTermInt -1]['id'].toString();

    //等待半秒，防止教务系统判定为过快点击
    if(GlobalVars.operationCanceled) {
      message.clear();
      message.add({
        'statue': true,
        'message': '操作已取消',
      });
      return message;
    }
    await Future.delayed(Duration(milliseconds: 500));

    //if(getStdExamCanceled) return;
    late Response stdExamresponse5;
    try{
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      var data = {
        'project.id': '1',
        'semester.id': semesterId
      };
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      stdExamresponse5 = await GlobalVars.globalDio.request(
        'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
    }catch (e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }

    dom.Document stdExamdocument1 = parser.parse(stdExamresponse5.data);
    // 找到 <select> 标签
    dom.Element? select = stdExamdocument1.querySelector('select#examBatchId');
    if (select == null){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法获取考试批次信息',
      });
      return message;
    }

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
    semesterId = semestersDataResponse[0]['semestersData']['y$currentYearInt'][currentTermInt -1]['id'].toString();

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
        currentExamBatchid = normalExam;
      }if(currentExamBatch == 1){
        currentExamBatchid = retakeExam;
      }
    }else{
      message.clear();
      message.add({
        'statue': false,
        'message': '当前学期暂未设置考试',
      });
      return message;
    }

    //if(getStdExamCanceled) return;
    late Response stdExamresponse6;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      stdExamresponse6 = await GlobalVars.globalDio.get(
        'http://jwgl.snut.edu.cn/eams/stdExamTable!examTable.action?examBatch.id=$currentExamBatchid',
        options: Options(
          headers: {
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
      );
    }catch (e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }

    List<Map<String, String>> foundedExams = [];
    dom.Document stdExmaDocument2 = parser.parse(stdExamresponse6.data);
    
    //提取 tableid
    dom.Element? table = stdExmaDocument2.querySelector('table.gridtable');
    if (table == null) {
      message.clear();
      message.add({
        'statue': false,
        'message': '无法获取考试信息',
      });
      return message;
    }
    String? tableId = table.attributes['id']; // 使用attributes获取id
    if (tableId == null || tableId.isEmpty) {
      message.clear();
      message.add({
        'statue': false,
        'message': '无法获取考试信息',
      });
      return message;
    }

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

    //保存考试信息到本地
    //使用本地选中的 semetserid
    semesterId = semestersDataResponse[0]['semestersData']['y$currentYearInt'][currentTermInt -1]['id'].toString();
    String stdExampath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-$currentExamBatchid.json';
    File stdExamfile = File(stdExampath);
    stdExamfile.writeAsString(jsonEncode(foundedExams));

    message.clear();
    message.add({
      'statue': true,
      'message': '',
      'stdExamTotal': foundedExams,
    });
    return message;

  }

  //获取成绩信息
  static Future<List> getStdGrades(int currentYearInt,int currentTermInt) async {
    GlobalVars.loadingHint = '正在获取成绩数据...';

    //存储返回的信息
    List message = [];

    //等待 350 毫秒，防止教务系统判定为过快点击
    if(GlobalVars.operationCanceled) {
      message.clear();
      message.add({
        'statue': true,
        'message': '操作已取消',
      });
      return message;
    }
    await Future.delayed(Duration(milliseconds: 350));

    late Response stdGradesresponse1;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      stdGradesresponse1 = await GlobalVars.globalDio.get(
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
          }
        ),
        'http://jwgl.snut.edu.cn/eams/teach/grade/course/person.action',
      );
    }catch (e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }

    //提取相关数据
    String semesterId = '';

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(stdGradesresponse1.headers['Set-Cookie']!.first);
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    //使用本地选中的 semetserid
    List semestersDataResponse = await getSemestersData();
    semesterId = semestersDataResponse[0]['semestersData']['y$currentYearInt'][currentTermInt -1]['id'].toString();

    //开始下载成绩
    late Response stdGradesresponse2;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      stdGradesresponse2 = await GlobalVars.globalDio.get(
        'http://jwgl.snut.edu.cn/eams/teach/grade/course/person!search.action?semesterId=$semesterId',
        options: Options(
          headers: {
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
      );
    }catch (e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }

    List<Map<String, String>> foundedGrades = [];
    dom.Document stdExmaDocument2 = parser.parse(stdGradesresponse2.data);
    
    //提取 tableid
    dom.Element? table = stdExmaDocument2.querySelector('table.gridtable');
    if (table == null) {
      message.clear();
      message.add({
        'statue': false,
        'message': '无法获取成绩信息',
      });
      return message;
    }
    String? tableId = table.attributes['id']; // 使用attributes获取id
    if (tableId == null || tableId.isEmpty) {
      message.clear();
      message.add({
        'statue': false,
        'message': '无法获取成绩信息',
      });
      return message;
    }

    // 查找 tbody 对应的 id
    String tbodyId = "${tableId}_data";
    stdExmaDocument2.querySelectorAll('#$tbodyId tr').forEach((tr) {
      List<dom.Element> tds = tr.querySelectorAll('td');
      if (tds.length >= 8) {
        Map<String, String> grades = {
          "CourseTY": tds[0].text.trim(),
          "CourseCode": tds[1].text.trim(),
          "CourseID": tds[2].text.trim(),
          "CourseName": tds[3].text.trim(),
          "CourseType": tds[4].text.trim(),
          "CourseCredit": tds[5].text.trim(),
          "CourseGradeTotal": tds[6].text.trim(),
          "CourseGradeFinal": tds[7].text.trim(),
          "CourseGradeGPA": tds[8].text.trim(),
        };
        foundedGrades.add(grades);
      }
    });

    // 保存成绩信息到本地
    // 使用本地选中的 semetserid
    semesterId = semestersDataResponse[0]['semestersData']['y$currentYearInt'][currentTermInt -1]['id'].toString();

    String stdGradespath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades/stdGrades$semesterId.json';
    File stdGradesfile = File(stdGradespath);
    stdGradesfile.writeAsString(jsonEncode(foundedGrades));

    if(foundedGrades.isEmpty){
      message.clear();
      message.add({
        'statue': false,
        'message': '当前学期暂未设置成绩',
      });
      return message;
    }
    message.clear();
    message.add({
      'statue': true,
      'message': '',
      'stdGradesTotal': foundedGrades,
    });
    return message;
  }

  //初始化空闲教室数据
  static Future<List> initPublicFreeData() async {
    GlobalVars.loadingHint = '正在获取初始数据...';

    //存储返回的信息
    List message = [];

    late Response publicFreeResponse;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      publicFreeResponse = await GlobalVars.globalDio.get('http://jwgl.snut.edu.cn/eams/publicFree!index.action');
    }catch(e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }

    //解析选择框数据
    List classroomTypeList = [];
    List campusList = [];
    List buildingList = [];

    // 使用 HTML 解析器解析响应内容
    var document = parser.parse(publicFreeResponse.data);
    
    // 提取教室类型数据
    var classroomTypeSelect = document.querySelector('select#type');
    if (classroomTypeSelect != null) {
      var options = classroomTypeSelect.querySelectorAll('option');
      classroomTypeList.add({
        'name': '未选择',
        'id': ''
      });
      for (var option in options) {
        String value = option.attributes['value'] ?? '';
        String title = option.attributes['title'] ?? '';
        
        // 跳过空选项（通常是"..."选项）
        if (value.isNotEmpty && title.isNotEmpty) {
          classroomTypeList.add({
            'name': title,
            'id': value
          });
        }
      }
    }
    
    // 提取校区数据
    var campusSelect = document.querySelector('select#campus');
    if (campusSelect != null) {
      var options = campusSelect.querySelectorAll('option');
      campusList.add({
        'name': '未选择',
        'id': ''
      });
      for (var option in options) {
        String value = option.attributes['value'] ?? '';
        String title = option.attributes['title'] ?? '';
        
        if (value.isNotEmpty && title.isNotEmpty) {
          campusList.add({
            'name': title,
            'id': value
          });
        }
      }
    }
    
    // 提取教学楼数据
    var buildingSelect = document.querySelector('select#building');
    if (buildingSelect != null) {
      var options = buildingSelect.querySelectorAll('option');
      buildingList.add({
        'name': '未选择',
        'id': ''
      });
      for (var option in options) {
        String value = option.attributes['value'] ?? '';
        String title = option.attributes['title'] ?? '';
        
        if (value.isNotEmpty && title.isNotEmpty) {
          buildingList.add({
            'name': title,
            'id': value
          });
        }
      }
    }

    // 返回成功信息和提取的数据
    message.clear();
    message.add({
      'statue': true,
      'message': '获取空闲教室初始数据成功',
      'campusList': campusList,
      'buildingList': buildingList,
      'classroomTypeList': classroomTypeList,
    });
    return message;
  }

  //查询空闲教室
  static Future<List> queryPublicFreeData(String classroomType,  String campus, String building,  String seats,  String classroomName, String cycleCount, String cycleType, String dateStart, String dateEnd, String roomApplyType, String timeBegin, String timeEnd,int pageNo) async {
    GlobalVars.loadingHint = '正在查询空闲教室...';

    //存储返回的信息
    List message = [];
    List publicFreeData = [];

    //查询信息
    var headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    var data = {
      'classroom.type.id': classroomType,
      'classroom.campus.id': campus,
      'classroom.building.id': building,
      'seats': seats,
      'classroom.name': classroomName,
      'cycleTime.cycleCount': cycleCount,
      'cycleTime.cycleType': cycleType,
      'cycleTime.dateBegin': dateStart,
      'cycleTime.dateEnd': dateEnd,
      'roomApplyTimeType': roomApplyType,
      'timeBegin': timeBegin,
      'timeEnd': timeEnd,
      'pageNo':pageNo
    };

    late Response publicFreeResponse;
    try {
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      var response = await GlobalVars.globalDio.request(
        'http://jwgl.snut.edu.cn/eams/publicFree!search.action',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      publicFreeResponse = response;
    } catch(e) {
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    
    //提取查询结果
    int currentPage = 1;
    int pageSize = 20;
    int totalItems = 0;
    try {
      // 使用HTML解析器解析响应内容
      var document = parser.parse(publicFreeResponse.data);
      // 获取教室数据表格，从表格体获取所有行
      var tableRows = document.querySelectorAll('table.gridtable > tbody > tr');
      // 遍历所有行，跳过标题行
      for (var row in tableRows) {
        var cells = row.querySelectorAll('td');
        if (cells.length >= 6) {
          // 直接从单元格中提取数据
          Map<String, String> classroom = {
            'Number': cells[0].text.trim(),              // 序号
            'Name': cells[1].text.trim(),                // 名称
            'Building': cells[2].text.trim(),            // 教学楼
            'Campus': cells[3].text.trim(),              // 校区
            'ClassroomType': cells[4].text.trim(),       // 教室设备配置
            'Capacity': cells[5].text.trim().replaceAll(RegExp(r'\s+'), ''), // 容量
          };
          publicFreeData.add(classroom);
        }
      }
      
      // 获取分页信息
      var scripts = document.querySelectorAll('script');
      for (var script in scripts) {
        String scriptText = script.text;
        if (scriptText.contains('page_grid') && scriptText.contains('pageInfo')) {
          // 提取总页数和每页数量信息
          RegExp pageInfoRegex = RegExp(r'page_\w+\.pageInfo\((\d+),(\d+),(\d+)\);');
          Match? pageInfoMatch = pageInfoRegex.firstMatch(scriptText);
          if (pageInfoMatch != null && pageInfoMatch.groupCount >= 3) {
            currentPage = int.parse(pageInfoMatch.group(1)!);
            pageSize = int.parse(pageInfoMatch.group(2)!);
            totalItems = int.parse(pageInfoMatch.group(3)!);
            break;
          }
        }
      }
      
    } catch (e) {
      message.clear();
      message.add({
        'statue': false,
        'message': '解析教室数据失败: ${e.toString()}',
      });
      return message;
    }

    message.clear();
    message.add({
      'statue': true,
      'message': '查询空闲教室成功',
      'currentPage': currentPage,
      'pageSize': pageSize,
      'totalItems': totalItems,
      'publicFreeData': publicFreeData,
    });

    return message;
  }

  //获取班级列表
  static Future<List> getClassList() async {
    GlobalVars.loadingHint = '正在获取班级列表...';

    //存储返回的信息
    List message = [];

    late Response classListResponse;
    try{
      if(GlobalVars.operationCanceled) {
        message.clear();
        message.add({
          'statue': true,
          'message': '操作已取消',
        });
        return message;
      }
      classListResponse = await GlobalVars.globalDio.get('https://wzxy.snut.edu.cn/basicinfo/mobile/studentAddressBookV2/classes/getAddressBookList');
    }catch(e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    Map classListJson = jsonDecode(classListResponse.data.toString());

    String classListpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/wzxyData/classList.json';
    File classListfile = File(classListpath);
    classListfile.writeAsString(jsonEncode(classListJson['data']['classesList']));

    message.clear();
    message.add({
      'statue': true,
      'message': '获取班级列表成功',
      'classList': classListJson['data']['classesList'],
    });
    return message;
  }

  //获取班级成员列表
  static Future<List> getClassMemberList(String classId) async {
    GlobalVars.loadingHint = '正在获取班级成员列表...';

    //存储返回的信息
    List message = [];

    late Response getClassUsersResponse;
    try{
      var response = await GlobalVars.globalDio.get('https://wzxy.snut.edu.cn/basicinfo/mobile/studentAddressBookV2/classes/getClassesUsers?classesId=$classId');
      getClassUsersResponse = response;
    }catch(e){
      message.clear();
      message.add({
        'statue': false,
        'message': '无法连接服务器，请稍后再试',
      });
      return message;
    }
    Map classMemberJson = jsonDecode(getClassUsersResponse.data.toString());

    String classMemberpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/wzxyData/ClassMembersList-$classId.json';
    File classMemberfile = File(classMemberpath);
    classMemberfile.writeAsString(jsonEncode(classMemberJson['data']));

    message.clear();
    message.add({
      'statue': true,
      'message': '获取班级成员列表成功',
      'classMemberList': jsonEncode(classMemberJson['data']),
    });
    return message;
  }
}