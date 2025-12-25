import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../cubit/checklist_list_cubit.dart';
import 'checklist_list_page.dart';

class Checklist extends StatelessWidget {
  const Checklist({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChecklistListCubit(AuthManager()),
      child: const ChecklistListPage(),
    );
  }
}
