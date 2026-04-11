/**
 * Firebase Console → Project settings → Your apps → Web
 * Authentication → Sign-in method → Google → Enable
 *
 * Supabase Dashboard → Authentication → Providers → Google:
 * Aynı Google Cloud projesindeki OAuth 2.0 Web client ID / secret kullanın
 * (signInWithIdToken için Google sağlayıcısı açık olmalı.)
 */
const firebaseConfig = {
  apiKey: 'YOUR_WEB_API_KEY',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
};
