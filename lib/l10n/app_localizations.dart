import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'POS Delivery'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @todaysDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Deliveries'**
  String get todaysDeliveries;

  /// No description provided for @salesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales Returns'**
  String get salesReturns;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @newDelivery.
  ///
  /// In en, this message translates to:
  /// **'New Delivery'**
  String get newDelivery;

  /// No description provided for @createNewDelivery.
  ///
  /// In en, this message translates to:
  /// **'Create a new delivery'**
  String get createNewDelivery;

  /// No description provided for @salesReturn.
  ///
  /// In en, this message translates to:
  /// **'Sales Return'**
  String get salesReturn;

  /// No description provided for @recordSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Record a sales return'**
  String get recordSalesReturn;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncPendingData.
  ///
  /// In en, this message translates to:
  /// **'Sync pending data'**
  String get syncPendingData;

  /// No description provided for @yourLocationIsBeingTracked.
  ///
  /// In en, this message translates to:
  /// **'Your location is being tracked'**
  String get yourLocationIsBeingTracked;

  /// No description provided for @pleaseStartDuty.
  ///
  /// In en, this message translates to:
  /// **'Please start duty'**
  String get pleaseStartDuty;

  /// No description provided for @startDuty.
  ///
  /// In en, this message translates to:
  /// **'Start Duty'**
  String get startDuty;

  /// No description provided for @stopDuty.
  ///
  /// In en, this message translates to:
  /// **'Stop Duty'**
  String get stopDuty;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncNowPending.
  ///
  /// In en, this message translates to:
  /// **'Sync Now ({count} pending)'**
  String syncNowPending(Object count);

  /// No description provided for @noPendingDataToSync.
  ///
  /// In en, this message translates to:
  /// **'No pending data to sync'**
  String get noPendingDataToSync;

  /// No description provided for @countPending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String countPending(Object count);

  /// No description provided for @addProducts.
  ///
  /// In en, this message translates to:
  /// **'Add Products'**
  String get addProducts;

  /// No description provided for @editDelivery.
  ///
  /// In en, this message translates to:
  /// **'Edit Delivery'**
  String get editDelivery;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @viewingCompletedInvoice.
  ///
  /// In en, this message translates to:
  /// **'Viewing completed invoice'**
  String get viewingCompletedInvoice;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @noProductsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No products in this category'**
  String get noProductsInCategory;

  /// No description provided for @selectCategoryToBrowse.
  ///
  /// In en, this message translates to:
  /// **'Select a category to browse products'**
  String get selectCategoryToBrowse;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get addMore;

  /// No description provided for @inCart.
  ///
  /// In en, this message translates to:
  /// **'In cart:'**
  String get inCart;

  /// No description provided for @pleaseSelectItems.
  ///
  /// In en, this message translates to:
  /// **'Please add items to continue'**
  String get pleaseSelectItems;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available:'**
  String get available;

  /// No description provided for @noDeliveriesForToday.
  ///
  /// In en, this message translates to:
  /// **'No deliveries for today'**
  String get noDeliveriesForToday;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartIsEmpty;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line Total'**
  String get lineTotal;

  /// No description provided for @editPrice.
  ///
  /// In en, this message translates to:
  /// **'Edit Price'**
  String get editPrice;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer:'**
  String get customerLabel;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @invoiceSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice Saved Successfully'**
  String get invoiceSavedSuccessfully;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @grossAmount.
  ///
  /// In en, this message translates to:
  /// **'Gross Amount'**
  String get grossAmount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @discountType.
  ///
  /// In en, this message translates to:
  /// **'Discount Type'**
  String get discountType;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @amountRs.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rs.)'**
  String get amountRs;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'Percent (%)'**
  String get percent;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentMode;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @remarksOptional.
  ///
  /// In en, this message translates to:
  /// **'Remarks (Optional)'**
  String get remarksOptional;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveInvoice.
  ///
  /// In en, this message translates to:
  /// **'Save Invoice'**
  String get saveInvoice;

  /// No description provided for @failedToSaveInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to save invoice'**
  String get failedToSaveInvoice;

  /// No description provided for @todaysEstimates.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Estimates'**
  String get todaysEstimates;

  /// No description provided for @noEstimatesForToday.
  ///
  /// In en, this message translates to:
  /// **'No estimates for today'**
  String get noEstimatesForToday;

  /// No description provided for @salesReturnSaved.
  ///
  /// In en, this message translates to:
  /// **'Sales Return Saved'**
  String get salesReturnSaved;

  /// No description provided for @successfullyRecorded.
  ///
  /// In en, this message translates to:
  /// **'Successfully recorded'**
  String get successfullyRecorded;

  /// No description provided for @newSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'New Sales Return'**
  String get newSalesReturn;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (Optional)'**
  String get reasonOptional;

  /// No description provided for @saveSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Save Sales Return'**
  String get saveSalesReturn;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @failedToSaveSalesReturn.
  ///
  /// In en, this message translates to:
  /// **'Failed to save sales return'**
  String get failedToSaveSalesReturn;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @serverData.
  ///
  /// In en, this message translates to:
  /// **'Server Data'**
  String get serverData;

  /// No description provided for @syncAll.
  ///
  /// In en, this message translates to:
  /// **'Sync All'**
  String get syncAll;

  /// No description provided for @syncCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sync completed successfully!'**
  String get syncCompletedSuccessfully;

  /// No description provided for @pendingItems.
  ///
  /// In en, this message translates to:
  /// **'Pending Items'**
  String get pendingItems;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @nepali.
  ///
  /// In en, this message translates to:
  /// **'Nepali'**
  String get nepali;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @deliveryNumber.
  ///
  /// In en, this message translates to:
  /// **'Delivery #{id}'**
  String deliveryNumber(Object id);

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone:'**
  String get phone;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment:'**
  String get payment;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid:'**
  String get paid;

  /// No description provided for @qtyWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty} × Rs. {price}'**
  String qtyWithPrice(Object price, Object qty);

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item'**
  String itemCount(Object count);

  /// No description provided for @itemCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCountPlural(Object count);

  /// No description provided for @customerId.
  ///
  /// In en, this message translates to:
  /// **'Customer #{id}'**
  String customerId(Object id);

  /// No description provided for @estimateNumber.
  ///
  /// In en, this message translates to:
  /// **'Estimate #{id}'**
  String estimateNumber(Object id);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(Object status);

  /// No description provided for @deliveryShort.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryShort;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining:'**
  String get remaining;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// No description provided for @makePayment.
  ///
  /// In en, this message translates to:
  /// **'Make Payment'**
  String get makePayment;

  /// No description provided for @volumeDiscount.
  ///
  /// In en, this message translates to:
  /// **'Volume Discount'**
  String get volumeDiscount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
