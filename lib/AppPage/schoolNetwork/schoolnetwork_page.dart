import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:smartsnut/globalvars.dart';

//用于存储外部链接的完整URL
Uri url = Uri.parse("uri");

//状态相关变量
bool isQuerying = false;

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
  final textUsernameController = TextEditingController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    textUsernameController.text = GlobalVars.userName;
    networkQuery();
    super.initState();
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
                padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
                child: Row(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/web.png'):AssetImage('assets/icons/darktheme/web.png'),height: 40,),
                    SizedBox(width: 10,),
                    Text('网费查询',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: TextField(
                      controller: textUsernameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '学号/工号',
                        hintText: '请输入您的学号/工号',
                        filled: false
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: SizedBox(
                          height: 75,
                          child:isQuerying? Center(child: CircularProgressIndicator(),):TextButton(
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: isQuerying? null:() {
                              if(textUsernameController.text == ''){
                                if(mounted){
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) => AlertDialog(
                                      scrollable: true,
                                      title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                                      content: Text('请您输入账号或登录后再查询',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, 'OK'),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }else{
                                networkQuery();
                              }
                            },
                            child: Text('网费查询',style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: SizedBox(
                          height: 75,
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: (){
                              url = Uri.parse('https://netpay.snut.edu.cn/WebPay/toRecharge?account=${textUsernameController.text}');
                              launchURL();
                            },
                            child: Text('立即充值',style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('账号：${textUsernameController.text}',style: TextStyle(fontSize: GlobalVars.genericTextLarge),),
                          SizedBox(height: 15,),
                          Text('姓名：$realName',style: TextStyle(fontSize: GlobalVars.genericTextLarge),),
                          SizedBox(height: 15,),
                          Text('余额：$balance',style: TextStyle(fontSize: GlobalVars.genericTextLarge),),
                          SizedBox(height: 15,),
                          Text('状态：$state',style: TextStyle(fontSize: GlobalVars.genericTextLarge),),
                          SizedBox(height: 15,),
                          Text('到期时间：$expire',style: TextStyle(fontSize: GlobalVars.genericTextLarge),),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('服务说明',style: TextStyle(fontSize: GlobalVars.genericTextLarge,fontWeight: FontWeight.bold),),
                        Text('1.校园网用户可使用微信，支付宝，云闪付等多种线上方式对校园网账号充值',style: TextStyle(fontSize: GlobalVars.genericTextMedium),),
                        Text('2.账号框输入校园网上网账号--->点击“网费查询”可查看账号状态及到期日期，点击“立即充值”按页面提示操作并完成支付即可完成对校园网账号的充值',style: TextStyle(fontSize: GlobalVars.genericTextMedium),),
                        Text('3.充值遇到问题，请致电信息化建设与管理处,服务电话:09162641255',style: TextStyle(fontSize: GlobalVars.genericTextMedium),),
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
    if(mounted){
      setState(() {
      isQuerying = true;
    });
    }
    CookieJar netcookiejar = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(netcookiejar));

    //第一次请求，提取相关信息
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
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接网络，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('确定'),
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


    //第二次请求，查询数据
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
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法查询到信息，请检查您输入的账号是否正确！',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'OK'), child: Text('确认'))],
          )
        );
        setState(() {
          realName = '';
          balance = '';
          state = '';
          expire = '';
          isQuerying = false;
        });
      }
      return;
    }

    var netdata = jsonDecode(netresponse2.data);
    if(netdata['userName'] == ''){
      if(mounted){
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法查询到信息，请检查您输入的账号是否正确！',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'OK'), child: Text('确认'))],
          )
        );
        setState(() {
          realName = '';
          balance = '';
          state = '';
          expire = '';
          isQuerying = false;
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
      isQuerying = false;
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
}