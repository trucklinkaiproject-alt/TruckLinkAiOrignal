import React, { createContext, useContext, useEffect, useState } from 'react';
import { 
  User as FirebaseUser,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut
} from 'firebase/auth';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../services/firebase';
import { AdminUser } from '../types/models';

interface AuthContextType {
  currentUser: FirebaseUser | null;
  adminProfile: AdminUser | null;
  isAdmin: boolean;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, name?: string) => Promise<void>;
  logout: () => Promise<void>;
  registerInitialAdmin: (uid: string, email: string, name: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<FirebaseUser | null>(null);
  const [adminProfile, setAdminProfile] = useState<AdminUser | null>(null);
  const [isAdmin, setIsAdmin] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);
      if (user) {
        try {
          const adminDocRef = doc(db, 'Admins', user.uid);
          const adminSnap = await getDoc(adminDocRef);

          if (adminSnap.exists()) {
            const data = adminSnap.data() as AdminUser;
            if (data.status !== 'suspended') {
              setAdminProfile({ ...data, uid: user.uid });
              setIsAdmin(true);
              // Update last login
              await setDoc(adminDocRef, { lastLoginAt: serverTimestamp() }, { merge: true });
            } else {
              setAdminProfile(null);
              setIsAdmin(false);
            }
          } else {
            // Check if user is recognized admin or default fallback for initial setup
            // For production setup, if this is an authorized super-user email, register admin doc
            const defaultAdminEmail = 'admin@trucklink.ai';
            if (user.email === defaultAdminEmail || user.email?.includes('admin')) {
              const newAdmin: AdminUser = {
                uid: user.uid,
                email: user.email || '',
                displayName: user.displayName || 'Super Admin',
                role: 'superadmin',
                status: 'active',
                createdAt: serverTimestamp(),
                lastLoginAt: serverTimestamp(),
              };
              await setDoc(adminDocRef, newAdmin);
              setAdminProfile(newAdmin);
              setIsAdmin(true);
            } else {
              // Not an admin in Admins collection
              setAdminProfile(null);
              setIsAdmin(false);
            }
          }
        } catch (error) {
          console.error('Error verifying admin permissions:', error);
          setIsAdmin(false);
        }
      } else {
        setAdminProfile(null);
        setIsAdmin(false);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const login = async (email: string, password: string) => {
    setLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } finally {
      setLoading(false);
    }
  };

  const register = async (email: string, password: string, name?: string) => {
    setLoading(true);
    try {
      const cred = await createUserWithEmailAndPassword(auth, email, password);
      const user = cred.user;
      const adminDocRef = doc(db, 'Admins', user.uid);
      const newAdmin: AdminUser = {
        uid: user.uid,
        email: email,
        displayName: name || 'Super Admin',
        role: 'superadmin',
        status: 'active',
        createdAt: serverTimestamp(),
        lastLoginAt: serverTimestamp(),
      };
      await setDoc(adminDocRef, newAdmin);
      setAdminProfile(newAdmin);
      setIsAdmin(true);
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    await firebaseSignOut(auth);
    setAdminProfile(null);
    setIsAdmin(false);
  };

  const registerInitialAdmin = async (uid: string, email: string, name: string) => {
    const adminDocRef = doc(db, 'Admins', uid);
    const newAdmin: AdminUser = {
      uid,
      email,
      displayName: name,
      role: 'superadmin',
      status: 'active',
      createdAt: serverTimestamp(),
      lastLoginAt: serverTimestamp(),
    };
    await setDoc(adminDocRef, newAdmin);
    setAdminProfile(newAdmin);
    setIsAdmin(true);
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        adminProfile,
        isAdmin,
        loading,
        login,
        register,
        logout,
        registerInitialAdmin,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
