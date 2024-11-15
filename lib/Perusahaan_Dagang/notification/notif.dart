import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      setState(() {});
    });
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

  // Fungsi untuk menghapus notifikasi
  Future<void> _deleteNotification(String notificationId) async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('Notifications')
            .doc(notificationId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Notifikasi berhasil dihapus'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Gagal menghapus notifikasi'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Dialog konfirmasi hapus
  Future<void> _showDeleteDialog(String notificationId) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Hapus Notifikasi'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteNotification(notificationId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
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
                onLongPress: () => _showDeleteDialog(notification.id),
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
  final VoidCallback? onLongPress;

  const NotificationCard({
    Key? key,
    required this.title,
    required this.message,
    required this.timestamp,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // Menambahkan gesture detector untuk menangani long Press
      onLongPress: onLongPress,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 7, horizontal: 15),
        color: Colors.blue.shade50,
        child: ListTile(
          leading: Icon(Icons.notifications, color: Colors.blueAccent),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
              Text(
                DateFormat('EEEE h:mm a', 'id_ID').format(timestamp),
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
