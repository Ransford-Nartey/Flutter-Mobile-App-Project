# Firestore Setup for Cycle Farms App

## Cart Data Structure

The cart system uses the following Firestore structure:

```
users/{userId}/cart/{productId}
```

Each cart item document contains:
- `id`: Unique cart item ID
- `productId`: Product identifier
- `name`: Product name
- `category`: Product category
- `price`: Product price
- `image`: Product image path
- `quantity`: Item quantity
- `totalPrice`: Calculated total (price × quantity)

## Security Rules

The `firestore.rules` file contains security rules that ensure:
- Users can only access their own user document
- Users can only access their own cart collection
- All other collections are denied by default

## Deployment

### 1. Deploy Security Rules

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (if not already done)
firebase init firestore

# Deploy the rules
firebase deploy --only firestore:rules
```

### 2. Verify Rules

After deployment, verify the rules are active in the Firebase Console:
1. Go to Firestore Database
2. Click on "Rules" tab
3. Ensure the rules are updated

## Cart Operations

The cart system automatically:
- ✅ Creates cart items in Firestore when added
- ✅ Updates quantities in real-time
- ✅ Removes items when deleted
- ✅ Syncs across devices for the same user
- ✅ Maintains data consistency

## Benefits of Firestore

- **Real-time Sync**: Cart updates appear instantly across devices
- **Offline Support**: Works even without internet connection
- **Security**: Users can only access their own cart data
- **Scalability**: Handles large numbers of users and cart items
- **Backup**: Automatic data backup and recovery

## Testing

To test the cart functionality:
1. Sign in with a user account
2. Add products to cart
3. Check Firestore Console to see cart documents
4. Verify real-time updates work
5. Test cart persistence across app restarts
