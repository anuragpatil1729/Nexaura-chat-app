# NexaAura Chat App

A modern, feature-rich Flutter chat application with a cyberpunk-themed UI, powered by Firebase.

## Features

### Core Messaging
- **One-to-One Chat**: Private conversations between users
- **Group Chat**: Create and participate in group conversations
- **Real-time Messaging**: Instant message delivery using Firebase Firestore
- **Media Sharing**: Send images and voice messages
- **Message Reactions**: React to messages with emojis
- **Reply to Messages**: Quote and reply to specific messages
- **Read Receipts**: Track message read status

### User Features
- **Authentication**: Email/password, Google Sign-In, and Facebook Login
- **User Profiles**: Customizable display names and profile pictures
- **Online Presence**: Real-time online/offline status indicators
- **Contact List**: View all registered users with online status

### Advanced Features
- **Voice Messages**: Record and send audio messages with long-press
- **Push Notifications**: Firebase Cloud Messaging integration
- **Typing Indicators**: See when someone is typing (prepared)
- **Message Deletion**: Swipe to delete messages (UI ready)
- **Cyberpunk Theme**: Unique neon-inspired dark theme

## Tech Stack

- **Flutter**: Cross-platform mobile framework
- **Firebase Authentication**: User authentication
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: Media file storage
- **Firebase Cloud Messaging**: Push notifications
- **flutter_sound**: Audio recording and playback
- **image_picker**: Image selection from gallery
- **RxDart**: Reactive programming extensions

## Project Structure

```
lib/
├── models/
│   ├── conversation_model.dart    # Conversation data model
│   ├── group_model.dart           # Group chat model
│   └── user_model.dart            # User profile model
├── screens/
│   ├── chat_screen.dart           # Main chat list screen
│   ├── contact_list_screen.dart   # User contact list
│   ├── create_group_screen.dart   # Group creation interface
│   ├── group_chat_screen.dart     # Group conversation screen
│   ├── login_screen.dart          # Login interface
│   ├── one_to_one_chat_screen.dart # Private chat screen
│   ├── profile_screen.dart        # User profile management
│   └── register_screen.dart       # Registration interface
├── services/
│   ├── audio_service.dart         # Audio recording/playback
│   ├── firestore_service.dart     # Firestore database operations
│   ├── notification_service.dart  # Push notification handling
│   ├── presence_service.dart      # Online status management
│   └── storage_service.dart       # Firebase Storage operations
├── widgets/
│   └── audio_message_bubble.dart  # Audio message UI component
├── firebase_options.dart          # Firebase configuration
├── main.dart                      # App entry point
└── theme.dart                     # Cyberpunk theme definition
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.10.3 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account

### Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project named "chatapp-new-7ec36" (or your preferred name)

2. **Enable Firebase Services**
   - Authentication (Email/Password, Google, Facebook)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging

3. **Configure Android**
   - Download `google-services.json`
   - Place in `android/app/`
   - Update package name in Firebase console to match `com.example.nexaaura`

4. **Configure iOS**
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`
   - Update bundle ID to match `com.example.nexaaura`

5. **Firestore Security Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth.uid == userId;
       }
       
       match /chats/{chatId} {
         allow read, write: if request.auth != null && 
           request.auth.uid in resource.data.participants;
       }
       
       match /groups/{groupId} {
         allow read: if request.auth != null && 
           request.auth.uid in resource.data.members;
         allow write: if request.auth != null;
       }
       
       match /presence/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth.uid == userId;
       }
     }
   }
   ```

6. **Storage Security Rules**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /images/{imageId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && 
           request.resource.size < 5 * 1024 * 1024;
       }
     }
   }
   ```

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nexaaura
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Update Firebase configuration**
   - Replace Firebase configuration files with your own
   - Update `lib/firebase_options.dart` with your Firebase project details

4. **Configure Android permissions**
   - Permissions are already set in `AndroidManifest.xml`
   - `INTERNET`, `RECORD_AUDIO` permissions included

5. **Configure iOS permissions**
   - Microphone usage description already in `Info.plist`

6. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Android
- **Min SDK**: 21 (automatically configured)
- **Target SDK**: Latest (automatically configured)
- **Compile SDK**: Latest (automatically configured)

### iOS
- **Minimum iOS Version**: 13.0
- **Swift Version**: 5.0

## Key Dependencies

```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.17.5
cloud_firestore: ^4.15.5
firebase_storage: ^11.6.5
firebase_messaging: ^14.7.15
image_picker: ^1.0.4
flutter_sound: ^9.2.13
google_sign_in: ^6.1.5
flutter_facebook_auth: ^6.0.2
permission_handler: ^11.0.1
flutter_slidable: ^3.0.0
rxdart: ^0.27.7
intl: ^0.18.1
```

## Features Implementation

### Authentication Flow
1. User lands on Login Screen
2. Can register new account or use social login
3. Upon authentication, redirected to Chat Screen
4. FCM token saved automatically for notifications

### Messaging Flow
1. View all conversations on Chat Screen
2. Tap contact to start/continue one-to-one chat
3. Create groups from Contact List screen
4. Send text, images, or voice messages
5. React to messages, reply to specific messages
6. Real-time presence indicators

### Voice Messages
- Long-press microphone icon to record
- Release to send
- Tap to play received voice messages

## Theming

The app uses a cyberpunk-inspired theme with:
- **Primary Colors**: Neon Magenta (#FF00FF) and Neon Cyan (#00FFFF)
- **Background**: Cyberpunk Black (#0A0A0A)
- **Surfaces**: Dark Grey (#1E1E1E)
- **Accent**: Light Grey (#8A8A8A)

Customize in `lib/theme.dart`.

## Known Issues & Limitations

- Social login (Google/Facebook) methods are stubbed out in `login_screen.dart`
- Voice message waveform visualization not implemented
- Typing indicators prepared but not fully implemented
- Group chat voice messages need same UI treatment as one-to-one

## Future Enhancements

- End-to-end encryption
- Video calling
- Message search
- Chat export
- Custom emoji reactions
- Message forwarding
- Delivery status (sent/delivered/read)
- Last seen timestamp
- Block users
- Report inappropriate content

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is private and not licensed for public use.

## Support

For issues and questions, please create an issue in the repository.

---

**NexaAura** - Modern chat experience with a cyberpunk edge ⚡

many more to come , Thinking ....
