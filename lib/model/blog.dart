import 'package:hive/hive.dart';
part 'blog.g.dart';

@HiveType(typeId: 0)
class Blog extends HiveObject{
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String image;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String summary;

  @HiveField(4)
  final String url;

  Blog({required this.id, required this.image, required this.title, required this.summary, required this.url});
}