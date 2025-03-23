import 'package:flutter/material.dart';

class SearchBuildings extends StatefulWidget {
  final List<Map<String, dynamic>> buildings;
  const SearchBuildings({super.key, required this.buildings});

  @override
  State<SearchBuildings> createState() => _SearchBuildingsState();
}

class _SearchBuildingsState extends State<SearchBuildings> {
  List<Map<String, dynamic>> foundBuildings = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    foundBuildings = widget.buildings;
  }

  void _searchBuildings(String query) {
    setState(() {
      foundBuildings = widget.buildings.where((building) {
        final name = building['name'].toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Buildings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  _searchBuildings(value);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: foundBuildings.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Card(
                        key: ValueKey(foundBuildings[index]['name']),
                        elevation: 8,
                        child: ListTile(
                          title: Text(foundBuildings[index]['name']),
                          subtitle: Text(foundBuildings[index]['code']),
                          onTap: () {
                            Navigator.pop(context, {
                              'building': foundBuildings[index],
                              'callback': 'editBuilding',
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.lightGreen,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'building': foundBuildings[index],
                                    'callback': 'editBuilding',
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'building': foundBuildings[index],
                                    'callback': 'deleteBuilding',
                                  });
                                },
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'building': foundBuildings[index],
                                    'callback': 'zoomToBuilding',
                                  });
                                },
                                icon: Icon(
                                  Icons.location_on,
                                  color: Colors.blue[400],
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
