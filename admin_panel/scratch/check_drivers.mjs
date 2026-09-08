import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';

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
const db = getFirestore(app);

async function check() {
  console.log('Fetching Driver collection...');
  const snap = await getDocs(collection(db, 'Driver'));
  console.log(`Found ${snap.docs.length} driver document(s):`);
  snap.docs.forEach((doc) => {
    console.log(`Doc ID: ${doc.id}`);
    console.log(JSON.stringify(doc.data(), null, 2));
  });

  console.log('\nFetching Broker collection...');
  const brokerSnap = await getDocs(collection(db, 'Broker'));
  console.log(`Found ${brokerSnap.docs.length} broker document(s):`);
  brokerSnap.docs.forEach((doc) => {
    console.log(`Broker ID: ${doc.id}, Name: ${doc.data().name || doc.data().companyName}`);
  });
}

check().catch(console.error);
