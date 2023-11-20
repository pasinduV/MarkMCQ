import 'dart:async';
import 'dart:io';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'add_marking_sheet.dart';
import 'package:path/path.dart' as path;
import 'new_project.dart';

int mcqSheetFormatIndex = 0;
String originalImageDir = '';
String processedImageDir = '';
String projectFolderDir = '';
String projectName = '';

class CameraSelect extends StatefulWidget {
  CameraSelect(String rProjectName, String rProjectFolderDir,
      String rOriginalImageDir, String rProcessedImageDir, int index,
      {super.key}) {
    originalImageDir = rOriginalImageDir;
    processedImageDir = rProcessedImageDir;
    projectFolderDir = rProjectFolderDir;
    projectName = rProjectName;
    mcqSheetFormatIndex = index;
  }

  @override
  State<CameraSelect> createState() => _CameraSelectState();
}

class _CameraSelectState extends State<CameraSelect> {
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  int _cameraId = -1;
  bool _initialized = false;
  Size? _previewSize;
  final ResolutionPreset _resolutionPreset = ResolutionPreset.veryHigh;
  StreamSubscription<CameraErrorEvent>? _errorStreamSubscription;
  StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription;
  String _lastImagePath = 'Photos/1.jpg';
  String studentIndex = '';

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    _fetchCameras();
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    _disposeCurrentCamera();
    _errorStreamSubscription?.cancel();
    _errorStreamSubscription = null;
    _cameraClosingStreamSubscription?.cancel();
    _cameraClosingStreamSubscription = null;
    super.dispose();
  }

  /// Fetches list of available cameras from camera_windows plugin.
  Future<void> _fetchCameras() async {
    List<CameraDescription> cameras = <CameraDescription>[];

    int cameraIndex = 0;
    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (cameras.isEmpty) {
      } else {
        cameraIndex = _cameraIndex % cameras.length;
      }
    } on PlatformException catch (e) {}

    if (mounted) {
      setState(() {
        _cameraIndex = cameraIndex;
        _cameras = cameras;
      });
    }
  }

  /// Initializes the camera on the device.
  Future<void> _initializeCamera() async {
    assert(!_initialized);

    if (_cameras.isEmpty) {
      return;
    }

    int cameraId = -1;
    try {
      final int cameraIndex = _cameraIndex % _cameras.length;
      final CameraDescription camera = _cameras[cameraIndex];

      cameraId = await CameraPlatform.instance.createCamera(
        camera,
        _resolutionPreset,
      );

      unawaited(_errorStreamSubscription?.cancel());
      _errorStreamSubscription = CameraPlatform.instance
          .onCameraError(cameraId)
          .listen(_onCameraError);

      final Future<CameraInitializedEvent> initialized =
          CameraPlatform.instance.onCameraInitialized(cameraId).first;

      await CameraPlatform.instance.initializeCamera(
        cameraId,
      );

      final CameraInitializedEvent event = await initialized;
      _previewSize = Size(
        event.previewWidth,
        event.previewHeight,
      );

      if (mounted) {
        setState(() {
          _initialized = true;
          _cameraId = cameraId;
          _cameraIndex = cameraIndex;
        });
      }
    } on CameraException {
      try {
        if (cameraId >= 0) {
          await CameraPlatform.instance.dispose(cameraId);
        }
      } on CameraException catch (e) {
        debugPrint('Failed to dispose camera: ${e.code}: ${e.description}');
      }

      // Reset state.
      if (mounted) {
        setState(() {
          _initialized = false;
          _cameraId = -1;
          _cameraIndex = 0;
          _previewSize = null;
        });
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraId >= 0 && _initialized) {
      try {
        await CameraPlatform.instance.dispose(_cameraId);

        if (mounted) {
          setState(() {
            _initialized = false;
            _cameraId = -1;
            _previewSize = null;
          });
        }
      } on CameraException catch (e) {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Widget _buildPreview() {
    return CameraPlatform.instance.buildPreview(_cameraId);
  }

  Future<void> _takePicture() async {
    final XFile imageFile =
        await CameraPlatform.instance.takePicture(_cameraId);
    final directory = await getApplicationDocumentsDirectory();
    final DateTime now = DateTime.now();
    final String timestamp = now.millisecondsSinceEpoch.toString();
    final fileName = 'image_$timestamp.jpg';
    final imageDir = '$originalImageDir/$fileName';
    await imageFile.saveTo(imageDir);
    setState(() {
      _lastImagePath = imageDir; // Update the _lastImagePath
    });
  }

  Widget _buildLastImagePreview() {
    if (_lastImagePath == null) {
      return const SizedBox.shrink();
    } else {
      return Image.file(
        File(_lastImagePath),
        width: 510,
        height: 320,
        fit: BoxFit.cover,
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.isNotEmpty) {
      // select next index;
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      if (_initialized && _cameraId >= 0) {
        await _disposeCurrentCamera();
        await _fetchCameras();
        if (_cameras.isNotEmpty) {
          await _initializeCamera();
        }
      } else {
        await _fetchCameras();
      }
    }
  }

  void _onCameraError(CameraErrorEvent event) {
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: ${event.description}')));

      // Dispose camera on camera error as it can not be used anymore.
      _disposeCurrentCamera();
      _fetchCameras();
    }
  }

  //delete file(for retake function)
  void deleteFile(String filePath) {
    File file = File(filePath);
    file.deleteSync();
  }

  Future<void> _retakePicture(String replaceFileDir) async {
    deleteFile(replaceFileDir);
    _takePicture();
  }

  //rename image
  void renameImage(String oldPath, String newName) async {
    String directory = path.dirname(oldPath);
    String newPath = path.join(directory, newName);

    File oldFile = File(oldPath);
    if (await oldFile.exists()) {
      File newFile = await oldFile.rename('$newPath.jpg');
    }
    _lastImagePath = newPath;
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          width: 1920,
          height: 1024,
          alignment: Alignment.center,
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
              if (_cameras.isEmpty)
                ElevatedButton(
                  onPressed: _fetchCameras,
                  child: const Text('Re-check available cameras'),
                ),
              if (_cameras.isNotEmpty)
                SizedBox(
                  width: 600,
                  height: 500,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Builder(builder: (context) {
                                return ElevatedButton(
                                  onPressed: () {
                                    _disposeCurrentCamera();
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) => const NewProject(),
                                    ));
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 8, 117, 225),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(
                            width: 388,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              if (_cameras.length > 1) ...<Widget>[
                                ElevatedButton(
                                  onPressed: _switchCamera,
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 8, 117, 225),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.switch_camera_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Switch Camera',
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
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            constraints: const BoxConstraints(
                                maxHeight: 400, maxWidth: 600),
                            decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(6))),
                            child: _buildPreview(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: 160,
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
                                  _retakePicture(_lastImagePath);
                                },
                                style: ButtonStyle(
                                  overlayColor: MaterialStateColor.resolveWith(
                                    (states) {
                                      if (states
                                          .contains(MaterialState.pressed)) {
                                        return Colors.blue
                                            .shade200; // Change the color when the button is pressed
                                      }
                                      return Colors.blue
                                          .shade100; // Use the default color otherwise
                                    },
                                  ),
                                  minimumSize: MaterialStateProperty.all(
                                      const Size(50,
                                          50)), // Set the button height to 30
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    const Color.fromRGBO(255, 255, 255, 1),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.refresh_outlined,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      size: 20,
                                    ),
                                    SizedBox(
                                      width:
                                          10, // Adjust the spacing between the icon and text
                                    ),
                                    Text(
                                      'Retake Photo',
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
                          const SizedBox(
                            width: 20,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _takePicture();
                              _buildLastImagePreview();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 8, 117, 225),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 10,
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(
                width: 50,
              ),
              SizedBox(
                width: 510,
                height: 500,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 510,
                          height: 320,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6))),
                          child: _buildLastImagePreview(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        const SizedBox(
                          width: 50,
                        ),
                        const Text('Index Number :',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.02,
                            )),
                        const SizedBox(width: 10),
                        Container(
                          height: 30,
                          width: 250,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                                255, 185, 185, 185), // background color
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              studentIndex = value;
                            },
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.02,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            decoration: const InputDecoration(
                              contentPadding:
                                  EdgeInsets.fromLTRB(10, -8, 0, 10),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            renameImage(_lastImagePath, studentIndex);
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 8, 117, 225),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Add',
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
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Builder(builder: (context) {
                          return ElevatedButton(
                            onPressed: () {
                              // Call the dispose() function here
                              _disposeCurrentCamera();
                              _errorStreamSubscription?.cancel();
                              _errorStreamSubscription = null;
                              _cameraClosingStreamSubscription?.cancel();
                              _cameraClosingStreamSubscription = null;

                              // Navigate to the CameraSelect screen
                              _disposeCurrentCamera(); //close opned camera before moving to next screem
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => AddMarkingSheet(
                                    projectName,
                                    projectFolderDir,
                                    originalImageDir,
                                    processedImageDir,
                                    mcqSheetFormatIndex),
                              ));
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 8, 117, 225),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Add Marking Sheet',
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
            ],
          )),
    );
  }
}
