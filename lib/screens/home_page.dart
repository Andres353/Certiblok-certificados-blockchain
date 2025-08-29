import 'package:flutter/material.dart';
import 'package:frontend_app/screens/admin_dashboard.dart' as admin;
import 'package:frontend_app/screens/user_dashboard.dart' as user;
import 'package:frontend_app/screens/guest_page.dart' as guest;
import 'package:frontend_app/screens/student_dashboard.dart' as student;

class HomePage extends StatelessWidget {
  final String role;
  HomePage({required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == 'admin') {
      return admin.AdminDashboard();
    } else if (role == 'user') {
      return user.UserDashboard();
    } else if (role == 'student') {
      return student.StudentDashboard();
    } else {
      return guest.GuestPage();
    }
  }
}
