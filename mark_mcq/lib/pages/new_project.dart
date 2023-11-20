import 'package:flutter/material.dart';
import 'dart:io';
import 'camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'home.dart';
import 'package:path/path.dart' as path;

class NewProject extends StatefulWidget {
  const NewProject({super.key});

  @override
  State<NewProject> createState() => _NewProjectState();
}

class _NewProjectState extends State<NewProject> {
  @override
  Widget build(BuildContext context) {
    return body();
  }

  String originalImageDir = ''; //captured or browsed images are stored here
  String processedImageDir = '';
  String projectFolderDir = '';
  String projectNameToPass = '';
  int mcqSheetFormatIndex = 0; //index for answer sheet format

  //New Project Function
  Future<void> setPath() async {
    // Get the root directory of the external storage.
    Directory rootDir = await getApplicationDocumentsDirectory();
    if (rootDir != null) {
      // Use the file_picker package to allow the user to select a folder.
      String? projectDir = await FilePicker.platform.getDirectoryPath();
      if (projectDir != null) {
        // Ask the user for a name for their project and create a new folder inside the selected folder with that name.
        // ignore: use_build_context_synchronously
        String? projectName = await showDialog(
          context: context,
          builder: (BuildContext context) {
            TextEditingController controller =
                TextEditingController(); // Add a controller to retrieve the entered project name.
            return AlertDialog(
              title: const Text(
                'Enter project name',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.02,
                ),
              ),
              content: TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                )),
                controller: controller,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(
                      context,
                      controller
                          .text), // Pass the entered project name to the Navigator.pop() method.
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
        if (projectName != null && projectName.isNotEmpty) {
          // Check if the project name is not empty.
          Directory newProjectDir = Directory('$projectDir/$projectName');
          newProjectDir.createSync();
          projectNameToPass = projectName;
          Directory originalImagesDir =
              Directory('${newProjectDir.path}/original images');
          originalImagesDir.createSync();
          Directory processedImagesDir =
              Directory('${newProjectDir.path}/processed images');
          processedImagesDir.createSync();
          setState(() {
            originalImageDir =
                "$projectDir\\$projectName\\original images"; //originalImagesDir.path;
            processedImageDir =
                "$projectDir\\$projectName\\processed images"; //processedImagesDir.path;
            projectFolderDir = "$projectDir\\$projectName";
            saveToLogFile(projectFolderDir);
          });
        }
      }
    }
  }

//Browse Function
  List<File> _images = []; // A list of files to store the selected images.

  Future<void> _pickImages() async {
    // A method to pick images from the gallery.
    final List<XFile>? images = await ImagePicker()
        .pickMultiImage(); // Using ImagePicker to pick multiple images from the gallery.

    if (images != null) {
      // If images are selected, then save them to a directory.
      setState(() {
        _images = images
            .map((XFile image) => File(image.path))
            .toList(); // Converting XFile objects to File objects and storing them in a list.
      });

      final String path =
          originalImageDir; // Getting the path of the directory.

      for (int i = 0; i < _images.length; i++) {
        // Looping through all the selected images and saving them to the directory.
        final String fileName = Uri.file(_images[i].path).pathSegments.last;
        final File localImage = await _images[i].copy(
            '$path/$fileName'); // Copying the image to the directory with the generated file name.
        print(
            'Image $i saved to $path/$fileName'); // Printing a message to indicate that the image has been saved.
      }
    }
  }

