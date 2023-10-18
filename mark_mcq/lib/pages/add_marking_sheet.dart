import 'package:flutter/material.dart';
import 'dart:io';
import 'show_marked_sheets.dart';

class AddMarkingSheet extends StatelessWidget {
  const AddMarkingSheet({super.key});

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
              width: 600,
              height: 450,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    //Camera Feed
                    width: 600,
                    height: 400,
                    color: Colors.black,
                    child: Text(
                      'Video Feed',
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
                        width: 120,
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
                              // Navigate to the AddMarkingShhet screen
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
                                  Icons.add_a_photo_outlined,
                                  color: Colors
                                      .white, // You can customize the icon color
                                  size: 20,
                                ),
                                SizedBox(
                                  width:
                                      10, // Adjust the spacing between the icon and text
                                ),
                                Text(
                                  'Capture',
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
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        width: 120,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black38, // Border color
                            width: 2.0, // Border width
                          ),
                          borderRadius:
                              BorderRadius.circular(4), // Border radius
                        ),
                        child: Builder(builder: (context) {
                          return ElevatedButton(
                            onPressed: () {
                              // Use a Builder to access the context
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const ShowMarkedSheets(),
                              ));
                            },
                            style: ButtonStyle(
                              overlayColor: MaterialStateColor.resolveWith(
                                (states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.blue
                                        .shade200; // Change the color when the button is pressed
                                  }
                                  return Colors.blue
                                      .shade100; // Use the default color otherwise
                                },
                              ),
                              minimumSize: MaterialStateProperty.all(const Size(
                                  50, 50)), // Set the button height to 30
                              backgroundColor: MaterialStateProperty.all<Color>(
                                Color.fromRGBO(255, 255, 255, 1),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // You can adjust alignment as needed
                              children: [
                                Icon(
                                  Icons.wifi_protected_setup_sharp,
                                  color: Color.fromARGB(255, 0, 0,
                                      0), // You can customize the icon color
                                  size: 20,
                                ),
                                SizedBox(
                                  width:
                                      10, // Adjust the spacing between the icon and text
                                ),
                                Text(
                                  'Process',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
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
