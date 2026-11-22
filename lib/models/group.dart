class GroupModel {
  final String id;
  final String name;
  final String description;
  final List<String> memberIds;

  const GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.memberIds = const [],
  });

  factory GroupModel.fromMap(String id, Map<dynamic, dynamic> data) {
    final List<String> members = [];
    if (data['members'] != null) {
      final mData = data['members'];
      if (mData is Map) {
        mData.forEach((key, val) {
          if (val == true || val == 'true' || val != null) {
            members.add(key.toString());
          }
        });
      } else if (mData is List) {
        for (var item in mData) {
          if (item != null) members.add(item.toString());
        }
      }
    } else if (data['memberIds'] != null) {
      final mData = data['memberIds'];
      if (mData is List) {
        members.addAll(mData.map((e) => e.toString()));
      }
    }

    return GroupModel(
      id: id,
      name: (data['name'] ?? data['title'] ?? id).toString(),
      description: (data['description'] ?? '').toString(),
      memberIds: members,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, bool> membersMap = {};
    for (var id in memberIds) {
      membersMap[id] = true;
    }
    return {
      'name': name,
      'description': description,
      'members': membersMap,
    };
  }
}
