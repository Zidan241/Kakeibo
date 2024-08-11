import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  late String? username;
  late String? gender;
  late String? dob;
  late String? address;
  late int themeColor;
  late String? currency;

  static Future<AppState> getState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? themeColor = prefs.getInt("themeColor");
    String? username = prefs.getString("username");
    String? gender = prefs.getString("gender");
    String? dob = prefs.getString("dob");
    String? currency = prefs.getString("currency");
    String? address = prefs.getString("address");

    AppState appState = AppState();
    appState.themeColor = themeColor ?? Colors.green.value;
    appState.username = username;
    appState.gender = gender;
    appState.dob = dob;
    appState.currency = currency;
    appState.address = address;

    return appState;
  }
}

class AppCubit extends Cubit<AppState> {
  AppCubit(AppState initialState) : super(initialState);

  Future<void> updateUsername(username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
    emit(await AppState.getState());
  }

  Future<void> updateDob(dob) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("dob", dob);
    emit(await AppState.getState());
  }

  Future<void> updateGender(gender) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("gender", gender);
    emit(await AppState.getState());
  }

  Future<void> updateCurrency(currency) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("currency", currency);
    emit(await AppState.getState());
  }

  Future<void> updateAddress(address) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("address", address);
    emit(await AppState.getState());
  }

  Future<void> updateThemeColor(int color) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("themeColor", color);
    emit(await AppState.getState());
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("currency");
    await prefs.remove("themeColor");
    await prefs.remove("username");
    await prefs.remove("dob");
    await prefs.remove("gender");
    await prefs.remove("address");
    emit(await AppState.getState());
  }
}
