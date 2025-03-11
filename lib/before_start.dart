import 'package:flutter/material.dart';

class BeforeStart extends StatefulWidget{
  const BeforeStart ({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BeforeStartState();
  }
}

class _BeforeStartState extends State<BeforeStart>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      body: ListView(),
    );
  }
}