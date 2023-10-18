import 'package:flutter/material.dart';
import 'dart:io';
import 'view_excel_sheet.dart';

class ShowMarkedSheets extends StatelessWidget {
  const ShowMarkedSheets({super.key});

  @override
  Widget build(BuildContext context) {
    return body();
  }

  Scaffold body() {
    return Scaffold(
      body: Container(
        width: 1920,
        height: 1024,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(
                "Photos/newprojectBack.jpg")), // Replace with your image asset
            opacity: 220,
            fit: BoxFit.fill, // Adjust the fit as needed
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 1000,
              height: 450,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    //Camera Feed
                    width: 1000,
                    height: 400,
                    color: Colors.black,
                    child: Text(
                      'View Marked Sheets',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.02,
                      ),
                    ),
                    alignment: Alignment.center,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 180,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(
                                255, 8, 117, 225), // Border color
                            width: 2.0, // Border width
                          ),
                          borderRadius:
                              BorderRadius.circular(4), // Border radius
                        ),
                        child: Builder(builder: (context) {
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const ViewExcelSheet(),
                              ));
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 8, 117, 225),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // You can adjust alignment as needed
                              children: [
                                Icon(
                                  Icons.view_compact_rounded,
                                  color: Colors
                                      .white, // You can customize the icon color
                                  size: 20,
                                ),
                                SizedBox(
                                  width:
                                      10, // Adjust the spacing between the icon and text
                                ),
                                Text(
                                  'View Excel Sheet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.02,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
