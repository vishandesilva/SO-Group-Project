import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/PostScreenPage.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile({this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: CachedNetworkImage(
          imageUrl: post.posturl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Padding(
            padding: EdgeInsets.all(10.0),
            child: circularProgress(),
          ),
          errorWidget: (context, url, error) => Icon(Icons.error_outline),
        ),
      ),
    );
  }

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreenPage(
          userId: post.ownerId,
          postId: post.postId,
        ),
      ),
    );
  }
}
