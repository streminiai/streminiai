import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:stremini_chatbot/widgets/drawer_widgets/app_search_bar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: App_Search_Bar(),
            ),
            const SizedBox(
              height: 86,
            ),

            //---------------------------------------
            ListTile(
              leading: Image(
                image: AssetImage('assets/home_icon.png'),
                width: 24,
                height: 24,
              ),
              title: Text(
                'Home',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                //TODO Handle home_screen tap
              },
            ),

//---------------------------------------
            ListTile(
              leading: Image(
                image: AssetImage('assets/question_mark_icon.png'),
                width: 24,
                height: 24,
              ),
              title: Text(
                'Settings',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                //TODO Handle settings_screem tap
              },
            ),

//---------------------------------------
            ListTile(
              leading: Image(
                image: AssetImage('assets/settings_icon.png'),
                width: 24,
                height: 24,
              ),
              title: Text(
                'Contact Us',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                //TODO Handle contact us tap
              },
            ),
          ],
        ),
      ),
    );
  }
}
