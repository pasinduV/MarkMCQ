import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      } else {
        // Handle errors here
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return body();
  }

  Scaffold body() {
    int cols = 0;
    int rows = 0;

    //set rows and columns for entering correct answers according to answer sheet type
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
            image: FileImage(File("Photos/newprojectBack.jpg")),
            opacity: 220,
            fit: BoxFit.fill,
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
                                    1, // Restrict input to a single digit
                                inputFormatters: [
                                  //allow only 1 to 5 values on text field
                                  FilteringTextInputFormatter.allow(
                                      RegExp('[1-5]'))
                                ],
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
                              sendFolderForProcessing();
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
                                  'Proceed',
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
