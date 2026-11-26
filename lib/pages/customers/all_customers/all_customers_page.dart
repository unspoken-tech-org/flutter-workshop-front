import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/controllers/all_customer_controller.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customers_list.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customers_list_shimmer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/widgets/core/ui_message_listener.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';
import 'package:flutter_workshop_front/widgets/shared/refresh_on_return.dart';
import 'package:flutter_workshop_front/widgets/ws_search_bar_widget.dart';
import 'package:provider/provider.dart';

class AllCustomersPage extends StatelessWidget {
  static const String route = 'customers';

  const AllCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AllCustomerController(
        customerRepository: context.read<CustomerRepository>(),
      ),
      child: const ProviderUiMessageListener<AllCustomerController>(
        child: AllCustomersView(),
      ),
    );
  }
}

class AllCustomersView extends StatelessWidget {
  const AllCustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AllCustomerController>();
    return RefreshOnReturn(
      onReturn: () => unawaited(controller.reload()),
      child: WsScaffold(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              children: [
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Clientes', style: WsTextStyles.h1),
                    Semantics(
                      identifier: 'customers.add',
                      child: TextButton.icon(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                WsSearchBarWidget(
                  labelText: 'Buscar por nome, CPF, ID ou telefone',
                  semanticsIdentifier: 'customers.search',
                  onChanged: controller.searchCustomers,
                  onClear: () => unawaited(controller.searchCustomers(null)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      if (controller.isLoading) {
                        return const CustomersListShimmer();
                      }
                      if (controller.customers.isEmpty) {
                        return const EmptyListWidget(
                          message: 'Nenhum cliente encontrado',
                        );
                      }
                      return CustomersList(
                        customers: controller.customers,
                        controller: controller,
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
    );
  }
}
