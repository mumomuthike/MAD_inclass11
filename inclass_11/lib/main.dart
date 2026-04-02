import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Manager',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final CollectionReference _products = FirebaseFirestore.instance.collection(
    'products',
  );

  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';

    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'].toString();
      _priceController.text = documentSnapshot['price'].toString();
    } else {
      _nameController.clear();
      _priceController.clear();
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action == 'create' ? 'Add Product' : 'Update Product',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    String name = _nameController.text.trim();
                    double? price = double.tryParse(
                      _priceController.text.trim(),
                    );

                    if (name.isNotEmpty && price != null) {
                      if (action == 'create') {
                        await _products.add({
                          'name': name,
                          'name_lower': name.toLowerCase(),
                          'price': price,
                        });
                      } else {
                        await _products.doc(documentSnapshot!.id).update({
                          'name': name,
                          'name_lower': name.toLowerCase(),
                          'price': price,
                        });
                      }

                      _nameController.clear();
                      _priceController.clear();

                      if (mounted) {
                        Navigator.of(ctx).pop();
                      }
                    }
                  },
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    await _products.doc(productId).delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have successfully deleted a product'),
        ),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _minPrice = double.tryParse(_minPriceController.text.trim());
      _maxPrice = double.tryParse(_maxPriceController.text.trim());
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();

    setState(() {
      _searchQuery = '';
      _minPrice = null;
      _maxPrice = null;
    });
  }

  bool _matchesFilters(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;

    final String nameLower = (data['name_lower'] ?? '').toString();
    final double price = (data['price'] as num).toDouble();

    final bool matchesSearch =
        _searchQuery.isEmpty || nameLower.contains(_searchQuery);

    final bool matchesMin = _minPrice == null || price >= _minPrice!;
    final bool matchesMax = _maxPrice == null || price <= _maxPrice!;

    return matchesSearch && matchesMin && matchesMax;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Operations'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search by name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Min Price',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Max Price',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply Filter'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _products.snapshots(),
              builder: (context, streamSnapshot) {
                if (streamSnapshot.hasError) {
                  return Center(child: Text('Error: ${streamSnapshot.error}'));
                }

                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!streamSnapshot.hasData) {
                  return const Center(child: Text('No products found.'));
                }

                final docs = streamSnapshot.data!.docs
                    .where(_matchesFilters)
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot documentSnapshot = docs[index];
                    final data =
                        documentSnapshot.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(data['name'].toString()),
                        subtitle: Text('\$${data['price'].toString()}'),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _createOrUpdate(documentSnapshot),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteProduct(documentSnapshot.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
