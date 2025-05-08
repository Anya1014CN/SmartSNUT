import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:smartsnut/globalvars.dart';

//用于存储外部链接的完整URL
Uri url = Uri.parse("uri");

//用户数据
String realName = GlobalVars.realName;
String balance = '';
String state = '';
String expire = '';

class SchoolNetworkPage extends StatefulWidget{
  const SchoolNetworkPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SchoolNetworkPage();
  }
}

class _SchoolNetworkPage extends State<SchoolNetworkPage>{
  late TextEditingController textUsernameController;
  bool _showAppBarTitle = false;

  @override
  void dispose() {
    textUsernameController.dispose();
    super.dispose();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled) {
        UmengCommonSdk.onPageEnd("校内应用 - 网费查询");
    }
  }

  @override
  void initState() {
    textUsernameController = TextEditingController();
    textUsernameController.text = GlobalVars.userName;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      networkQuery();
      if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled) {
          UmengCommonSdk.onPageStart("校内应用 - 网费查询");
      }
    });
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
                title: _showAppBarTitle ? Text("网费查询") : null,
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
                          ? AssetImage('assets/icons/lighttheme/web.png')
                          : AssetImage('assets/icons/darktheme/web.png'),
                        height: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '网费查询',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              
              // 账号输入框
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Card(
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: TextField(
                      controller: textUsernameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelText: '学号/工号',
                        hintText: '请输入您的学号/工号',
                        prefixIcon: Icon(Icons.person),
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 操作按钮区域
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                        color: Theme.of(context).colorScheme.primary,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if(textUsernameController.text == '') {
                              if(mounted) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    scrollable: true,
                                    title: Row(
                                      children: [
                                        Icon(Icons.info),
                                        SizedBox(width: 8),
                                        Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                                      ],
                                    ),
                                    content: Text('请您输入账号或登录后再查询', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('确定'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              networkQuery();
                            }
                          },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            child: Text(
                              '网费查询',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            url = Uri.parse('https://netpay.snut.edu.cn/WebPay/toRecharge?account=${textUsernameController.text}');
                            launchURL();
                          },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            child: Text(
                              '立即充值',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              
              // 用户信息卡片
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Card(
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '账号：${textUsernameController.text}',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextLarge,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '姓名：$realName',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextLarge,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '余额：$balance',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextLarge,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '状态：$state',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextLarge,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '到期时间：$expire',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextLarge,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 服务说明卡片
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Card(
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Text(
                            '服务说明',
                            style: TextStyle(
                              fontSize: GlobalVars.genericTextLarge,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '1. 校园网用户可使用微信，支付宝，云闪付等多种线上方式对校园网账号充值',
                            style: TextStyle(
                              fontSize: GlobalVars.genericTextMedium,
                              height: 1.5
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '2. 账号框输入校园网上网账号--->点击"网费查询"可查看账号状态及到期日期，点击"立即充值"按页面提示操作并完成支付即可完成对校园网账号的充值',
                            style: TextStyle(
                              fontSize: GlobalVars.genericTextMedium,
                              height: 1.5
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '3. 充值遇到问题，请致电信息化建设与管理处,服务电话:09162641255',
                            style: TextStyle(
                              fontSize: GlobalVars.genericTextMedium,
                              height: 1.5
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  networkQuery() async {
    bool networkQueryCanceled = false;
    if(mounted){
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('请稍后...', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Column(
            children: [
              SizedBox(height: 10,),
              CircularProgressIndicator(),
              SizedBox(height: 10,),
              Text('正在查询...',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                networkQueryCanceled = true;
                Navigator.pop(context);
              },
              child: Text('取消'),
            ),
          ],
        ),
      );
    }
    CookieJar netcookiejar = CookieJar();
    Dio dio = Dio(
      BaseOptions(
        headers: {
          'User-Agent':
              (Platform.isWindows)? 'SmartSNUT-Windows/${GlobalVars.versionCodeString}':(Platform.isAndroid)? 'SmartSNUT-Android/${GlobalVars.versionCodeString}':'SmartSNUT/${GlobalVars.versionCodeString}',
        }
      )
    );
    dio.interceptors.add(CookieManager(netcookiejar));

    //第一次请求，提取相关信息
    if(networkQueryCanceled) return;
    late html_dom.Document document;
    String csrfToken = '';
    String ajaxCsrfToken = '';

    try{
      Response netresponse1 = await dio.get('https://netpay.snut.edu.cn/WebPay/toRecharge?account=${textUsernameController.text}');
      document = html_parser.parse(netresponse1.data);
      
      //提取 csrftoken
      final csrfTokenInput = document.querySelector('input[name="csrftoken"]');
      csrfToken = csrfTokenInput?.attributes['value']?? '';

      //提取 AJAXCSRFTOKEN
      final ajaxCsrfTokenRegExp = RegExp(r'window\.AJAXCSRFTOKEN\s*=\s*"([^"]+)"');
      final ajaxCsrfTokenMatch = ajaxCsrfTokenRegExp.firstMatch(netresponse1.data);
      ajaxCsrfToken = (ajaxCsrfTokenMatch?.group(1)).toString();
    }catch (e){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info),
                SizedBox(width: 8),
                Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text('无法连接网络，请稍后再试', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
      }
      return;
    }


    //第二次请求，查询数据
    if(networkQueryCanceled) return;
    late Response netresponse2;
    try{
      netresponse2 = await dio.post(
        'https://netpay.snut.edu.cn/WebPay/queryUser',
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-CSRF-Token': csrfToken,
            'Referer': 'https://netpay.snut.edu.cn/WebPay/toRecharge?account=${textUsernameController.text}',
          },
        ),
        data: {
          'ajaxCsrfToken': ajaxCsrfToken,
          'token': csrfToken,
          'account': textUsernameController.text
        },
      );
    }catch(e){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info),
                SizedBox(width: 8),
                Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text('无法查询到信息，请检查您输入的账号是否正确！', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          )
        );
        setState(() {
          realName = '';
          balance = '';
          state = '';
          expire = '';
        });
      }
      return;
    }

    var netdata = jsonDecode(netresponse2.data);
    if(netdata['userName'] == ''){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info),
                SizedBox(width: 8),
                Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text('无法查询到信息，请检查您输入的账号是否正确！', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          )
        );
        setState(() {
          realName = '';
          balance = '';
          state = '';
          expire = '';
        });
      }
      return;
    }
    if(mounted){
      setState(() {
        realName = netdata['userName'];
        balance = netdata['leftMoney'];
        state = netdata['useFlag'];
        expire = netdata['dueDate'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('网费数据查询成功'),
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

  //打开链接
  void launchURL() async{
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.help),
            SizedBox(width: 8),
            Text('询问', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
          ],
        ),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if(context.mounted){
                Navigator.pop(context);
              }
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}