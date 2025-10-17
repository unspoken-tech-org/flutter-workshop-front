import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/controllers/customer_register_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/widgets/customer_register_form.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:provider/provider.dart';

class CustomerRegisterPage extends StatefulWidget {
  static const String route = 'customer_register';

  const CustomerRegisterPage({super.key});

  @override
  State<CustomerRegisterPage> createState() => _CustomerRegisterPageState();
}

class _CustomerRegisterPageState extends State<CustomerRegisterPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ChangeNotifierProvider(
      lazy: false,
      create: (context) => CustomerRegisterController(
        CustomerRemoteDataSource(),
      ),
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: width * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CustomerRegisterForm(),
          ),
        ),
      ),
    );
  }
}
