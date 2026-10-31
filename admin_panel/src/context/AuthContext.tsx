import React, { createContext, useContext, useEffect, useState } from 'react';
import {
  User as FirebaseUser,
  onAuthStateChanged,
  signInWithEmailAndPassword,
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
  logout: () => Promise<void>;
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
          // Force-refresh the token to get the latest custom claims
          const idTokenResult = await user.getIdTokenResult(/* forceRefresh */ true);
          const hasAdminClaim = idTokenResult.claims['admin'] === true;

          if (!hasAdminClaim) {
            // Not an admin — do NOT auto-promote based on email
            setAdminProfile(null);
            setIsAdmin(false);
            setLoading(false);
            return;
          }

          // Verify admin doc exists and is not suspended
          const adminDocRef = doc(db, 'Admins', user.uid);
          const adminSnap = await getDoc(adminDocRef);

          if (adminSnap.exists()) {
            const data = adminSnap.data() as AdminUser;
            if (data.status !== 'suspended') {
              setAdminProfile({ ...data, uid: user.uid });
              setIsAdmin(true);
              // Update last login timestamp
              await setDoc(adminDocRef, { lastLoginAt: serverTimestamp() }, { merge: true });
            } else {
              setAdminProfile(null);
              setIsAdmin(false);
            }
          } else {
            // Has admin claim but no Admins doc — treat as unauthorized
            setAdminProfile(null);
            setIsAdmin(false);
          }
        } catch (error) {
          console.error('Error verifying admin permissions:', error);
          setAdminProfile(null);
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

  const logout = async () => {
    await firebaseSignOut(auth);
    setAdminProfile(null);
    setIsAdmin(false);
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        adminProfile,
        isAdmin,
        loading,
        login,
        logout,
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
