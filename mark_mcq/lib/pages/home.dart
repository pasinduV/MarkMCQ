import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'new_project.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [leftPanel(), rightPanel()],
      ),
    );
  }

  Future<List<String>> readTextFile() async {
    Directory documentDirectory =
        await getApplicationDocumentsDirectory(); //get user's document path
    String docPath = documentDirectory.path; //store path to variable
    File logFile = File('$docPath/logfile.txt');
    List<String> folderLocations = [];
    try {
      String content = await File('$docPath/logfile.txt').readAsString();
      folderLocations = content.split('\n');
    } catch (e) {
      print('Failed to read the text file: $e');
    }
    return folderLocations;
  }

  //recent projects-------------------------------
  List<String> folderLocations = [];

  @override
  void initState() {
    super.initState();
    loadFolderLocations();
  }

  Future<void> loadFolderLocations() async {
    List<String> locations = await readTextFile();
    setState(() {
      folderLocations = locations;
    });
  }

  void openFolder(String folderPath) {
    if (Platform.isWindows) {
      Process.run('explorer.exe', [folderPath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [folderPath]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [folderPath]);
    }
  }
  //----------------------------------------------

  Container leftPanel() {
    return Container(
      width: 600,
      height: 1024,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File("Photos/3.jpg")),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            bottom: 50, // Adjust this value to position the blue box
            left: 50, // Adjust this value to position the blue box
            right: 50, // Adjust this value to position the blue box
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                width: 200,
                height: 200,
                color: const Color.fromARGB(202, 8, 117, 225),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to the Ultimate MCQ Grading Solution!',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Capture and Process with Ease! ',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w100),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container rightPanel() {
    return Container(
      width: 664, // Set the width of the right panel as needed
      height: 1024, // Set the height of the right panel as needed
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        children: [
          Row(
            children: [
              const SizedBox(
                width: 42,
              ),
              SizedBox(
                width: 155,
                height: 30,
                child: Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      // Use a Builder to access the context
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const NewProject(),
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
                          Icons.create_new_folder_rounded,
                          color:
                              Colors.white, // You can customize the icon color
                          size: 20,
                        ),
                        SizedBox(
                          width:
                              10, // Adjust the spacing between the icon and text
                        ),
                        Text(
                          'Create Project',
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
          SizedBox(
            width: 580,
            height: 450,

            // color: Colors.green, // Second container above the other
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 580,
                  height: 30,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Align search bar and button to opposite ends
                    children: [
                      const Expanded(
                        child: TextField(
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.02,
                          ),
                          decoration: InputDecoration(
                              hintText: 'Search here...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 5.5, horizontal: 5)),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Add search functionality
                        },
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(const Size(
                              60, 60)), // Set the button height to 30
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 8, 117, 225),
                          ),
                        ),
                        child: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Container(
                  width: 580,
                  height: 380,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(
                          255, 160, 157, 157), // Border color
                      width: 1.0, // Border width
                    ),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  // child: const Center(
                  //   child: Text(
                  //     'Inner Container 2',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       color: Colors.black,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                  child: ListView.builder(
                    itemCount: folderLocations.length,
                    itemBuilder: (context, index) {
                      String folderPath = folderLocations[index];
                      return ListTile(
                        title: Text(folderPath),
                        onTap: () => openFolder(folderPath),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
