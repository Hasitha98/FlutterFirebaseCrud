import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import './Models/book.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
   runApp(BookApp());
}

class BookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Firebase Crud",
      home: BookFirbaseDemo(),
    );
  }
}

class BookFirbaseDemo extends StatefulWidget {

  BookFirbaseDemo() : super();

  final String title = "Book DB";

  @override
  _BookFirbaseDemoState createState() => _BookFirbaseDemoState();
}

class _BookFirbaseDemoState extends State<BookFirbaseDemo> {

  TextEditingController bookNameController = TextEditingController();
  TextEditingController authorNameController = TextEditingController();

  bool isEditing = false;
  bool textFieldVisibilty = false;

  String firestoreCollectionName = "Books";

  Book currentBook;

  getAllBooks() {
    return FirebaseFirestore.instance.collection(firestoreCollectionName).snapshots();
  }

  addBook() async {
    Book book = Book(bookName: bookNameController.text, authorName: authorNameController.text);

    try{
      FirebaseFirestore.instance.runTransaction(
        (Transaction transaction) async {
          await FirebaseFirestore.instance
                                 .collection(firestoreCollectionName)
                                 .doc()
                                 .set(book.toJson());

        }
      );
    } catch(exc) {
      print(exc.toString());
    }
  }

  updateBook(Book book, String bookName, String authorName) {
    try {

      FirebaseFirestore.instance.runTransaction((transaction) async {
        await transaction.update(book.documentReference, {'bookName': bookName, 'authorName': authorName});
      });

    } catch(exc) {
      print(exc.toString());
    }
  }

  updateIfEditing() {
    if (isEditing) {
      // Update
      updateBook(currentBook, bookNameController.text, authorNameController.text);

      setState(() {
        isEditing = false;
      });
    }
  }

  deleteBook(Book book) {
    FirebaseFirestore.instance.runTransaction(
      (Transaction transaction) async {
        await transaction.delete(book.documentReference);
      }
       );
  }

  Widget buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getAllBooks(),
      builder: (context,snapshot) {
        if(snapshot.hasError) {
          return Text('Error ${snapshot.error}');
        }
        if(snapshot.hasData) {
          print("documents -> ${snapshot.data.docs.length}");
          return buildList(context, snapshot.data.docs);
        }
      },
    ); 
  }

  Widget buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      children: snapshot.map((data) => listItemBuilder(context, data)).toList(),
    );
  }

  Widget listItemBuilder(BuildContext context, DocumentSnapshot data) {
    final book = Book.fromSnapshot(data);

    return Padding(
      key: ValueKey(book.bookName),
      padding: EdgeInsets.symmetric(vertical: 19, horizontal: 1),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SingleChildScrollView(
          child: ListTile(
            title: Column(
              children : [
                Row(
                  children: [
                    Icon(Icons.book, color: Colors.yellow,),
                    Text(book.bookName),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.purple,), 
                    Text(book.authorName),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                deleteBook(book);
              },
            ),
            onTap: () {
              setUpdateUI(book);
            },
          ),
        ),
      ),
    );
  }

  setUpdateUI(Book book) {
    bookNameController.text = book.bookName;
    authorNameController.text = book.authorName;

    setState(() {
      textFieldVisibilty = true;
      isEditing = true;
      currentBook = book;
    });
  }

  button() {
    return SizedBox(
      width: double.infinity,
      child: OutlineButton(
        child: Text(isEditing ? "UPDATE" : "ADD"),
        onPressed: () {
          if(isEditing == true){
            updateIfEditing();
          } else {
            addBook();
          }

          setState(() {
            textFieldVisibilty = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                textFieldVisibilty = !textFieldVisibilty;
              });
            },
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            textFieldVisibilty
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    TextFormField(
                      controller: bookNameController,
                      decoration: InputDecoration(
                        labelText: "Book Name",
                        hintText: "Enter Book Name",
                      ),
                    ),
                    TextFormField(
                  controller: authorNameController,
                  decoration: InputDecoration(
                    labelText: "Book Author",
                    hintText: "Enter Author Name",
                  ),
                ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ), 
                button()               
              ],
            ): Container(),
            SizedBox(
              height: 20,
            ),
            Text("Books",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            ),
            SizedBox(
              height: 20,
            ),
            Flexible(child: buildBody(context),)
          ],
        ),
      ),
    );
  }
}