// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'POS डेलिभरी';

  @override
  String get dashboard => 'ड्यासबोर्ड';

  @override
  String get online => 'अनलाइन';

  @override
  String get offline => 'अफलाइन';

  @override
  String get welcomeBack => 'फेरि स्वागत छ,';

  @override
  String get todaysDeliveries => 'आजको डेलिभरीहरू';

  @override
  String get salesReturns => 'सेल्स रिटर्न';

  @override
  String get categories => 'कोटिहरू';

  @override
  String get customers => 'ग्राहकहरू';

  @override
  String get quickActions => 'द्रुत कार्यहरू';

  @override
  String get newDelivery => 'नयाँ डेलिभरी';

  @override
  String get createNewDelivery => 'नयाँ डेलिभरी सिर्जना गर्नुहोस्';

  @override
  String get salesReturn => 'सेल्स रिटर्न';

  @override
  String get recordSalesReturn => 'सेल्स रिटर्न रेकर्ड गर्नुहोस्';

  @override
  String get sync => 'सिङ्क';

  @override
  String get syncPendingData => 'पेन्डिङ डेटा सिङ्क गर्नुहोस्';

  @override
  String get yourLocationIsBeingTracked => 'तपाईंको स्थान ट्र्याक गरिँदैछ';

  @override
  String get pleaseStartDuty => 'कृपया ड्युटी सुरु गर्नुहोस्';

  @override
  String get startDuty => 'ड्युटी सुरु गर्नुहोस्';

  @override
  String get stopDuty => 'ड्युटी बन्द गर्नुहोस्';

  @override
  String get syncNow => 'अहिले सिङ्क गर्नुहोस्';

  @override
  String syncNowPending(Object count) {
    return 'अहिले सिङ्क गर्नुहोस् ($count पेन्डिङ)';
  }

  @override
  String get noPendingDataToSync => 'सिङ्क गर्न पेन्डिङ डेटा छैन';

  @override
  String countPending(Object count) {
    return '$count पेन्डिङ';
  }

  @override
  String get addProducts => 'उत्पादनहरू थप्नुहोस्';

  @override
  String get editDelivery => 'डेलिभरी सम्पादन गर्नुहोस्';

  @override
  String get invoice => 'इन्भ्वाइस';

  @override
  String get viewingCompletedInvoice => 'पूरा भएको इन्भ्वाइस हेर्दै';

  @override
  String get customer => 'ग्राहक';

  @override
  String get items => 'वस्तुहरू';

  @override
  String get total => 'जम्मा';

  @override
  String get all => 'सबै';

  @override
  String get searchProducts => 'उत्पादनहरू खोज्नुहोस्...';

  @override
  String get clearFilter => 'फिल्टर हटाउनुहोस्';

  @override
  String get noProductsInCategory => 'यस कोटीमा कुनै उत्पादन छैन';

  @override
  String get selectCategoryToBrowse => 'उत्पादनहरू हेर्न कोटी चयन गर्नुहोस्';

  @override
  String get add => 'थप्नुहोस्';

  @override
  String get addMore => 'थप थप्नुहोस्';

  @override
  String get inCart => 'कार्टमा:';

  @override
  String get pleaseSelectCustomerAndItems =>
      'कृपया ग्राहक चयन गर्नुहोस् र वस्तुहरू थप्नुहोस्';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get qty => 'मात्रा';

  @override
  String get available => 'उपलब्ध:';

  @override
  String get noDeliveriesForToday => 'आजको लागि कुनै डेलिभरी छैन';

  @override
  String get cart => 'कार्ट';

  @override
  String get clear => 'खाली गर्नुहोस्';

  @override
  String get cartIsEmpty => 'कार्ट खाली छ';

  @override
  String get continueLabel => 'जारी राख्नुहोस्';

  @override
  String get lineTotal => 'लाइन जम्मा';

  @override
  String get editPrice => 'मूल्य सम्पादन गर्नुहोस्';

  @override
  String get unitPrice => 'एकाइ मूल्य';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get save => 'सुरक्षित गर्नुहोस्';

  @override
  String get customerLabel => 'ग्राहक:';

  @override
  String get billing => 'बिलिङ';

  @override
  String get invoiceSavedSuccessfully => 'इन्भ्वाइस सफलतापूर्वक सुरक्षित भयो';

  @override
  String get backToDashboard => 'ड्यासबोर्डमा फर्कनुहोस्';

  @override
  String get grossAmount => 'कुल रकम';

  @override
  String get discount => 'छुट';

  @override
  String get discountType => 'छुट प्रकार';

  @override
  String get none => 'कुनै पनि होइन';

  @override
  String get amountRs => 'रकम (रु.)';

  @override
  String get percent => 'प्रतिशत (%)';

  @override
  String get totalAmount => 'जम्मा रकम';

  @override
  String get paymentDetails => 'भुक्तानी विवरण';

  @override
  String get paymentMode => 'भुक्तानी मोड';

  @override
  String get paidAmount => 'भुक्तान गरिएको रकम';

  @override
  String get remarksOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get saving => 'सुरक्षित गरिँदै...';

  @override
  String get saveInvoice => 'इन्भ्वाइस सुरक्षित गर्नुहोस्';

  @override
  String get failedToSaveInvoice => 'इन्भ्वाइस सुरक्षित गर्न असफल भयो';

  @override
  String get todaysEstimates => 'आजको अनुमानहरू';

  @override
  String get noEstimatesForToday => 'आजको लागि कुनै अनुमान छैन';

  @override
  String get salesReturnSaved => 'सेल्स रिटर्न सुरक्षित भयो';

  @override
  String get successfullyRecorded => 'सफलतापूर्वक रेकर्ड गरियो';

  @override
  String get newSalesReturn => 'नयाँ सेल्स रिटर्न';

  @override
  String get product => 'उत्पादन';

  @override
  String get products => 'उत्पादनहरू';

  @override
  String get quantity => 'मात्रा';

  @override
  String get additionalDetails => 'अतिरिक्त विवरण';

  @override
  String get reasonOptional => 'कारण (वैकल्पिक)';

  @override
  String get saveSalesReturn => 'सेल्स रिटर्न सुरक्षित गर्नुहोस्';

  @override
  String get selectProduct => 'उत्पादन चयन गर्नुहोस्';

  @override
  String get failedToSaveSalesReturn => 'सेल्स रिटर्न सुरक्षित गर्न असफल भयो';

  @override
  String get syncStatus => 'सिङ्क स्थिति';

  @override
  String get pending => 'पेन्डिङ';

  @override
  String get failed => 'असफल';

  @override
  String get synced => 'सिङ्क गरिएको';

  @override
  String get lastSync => 'अन्तिम सिङ्क';

  @override
  String get never => 'कहिल्यै पनि होइन';

  @override
  String get syncing => 'सिङ्क गरिँदै...';

  @override
  String get serverData => 'सर्भर डेटा';

  @override
  String get syncAll => 'सबै सिङ्क गर्नुहोस्';

  @override
  String get syncCompletedSuccessfully => 'सिङ्क सफलतापूर्वक पूरा भयो!';

  @override
  String get pendingItems => 'पेन्डिङ वस्तुहरू';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अङ्ग्रेजी';

  @override
  String get nepali => 'नेपाली';

  @override
  String get delivery => 'डेलिभरी';

  @override
  String deliveryNumber(Object id) {
    return 'डेलिभरी #$id';
  }

  @override
  String get phone => 'फोन:';

  @override
  String get date => 'मिति:';

  @override
  String get payment => 'भुक्तानी:';

  @override
  String get paid => 'भुक्तान गरिएको:';

  @override
  String qtyWithPrice(Object price, Object qty) {
    return 'मात्रा: $qty × रु. $price';
  }

  @override
  String itemCount(Object count) {
    return '$count वस्तु';
  }

  @override
  String itemCountPlural(Object count) {
    return '$count वस्तुहरू';
  }

  @override
  String customerId(Object id) {
    return 'ग्राहक #$id';
  }

  @override
  String estimateNumber(Object id) {
    return 'अनुमान #$id';
  }

  @override
  String statusLabel(Object status) {
    return 'स्थिति: $status';
  }

  @override
  String get deliveryShort => 'डेलिभरी';

  @override
  String get receipt => 'रसिद';
}
