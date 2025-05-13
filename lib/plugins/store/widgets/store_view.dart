import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import '../controllers/store_controller.dart';

class StoreView extends StatelessWidget {
  final StoreController controller;

  const StoreView({
    Key? key, 
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreMain(
      controller: controller,
    );
  }
}

