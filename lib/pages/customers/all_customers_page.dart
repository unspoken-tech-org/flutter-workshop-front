import 'package:flutter/material.dart';
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
          appBar: AppBar(
            title: const Center(child: Text('Clientes')),
          ),
          body: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _controller.searchCustomers,
                          decoration: InputDecoration(
                            labelText: 'Buscar por nome, CPF, ID ou telefone',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: clearSearch,
                                  )
                                : null,
                          ),
                        ),
                      ),
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
                                WsNavigator.pushCustomerDetail(
                                    context, customerId);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                right: (MediaQuery.of(context).size.width / 4) - 80,
                child: FloatingActionButton(
                  onPressed: () {
                    WsNavigator.pushCustomerRegister(context);
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
