const firebaseConfig = {
  apiKey: "AIzaSyDFegY-o71J9jW6_wmGw2sdg0ZQp4EuNc8",
  authDomain: "nopcommerce-e42f7.firebaseapp.com",
  databaseURL: "https://nopcommerce-e42f7.firebaseio.com",
  projectId: "nopcommerce-e42f7",
  storageBucket: "nopcommerce-e42f7.appspot.com",
  messagingSenderId: "462895795064",
  appId: "1:462895795064:web:d2b330a8632127a575968d",
  measurementId: "G-RFNFKJCGTV"
};


// Initialize Firebase
firebase.initializeApp(firebaseConfig);

debugger;
firebase.auth().languageCode = 'en';

window.recaptchaVerifier = new firebase.auth.RecaptchaVerifier('SubmitBtn', {
  'size': 'invisible',
  'callback': function (response) {
    // reCAPTCHA solved, allow signInWithPhoneNumber.
    //alert('1');
    onSignInSubmit();
  }
});

window.recaptchaVerifier = new firebase.auth.RecaptchaVerifier('reCAPTCHA', {
  'size': 'normal',
  'callback': function (response) {

    sendCode();
    showConfirmBtn();
  },
  'expired-callback': function () {
    // Response expired. Ask user to solve reCAPTCHA again.
    // ...
  }
});
recaptchaVerifier.render().then(function (widgetId) {
  window.recaptchaWidgetId = widgetId;

});

//var recaptchaResponse = grecaptcha.getResponse(window.recaptchaWidgetId);

function Succeeded() {
  showSubmitBtn();
  hideConfirmBtn();
  //alert('Succeeded');
}
function SignInFailed() {
  //alert('SignInFailed');
}
function confirm() {
  var code = document.getElementById('Code').value;
  //$("#Code").val();
  window.confirmationResult.confirm(code).then(function (result) {
    // User signed in successfully.
    Succeeded();
    var user = result.user;
    var credential = firebase.auth.PhoneAuthProvider.credential(confirmationResult.verificationId, code);

    // ...
  }).catch(function (error) {
    // User couldn't sign in (bad verification code?)
    SignInFailed();
  });
}

function sendCode() {
  var phoneNumber = document.getElementById('PhoneNumber').value;
  //$("#PhoneNumber").val();// "01206173975"
  var appVerifier = window.recaptchaVerifier;
  firebase.auth().signInWithPhoneNumber(phoneNumber, appVerifier)
    .then(function (confirmationResult) {
      // SMS sent. Prompt user to type the code from the message, then sign the
      // user in with confirmationResult.confirm(code).
      window.confirmationResult = confirmationResult;
    }).catch(function (error) {
      // Error; SMS not sent
      // ...
    });
}

function onSignInSubmit() {
  alert('onSignInSubmit');
}
function showConfirmBtn() {
  $('#ConfirmBtn').show();
}
function showSubmitBtn() {
  $('#SubmitBtn').show();
}

function hideConfirmBtn() {
  $('#ConfirmBtn').hide();
}
function hideSubmitBtn() {
  $('#SubmitBtn').hide();
}