  void saveToLogFile(String data) async {
    Directory documentDirectory =
        await getApplicationDocumentsDirectory(); //get user's document path
    String docPath = documentDirectory.path; //store path to variable
    File logFile = File('$docPath/markMCQlogfile.txt');
    RandomAccessFile outputFile = logFile.openSync(
        mode: FileMode
            .append); // Open the file in write mode and create it if it doesn't exist
    outputFile.writeStringSync('$data\n'); // Write the string to the file
    outputFile.closeSync(); // Close the file
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const HomePage(),
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
                          .spaceAround, // You can adjust alignment as needed
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          color: Color.fromARGB(255, 255, 255,
                              255), // You can customize the icon color
                          size: 20,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(
                  width: 440,
                ),
              ],
            ),
            const SizedBox(
              height: 25,
            ),
            const SizedBox(
              width: 500,
              height: 30,
              child: Text('Path',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.02,
                  )),
            ),
            SizedBox(
              width: 500,
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Align search bar and button to opposite ends
                children: [
                  Container(
                    height: 30,
                    width: 430,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black54),
                        borderRadius: BorderRadius.circular(4)),
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          projectFolderDir,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.02,
                          ),
                        )),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setPath();
                    },
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(
                          const Size(60, 60)), // Set the button height to 30
                      backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 8, 117, 225),
                      ),
                    ),
                    child: const Icon(Icons.open_in_browser),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              width: 510,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 40, // Set the desired width
                  child: TextButton(
                    onPressed: () {
                      _showInstructionsDialog(context);
                      // Add your onPressed logic here
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.all(4),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 500,
              height: 100,
              // Here, default theme colors are used for activeBgColor, activeFgColor, inactiveBgColor and inactiveFgColor
              child: ToggleSwitch(
                minWidth: 164.6,
                minHeight: 100.0,
                initialLabelIndex: null,
                cornerRadius: 4.0,
                activeFgColor: Colors.white,
                inactiveBgColor: const Color.fromARGB(255, 255, 255, 255),
                inactiveFgColor: const Color.fromARGB(255, 0, 0, 0),
                totalSwitches: 3,
                labels: const ['25 x 1', '10 x 4', '25 x 2'],
                customTextStyles: const [
                  TextStyle(
                    fontSize: 40,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.02,
                  )
                ],
                borderWidth: 2.0,
                borderColor: const [Color.fromARGB(255, 66, 165, 245)],
                dividerColor: const Color.fromARGB(255, 66, 165, 245),
                activeBgColors: const [
                  [Color.fromARGB(255, 8, 117, 225)],
                  [Color.fromARGB(255, 8, 117, 225)],
                  [Color.fromARGB(255, 8, 117, 225)],
                ],
                onToggle: (index) {
                  mcqSheetFormatIndex = index!;
                },
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            SizedBox(
              width: 510,
              height: 100,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Adjust the alignment as needed
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromRGBO(
                            66, 165, 245, 1), // Border color
                        width: 2.0, // Border width
                      ),
                      borderRadius: BorderRadius.circular(4), // Border radius
                    ),
                    child: Builder(builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          // Navigate to the CameraSelect screen
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CameraSelect(
                                projectNameToPass,
                                projectFolderDir,
                                originalImageDir,
                                processedImageDir,
                                mcqSheetFormatIndex),
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
                              150, 100)), // Set the button height to 30
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromRGBO(255, 255, 255, 1),
                          ),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.black, size: 50),
                      );
                    }),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.shade400, // Border color
                        width: 2.0, // Border width
                      ),
                      borderRadius: BorderRadius.circular(4), // Border radius
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Add search functionality
                        _pickImages();
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
                            150, 100)), // Set the button height to 30
                        backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      child: const Icon(
                        Icons.drive_folder_upload,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  width: 380,
                ),
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            CameraSelect(originalImageDir, mcqSheetFormatIndex),
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
                          Icons.wifi_protected_setup_outlined,
                          color:
                              Colors.white, // You can customize the icon color
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Instructions',
          ),
          content: Row(
            children: [
              _buildColumn(
                heading: '25 x 1',
                imagePath: 'Photos/Icons/column1.png',
                description: 'Description for Column 1...',
              ),
              SizedBox(width: 10), // Set the space between columns
              _buildColumn(
                heading: '10 x 4',
                imagePath: 'Photos/Icons/column2.png',
                description: 'Description for Column 2...',
              ),
              SizedBox(width: 10), // Set the space between columns
              _buildColumn(
                heading: '25 x 2',
                imagePath: 'Photos/Icons/column3.png',
                description: 'Description for Column 3...',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColumn({
    required String heading,
    required String imagePath,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black, // Set the border color
          width: 2.0, // Set the border width
        ),
        borderRadius: BorderRadius.circular(8.0), // Set the border radius
        color: Colors.blue.shade50, // Set the background color
      ),
      padding: EdgeInsets.all(10.0), // Adjust the padding as needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            heading,
            style: const TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
              letterSpacing: 0.02,
            ),
          ),
          SizedBox(height: 8),
          Image.asset(
            imagePath,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }
}
