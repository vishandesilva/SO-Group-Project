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

  final TextEditingController contestDurationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Contests",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 25.0,
          ),
        ),
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        actions: [
          IconButton(
            tooltip: "Create new contest",
            iconSize: 35.0,
            icon: Icon(
              Icons.add,
              color: Theme.of(context).accentColor,
            ),
            onPressed: () => contestForm(),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 0.5,
                  color: Theme.of(context).primaryColor,
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

        bool _contestDuration = true;
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
                child: Container(
                  width: double.maxFinite,
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
                            hintText: "About your contest",
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: contestDurationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Duration (1-5 days)",
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: "How long is the contest",
                            hintStyle: TextStyle(color: Colors.white38),
                            errorText: !_contestDuration ? "Duration between 1 to 5 days" : null,
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
                        if (int.parse(contestDurationController.text) < 1 || int.parse(contestDurationController.text) > 5) {
                          _contestDuration = false;
                        } else {
                          _contestDuration = true;
                        }
                      },
                    );

                    if (_contestName && _contestDuration) {
                      var df = contestReference.doc();
                      contestReference.doc(df.id).set({
                        'contestId': df.id,
                        'endDate': getDuration(contestDurationController.text),
                        'contestName': contestNameController.text,
                        'description': contestDesriptionController.text,
                        'hostUserId': widget.userId,
                        'contestEnd': false,
                        'participants': [widget.userId],
                        'hostUsername': user.userName,
                      });
                      contestNameController.clear();
                      contestDesriptionController.clear();
                      contestDurationController.clear();
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
                    contestDurationController.clear();
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

  int getDuration(String days) {
    var today = DateTime.now();
    var fiftyDaysFromNow = today.add(Duration(days: int.parse(days)));
    int dateTimeCreatedAt = fiftyDaysFromNow.millisecondsSinceEpoch;
    return dateTimeCreatedAt;
  }
}

class ContestTile extends StatelessWidget {
  final String contestName;
  final String contestId;
  final String contestDescription;
  final String hostUserId;
  final String hostUsername;
  final List participants;
  final int endDate;
  bool contestEnd;

  ContestTile({
    this.contestName,
    this.hostUsername,
    this.contestId,
    this.contestDescription,
    this.participants,
    this.hostUserId,
    this.contestEnd,
    this.endDate,
  });

  factory ContestTile.fromDocument(DocumentSnapshot doc) {
    return ContestTile(
      contestId: doc.data()['contestId'],
      contestName: doc.data()['contestName'],
      contestDescription: doc.data()['description'],
      participants: doc.data()['participants'],
      hostUserId: doc.data()['hostUserId'],
      contestEnd: doc.data()['contestEnd'],
      endDate: doc.data()['endDate'],
      hostUsername: doc.data()['hostUsername'],
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
            endDate: endDate,
            contestEnd: contestEnd,
          ),
        ),
      ),
      title: Text(
        contestName,
        style: TextStyle(color: Colors.white, fontSize: 20.0),
      ),
      subtitle: Text(
        "Host by " + hostUsername,
        style: TextStyle(color: Colors.grey),
      ),
      trailing: !contestEnd
          ? Text(
              "Available",
              style: TextStyle(color: Colors.green, fontSize: 15.0),
            )
          : Text(
              "Over",
              style: TextStyle(color: Colors.red, fontSize: 15.0),
            ),
    );
  }
}
