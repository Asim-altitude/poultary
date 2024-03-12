// import 'package:clever_ads_solutions/public/AdCallback.dart';
// import 'package:clever_ads_solutions/public/AdPosition.dart';
// import 'package:clever_ads_solutions/public/AdSize.dart';
// import 'package:clever_ads_solutions/public/AdImpression.dart';
// import 'package:clever_ads_solutions/public/AdViewListener.dart';
// import 'package:clever_ads_solutions/public/CASBannerView.dart';
// import 'package:clever_ads_solutions/public/ConsentFlow.dart';
// import 'package:clever_ads_solutions/public/InitConfig.dart';
// import 'package:clever_ads_solutions/public/InitializationListener.dart';
// import 'package:clever_ads_solutions/public/MediationManager.dart';
// import 'package:clever_ads_solutions/public/OnDismissListener.dart';
// import 'package:clever_ads_solutions/public/UserConsent.dart';
// import 'package:flutter/material.dart';
// import 'package:clever_ads_solutions/CAS.dart';
// import 'package:clever_ads_solutions/public/ManagerBuilder.dart';
// import 'package:clever_ads_solutions/public/AdTypes.dart';
// import 'package:poultary/utils/utils.dart';
// class InitializationListenerWrapper extends InitializationListener {
//   @override
//   void onCASInitialized(InitConfig initialConfig) {
//     String error = initialConfig.error;
//     String countryCode = initialConfig.countryCode;
//     bool isTestMode = initialConfig.isTestMode;
//     bool isConsentRequired = initialConfig.isConsentRequired;
//   }
// }
//
// class DismissListenerWrapper extends OnDismissListener {
//   @override
//   onConsentFlowDismissed(int status) {
//   }
// }
//
// class InterstitialListenerWrapper extends AdCallback {
//   @override
//   void onClicked() {
//     // print("click");
//   }
//
//   @override
//   void onClosed() {
//     // print("closed");
//   }
//
//   @override
//   void onComplete() {
//     // print("complete");
//   }
//
//   @override
//   void onImpression(AdImpression? adImpression) {
//     // print(adImpression?.cpm);
//   }
//
//   @override
//   void onShowFailed(String? message) {}
//
//   @override
//   void onShown() {
//     // print("shown");
//   }
// }
//
// class AdaptiveBannerListener extends AdViewListener {
//   @override
//   void onAdViewPresented() {
//     // print("pr");
//     //Utils.isShowAdd = true;
//
//   }
//
//   @override
//   void onClicked() {
//     // print("click");
//   }
//
//   @override
//   void onFailed(String? message) {
//     // TODO: implement onFailed
//     // print('LostLOST');
//     //Utils.isShowAdd = false;
//   }
//
//   @override
//   void onImpression(AdImpression? adImpression) {
//     // print(adImpression?.cpm);
//   }
//
//   @override
//   void onLoaded() {
//     // TODO: implement onLoaded
//   }
// }
//
// class StandartBannerListener extends AdViewListener {
//   @override
//   void onAdViewPresented() {
//     // print("pr");
//   }
//
//   @override
//   void onClicked() {
//     // print("click");
//   }
//
//   @override
//   void onFailed(String? message) {
//     // TODO: implement onFailed
//   }
//
//   @override
//   void onImpression(AdImpression? adImpression) {
//     // print(adImpression?.cpm);
//   }
//
//   @override
//   void onLoaded() {
//     // TODO: implement onLoaded
//   }
// }