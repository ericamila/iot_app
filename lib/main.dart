import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child("users");

  // Ações do menu
  static const String editAction = "edit";
  static const String deleteAction = "delete";

  // Exibe o AlertDialog para adicionar ou editar
  void _showUserDialog(
    BuildContext context, {
    String? userId,
    Map<dynamic, dynamic>? userData,
  }) {
    final TextEditingController nameController =
        TextEditingController(text: userData != null ? userData["name"] : "");
    final TextEditingController ageController = TextEditingController(
        text: userData != null ? userData["age"].toString() : "");
    final TextEditingController emailController =
        TextEditingController(text: userData != null ? userData["email"] : "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(userId == null ? "Adicionar Usuário" : "Alterar Usuário"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nome"),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Idade"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(userId == null ? "Adicionar" : "Salvar"),
              onPressed: () {
                final String name = nameController.text;
                final int? age = int.tryParse(ageController.text);
                final String email = emailController.text;

                if (name.isEmpty || age == null || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text("Preencha todos os campos corretamente!")),
                  );
                  return;
                }

                if (userId == null) {
                  // Adiciona
                  dbRef.push().set({
                    "name": name,
                    "age": age,
                    "email": email,
                  }).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Usuário adicionado com sucesso!")),
                    );
                    Navigator.of(context).pop(); //aqui
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Erro ao adicionar usuário: $error")),
                    );
                  });
                } else {
                  // Atualiza
                  dbRef.child(userId).update({
                    "name": name,
                    "age": age,
                    "email": email,
                  }).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Usuário alterado com sucesso!")),
                    );
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erro ao altera usuário: $error")),
                    );
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Exibe o AlertDialog para excluir
  void _showDeleteDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content:
              const Text("Tem certeza de que deseja excluir este usuário?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Excluir"),
              onPressed: () {
                dbRef.child(userId).remove().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Usuário excluído com sucesso!")),
                  );
                  Navigator.of(context).pop();
                }).catchError((error) {
                  debugPrint("Erro ao excluir dados: $error");
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CRUD com Firebase")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _showUserDialog(context),
            child: const Text("Adicionar Usuário"),
          ),
          Expanded(
            child: StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Sem dados"));
                }

                final Map<dynamic, dynamic> users =
                    snapshot.data!.snapshot.value as Map;

                return ListView(
                  children: users.entries.map((entry) {
                    final String userId = entry.key;
                    final Map<dynamic, dynamic> user = entry.value;

                    return ListTile(
                      title: Text(user["name"]),
                      subtitle: Text(
                          "Idade: ${user["age"]}, Email: ${user["email"]}"),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == editAction) {
                            _showUserDialog(context,
                                userId: userId, userData: user);
                          } else if (value == deleteAction) {
                            _showDeleteDialog(context, userId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: editAction,
                            child: Text("Alterar"),
                          ),
                          const PopupMenuItem(
                            value: deleteAction,
                            child: Text("Excluir"),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
