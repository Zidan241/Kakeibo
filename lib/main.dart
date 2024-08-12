import 'package:kakeibo/app.dart';
import 'package:kakeibo/bloc/cubit/app_cubit.dart';
import 'package:kakeibo/helpers/db.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getDBInstance();
  AppState appState = await AppState.getState();
  await dotenv.load(fileName: ".env");
  runApp(MultiBlocProvider(
      providers: [BlocProvider(create: (_) => AppCubit(appState))],
      child: const App()));
}
