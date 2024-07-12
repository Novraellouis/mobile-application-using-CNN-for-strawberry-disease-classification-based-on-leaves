import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strawberry Disease Detection',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  bool modelLoaded = false;

  Future<void> _tfLiteInit() async {
    String? res = await Tflite.loadModel(
      model: "assets/model_final.tflite",
      labels: "assets/labels.txt",
    );
    print("TFLite model loaded: $res");
    setState(() {
      modelLoaded = true;
    });
  }

  pickImageGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      filePath = File(image.path);
    });

    predictImage(image);
  }

  pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() {
      filePath = File(image.path);
    });

    predictImage(image);
  }

  void predictImage(XFile image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      imageMean: 0.0, // Menetapkan imageMean dan imageStd untuk normalisasi
      imageStd: 255.0,
    );

    if (recognitions == null || recognitions.isEmpty) {
      print("Recognition is null");
      return;
    }

    setState(() {
      // Mengambil label dengan nilai confidence tertinggi
      label = recognitions[0]['label'];
      confidence = recognitions[0]['confidence'] * 100;
    });
  }

  @override
  void initState() {
    super.initState();
    _tfLiteInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Strawberry Disease Detection"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Card(
                elevation: 20,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        height: 280,
                        width: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          image: filePath != null
                              ? DecorationImage(
                                  image: FileImage(filePath!),
                                  fit: BoxFit.fill,
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/upload.jpg'),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Accuracy: ${confidence.toStringAsFixed(2)}%",
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: modelLoaded ? pickImageCamera : null,
                child: const Text("Take a Photo"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: modelLoaded ? pickImageGallery : null,
                child: const Text("Pick from Gallery"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
