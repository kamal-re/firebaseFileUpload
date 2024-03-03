import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyALvLNv6t_cRNi5v0pO1haiKckjDrlaZkA",
      appId: "1:977399143022:android:b7dc5e7ec56692f2efa47f",
      messagingSenderId: "977399143022",
      projectId: "fir-fileupload-d673a",
      storageBucket: "fir-fileupload-d673a.appspot.com",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Upload',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.indigo[900],
        scaffoldBackgroundColor: Colors.indigo[50],
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.indigo[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
        ),
      ),
      home: UploadScreen(),
    );
  }
}

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {

  File? _selectedFile;
  String _uploadStatus = '';
  int _uploadProgress = 0;
  bool _uploading = false;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _selectAndPreviewFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
    );

    if (result != null) {
      File selectedFile = File(result.files.single.path!);
      int maxSize = 10 * 1024 * 1024; // 10 MB in bytes
      if (selectedFile.lengthSync() > maxSize) {
        _showErrorDialog("The selected file is larger than 10 MB. Please select a file smaller than 10 MB.");
        return;
      }

      setState(() {
        _selectedFile = selectedFile;
        if (isVideo(_selectedFile!.path)) {
          _videoController = VideoPlayerController.file(_selectedFile!)
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _uploading = true;
      _uploadStatus = 'Please wait while uploading...';
    });

    Reference storageRef = FirebaseStorage.instance.ref().child(
        'uploads/${DateTime.now().millisecondsSinceEpoch}');
    UploadTask uploadTask = storageRef.putFile(_selectedFile!);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _uploadProgress = ((snapshot.bytesTransferred / snapshot.totalBytes) * 100).round();
      });
    }, onError: (error) {
      setState(() {
        _uploadStatus = 'Error uploading file: $error';
        _uploading = false;
      });
      _showErrorDialog("Error uploading file. Please try again.");
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents the dialog from being dismissed by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    //value: _uploadProgress / 100, // Since we're not using a double value
                    backgroundColor: Colors.grey[300], // Background color
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // Fill color
                  ),
                  SizedBox(height: 10), // Spacer
                  Text(
                    'Please Wait While Uploading...', // Display progress as an integer
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // SizedBox(height: 10), // Spacer
                  // Text(
                  //   '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                  //   style: TextStyle(fontWeight: FontWeight.bold),
                  // ),
                ],
              ),
            );
          },
        );
      },
    );




    await uploadTask.whenComplete(() {
      setState(() {
        _uploadStatus = 'File uploaded successfully!';
        _uploading = false;
        _uploadProgress = 100;
        _selectedFile = null;
        _videoController?.dispose();
        _isPlaying = false;
      });
      Navigator.of(context).pop();
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: Text('File uploaded successfully!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'File Upload',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
      ),
      body:
      Center(
          child:SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(Icons.cloud_upload),
                  iconSize: 60,
                  onPressed: _uploading ? null : _selectAndPreviewFile,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Note: Upload Files less than 10 MB',
                style: TextStyle(fontSize: 14, color: Colors.red), // Adjust the style as needed
              ),
              SizedBox(height: 16.0),
              _selectedFile != null
                  ? Column(
                children: [
                  if (isImage(_selectedFile!.path))
                    AspectRatio(
                      aspectRatio: 1,
                      child: Image.file(
                        _selectedFile!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (isVideo(_selectedFile!.path))
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_videoController!),
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, color: Colors.white,size: 40,),
                            onPressed: () {
                              setState(() {
                                _isPlaying ? _videoController!.pause() : _videoController!.play();
                                _isPlaying = !_isPlaying;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _uploading ? null : _uploadFile,
                    child: _uploading
                        ? null
                        : Text('Upload File'),
                  ),
                ],
              )
                  : ElevatedButton(
                onPressed: _uploading ? null : _selectAndPreviewFile,
                style: ElevatedButton.styleFrom(
                  primary: Colors.indigo[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: _uploading
                    ? CircularProgressIndicator()
                    : Text('Select and Preview File'),
              ),
              SizedBox(height: 20.0),
            ],
          ),
        )),
      );
  }

  bool isImage(String path) => path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.gif');
  bool isVideo(String path) => path.endsWith('.mp4') || path.endsWith('.mov');
}

