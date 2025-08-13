# Cycle Farms Ecommerce App

A Flutter mobile application for Cycle Farms, specializing in aquaculture feed products for West Africa. The app provides an ecommerce platform for customers to purchase feed products and for admins to manage inventory and orders.

## Features

### Customer Features
- **Onboarding**: Introduction to Cycle Farms products and services
- **Authentication**: Secure login and signup with email/password
- **Product Catalog**: Browse feed products (Tilapia, Catfish, Hatchery)
- **Shopping Cart**: Add products and manage quantities
- **Order Management**: Place orders and track delivery status
- **Profile Management**: Update personal information and view order history

### Admin Features
- **Dashboard**: Overview of sales, inventory, and customer data
- **Product Management**: Add, edit, and remove products
- **Inventory Control**: Monitor stock levels and set alerts
- **Order Processing**: Manage customer orders and delivery
- **Customer Management**: View customer information and order history
- **Analytics**: Sales reports and performance metrics

## Color Theme

The app uses a carefully selected color palette that reflects Cycle Farms' brand:

- **Primary Color**: `#1BA6A6` (Teal) - Main brand color
- **Secondary Color**: `#F2F2F2` (Light Gray) - Background and accents
- **Dark Color**: `#0D0D0D` (Near Black) - Text and primary content
- **White**: `#FFFFFF` - Clean backgrounds
- **Success**: `#388E3C` (Green) - Success states
- **Error**: `#D32F2F` (Red) - Error states
- **Warning**: `#F57C00` (Orange) - Warning states

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Cloud Storage
  - Cloud Functions
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI Components**: Material Design 3

## Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   ├── constants/
│   ├── utils/
│   └── services/
├── features/
│   ├── onboarding/
│   │   └── screens/
│   │       └── onboarding_screen.dart
│   ├── auth/
│   │   └── screens/
│   │       └── auth_screen.dart
│   ├── home/
│   ├── products/
│   ├── cart/
│   ├── orders/
│   └── profile/
├── shared/
│   ├── widgets/
│   └── models/
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.6.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd cycle_farms
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   - Create a new Firebase project
   - Enable Authentication, Firestore, and Storage
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place configuration files in appropriate directories

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

1. **Authentication**
   - Enable Email/Password authentication
   - Configure sign-in methods (Google, Facebook)

2. **Firestore Database**
   - Create collections for users, products, orders, etc.
   - Set up security rules

3. **Storage**
   - Configure rules for image uploads
   - Set up product image storage

## Development

### Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent formatting

### Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows

### State Management

The app uses Provider for state management:
- `AuthProvider`: Manages authentication state
- `CartProvider`: Manages shopping cart
- `ProductProvider`: Manages product data
- `OrderProvider`: Manages order processing

## Deployment

### Android

1. Update version in `pubspec.yaml`
2. Build APK: `flutter build apk --release`
3. Build App Bundle: `flutter build appbundle --release`

### iOS

1. Update version in `pubspec.yaml`
2. Build: `flutter build ios --release`
3. Archive and upload to App Store Connect

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is proprietary software owned by Cycle Farms.

## Support

For technical support or questions, please contact the development team.

---

**Cycle Farms** - Bet on quality, increase your profits: Choose Enam Papa
