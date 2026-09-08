// Firebase Cloud Messaging Service Worker for TruckLink AI
// Uses Firebase JS SDK v11.9.1 compatible with flutterfire firebase_core_web 2.24.1 & firebase_messaging_web 3.10.10

importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker
// Configuration matches DefaultFirebaseOptions.web in lib/Core/Constants/firebase_options.dart
const firebaseConfig = {
  apiKey: "AIzaSyActpi6mWY1fd7bDPrh3ALSuh1cB9N4uxI",
  appId: "1:848099422906:web:a0fbf7518c75a12a060883",
  messagingSenderId: "848099422906",
  projectId: "trucklink-ai-orignal",
  authDomain: "trucklink-ai-orignal.firebaseapp.com",
  storageBucket: "trucklink-ai-orignal.firebasestorage.app",
  measurementId: "G-Z9R9W65TQN"
};

firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging to handle background notifications
const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message: ", payload);

  const notificationTitle = payload.notification?.title || payload.data?.title || "TruckLink AI";
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || "",
    icon: "/icons/Icon-192.png",
    data: payload.data || {}
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
