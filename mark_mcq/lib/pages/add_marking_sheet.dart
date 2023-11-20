import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'package:open_file/open_file.dart';

class AddMarkingSheet extends StatelessWidget {
  int mcqSheetFormatIndex = 0;
  String projectName = '';
  String projectFolderDir = '';
  String originalImageDir = '';
  String processedImageDir = '';
  List<int>? correctAnswerListToPass;

  AddMarkingSheet(String rProjectName, String rProjectFolderDir,
      String rOriginalImageDir, String rProcessedImageDir, int index,
      {super.key}) {
    mcqSheetFormatIndex = index;
    projectName = rProjectName;
    projectFolderDir = rProjectFolderDir;
    originalImageDir = rOriginalImageDir;
    processedImageDir = rProcessedImageDir;
    print("index passed to third screen: $mcqSheetFormatIndex"); //test
    print("image directory in answer page: $originalImageDir");
    print("project name in answer page: $projectName");
  }

  //backend link --------------------------------------------------------------
  String apiUrl = "http://127.0.0.1:5000/process_folder";
  Future<void> sendFolderForProcessing() async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "project_folder_path": projectFolderDir,
          "paper_type_index": mcqSheetFormatIndex,
          "answer_list": correctAnswerListToPass,
          "project_name": projectName,
          "processed_image_folder": processedImageDir,
          "original_image_path": originalImageDir,
        }),
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> data =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        // for (var entry in data) {
        //   String imageName = entry['imageName'];
        //   int totalScore = entry['totalScore'];

        //   print('Image Name: $imageName, Total Score: $totalScore');
        // }
      } else {
        // Handle errors here
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Exception: $e');
    }
  }
  //---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return body();
  }

  Scaffold body() {
    int cols = 0;
    int rows = 0;
    switch (mcqSheetFormatIndex) {
      case 0:
        {
          rows = 5;
          cols = 5;
          break;
        }
      case 1:
        {
          rows = 8;
          cols = 5;
          break;
        }
      case 2:
        {
          rows = 10;
          cols = 5;
          break;
        }
      default:
        break;
    }

    List<int> correctAnswerList = List<int>.filled(
        rows * cols, 0); //  stores the given answers by the teacher

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
                  // MCQ answer input section
                  for (int i = 0; i < rows; i++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (int j = 0; j < cols; j++)
                          Row(children: [
                            Container(
                              width: 20,
                              height: 40,
                              child: Text(
                                (i * cols + j + 1).toString(),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                ),
                                maxLength:
                                    1, // Restrict input to a single digit (1-5)
                                onChanged: (value) {
                                  correctAnswerList[i * cols + j] =
                                      int.parse(value);
                                  correctAnswerListToPass = correctAnswerList;
                                },
                              ),
                            ),
                          ]),
                      ],
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
                              //print for test
                              for (int i = 0; i < rows; i++) {
                                for (int j = 0; j < cols; j++) {
                                  print(
                                      "${i * cols + j + 1}: ${correctAnswerList[i * cols + j]}");
                                }
                              }
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
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Completed'),
                                      //content: Text('This is a popup window'),
                                      actions: [
                                        TextButton(
                                          child: Text('Home'),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomePage(),
                                            ));
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Open Excel Sheet'),
                                          onPressed: () async {
                                            String filePath =
                                                '$projectFolderDir\\$projectName.xlsx';
                                            await OpenFile.open(filePath);
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomePage(),
                                            ));
                                          },
                                        ),
                                      ],
                                    );
                                  });
                              sendFolderForProcessing(); //API calling
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
