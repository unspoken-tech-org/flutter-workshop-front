import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/all_customers/all_customer_controller.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/all_customers/inherited_all_customer_controller.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/customers_list.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/customers_list_shimmer.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';

class AllCustomersPage extends StatefulWidget {
  static const String route = 'customers';

  const AllCustomersPage({super.key});

  @override
  State<AllCustomersPage> createState() => _AllCustomersPageState();
}

class _AllCustomersPageState extends State<AllCustomersPage> {
  late final AllCustomerController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AllCustomerController();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void clearSearch() {
    _searchController.clear();
    _controller.searchCustomers(null);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedAllCustomerController(
      controller: _controller,
      child: WsScaffold(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Clientes', style: WsTextStyles.h1),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Cliente'),
                        onPressed: () =>
                            WsNavigator.pushCustomerRegister(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _controller.searchCustomers,
                      decoration: InputDecoration(
                        labelText: 'Buscar por nome, CPF, ID ou telefone',
                        labelStyle: WsTextStyles.body1.copyWith(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Colors.blue.shade700,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: clearSearch,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        if (_controller.isLoading) {
                          return const CustomersListShimmer();
                        }
                        if (_controller.customers.isEmpty) {
                          return const EmptyListWidget(
                            message: 'Nenhum cliente encontrado',
                          );
                        }
                        return CustomersList(
                          customers: _controller.customers,
                          onTap: (customerId) {
                            WsNavigator.pushCustomerDetail(context, customerId);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
