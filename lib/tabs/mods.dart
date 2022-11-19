import "dart:io";

import "package:flutter/material.dart";
import "package:mod_manager/main.dart";
import "package:mod_manager/tabs/settings.dart";
import "package:mod_manager/util/bepinhecks_install_helper.dart";
import "package:mod_manager/util/instance_file_manager.dart";
import "package:path/path.dart" as p;

class ModsTab extends StatefulWidget {
  const ModsTab({super.key});
  @override
  State<ModsTab> createState() => ModsTabState();
}

class ModsTabState extends State<ModsTab> {
  void handleLaunchClick(instId) {
    switchInstance(instId);
  }

  List<Widget> genModWidgets(instId, jsonInp, dialogSetState) {
    var i = 0;
    List<Widget> out = List.empty(growable: true);
    for (var mod in jsonInp) {
      i++;
      out.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text("$i: ${mod["name"]} v${mod["version"]}"),
          IconButton(
              onPressed: () {
                removeMod(instId, mod["id"]);
                dialogSetState(() {
                  var test = 1 * 1;
                });
              },
              icon: const Icon(Icons.delete))
        ],
      ));
    }
    return out;
  }

  void removeMod(instId, modId) {
    var curr = MyApp.cfg.getInstanceId(instId);
    var modToRemove = getMod(curr["mods"], modId);
    (curr["mods"] as List<dynamic>).remove(modToRemove);
    MyApp.cfg.editInstance(instId, curr);
  }

  dynamic getMod(mdodList, id) {
    for (var mod in mdodList) {
      if (mod["id"] == id) {
        return mod;
      }
    }
  }

  void addMod(dialogSetState) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, subDialogSetState) {
            return const AlertDialog(
              title: Text("Info"),
              content: Text("TODO: modweaver api to install mods"),
            );
          });
        });
  }

  void handleModsClick(instId) {
    var instances = MyApp.cfg.getInstances();
    dynamic selected;
    for (var ins in instances) {
      if (ins["id"] == instId) {
        selected = ins;
        break;
      }
    }
    var mods = selected["mods"];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context, dialogSetState) {
          return AlertDialog(
            title: Text('Mods installed to ${selected["name"]}'),
            content:
                Column(children: genModWidgets(instId, mods, dialogSetState)),
            actions: [
              TextButton(
                  onPressed: () {
                    addMod(dialogSetState);
                  },
                  child: const Text("Add...")),
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        });
      },
    );
  }

  void handleDeleteClick(id) {
    MyApp.cfg.deleteInstance(id);
    deleteInstanceFiles(id);
    setState(() {
      var x = 1 * 1;
    });
  }

  void handleAddClick() {
    var instName = "";
    var instId = "";
    var bepinVersion = "latest";
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, subDialogSetState) {
            return AlertDialog(
              title: const Text("Add an instance"),
              content: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Instance name",
                    ),
                    onChanged: (value) => instName = value,
                  ),
                  const Text(" \n "),
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          "Instance ID (letters, numbers, underscores only)",
                    ),
                    onChanged: (value) => instId = value,
                  ),
                  const Text(" \n "),
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "BepInHecks version (default latest)",
                    ),
                    onChanged: (value) => bepinVersion = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    createInstance(instName, instId, bepinVersion);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          });
        });
  }

  Future<void> createInstance(String name, String id, String bihVersion) async {
    await pullLatestReleaseGH("cobwebsh/BepInHecks", "bepinhecks-dl",
        version: bihVersion == "" ? "latest" : bihVersion);
    var instDir = p.join(SettingsTabState.instPath, id);

    var dir = Directory(instDir);
    if (dir.existsSync()) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context, subDialogSetState) {
              return const AlertDialog(
                title: Text("Error"),
                content: Text("An instance with that ID already exists"),
              );
            });
          });
      return;
    }
    dir.createSync();
    copyPath("bepinhecks-dl", instDir);

    MyApp.cfg.addInstance(name, id, bihVersion);
  }

  List<Widget> generateCards() {
    List<Widget> out = List.empty(growable: true);

    out.add(Card(
      color: Colors.indigo[100],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.interests),
            title: const Text("Vanilla"),
            subtitle: Text(
                "${SettingsTabState.instPath}${Platform.pathSeparator}spiderheck"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  switchVanilla();
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith(
                        (states) => Colors.amber),
                    foregroundColor: MaterialStateProperty.resolveWith(
                        (states) => Colors.white)),
                child: const Text("Select"),
              ),
              const Text(" \n "),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    ));

    var instances = MyApp.cfg.getInstances();
    for (var inst in instances) {
      out.add(
        Card(
          color: Colors.indigo[100],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.interests),
                title: Text(inst["name"]),
                subtitle: Text(
                    "${SettingsTabState.instPath}${Platform.pathSeparator}${inst["id"]}"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      handleModsClick(inst["id"]);
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.amber),
                        foregroundColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.white)),
                    child: const Text("Mods"),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      handleLaunchClick(inst["id"]);
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.amber),
                        foregroundColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.white)),
                    child: const Text("Select"),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      handleDeleteClick(inst["id"]);
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.amber),
                        foregroundColor: MaterialStateProperty.resolveWith(
                            (states) => Colors.white)),
                    child: const Text("Delete"),
                  ),
                  const Text(" \n "),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      );
    }

    out.add(Card(
      color: Colors.indigo[100],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                handleAddClick();
              },
            ),
          )
        ],
      ),
    ));

    return out;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2, children: [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: generateCards()),
        ),
      )
    ]);
  }
}
