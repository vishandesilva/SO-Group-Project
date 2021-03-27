import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novus/widgets/ContestWidget.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'HomePage.dart';



class ContestsPage extends StatefulWidget {
  final String userId;

  ContestsPage({this.userId});

  @override
  _ContestsPageState createState() => _ContestsPageState();
}

class _ContestsPageState extends State<ContestsPage> {
  final TextEditingController contestNameController = TextEditingController();
  final TextEditingController contestDesriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Contest"),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "Your Current",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30.0),
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).accentColor,
                ),
                onPressed: () => contestForm(),
              )
            ],
          ),
          Divider(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 0.5,
                  color: Colors.purple,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: StreamBuilder(
                stream: contestReference.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) return circularProgress();
                  List<ContestTile> comments = [];
                  snapshot.data.docs.forEach(
                    (element) {
                      ContestTile temp = ContestTile.fromDocument(element);
                      if (temp.participants.contains(widget.userId)) {
                        comments.add(temp);
                      }
                    },
                  );
                  return ListView(children: comments);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  contestForm() {
    return showDialog(
      context: context,
      builder: (context) {
        bool _contestName = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              contentPadding: EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: Colors.grey[900],
              title: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Contest Details",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: contestNameController,
                        decoration: InputDecoration(
                          labelText: "Title",
                          labelStyle: TextStyle(color: Colors.white),
                          hintText: "Provide a name",
                          hintStyle: TextStyle(color: Colors.white38),
                          errorText: !_contestName ? "name required" : null,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        cursorColor: Colors.white,
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: contestDesriptionController,
                        decoration: InputDecoration(
                          labelText: "Description",
                          labelStyle: TextStyle(color: Colors.white),
                          hintText: "About your contest...",
                          hintStyle: TextStyle(color: Colors.white38),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        cursorColor: Colors.white,
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              children: <Widget>[
                Container(
                  height: 0.10,
                  color: Colors.white,
                ),
                SimpleDialogOption(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        "Done",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 17.0,
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(
                      () {
                        if (contestNameController.text.isEmpty) {
                          _contestName = false;
                        } else {
                          _contestName = true;
                        }
                      },
                    );

                    if (_contestName) {
                      var df = contestReference.doc();
                      contestReference.doc(df.id).set({
                        'contestId': df.id,
                        'contestName': contestNameController.text,
                        'description': contestDesriptionController.text,
                        'hostUserId': widget.userId,
                        'participants': [widget.userId],
                      });
                      contestNameController.clear();
                      contestDesriptionController.clear();
                      Navigator.pop(context);
                    }
                  },
                ),
                Container(
                  height: 0.10,
                  color: Colors.white,
                ),
                SimpleDialogOption(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.0,
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    contestNameController.clear();
                    contestDesriptionController.clear();
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }
}

class ContestTile extends StatelessWidget {
  final String contestName;
  final String contestId;
  final String contestDescription;
  final String hostUserId;
  final List participants;

  ContestTile({
    this.contestName,
    this.contestId,
    this.contestDescription,
    this.participants,
    this.hostUserId,
  });

  factory ContestTile.fromDocument(DocumentSnapshot doc) {
    return ContestTile(
      contestId: doc.data()['contestId'],
      contestName: doc.data()['contestName'],
      contestDescription: doc.data()['description'],
      participants: doc.data()['participants'],
      hostUserId: doc.data()['hostUserId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Contest(
            contestName: contestName,
            contestId: contestId,
            contestDescription: contestDescription,
            participants: participants,
            hostUserId: hostUserId,
          ),
        ),
      ),
      title: Text(
        contestName,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
