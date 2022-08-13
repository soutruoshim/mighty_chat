import 'dart:io';

import 'package:chat/models/StoryModel.dart';
import 'package:chat/utils/AppConstants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path/path.dart';

import 'BaseService.dart';

class StoryService extends BaseService {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  FirebaseStorage _storage = FirebaseStorage.instance;

  StoryService() {
    ref = fireStore.collection(STORY_COLLECTION);
  }

  Future<DocumentReference> addStory(StoryModel data, {String? userId}) async {
    var doc = await ref!.add(data.toJson());
    doc.update({'id': doc.id});
    return doc;
  }

  Future<List<StoryModel>> getAllStory({String? uid}) async {
    return ref!.where('userId', isNotEqualTo: uid).get().then((value) {
      return value.docs.map((y) {
        return StoryModel.fromJson(y.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<List<StoryModel>> getMyStory({String? uid}) async {
    return ref!.where('userId', isEqualTo: uid).get().then((value) {
      return value.docs.map((y) {
        return StoryModel.fromJson(y.data() as Map<String, dynamic>);
      }).toList();
    }).catchError((e) {
      toast('error : $e', print: true);
      throw e;
    });
  }

  Future<String> uploadImage(File? image) async {
    String imageUrl = '';

    if (image != null) {
      String fileName = basename(image.path);
      Reference storageRef = _storage.ref().child("$STORY_DATA_IMAGES/${getStringAsync(userId)}/${getStringAsync(userId) + fileName}");

      UploadTask uploadTask = storageRef.putFile(image);

      await uploadTask.then((e) async {
        await e.ref.getDownloadURL().then((value) async {
          imageUrl = value;
        });
      });
    }

    return imageUrl;
  }

  Future<void> deleteStory({String? id, String? url}) async {
    Reference fileRef = _storage.refFromURL(url!);

    await fileRef.delete().then((value) {
      ref!.doc(id).delete();
    }).catchError((e) {
      log(e.toString());  
    });

  }
}
