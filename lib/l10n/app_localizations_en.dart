// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'POS Delivery';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get todaysDeliveries => 'Today\'s Deliveries';

  @override
  String get salesReturns => 'Sales Returns';

  @override
  String get categories => 'Categories';

  @override
  String get customers => 'Customers';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get newDelivery => 'New Delivery';

  @override
  String get createNewDelivery => 'Create a new delivery';

  @override
  String get salesReturn => 'Sales Return';

  @override
  String get recordSalesReturn => 'Record a sales return';

  @override
  String get sync => 'Sync';

  @override
  String get syncPendingData => 'Sync pending data';

  @override
  String get yourLocationIsBeingTracked => 'Your location is being tracked';

  @override
  String get pleaseStartDuty => 'Please start duty';

  @override
  String get startDuty => 'Start Duty';

  @override
  String get stopDuty => 'Stop Duty';

  @override
  String get syncNow => 'Sync Now';

  @override
  String syncNowPending(Object count) {
    return 'Sync Now ($count pending)';
  }

  @override
  String get noPendingDataToSync => 'No pending data to sync';

  @override
  String countPending(Object count) {
    return '$count pending';
  }

  @override
  String get addProducts => 'Add Products';

  @override
  String get editDelivery => 'Edit Delivery';

  @override
  String get invoice => 'Invoice';

  @override
  String get viewingCompletedInvoice => 'Viewing completed invoice';

  @override
  String get customer => 'Customer';

  @override
  String get items => 'Items';

  @override
  String get total => 'Total';

  @override
  String get all => 'All';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get noProductsInCategory => 'No products in this category';

  @override
  String get selectCategoryToBrowse => 'Select a category to browse products';

  @override
  String get add => 'Add';

  @override
  String get addMore => 'Add more';

  @override
  String get inCart => 'In cart:';

  @override
  String get pleaseSelectItems => 'Please add items to continue';

  @override
  String get unknown => 'Unknown';

  @override
  String get qty => 'Qty';

  @override
  String get available => 'Available:';

  @override
  String get noDeliveriesForToday => 'No deliveries for today';

  @override
  String get cart => 'Cart';

  @override
  String get clear => 'Clear';

  @override
  String get cartIsEmpty => 'Cart is empty';

  @override
  String get continueLabel => 'Continue';

  @override
  String get lineTotal => 'Line Total';

  @override
  String get editPrice => 'Edit Price';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get customerLabel => 'Customer:';

  @override
  String get billing => 'Billing';

  @override
  String get invoiceSavedSuccessfully => 'Invoice Saved Successfully';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get grossAmount => 'Gross Amount';

  @override
  String get tax => 'Tax';

  @override
  String get discount => 'Discount';

  @override
  String get discountType => 'Discount Type';

  @override
  String get none => 'None';

  @override
  String get amountRs => 'Amount (Rs.)';

  @override
  String get percent => 'Percent (%)';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get paymentMode => 'Payment Mode';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get remarksOptional => 'Remarks (Optional)';

  @override
  String get saving => 'Saving...';

  @override
  String get saveInvoice => 'Save Invoice';

  @override
  String get failedToSaveInvoice => 'Failed to save invoice';

  @override
  String get todaysEstimates => 'Today\'s Estimates';

  @override
  String get noEstimatesForToday => 'No estimates for today';

  @override
  String get salesReturnSaved => 'Sales Return Saved';

  @override
  String get successfullyRecorded => 'Successfully recorded';

  @override
  String get newSalesReturn => 'New Sales Return';

  @override
  String get product => 'Product';

  @override
  String get products => 'Products';

  @override
  String get quantity => 'Quantity';

  @override
  String get additionalDetails => 'Additional Details';

  @override
  String get reasonOptional => 'Reason (Optional)';

  @override
  String get saveSalesReturn => 'Save Sales Return';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get failedToSaveSalesReturn => 'Failed to save sales return';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get pending => 'Pending';

  @override
  String get failed => 'Failed';

  @override
  String get synced => 'Synced';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get never => 'Never';

  @override
  String get syncing => 'Syncing...';

  @override
  String get serverData => 'Server Data';

  @override
  String get syncAll => 'Sync All';

  @override
  String get syncCompletedSuccessfully => 'Sync completed successfully!';

  @override
  String get pendingItems => 'Pending Items';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get nepali => 'Nepali';

  @override
  String get delivery => 'Delivery';

  @override
  String deliveryNumber(Object id) {
    return 'Delivery #$id';
  }

  @override
  String get phone => 'Phone:';

  @override
  String get date => 'Date:';

  @override
  String get payment => 'Payment:';

  @override
  String get paid => 'Paid:';

  @override
  String qtyWithPrice(Object price, Object qty) {
    return 'Qty: $qty × Rs. $price';
  }

  @override
  String itemCount(Object count) {
    return '$count item';
  }

  @override
  String itemCountPlural(Object count) {
    return '$count items';
  }

  @override
  String customerId(Object id) {
    return 'Customer #$id';
  }

  @override
  String estimateNumber(Object id) {
    return 'Estimate #$id';
  }

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get deliveryShort => 'Delivery';

  @override
  String get receipt => 'Receipt';
}
