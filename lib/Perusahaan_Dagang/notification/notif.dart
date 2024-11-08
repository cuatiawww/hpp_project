import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  // Fungsi untuk menandai semua notifikasi sebagai sudah dibaca
  void _markNotificationsAsRead() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Ambil notifikasi yang belum dibaca
      QuerySnapshot unreadNotifications = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Notifications')
          .where('isRead', isEqualTo: false)
          .get();

      // Tandai notifikasi sebagai dibaca
      for (var doc in unreadNotifications.docs) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan UID pengguna yang sedang login
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Notifikasi"),
        ),
        body: Center(
          child: Text("Anda belum login"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
      centerTitle: true,
      elevation: 0,
      title: const Text(
        'Notifikasi',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF080C67),
              Color(0xFF1E23A7),
            ],
          ),
        ),
      ),
    ),
      body: StreamBuilder(
        // Ambil data dari subkoleksi "Notifications" pengguna yang login
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('Notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Tidak ada notifikasi"));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                title: notification['title'] ?? 'No Title',
                message: notification['message'] ?? 'No Message',
                timestamp: (notification['createdAt'] as Timestamp).toDate(),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final DateTime timestamp;

  const NotificationCard({
    Key? key,
    required this.title,
    required this.message,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      color: Colors.blue.shade50,
      child: ListTile(
        leading: Icon(Icons.notifications, color: Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          "${timestamp.hour}:${timestamp.minute}",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
