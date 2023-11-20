import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_intro/home/home_view_service.dart';
import 'package:hive_intro/home/model/user_model.dart';
import 'package:hive_intro/manager/user_cache_manager.dart';
import 'package:hive_intro/search_view/search_view.dart';
import 'package:kartal/kartal.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final String _baseUrl = 'https://jsonplaceholder.typicode.com';
  final _dummyString = 'https://picsum.photos/200/300';

  List<UserModel>? _items;
  late final ICacheManager<UserModel> cacheManager;
  late final IHomeService _homeService;

  @override
  void initState() {
    super.initState();
    _homeService = HomeService(Dio(BaseOptions(baseUrl: _baseUrl)));
    cacheManager = UserCacheManager('userCacheNew2');
    fetchDatas();
  }

  void _showAddDialog(bool update, String? id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        return AlertDialog(
          title: Text(update ? 'Kişiyi Güncelle' : 'Yeni Kişi Ekle'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'İsim',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog penceresini kapat
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                // Yeni kişiyi ekleme işlemini gerçekleştir
                String name = nameController.text;
                if (update) {
                  _updateUser(id ?? '', name);
                } else {
                  _addNewUser(name);
                }
                Navigator.pop(context); // Dialog penceresini kapat
              },
              child: Text(update ? 'Güncelle' : 'Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kişiyi Sil'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog penceresini kapat
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                _deleteUser(id);
                Navigator.pop(context); // Dialog penceresini kapat
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showChoosingDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İşlem Seç'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddDialog(true, id);
                // Dialog penceresini kapat
              },
              child: const Text('Güncelle'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteDialog(id);
                // Dialog penceresini kapat
              },
              child: const Text('Sil'),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _addNewUser(String name) async {
    Random random = Random();
    int id = random.nextInt(1000) + 1153; // Rastgele bir id oluştur
    UserModel newUser =
        UserModel(id: id, name: name); // Yeni kullanıcı modelini oluştur
    await cacheManager.putItem(
        newUser.id.toString(), newUser); // Yeni kullanıcıyı sakla
    _items?.add(newUser); // Yeni kullanıcıyı liste içine ekle
    setState(() {}); // UI'yı güncelle
  }

  Future<void> _deleteUser(String id) async {
    await cacheManager.removeItem(id);
    _items?.removeWhere((element) => element.id.toString() == id);
    setState(() {});
  }

  Future<void> _updateUser(String id, String name) async {
    await cacheManager.putItem(id, UserModel(id: int.parse(id), name: name));
    _items?.firstWhere((element) => element.id.toString() == id).name = name;
    setState(() {});
  }

  Future<void> fetchDatas() async {
    await cacheManager.init();
    if (cacheManager.getValues()?.isNotEmpty ?? false) {
      _items = cacheManager.getValues();
    } else {
      _items = await _homeService.fetchUsers();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                context.navigateToPage(SearchView(model: cacheManager));
              },
              icon: const Icon(Icons.search)),
          IconButton(
              onPressed: () {
                _showAddDialog(false, null);
              },
              icon: const Icon(Icons.add))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          cacheManager.getValues();
          if (_items?.isNotEmpty ?? false) {
            await cacheManager.addItems(_items!);
          }
        },
        child: const Icon(Icons.save),
      ),
      body: (_items?.isNotEmpty ?? false)
          ? ListView.builder(
              itemCount: _items?.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    onTap: () {
                      _showChoosingDialog(_items?[index].id.toString() ?? '');
                    },
                    leading: CircleAvatar(
                        backgroundImage: NetworkImage(_dummyString)),
                    title: Text('${_items?[index].name}'),
                  ),
                );
              },
            )
          : const CircularProgressIndicator(),
    );
  }
}
