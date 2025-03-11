import 'package:flutter/material.dart';
import 'package:smartsnut/globalvars.dart';

class EMBindGuidePage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        title: Text('电费账号绑定教程',style: TextStyle(fontSize: GlobalVars.guide_page_title),),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: IconButton(
          onPressed: (){Navigator.pop(context);},
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        children: [
          Center(child: Text('智慧陕理 电费账号绑定教程',style: TextStyle(fontSize: GlobalVars.guide_title_title,fontWeight: FontWeight.bold),),),
          SizedBox(height: 10,),
          Container(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
              color: Theme.of(context).colorScheme.surfaceDim,
              shadowColor: Theme.of(context).colorScheme.onPrimary,
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('1.首先，您需要关注 陕西理工大学后勤保障部 公众号',style: TextStyle(fontSize: GlobalVars.guide_content_title),textAlign: TextAlign.start,),
                    SizedBox(height: 10,),
                    Image(image: AssetImage('assets/guide/EMBindGuide/1.jpg')),
                    SizedBox(height: 10,),
                    Text('2.关注后，点击 智慧后勤 -〉 电费充值',style: TextStyle(fontSize: GlobalVars.guide_content_title),textAlign: TextAlign.start),
                    SizedBox(height: 10,),
                    Image(image: AssetImage('assets/guide/EMBindGuide/2.jpg')),
                    SizedBox(height: 10,),
                    Text('3.授权登录后，点击信息查询，确保账号下已经绑定至少一个电表',style: TextStyle(fontSize: GlobalVars.guide_content_title),textAlign: TextAlign.start),
                    SizedBox(height: 10,),
                    Image(image: AssetImage('assets/guide/EMBindGuide/3.jpg')),
                    SizedBox(height: 10,),
                    Text('若未绑定电表，请先点击 绑定用户 绑定电表',style: TextStyle(fontSize: GlobalVars.guide_content_title),),
                    SizedBox(height: 10,),
                    Image(image: AssetImage('assets/guide/EMBindGuide/4.jpg')),
                    Image(image: AssetImage('assets/guide/EMBindGuide/5.jpg')),
                    SizedBox(height: 10,),
                    Text('4.点击右上角三个点，点击 复制链接，并将其粘贴到便于编辑的地方',style: TextStyle(fontSize: GlobalVars.guide_content_title),),
                    SizedBox(height: 10,),
                    Image(image: AssetImage('assets/guide/EMBindGuide/6.jpg')),
                    SizedBox(height: 10,),
                    Text('5.如图，wechatUserOpenid= 后面的内容（不包含等号）ob6-qwZxxxxxxxxxxxxxxxfL4f0Q 即为获取到的 openId （注意：请务必保护好您的 openId，请勿泄露给任何人，否则您的电费账号可能会被他人盗取',style: TextStyle(fontSize: GlobalVars.guide_content_title),),
                    SizedBox(height: 10,),
                    Image(image: AssetImage('assets/guide/EMBindGuide/7.jpg')),
                    SizedBox(height: 10,),
                    Text('6.回到智慧陕理，打开电费账号绑定页面，填入刚刚获取的 openId，点击绑定',style: TextStyle(fontSize: GlobalVars.guide_content_title),),
                    Image(image: AssetImage('assets/guide/EMBindGuide/8.jpg')),
                    Image(image: AssetImage('assets/guide/EMBindGuide/9.jpg')),
                  ],
                ),
              )
            )
          ),
        ],
      ),
    );
  }
}