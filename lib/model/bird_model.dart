class BirdModel{
  String id = "-1";
  String name = "";
  String totalDays = "-1";
  String image = "";

  BirdModel(
      {
        required this.id, required this.name,required this.totalDays,required this.image
      });

  BirdModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'].toString();
    totalDays = json['days'].toString();
    image = json['image'].toString();

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['totalDays'] = this.totalDays;
    data['image'] = this.image;

    return data;
  }
}