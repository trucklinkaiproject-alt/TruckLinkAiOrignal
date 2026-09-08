import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Firebase config copied from lib/Core/Constants/firebase_options.dart (web configuration)
const firebaseConfig = {
  apiKey: 'AIzaSyActpi6mWY1fd7bDPrh3ALSuh1cB9N4uxI',
  authDomain: 'trucklink-ai-orignal.firebaseapp.com',
  projectId: 'trucklink-ai-orignal',
  storageBucket: 'trucklink-ai-orignal.firebasestorage.app',
  messagingSenderId: '848099422906',
  appId: '1:848099422906:web:a0fbf7518c75a12a060883',
  measurementId: 'G-Z9R9W65TQN',
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
