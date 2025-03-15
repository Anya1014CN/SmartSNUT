import 'package:flutter/material.dart';
import 'package:smartsnut/globalvars.dart';

class GPACalculatorPage extends StatefulWidget{
  const GPACalculatorPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GPACalculatorPageState();
  }
}

class _GPACalculatorPageState extends State<GPACalculatorPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: IconButton(
          onPressed: (){Navigator.pop(context);},
          icon: Icon(Icons.arrow_back),
        ),
      ),
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
        ],
      ),
    );
  }
}