import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:pytorch_mobile/model.dart';
import 'package:pytorch_mobile/pytorch_mobile.dart';
import 'package:flutter_svg/flutter_svg.dart';

late List<CameraDescription> cameras;

List<String> getInstructions(bool isUrdu) {
  if (isUrdu) {
    return [
      "براہ کرم آگے بڑھنے کے لیے دی گئی ہدایات پر عمل کریں:",
      "",
      "1.",
      "سب سے پہلے پتے کو اس طرح رکھیں کہ اس کے پیچھے کوئی اور پتا نظر نہ آئے۔ پتیوں کو کاغذ کی سفید شیٹ پر رکھنے کی کوشش کریں۔",
      "",
      "2.",
      "اب صرف پتی پر توجہ مرکوز کریں اور اس کی تصویر لیں۔",
      "",
      "3.",
      "تصویر لینے کے بعد اب آپ اسے اس آپشن سے محفوظ کر سکتے ہیں یا دوسرے ٹیب کے ذریعے اس کی صحت جان سکتے ہیں۔",
      "",
      "4.",
      "پتوں کی صحت کی حالت آپ کے سامنے اسکرین پر ظاہر ہوگی۔",
      "",
      "5.",
      "پتوں کی صحت کی حالت کو دوبارہ چیک کرنے کے لیے دوبارہ چیک کے بٹن پر کلک کریں۔",
      "",
      "اب آپ اس ایپ کو استعمال کرنے کے لیے تیار ہیں۔"
    ];
  }

  return [
    "Please follow the given instructions to proceed:",
    "",
    "Step 1: ",
    "First, place the leaf in such a way that no other leaves are visible behind it. Try placing the leaves on a white sheet of paper.",
    "",
    "Step 2: ",
    "Now just focus on the leaf and take a picture of it.",
    "",
    "Step 3: ",
    "After taking the picture, you can now save it with this option or you can know its health through other tab.",
    "",
    "Step 4: ",
    "The health status of the leaves will be displayed on the screen in front of you.",
    "",
    "Step 5: ",
    "Tap the recheck button to recheck the health condition of leaves.",
    "",
    "Now you are ready to use this app."
  ];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: const ImageCaptureScaffold(),
  ));
}

class InstructionsScaffold extends StatefulWidget {
  const InstructionsScaffold({Key? key}) : super(key: key);

  @override
  State<InstructionsScaffold> createState() => _InstructionsScaffoldState();
}

class _InstructionsScaffoldState extends State<InstructionsScaffold> {
  bool isUrdu = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (!isUrdu) ? "Instructions" : "ہدایات",
          textDirection: (!isUrdu) ? TextDirection.ltr : TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isUrdu = !isUrdu;
              });
            },
            child: Text(
              (!isUrdu) ? "English" : "اردو",
              textDirection: (!isUrdu) ? TextDirection.ltr : TextDirection.rtl,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: (!isUrdu) ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: getInstructions(isUrdu).map((String text) {
              return Text(
                text,
                textDirection: (!isUrdu) ? TextDirection.ltr : TextDirection.rtl,
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.navigate_next),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class ImageCaptureScaffold extends StatefulWidget {
  const ImageCaptureScaffold({Key? key}) : super(key: key);

  @override
  _ImageCaptureScaffoldState createState() => _ImageCaptureScaffoldState();
}

class _ImageCaptureScaffoldState extends State<ImageCaptureScaffold> {
  late CameraController _controller;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(cameras[0], ResolutionPreset.max);
    _controller.initialize().then((value) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: CameraPreview(_controller),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      child: SvgPicture.asset("assets/icon/question_mark.svg"),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                          return const InstructionsScaffold();
                        }));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                        heroTag: "GotoPreviewPage",
                        onPressed: () async {
                          XFile image = await _controller.takePicture();
                          Navigator.of(context).push(MaterialPageRoute(builder: (builder) {
                            return PreviewScaffold(image: image);
                          }));
                        },
                        child: const Icon(Icons.camera_alt, size: 48))
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewScaffold extends StatefulWidget {
  final XFile image;

  const PreviewScaffold({Key? key, required this.image}) : super(key: key);

  @override
  _PreviewScaffoldState createState() => _PreviewScaffoldState();
}

class _PreviewScaffoldState extends State<PreviewScaffold> {
  late File imageFile;
  String prediction = "";
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();

    imageFile = File(widget.image.path);
  }

  @override
  void dispose() {
    imageFile.deleteSync();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Image.file(imageFile),
          ),
          (prediction != "")
              ? Center(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Text(
                      prediction,
                      style: const TextStyle(color: Colors.black, fontSize: 32),
                    ),
                  ),
                )
              : Container(),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.025,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FloatingActionButton(
                      heroTag: "SaveImage",
                      child: const Icon(Icons.save),
                      onPressed: (!isProcessing)
                          ? () {
                              GallerySaver.saveImage(widget.image.path).then((value) {
                                Fluttertoast.showToast(msg: "Image saved successfully...");
                              }).onError((error, stackTrace) {
                                showAlertDialog(context, "Error", error.toString());
                              });
                            }
                          : null,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.tealAccent,
                      ),
                      child: Text(
                        (!isProcessing) ? "Process" : "Processing...",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      onPressed: (!isProcessing)
                          ? () async {
                              try {
                                setState(() {
                                  isProcessing = true;
                                });

                                Model modelImage = await PyTorchMobile.loadModel("assets/model/model.pt");
                                Size decodedImage = ImageSizeGetter.getSize(FileInput(imageFile));

                                List<dynamic> predictionsDynamic = (await modelImage.getImagePredictionList(
                                    imageFile, decodedImage.width, decodedImage.height))!;
                                List<double> predictions = predictionsDynamic.map((value) {
                                  return value as double;
                                }).toList();

                                int index = 0;
                                double max = predictions[0];
                                for (int i = 1; i < predictions.length; i++) {
                                  if (predictions[i] > max) {
                                    max = predictions[i];
                                    index = i;
                                  }
                                }

                                if (index == 0) {
                                  setState(() {
                                    prediction = "HEALTHY";
                                  });
                                } else if (index == 1) {
                                  setState(() {
                                    prediction = "RESISTANT";
                                  });
                                } else if (index == 2) {
                                  setState(() {
                                    prediction = "SUSCEPTIBLE";
                                  });
                                }
                              } catch (e) {
                                showAlertDialog(context, "Error", e.toString());
                              } finally {
                                setState(() {
                                  isProcessing = false;
                                });
                              }
                            }
                          : null,
                    ),
                    FloatingActionButton(
                      heroTag: "GoBack",
                      child: const Icon(Icons.arrow_back),
                      onPressed: (!isProcessing)
                          ? () {
                              Navigator.of(context).pop();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showAlertDialog(BuildContext context, String title, String message) {
  return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
        );
      });
}
